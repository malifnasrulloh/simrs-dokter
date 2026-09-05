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
import '../utils/notification_dedup_helper.dart';
import 'fcm_push_service.dart';
import '../../features/dashboard/controllers/dashboard_controller.dart';
import '../../features/rekam_medis/controllers/rekam_medis_controller.dart';
import '../../features/auth/controllers/auth_controller.dart';

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
  'dpjp_assigned': NotifRoute('/rekam-medis', tabIndex: 0),
  'dpjp_removed': NotifRoute('/home', tabIndex: 1),
  'new_admission': NotifRoute('/home', tabIndex: 1),
  'bed_request': NotifRoute('/home', tabIndex: 1),
  'surgery_booking': NotifRoute('/home', tabIndex: 1),
  'cbg_estimate_updated': NotifRoute('/rekam-medis', tabIndex: 0),
  'billing_threshold_80': NotifRoute('/rekam-medis', tabIndex: 0),
  'billing_threshold_100': NotifRoute('/rekam-medis', tabIndex: 0),
  'billing_threshold_120': NotifRoute('/rekam-medis', tabIndex: 0),
  'harian_access_updated': NotifRoute('/home', tabIndex: 2),
};

const NotifRoute defaultNotifRoute = NotifRoute('/home');

class NotificationPollingService extends GetxService {
  static const String _deviceIdKey = 'notification_device_id';

  // Adaptive Polling: 30s when FCM/GMS active; 5s fallback for non-GMS / offline
  static const Duration _fcmPollInterval = Duration(seconds: 30);
  static const Duration _legacyPollInterval = Duration(seconds: 5);

  Timer? _timer;
  String _deviceId = '';
  int _lastReadId = 0;
  bool _initialized = false;
  final _api = ApiClient();

  Duration get currentPollInterval =>
      FcmPushService.hasGms ? _fcmPollInterval : _legacyPollInterval;

  Future<void> init() async {
    _deviceId = await _getOrCreateDeviceId();
    _initialized = true;
    await FcmPushService.initialize();
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
    _timer = Timer.periodic(currentPollInterval, (_) => _poll());
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

  /// Processes incoming notification batch with intelligent anti-flood protection
  /// and trailing single dashboard refresh to prevent server overload.
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
      final isTesting = Platform.environment.containsKey('FLUTTER_TEST');

      // 1. Parse notifications
      final parsedItems = <Map<String, dynamic>>[];
      bool hasUrgent = false;
      bool hasHarianAccessUpdate = false;

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

        if (eventType == 'emergency_igd_consultation') hasUrgent = true;
        if (eventType == 'harian_access_updated') hasHarianAccessUpdate = true;

        parsedItems.add({
          'id': item['id'] as int? ?? 0,
          'event_type': eventType,
          'title': title,
          'body': body,
          'payload': payload,
        });
      }

      // Filter out items already displayed by FCM background isolate (Defense-in-Depth)
      final itemsToAlert = <Map<String, dynamic>>[];
      for (final item in parsedItems) {
        final notifId = item['id'] as int;
        final alreadyDisplayed = await NotificationDedupHelper.isDisplayed(notifId);
        if (!alreadyDisplayed) {
          itemsToAlert.add(item);
          await NotificationDedupHelper.markDisplayed(notifId);
        }
      }

      final alertBatchSize = itemsToAlert.length;

      // 2. Anti-Flood System Tray Notifications (Only for previously unseen items)
      if (AppConfig.enableSystemNotifications && !isTesting && alertBatchSize > 0) {
        if (alertBatchSize <= 3) {
          // Standard small batch: show individually with sound/vibration
          for (final n in itemsToAlert) {
            final isItemUrgent = n['event_type'] == 'emergency_igd_consultation';
            await LocalNotificationService.showNotification(
              id: (n['id'] as int) % 100000,
              title: n['title'] as String,
              body: n['body'] as String,
              payload: jsonEncode({
                'event_type': n['event_type'],
                'no_rawat': n['payload']['no_rawat'] ?? '',
              }),
              isUrgent: isItemUrgent,
              playSound: true,
            );
          }
        } else {
          // Backlog flood (> 3 alerts):
          // Ring/vibrate ONCE for the top 2 urgent items, collapse rest into Group Summary
          final urgentItems = itemsToAlert
              .where((i) => i['event_type'] == 'emergency_igd_consultation')
              .take(2)
              .toList();

          bool firstAlertPlayed = false;
          for (final n in urgentItems) {
            await LocalNotificationService.showNotification(
              id: (n['id'] as int) % 100000,
              title: n['title'] as String,
              body: n['body'] as String,
              payload: jsonEncode({
                'event_type': n['event_type'],
                'no_rawat': n['payload']['no_rawat'] ?? '',
              }),
              isUrgent: true,
              playSound: !firstAlertPlayed, // Only ring once
            );
            firstAlertPlayed = true;
          }

          // Show consolidated InboxStyle summary card
          final lines = itemsToAlert.take(5).map((i) => '• ${i['title']}').toList();
          await LocalNotificationService.showGroupSummary(
            count: alertBatchSize,
            previewLines: lines,
          );
        }
      }

