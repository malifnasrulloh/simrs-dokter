import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../utils/local_notification_service.dart';
import '../utils/google_fonts.dart';
import '../../features/dashboard/controllers/dashboard_controller.dart';
import '../../features/rekam_medis/controllers/rekam_medis_controller.dart';

/// Polls the backend notification_queue table at a regular interval.
/// Replaces the SSE-based push that never worked reliably.
class NotificationPollingService extends GetxService {
  static const String _deviceIdKey = 'notification_device_id';
  static const Duration _pollInterval = Duration(seconds: 5);

  Timer? _timer;
  String _deviceId = '';
  int _lastReadId = 0;
  bool _initialized = false;
  final _api = ApiClient();

  // ── Lifecycle ──────────────────────────────────────────────────────

  /// Initialize device ID (call once on app startup).
  Future<void> init() async {
    _deviceId = await _getOrCreateDeviceId();
    _initialized = true;
  }

  /// Start polling. Call after login or when token is refreshed.
  void start() {
    if (!_initialized) return;
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
    // Immediate first poll
    _poll();
  }

  /// Stop polling. Call on logout.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// One-time backlog fetch. Call on AppLifecycleState.resumed.
  Future<void> fetchBacklog() async {
    await _poll();
  }

  /// Reset cursor to 0 and re-fetch everything (used after token refresh).
  void resetCursor() {
    _lastReadId = 0;
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }

  // ── Device ID ──────────────────────────────────────────────────────

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_deviceIdKey);
    if (cached != null && cached.isNotEmpty) return cached;

    String rawId;
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        rawId = 'android_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        rawId = 'ios_${iosInfo.identifierForVendor ?? DateTime.now().millisecondsSinceEpoch}';
      } else {
        rawId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (_) {
      rawId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }

    // Truncate if absurdly long (shouldn't happen, but safety)
    final deviceId = rawId.length > 100 ? rawId.substring(0, 100) : rawId;
    await prefs.setString(_deviceIdKey, deviceId);
    return deviceId;
  }

  // ── Polling ────────────────────────────────────────────────────────

  Future<void> _poll() async {
    if (_deviceId.isEmpty) return;

    try {
      final response = await _api.dio.get(
        '/notifications/poll',
        queryParameters: {'device_id': _deviceId},
      );

      final data = response.data;
      if (data == null || data['success'] != true) return;

      final notifList = data['data']?['notifications'] as List?;
      if (notifList == null || notifList.isEmpty) return;

      final int lastId = data['data']?['last_id'] ?? 0;

      for (final item in notifList) {
        if (item is! Map) continue;
        final eventType = item['event_type'] as String? ?? '';
        final title = item['title'] as String? ?? '';
        final body = item['body'] as String? ?? '';
        Map<String, dynamic> payload = {};
        try {
          final payloadRaw = item['payload'];
          if (payloadRaw is Map) {
            payload = Map<String, dynamic>.from(payloadRaw);
          } else if (payloadRaw is String && (payloadRaw as String).isNotEmpty) {
            payload = Map<String, dynamic>.from(
              // ignore: avoid_dynamic_calls
              (jsonDecode(payloadRaw as String) as Map?) ?? {},
            );
          } else {
            payload = {};
          }
        } catch (_) {
          payload = {};
        }

        _dispatchNotification(
          eventType: eventType,
          title: title,
          body: body,
          payload: payload,
          notificationId: item['id'] as int? ?? 0,
        );
      }

      // Track the highest ID for ack
      // Only advance _lastReadId if the ack succeeds, so a failed ack
      // does not permanently skip notifications on the next poll.
      if (lastId > _lastReadId) {
        final acked = await _sendAck(lastId);
        if (acked) {
          _lastReadId = lastId;
        }
      }
    } catch (_) {
      // Silent fail — polling retries on next timer tick
    }
  }

  Future<bool> _sendAck(int lastId) async {
    try {
      final res = await _api.dio.post('/notifications/ack', data: {
        'device_id': _deviceId,
        'last_id': lastId,
      });
      return res.data?['success'] == true;
    } catch (_) {
      return false; // Next poll will retry
    }
  }

  // ── Dispatch ───────────────────────────────────────────────────────

  void _dispatchNotification({
    required String eventType,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
    required int notificationId,
  }) {
    final isTesting = Platform.environment.containsKey('FLUTTER_TEST');
    final isUrgent = eventType == 'emergency_igd_consultation';
    final notifId = notificationId % 100000;

    // ── In-app snackbar ──
    if (AppConfig.enableInAppNotifications && !isTesting) {
      _showInAppNotification(
        title: title,
        body: body,
        isUrgent: isUrgent,
      );
    }

    // ── System notification via awesome_notifications ──
    if (AppConfig.enableSystemNotifications && !isTesting) {
      LocalNotificationService.showNotification(
        id: notifId,
        title: title,
        body: body,
        payload: payload.toString(),
      );
    }

    // ── Background data refresh ──
    _refreshDashboards(eventType);
  }

  void _showInAppNotification({
    required String title,
    required String body,
    bool isUrgent = false,
  }) {
    Get.rawSnackbar(
      titleText: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      messageText: Text(
        body,
        style: GoogleFonts.outfit(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
      backgroundColor: isUrgent
          ? const Color(0xFFE11D48).withValues(alpha: 0.95)
          : const Color(0xFF1E293B).withValues(alpha: 0.95),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 14,
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: isUrgent ? 6 : 4),
      shouldIconPulse: false,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isUrgent ? Icons.warning_amber_rounded : Icons.notifications_active_rounded,
          color: isUrgent ? Colors.white : const Color(0xFF2DD4BF),
          size: 18,
        ),
      ),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
      dismissDirection: DismissDirection.horizontal,
    );
  }

  void _refreshDashboards(String eventType) {
    try {
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().fetchDashboard(isBackground: true);
      }
    } catch (_) {}

    try {
      if (Get.isRegistered<RekamMedisController>()) {
        final rm = Get.find<RekamMedisController>();

        // Category A: Consultation/SBAR — refresh consultation tab + full data
        if (eventType == 'consultation_request' ||
            eventType == 'consultation_response' ||
            eventType == 'emergency_igd_consultation' ||
            eventType == 'sbar_request') {
          rm.fetchConsultations(isBackground: true);
          rm.fetchAllData(isBackground: true);
        }
        // Category B: Lab / Radiology — refresh lab & radio tabs
        else if (eventType == 'lab_request' ||
            eventType == 'labpa_request' ||
            eventType == 'labmb_request' ||
            eventType == 'radiology_request') {
          rm.fetchAllData(isBackground: true);
        }
        // Category C: Medication — refresh obat tab
        else if (eventType == 'discharge_prescription' ||
            eventType == 'prescription_dispensed' ||
            eventType == 'medication_stock_request' ||
            eventType == 'medication_dispensed' ||
            eventType == 'medication_request') {
          rm.fetchAllData(isBackground: true);
        }
        // Category D: Patient admission / bed / surgery — refresh all
        else if (eventType == 'new_admission' ||
            eventType == 'bed_request' ||
            eventType == 'surgery_booking') {
          rm.fetchAllData(isBackground: true);
        }
        // Category E: Billing threshold — refresh billing section only
        else if (eventType.startsWith('billing_threshold')) {
          rm.fetchBillingOnly();
        }
      }
    } catch (_) {}
  }
}
