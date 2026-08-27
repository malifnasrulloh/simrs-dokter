import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../utils/app_logger.dart';
import '../utils/local_notification_service.dart';
import '../utils/google_fonts.dart';
import '../../features/dashboard/controllers/dashboard_controller.dart';
import '../../features/rekam_medis/controllers/rekam_medis_controller.dart';

class NotifRoute {
  final String route;
  final int? tabIndex;
  const NotifRoute(this.route, {this.tabIndex});
}

const notificationRoutes = <String, NotifRoute>{
  'consultation_request': NotifRoute('/rekam-medis', tabIndex: 5),
  'consultation_response': NotifRoute('/rekam-medis', tabIndex: 5),
  'emergency_igd_consultation': NotifRoute('/rekam-medis', tabIndex: 5),
  'sbar_request': NotifRoute('/rekam-medis', tabIndex: 5),
  'second_opinion_request': NotifRoute('/rekam-medis', tabIndex: 5),
  'lab_request': NotifRoute('/rekam-medis', tabIndex: 3),
  'labpa_request': NotifRoute('/rekam-medis', tabIndex: 3),
  'labmb_request': NotifRoute('/rekam-medis', tabIndex: 3),
  'radiology_request': NotifRoute('/rekam-medis', tabIndex: 4),
  'discharge_prescription': NotifRoute('/rekam-medis', tabIndex: 2),
  'prescription_dispensed': NotifRoute('/rekam-medis', tabIndex: 2),
  'medication_stock_request': NotifRoute('/rekam-medis', tabIndex: 2),
  'medication_dispensed': NotifRoute('/rekam-medis', tabIndex: 2),
  'medication_request': NotifRoute('/rekam-medis', tabIndex: 2),
  'spiritual_guidance_request': NotifRoute('/rekam-medis', tabIndex: 0),
  'violence_protection_letter': NotifRoute('/rekam-medis', tabIndex: 0),
  'dpjp_assigned': NotifRoute('/rekam-medis'),
  'dpjp_removed': NotifRoute('/patient-list'),
  'new_admission': NotifRoute('/patient-list'),
  'bed_request': NotifRoute('/patient-list'),
  'surgery_booking': NotifRoute('/patient-list'),
  'billing_threshold_80': NotifRoute('/rekam-medis'),
  'billing_threshold_100': NotifRoute('/rekam-medis'),
  'billing_threshold_120': NotifRoute('/rekam-medis'),
};

/// Fallback target for any event type the triggers emit but the app does
/// not map explicitly (kitchen, medical/non-medical supplies, inventory,
/// leave applications, ...): land on the dashboard home tab instead of
/// silently ignoring the tap.
const NotifRoute defaultNotifRoute = NotifRoute('/home');

class NotificationPollingService extends GetxService {
  static const String _deviceIdKey = 'notification_device_id';
  static const Duration _pollInterval = Duration(seconds: 5);

  Timer? _timer;
  String _deviceId = '';
  int _lastReadId = 0;
  bool _initialized = false;
  final _api = ApiClient();

  Future<void> init() async {
    _deviceId = await _getOrCreateDeviceId();
    _initialized = true;
  }