      // 3. Anti-Flood In-App UI Banner (Only for previously unseen items)
      if (AppConfig.enableInAppNotifications && !isTesting && alertBatchSize > 0) {
        if (alertBatchSize == 1) {
          final first = itemsToAlert.first;
          _showInAppNotification(
            eventType: first['event_type'] as String,
            title: first['title'] as String,
            body: first['body'] as String,
            payload: first['payload'] as Map<String, dynamic>,
            isUrgent: first['event_type'] == 'emergency_igd_consultation',
          );
        } else {
          // Single consolidated banner for entire batch
          _showBatchInAppNotification(
            count: alertBatchSize,
            hasUrgent: hasUrgent,
          );
        }
      }

      // 4. Send ACK to server
      if (lastId > _lastReadId) {
        final acked = await _sendAck(lastId);
        if (acked) {
          _lastReadId = lastId;
        }
      }

      // 5. Anti-DDoS Trailing Batch Refresh (Fires exactly ONCE per batch)
      _executeTrailingBatchRefresh(
        hasHarianAccessUpdate: hasHarianAccessUpdate,
        hasClinicalUpdate: parsedItems.isNotEmpty,
      );
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

  /// Displays one consolidated banner when backlog contains multiple notifications.
  void _showBatchInAppNotification({
    required int count,
    required bool hasUrgent,
  }) {
    Get.rawSnackbar(
      titleText: Text(
        hasUrgent ? 'PANGGILAN KLINIS & PEMBARUAN' : 'Pembaruan Klinis Masuk',
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      messageText: Text(
        '$count notifikasi klinis baru diterima saat Anda tidak aktif.',
        style: GoogleFonts.outfit(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
      backgroundColor: hasUrgent
          ? const Color(0xFFE11D48).withValues(alpha: 0.95)
          : const Color(0xFF1E293B).withValues(alpha: 0.95),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 14,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 5),
      shouldIconPulse: false,
      onTap: (_) {
        if (Get.currentRoute != '/home') {
          Get.offAllNamed('/home');
        }
      },
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          hasUrgent
              ? Icons.warning_amber_rounded
              : Icons.mark_chat_unread_rounded,
          color: hasUrgent ? Colors.white : const Color(0xFF2DD4BF),
          size: 18,
        ),
      ),
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
      if (noRawat.isEmpty) {
        if (Get.currentRoute != '/home') {
          Get.offAllNamed('/home');
        }
        return;
      }
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
    } else if (route.route == '/home') {
      if (Get.currentRoute != '/home') {
        Get.offAllNamed('/home');
      }
      if (route.tabIndex != null && Get.isRegistered<DashboardController>()) {
        final dash = Get.find<DashboardController>();
        dash.currentNavIndex.value = route.tabIndex!;
        if (route.tabIndex == 1) {
          dash.selectedTab.value = 0;
        }
      }
    } else {
      if (Get.currentRoute != '/home') {
        Get.offAllNamed('/home');
      }
    }
  }

  /// Trailing batch refresh: executes exactly ONCE at the end of the batch
  /// to eliminate UI jank and avoid DDoS'ing Backend-Dokter with 50 simultaneous queries.
  void _executeTrailingBatchRefresh({
    required bool hasHarianAccessUpdate,
    required bool hasClinicalUpdate,
  }) {
    if (hasHarianAccessUpdate) {
      try {
        if (Get.isRegistered<AuthController>()) {
          Get.find<AuthController>().fetchProfile();
        }
      } catch (e, s) {
        AppLogger.error('NotifPolling', e, s);
      }
    }

    if (hasClinicalUpdate) {
      try {
        if (Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().fetchDashboard(isBackground: true);
        }
      } catch (e, s) {
        AppLogger.error('NotifPolling', e, s);
      }

      try {
        if (Get.isRegistered<RekamMedisController>()) {
          Get.find<RekamMedisController>().fetchAllData();
        }
      } catch (e, s) {
        AppLogger.error('NotifPolling', e, s);
      }
    }
  }
}
