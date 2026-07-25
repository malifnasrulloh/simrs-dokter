import 'dart:convert';
import 'dart:ui';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:get/get.dart';

/// Handles actions from system notifications (awesome_notifications).
class NotificationActionController {
  static final pendingNavigation = Rx<_NavigationRequest?>(null);

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
      return;
    }
    final sendPort =
        IsolateNameServer.lookupPortByName('edokter_notification_action_port');
    if (sendPort != null) {
      sendPort.send(receivedAction);
    } else {
      _handleAction(receivedAction);
    }
  }

  static void _handleAction(ReceivedAction action) {
    final payloadStr = action.payload?['data'] ?? '';
    if (payloadStr.isEmpty) return;

    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(payloadStr) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final eventType = payload['event_type'] as String? ?? '';
    final noRawat = payload['no_rawat'] as String? ?? '';
    if (noRawat.isEmpty || eventType.isEmpty) return;

    pendingNavigation.value = _NavigationRequest(
      eventType: eventType,
      noRawat: noRawat,
    );
  }
}

class _NavigationRequest {
  final String eventType;
  final String noRawat;
  const _NavigationRequest({
    required this.eventType,
    required this.noRawat,
  });
}