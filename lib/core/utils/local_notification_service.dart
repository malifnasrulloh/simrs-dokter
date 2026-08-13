import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class LocalNotificationService {
  static const String channelKey = 'edokter_alerts';

  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      // Use the launcher icon as default notification icon
      'resource://mipmap/launcher_icon',
      [
        NotificationChannel(
          channelKey: channelKey,
          channelName: 'Notifikasi E-Dokter',
          channelDescription: 'Channel untuk notifikasi klinis real-time E-Dokter',
          channelGroupKey: 'edokter_group',
          defaultColor: const Color(0xFF1E293B),
          ledColor: const Color(0xFF1E293B),
          importance: NotificationImportance.Max,
          playSound: true,
          enableVibration: true,
          onlyAlertOnce: true,
          groupAlertBehavior: GroupAlertBehavior.Children,
          defaultPrivacy: NotificationPrivacy.Private,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'edokter_group',
          channelGroupName: 'E-Dokter',
        ),
      ],
      debug: false,
    );
  }

  static Future<bool> requestPermissions() async {
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!allowed) {
      return await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    return true;
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: channelKey,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        payload: payload != null ? {'data': payload} : null,
        color: const Color(0xFF1E293B),
        backgroundColor: const Color(0xFFF8FAFC),
      ),
    );
  }

}
