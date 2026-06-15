import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';

class AuthController extends GetxController {
  final _storage = const FlutterSecureStorage();
  final _api = ApiClient();

  final isLoading = false.obs;
  final errorMsg = ''.obs;
  final user = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final token = await _storage.read(key: 'auth_token');
    final userData = await _storage.read(key: 'user_data');
    if (token != null && userData != null) {
      try {
        user.value = Map<String, dynamic>.from(jsonDecode(userData));
      } catch (_) {}
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

        user.value = userData;
        Get.offAllNamed('/home');
      } else {
        errorMsg.value = response.data['message'] ?? 'Login gagal';
      }
    } catch (e) {
      errorMsg.value = 'Koneksi gagal. Periksa jaringan Anda.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    user.value = null;
    Get.offAllNamed('/login');
  }
}
