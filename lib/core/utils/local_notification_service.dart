import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_action_controller.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String urgentChannelId = 'edokter_urgent';
  static const String urgentChannelName = 'Panggilan Darurat & Konsultasi IGD';
  static const String urgentChannelDescription =
      'Notifikasi prioritas tinggi untuk panggilan medis darurat.';

  static const String standardChannelId = 'edokter_standard';
  static const String standardChannelName = 'Notifikasi Klinis & Pembaruan';
  static const String standardChannelDescription =
      'Notifikasi rutin untuk hasil lab, perkiraan biaya, dan admisi baru.';

  static const String alertGroupKey = 'id.khanza.edokter.ALERTS_GROUP';
  static const int summaryNotificationId = 999999;

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          NotificationActionController.handlePayload(payload);
        }
      },
    );

    if (Platform.isAndroid) {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // 1. Channel Darurat (Maksimal / Alarm stream)
        const urgentChannel = AndroidNotificationChannel(
          urgentChannelId,
          urgentChannelName,
          description: urgentChannelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        // 2. Channel Standar (Default)
        const standardChannel = AndroidNotificationChannel(
          standardChannelId,
          standardChannelName,
          description: standardChannelDescription,
          importance: Importance.defaultImportance,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        await androidImplementation.createNotificationChannel(urgentChannel);
        await androidImplementation.createNotificationChannel(standardChannel);
      }
    }
  }

  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final iosImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  /// Displays an individual notification with audio/vibration.
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool isUrgent = false,
    bool playSound = true,
  }) async {
    final channelId = isUrgent ? urgentChannelId : standardChannelId;
    final channelName = isUrgent ? urgentChannelName : standardChannelName;
    final channelDesc =
        isUrgent ? urgentChannelDescription : standardChannelDescription;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: isUrgent ? Importance.max : Importance.defaultImportance,
      priority: isUrgent ? Priority.high : Priority.defaultPriority,
      playSound: playSound,
      enableVibration: playSound,
      groupKey: alertGroupKey,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: isUrgent ? 'Darurat IGD' : 'Pembaruan Klinis',
      ),
    );

    const darwinDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Displays an InboxStyle native summary card when backlog > 3 alerts.
  static Future<void> showGroupSummary({
    required int count,
    required List<String> previewLines,
  }) async {
    if (!Platform.isAndroid) return;

    final inboxStyle = InboxStyleInformation(
      previewLines,
      contentTitle: '$count Notifikasi Klinis Baru',
      summaryText: 'E-Dokter SIMRS',
    );

    final androidDetails = AndroidNotificationDetails(
      standardChannelId,
      standardChannelName,
      channelDescription: standardChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      groupKey: alertGroupKey,
      setAsGroupSummary: true,
      styleInformation: inboxStyle,
      playSound: false,
      enableVibration: false,
    );

    await _notificationsPlugin.show(
      summaryNotificationId,
      '$count Notifikasi Klinis Baru',
      'Ketuk untuk melihat pembaruan di aplikasi.',
      NotificationDetails(android: androidDetails),
      payload: '{"event_type":"backlog_summary"}',
    );
  }
}
