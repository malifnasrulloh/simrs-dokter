import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/notification_polling_service.dart';
import '../../../core/services/fcm_push_service.dart';
import '../../../core/services/app_update_service.dart';
import '../../../core/utils/app_logger.dart';

class AuthController extends GetxController with WidgetsBindingObserver {
  final _storage = const FlutterSecureStorage();
  final _api = ApiClient();
  NotificationPollingService? get _notificationService =>
      Get.isRegistered<NotificationPollingService>()
          ? Get.find<NotificationPollingService>()
          : null;

  final isLoading = false.obs;
  final errorMsg = ''.obs;
  final user = Rxn<Map<String, dynamic>>();
  final setting = Rxn<Map<String, dynamic>>();
  final profileData = Rxn<Map<String, dynamic>>();

  bool get isAdmin => user.value?['isadmin'] == true;

  bool hasAccess(String key) {
    if (isAdmin) return true;
    final access = user.value?['userakses'];
    if (access == null) {
      return true; // Default to true in tests or unconfigured profiles
    }
    final List<dynamic> accessList = List.from(access);
    return accessList.contains(key);
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _checkToken();
  }

  Future<void> fetchSetting() async {
    try {
      final response = await _api.dio.get('/setting');
      if (response.data != null && response.data['success'] == true) {
        setting.value = Map<String, dynamic>.from(response.data['data']);
        await _storage.write(
            key: 'setting_data', value: jsonEncode(setting.value));
      }
    } catch (_) {
      try {
        final cached = await _storage.read(key: 'setting_data');
        if (cached != null) {
          setting.value = Map<String, dynamic>.from(jsonDecode(cached));
        }
      } catch (e, s) {
        AppLogger.error('Auth', e, s);
      }
    }
  }

  bool _profileFetchInFlight = false;

  Future<void> fetchProfile() async {
    if (_profileFetchInFlight) return;
    _profileFetchInFlight = true;
    try {
      final response = await _api.dio.get('/profile');
      if (response.data != null && response.data['success'] == true) {
        final data = Map<String, dynamic>.from(response.data['data']);
        profileData.value = data;
        await _storage.write(key: 'profile_data', value: jsonEncode(data));

        // Dynamically refresh permissions list if returned by profile
        final newUserAkses = data['userakses'];
        if (newUserAkses != null && user.value != null) {
          final updatedUser = Map<String, dynamic>.from(user.value!);
          updatedUser['userakses'] = newUserAkses;
          user.value = updatedUser;
          await _storage.write(
              key: 'user_data', value: jsonEncode(updatedUser));
        }
      }
    } catch (_) {
      try {
        final cached = await _storage.read(key: 'profile_data');
        if (cached != null) {
          profileData.value = Map<String, dynamic>.from(jsonDecode(cached));
        }
      } catch (e, s) {
        AppLogger.error('Auth', e, s);
      }
    } finally {
      _profileFetchInFlight = false;
    }
  }

  Future<void> _checkToken() async {
    final token = await _storage.read(key: 'auth_token');
    final userData = await _storage.read(key: 'user_data');
    final cachedSetting = await _storage.read(key: 'setting_data');
    final cachedProfile = await _storage.read(key: 'profile_data');

    if (cachedSetting != null) {
      try {
        setting.value = Map<String, dynamic>.from(jsonDecode(cachedSetting));
      } catch (e, s) {
        AppLogger.error('Auth', e, s);
      }
    }

    if (cachedProfile != null) {
      try {
        profileData.value =
            Map<String, dynamic>.from(jsonDecode(cachedProfile));
      } catch (e, s) {
        AppLogger.error('Auth', e, s);
      }
    }

    fetchSetting();

    if (token != null && userData != null) {
      try {
        user.value = Map<String, dynamic>.from(jsonDecode(userData));
      } catch (e, s) {
        AppLogger.error('Auth', e, s);
      }
      fetchProfile();
      _notificationService?.start();
      if (Get.isRegistered<AppUpdateService>()) {
        Get.find<AppUpdateService>().checkForUpdates();
      }
      Get.offAllNamed('/home');
    }
  }

  /// Server-driven write policy (decision D1).
  /// Source of truth: GET /auth/capabilities → write_access.
  /// Build-time AppConfig.enableWriteAccess is only an offline fallback
  /// until capabilities load.
  final canWriteAccess = false.obs;
  final capabilitiesLoaded = false.obs;

  bool get writeEnabled => capabilitiesLoaded.value
      ? canWriteAccess.value
      : AppConfig.enableWriteAccess;

  Future<void> fetchCapabilities() async {
    try {
      final res = await _api.dio.get('/auth/capabilities');
      if (res.data != null && res.data['success'] == true) {
        final data = res.data['data'];
        canWriteAccess.value = data?['write_access'] == true;
        capabilitiesLoaded.value = true;
      }
    } catch (e) {
      // Offline / backend down → fall back to build-time config.
      AppLogger.error('Capabilities', e);
      capabilitiesLoaded.value = false;
    }
  }

  Future<void> login(String username, String password) async {
    try {
      isLoading.value = true;
      errorMsg.value = '';

      final response = await _api.dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      if (response.data['success'] == true) {
        final token = response.data['token'];
        final userData = response.data['data'];
        final isAdmin = response.data['isadmin'] == true;
        final userAkses = List<String>.from(response.data['userakses'] ?? []);

        final userMap = Map<String, dynamic>.from(userData ?? {});
        userMap['isadmin'] = isAdmin;
        userMap['userakses'] = userAkses;

        await _storage.write(key: 'auth_token', value: token);
        await _storage.write(key: 'user_data', value: jsonEncode(userMap));

        ApiClient.setCachedToken(token);

        user.value = userMap;
        await fetchSetting();
        await fetchProfile();
        await fetchCapabilities();
        _notificationService?.start();
        FcmPushService.syncTokenWithBackend();
        if (Get.isRegistered<AppUpdateService>()) {
          Get.find<AppUpdateService>().checkForUpdates();
        }
        Get.offAllNamed('/home');
      } else {
        errorMsg.value = response.data['message'] ?? 'Login gagal';
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response != null && e.response?.data != null) {
          final data = e.response?.data;
          if (data is Map && data['message'] != null) {
            errorMsg.value = data['message'].toString();
            return;
          }
        }
      }
      errorMsg.value = 'Koneksi gagal. Periksa jaringan Anda.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    _notificationService?.stop();

    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('notification_device_id') ?? '';
      if (deviceId.isNotEmpty) {
        await FcmPushService.revokeToken(deviceId);
      }
      await _api.dio.post('/auth/logout', data: {
        'device_id': deviceId,
      });
    } catch (_) {
      // Offline logout is still valid locally.
    }
    ApiClient.setCachedToken(null);
    await _storage.deleteAll();
    user.value = null;
    setting.value = null;
    profileData.value = null;
    Get.offAllNamed('/login');
  }

  /// Called after a silent token refresh in api_client.dart
  void refreshNotificationPolling() {
    _notificationService?.resetCursor();
    _notificationService?.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Re-validate profile and permissions immediately when resuming
      fetchProfile();
      // Fetch any notifications that arrived while app was in background
      _notificationService?.fetchBacklog();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationService?.stop();
    super.onClose();
  }
}
