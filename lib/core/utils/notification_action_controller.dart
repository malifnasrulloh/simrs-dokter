import 'dart:convert';
import 'package:get/get.dart';

/// Handles actions and routing from system notification taps.
class NotificationActionController {
  static final pendingNavigation = Rx<_NavigationRequest?>(null);

  static void handlePayload(String? payloadStr) {
    if (payloadStr == null || payloadStr.isEmpty) return;

    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(payloadStr) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final eventType = payload['event_type'] as String? ?? '';
    final noRawat = payload['no_rawat'] as String? ?? '';

    if (eventType.isEmpty) return;

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
