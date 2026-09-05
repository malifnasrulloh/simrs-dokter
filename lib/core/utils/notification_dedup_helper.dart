import 'package:shared_preferences/shared_preferences.dart';

/// Client-side deduplication helper to prevent double-alerting.
/// Tracks the last 100 displayed notification IDs in SharedPreferences.
/// If an alert was already displayed by the FCM background runner,
/// the foreground polling service skips re-alerting (no sound, no duplicate snackbar).
class NotificationDedupHelper {
  static const String _key = 'displayed_notification_ids';
  static const int _maxEntries = 100;

  static Future<bool> isDisplayed(int id) async {
    if (id <= 0) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_key) ?? [];
      return list.contains(id.toString());
    } catch (_) {
      return false;
    }
  }

  static Future<void> markDisplayed(int id) async {
    if (id <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_key) ?? [];
      final idStr = id.toString();
      if (!list.contains(idStr)) {
        list.add(idStr);
        if (list.length > _maxEntries) {
          list.removeRange(0, list.length - _maxEntries);
        }
        await prefs.setStringList(_key, list);
      }
    } catch (_) {}
  }
}
