import 'dart:isolate';
import 'dart:ui';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:get/get.dart';

/// Handles notification actions (tap, dismiss, button press) for awesome_notifications.
/// Initialized in main.dart using the global isolate pattern.
class NotificationActionController {
  static final Rx<ReceivedAction?> pendingAction = Rx<ReceivedAction?>(null);

  /// Must be called from main() to receive background notification events.
  static Future<void> initializeIsolateReceivePort() async {
    final receivePort = ReceivePort('Notification action port')
      ..listen((silentData) {
        if (silentData is ReceivedAction) {
          _handleAction(silentData);
        }
      });

    IsolateNameServer.registerPortWithName(
      receivePort.sendPort,
      'edokter_notification_action_port',
    );
  }

  /// Start listening to foreground notification events.
  static void startListening() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    if (receivedAction.actionType == ActionType.SilentAction ||
        receivedAction.actionType == ActionType.SilentBackgroundAction) {
      // Background action — nothing to navigate, just log
      return;
    }

    // Forward to main isolate for navigation
    final sendPort =
        IsolateNameServer.lookupPortByName('edokter_notification_action_port');
    if (sendPort != null) {
      sendPort.send(receivedAction);
    } else {
      // Already in main isolate
      _handleAction(receivedAction);
    }
  }

  static void _handleAction(ReceivedAction action) {
    // User tapped a notification — we could navigate somewhere specific
    // based on action.payload or buttonKey
    // For now, just mark as pending so any active screen can respond
    pendingAction.value = action;
  }
}