  void start() {
    if (!_initialized) {
      init().then((_) => _startPolling());
    } else {
      _startPolling();
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
    _poll();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> fetchBacklog() async {
    await _poll();
  }

  void resetCursor() {
    _lastReadId = 0;
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }

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
        rawId =
            'ios_${iosInfo.identifierForVendor ?? DateTime.now().millisecondsSinceEpoch}';
      } else {
        rawId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (_) {
      rawId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }

    final deviceId = rawId.length > 100 ? rawId.substring(0, 100) : rawId;
    await prefs.setString(_deviceIdKey, deviceId);
    return deviceId;
  }

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
          } else if (payloadRaw is String && (payloadRaw).isNotEmpty) {
            payload = Map<String, dynamic>.from(
              (jsonDecode(payloadRaw) as Map?) ?? {},
            );
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

      if (lastId > _lastReadId) {
        final acked = await _sendAck(lastId);
        if (acked) {
          _lastReadId = lastId;
        }
      }
    } catch (e, s) {
      AppLogger.error('NotifPolling', e, s);
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
      return false;
    }
  }

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

    if (AppConfig.enableInAppNotifications && !isTesting) {
      _showInAppNotification(
        eventType: eventType,
        title: title,
        body: body,
        payload: payload,
        isUrgent: isUrgent,
      );
    }

    if (AppConfig.enableSystemNotifications && !isTesting) {
      // Include enough payload for the system notification handler
      final String sysPayload = jsonEncode({
        'event_type': eventType,
        'no_rawat': payload['no_rawat'] ?? '',
      });
      LocalNotificationService.showNotification(
        id: notifId,
        title: title,
        body: body,
        payload: sysPayload,
      );
    }

    _refreshDashboards(eventType);
  }

  void _showInAppNotification({
    required String eventType,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
    bool isUrgent = false,
  }) {
    final route = notificationRoutes[eventType] ?? defaultNotifRoute;

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
      onTap: (_) => _navigateFromNotification(eventType, payload, route),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isUrgent
              ? Icons.warning_amber_rounded
              : Icons.notifications_active_rounded,
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

  Future<void> _navigateFromNotification(
    String eventType,
    Map<String, dynamic> payload,
    NotifRoute route,
  ) async {
    final noRawat = payload['no_rawat'] as String? ?? '';

    // Mark notification as read immediately
    await _sendAck(_lastReadId);

    if (route.route == '/rekam-medis') {
      // Some events (e.g. kitchen/supply) carry no patient context; the
      // payload might lack no_rawat even on mapped clinical events.
      if (noRawat.isEmpty) {
        if (Get.currentRoute != '/home') {
          Get.offAllNamed('/home');
        }
        return;
      }
      // If already viewing the same patient, just switch tab
      if (Get.isRegistered<RekamMedisController>() &&
          Get.find<RekamMedisController>().noRawat == noRawat) {
        if (route.tabIndex != null) {
          Get.find<RekamMedisController>().activeTab.value = route.tabIndex!;
        }
        return;
      }
      Get.toNamed('/rekam-medis', arguments: <String, dynamic>{
        'no_rawat': noRawat,
        'nm_pasien': payload['nm_pasien'] ?? 'Pasien',
        '_type': payload['_type'] ?? 'RANAP',
        '_targetTab': route.tabIndex,
      });
    } else if (route.route == '/patient-list') {
      Get.toNamed('/patient-list');
    } else {
      // Default fallback: return to the dashboard shell.
      if (Get.currentRoute != '/home') {
        Get.offAllNamed('/home');
      }
    }
  }

  void _refreshDashboards(String eventType) {
    try {
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().fetchDashboard(isBackground: true);
      }
    } catch (e, s) {
      AppLogger.error('NotifPolling', e, s);
    }

    try {
      if (Get.isRegistered<RekamMedisController>()) {
        final rm = Get.find<RekamMedisController>();

        if (eventType == 'consultation_request' ||
            eventType == 'consultation_response' ||
            eventType == 'emergency_igd_consultation' ||
            eventType == 'sbar_request' ||
            eventType == 'second_opinion_request') {
          rm.fetchConsultations(isBackground: true);
          rm.fetchAllData(isBackground: true);
        } else if (eventType == 'lab_request' ||
            eventType == 'labpa_request' ||
            eventType == 'labmb_request' ||
            eventType == 'radiology_request') {
          rm.fetchAllData(isBackground: true);
        } else if (eventType == 'discharge_prescription' ||
            eventType == 'prescription_dispensed' ||
            eventType == 'medication_stock_request' ||
            eventType == 'medication_dispensed' ||
            eventType == 'medication_request' ||
            eventType == 'spiritual_guidance_request' ||
            eventType == 'violence_protection_letter') {
          rm.fetchAllData(isBackground: true);
        } else if (eventType == 'new_admission' ||
            eventType == 'bed_request' ||
            eventType == 'surgery_booking') {
          rm.fetchAllData(isBackground: true);
        } else if (eventType.startsWith('billing_threshold')) {
          rm.fetchBillingOnly();
        } else {
          // Unmapped support/facility events (kitchen, supplies, inventory,
          // leave, ...): refresh the open record in the background.
          rm.fetchAllData(isBackground: true);
        }
      }
    } catch (e, s) {
      AppLogger.error('NotifPolling', e, s);
    }
  }
}
