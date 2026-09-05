import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../utils/app_logger.dart';
import '../utils/local_notification_service.dart';
import '../utils/notification_action_controller.dart';
import '../../features/dashboard/controllers/dashboard_controller.dart';
import 'package:get/get.dart';

/// Top-level background isolate entry point for FCM High-Priority Data-Only pushes.
///
/// Privacy Guarantees (UU PDP / Permenkes):
/// - ZERO Protected Health Information crosses Google servers.
/// - FCM payload strictly carries `{ notification_id, event_type, timestamp }`.
/// - The background isolate wakes, connects to Backend-Dokter over TLS,
///   authenticates with the doctor's JWT, fetches clinical details,
///   and displays the native notification locally via [LocalNotificationService].
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    await LocalNotificationService.initialize();

    final data = message.data;
    if (data.isEmpty) return;

    final eventType = data['event_type'] ?? '';
    final notificationId = int.tryParse(data['notification_id']?.toString() ?? '0') ?? 0;
    final isUrgent = eventType == 'emergency_igd_consultation';

    // 1. Silent JWT Authentication in background isolate
    const storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'auth_token');

    final api = ApiClient();
    Map<String, dynamic>? clinicalData;

    if (token != null && token.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final deviceId = prefs.getString('notification_device_id') ?? 'bg_device';

        final res = await api.dio.get(
          '/notifications/poll',
          queryParameters: {'device_id': deviceId},
        );

        if (res.data?['success'] == true) {
          final list = res.data?['data']?['notifications'] as List?;
          if (list != null && list.isNotEmpty) {
            final match = list.firstWhere(
              (n) => n['id'] == notificationId,
              orElse: () => list.last,
            );
            if (match is Map) {
              clinicalData = {
                'title': match['title'] ?? 'Panggilan Klinis',
                'body': match['body'] ?? 'Pembaruan klinis baru diterima.',
                'payload': match['payload'],
              };
            }
          }
        }
      } catch (err) {
        AppLogger.error('FCM-Background', 'Error fetching notification details: $err');
      }
    }

    // 2. Safe Fallback Display if network or token refresh fails
    final title = clinicalData?['title'] ??
        (isUrgent ? 'PANGGILAN DARURAT IGD' : 'Notifikasi Klinis E-Dokter');
    final body = clinicalData?['body'] ??
        'Terdapat pembaruan konsultasi/rekam medis. Buka aplikasi untuk rincian.';

    final payload = jsonEncode({
      'event_type': eventType,
      'no_rawat': clinicalData?['payload']?['no_rawat'] ?? '',
      'id': notificationId,
    });

    await LocalNotificationService.showNotification(
      id: notificationId % 100000,
      title: title,
      body: body,
      payload: payload,
      isUrgent: isUrgent,
      playSound: true,
    );
  } catch (e, s) {
    AppLogger.error('FCM-Background', 'Fatal background isolate error: $e', s);
  }
}

class FcmPushService {
  static final _api = ApiClient();
  static bool _initialized = false;
  static bool _hasGms = false;

  static bool get hasGms => _hasGms;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize Firebase Core if available
      await Firebase.initializeApp();
      _hasGms = true;

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Handle notification opened when app was terminated
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }

      // Handle notification opened when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      // Handle foreground push messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final data = message.data;
        if (data.isEmpty) return;

        // If app is currently in foreground, refresh dashboard
        if (Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().fetchDashboard(isBackground: true);
        }
      });

      _initialized = true;
      AppLogger.info('FCM', 'Firebase Messaging initialized successfully');
    } catch (e) {
      _hasGms = false;
      AppLogger.warn('FCM', 'Firebase Messaging not available on this device: $e');
    }
  }

  /// Registers or refreshes the FCM device push token with Backend-Dokter.
  static Future<void> syncTokenWithBackend() async {
    if (!_hasGms) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('notification_device_id') ?? '';
      if (deviceId.isEmpty) return;

      await _api.dio.post('/notifications/fcm-token', data: {
        'device_id': deviceId,
        'fcm_token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
      });

      AppLogger.info('FCM', 'FCM device token synced with Backend-Dokter');
    } catch (e) {
      AppLogger.warn('FCM', 'Failed to sync FCM token with backend: $e');
    }
  }

  /// Revokes device token on user logout.
  static Future<void> revokeToken(String deviceId) async {
    if (!_hasGms) return;

    try {
      await FirebaseMessaging.instance.deleteToken();
      await _api.dio.delete('/notifications/fcm-token', data: {
        'device_id': deviceId,
      });
      AppLogger.info('FCM', 'FCM token revoked on logout');
    } catch (e) {
      AppLogger.warn('FCM', 'Token revocation error: $e');
    }
  }

  static void _handleMessageTap(RemoteMessage message) {
    final data = message.data;
    if (data.isEmpty) return;

    final eventType = data['event_type'] ?? '';
    final noRawat = data['no_rawat'] ?? '';

    if (eventType.isNotEmpty) {
      NotificationActionController.handlePayload(jsonEncode({
        'event_type': eventType,
        'no_rawat': noRawat,
      }));
    }
  }
}
