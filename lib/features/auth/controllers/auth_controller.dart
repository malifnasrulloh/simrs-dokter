import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class AuthController extends GetxController {
  final _storage = const FlutterSecureStorage();
  final _api = ApiClient();

  final isLoading = false.obs;
  final errorMsg = ''.obs;
  final user = Rxn<Map<String, dynamic>>();
  final setting = Rxn<Map<String, dynamic>>();
  final profileData = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    _checkToken();
  }

  Future<void> fetchSetting() async {
    try {
      final response = await _api.dio.get('/setting');
      if (response.data != null && response.data['success'] == true) {
        setting.value = Map<String, dynamic>.from(response.data['data']);
        await _storage.write(key: 'setting_data', value: jsonEncode(setting.value));
      }
    } catch (_) {
      try {
        final cached = await _storage.read(key: 'setting_data');
        if (cached != null) {
          setting.value = Map<String, dynamic>.from(jsonDecode(cached));
        }
      } catch (_) {}
    }
  }

  Future<void> fetchProfile() async {
    try {
      final response = await _api.dio.get('/profile');
      if (response.data != null && response.data['success'] == true) {
        profileData.value = Map<String, dynamic>.from(response.data['data']);
        await _storage.write(key: 'profile_data', value: jsonEncode(profileData.value));
      }
    } catch (_) {
      try {
        final cached = await _storage.read(key: 'profile_data');
        if (cached != null) {
          profileData.value = Map<String, dynamic>.from(jsonDecode(cached));
        }
      } catch (_) {}
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
      } catch (_) {}
    }

    if (cachedProfile != null) {
      try {
        profileData.value = Map<String, dynamic>.from(jsonDecode(cachedProfile));
      } catch (_) {}
    }

    fetchSetting();

    if (token != null && userData != null) {
      try {
        user.value = Map<String, dynamic>.from(jsonDecode(userData));
      } catch (_) {}
      fetchProfile();
      Get.offAllNamed('/home');
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

        await _storage.write(key: 'auth_token', value: token);
        await _storage.write(key: 'user_data', value: jsonEncode(userData));
        await _storage.write(key: 'username', value: username);
        await _storage.write(key: 'password', value: password);

        user.value = userData;
        await fetchSetting();
        await fetchProfile();
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
    await _storage.deleteAll();
    user.value = null;
    setting.value = null;
    profileData.value = null;
    Get.offAllNamed('/login');
  }
}
