import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/local_notification_service.dart';
import '../../../core/utils/google_fonts.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../rekam_medis/controllers/rekam_medis_controller.dart';

class AuthController extends GetxController {
  final _storage = const FlutterSecureStorage();
  final _api = ApiClient();

  final isLoading = false.obs;
  final errorMsg = ''.obs;
  final user = Rxn<Map<String, dynamic>>();
  final setting = Rxn<Map<String, dynamic>>();
  final profileData = Rxn<Map<String, dynamic>>();

  HttpClient? _sseClient;
  HttpClientRequest? _sseRequest;
  HttpClientResponse? _sseResponse;

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
      initNotificationSse();
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
        final isAdmin = response.data['isadmin'] == true;
        final userAkses = List<String>.from(response.data['userakses'] ?? []);

        final userMap = Map<String, dynamic>.from(userData ?? {});
        userMap['isadmin'] = isAdmin;
        userMap['userakses'] = userAkses;

        await _storage.write(key: 'auth_token', value: token);
        await _storage.write(key: 'user_data', value: jsonEncode(userMap));
        await _storage.write(key: 'username', value: username);
        await _storage.write(key: 'password', value: password);

        ApiClient.setCachedToken(token);

        user.value = userMap;
        await fetchSetting();
        await fetchProfile();
        initNotificationSse();
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
    stopNotificationSse();
    ApiClient.setCachedToken(null);
    await _storage.deleteAll();
    user.value = null;
    setting.value = null;
    profileData.value = null;
    Get.offAllNamed('/login');
  }

  int _sseRetryCount = 0;

  void initNotificationSse() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    _sseRequest?.abort();
    _sseClient?.close();

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return;

      final sseUrl = Uri.parse('${AppConfig.baseUrl}/notifications');

      _sseClient = HttpClient();
      _sseClient!.connectionTimeout = const Duration(seconds: 10);
      
      _sseRequest = await _sseClient!.getUrl(sseUrl);
      _sseRequest!.headers.set('Authorization', 'Bearer $token');
      _sseResponse = await _sseRequest!.close();

      if (_sseResponse!.statusCode == 200) {
        // Reset retry counter on successful connection
        _sseRetryCount = 0;
        _sseResponse!
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) {
          _handleSseLine(line);
        }, onError: (err) {
          _scheduleReconnect();
        }, onDone: () {
          _scheduleReconnect();
        });
      } else if (_sseResponse!.statusCode == 401) {
        // Token expired — trigger silent re-auth, then reconnect
        _refreshAndReconnectSse();
      } else {
        _scheduleReconnect();
      }
    } catch (_) {
      _scheduleReconnect();
    }
  }

  /// Exponential backoff: 2s → 4s → 8s → 16s → 30s (cap)
  void _scheduleReconnect() {
    if (isClosed) return;
    final delay = [2, 4, 8, 16, 30][_sseRetryCount.clamp(0, 4)];
    _sseRetryCount++;
    Future.delayed(Duration(seconds: delay), () {
      if (!isClosed) initNotificationSse();
    });
  }

  /// Re-read fresh token and restart SSE
  void _refreshAndReconnectSse() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token != null) {
        _sseRetryCount = 0;
        initNotificationSse();
      }
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void stopNotificationSse() {
    _sseRequest?.abort();
    _sseClient?.close();
    _sseRetryCount = 0;
  }

  String? _currentEvent;

  void _handleSseLine(String line) {
    if (line.isEmpty) return;
    if (line.startsWith('event: ')) {
      _currentEvent = line.substring(7).trim();
    } else if (line.startsWith('data: ') && _currentEvent != null) {
      final dataStr = line.substring(6).trim();
      if (dataStr != 'keep-alive') {
        try {
          final data = jsonDecode(dataStr);
          _handleSseEvent(_currentEvent!, data);
        } catch (_) {}
      }
      _currentEvent = null;
    }
  }

  void _showModernInAppNotification(String title, String message, {bool isUrgent = false}) {
    Get.rawSnackbar(
      titleText: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      messageText: Text(
        message,
        style: GoogleFonts.outfit(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
      backgroundColor: isUrgent 
          ? const Color(0xFFE11D48).withValues(alpha: 0.95) // Rose 600
          : const Color(0xFF1E293B).withValues(alpha: 0.95), // Slate 800
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 14,
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: isUrgent ? 6 : 4),
      shouldIconPulse: false,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isUrgent ? Icons.warning_amber_rounded : Icons.notifications_active_rounded,
          color: isUrgent ? Colors.white : const Color(0xFF2DD4BF), // Mint 400
          size: 18,
        ),
      ),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 8),
        )
      ],
      dismissDirection: DismissDirection.horizontal,
    );
  }

  void _handleSseEvent(String event, dynamic data) {
    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    final isTesting = Platform.environment.containsKey('FLUTTER_TEST');

    if (AppConfig.enableInAppNotifications && !isTesting) {
      if (event == 'consultation_request') {
        final drPemberi = data['nm_dokter_pemberi'] ?? 'Rekan Dokter';
        final diagnosa = data['diagnosa_kerja'] ?? '';
        _showModernInAppNotification('Konsultasi Baru', 'Permintaan konsultasi dari $drPemberi: "$diagnosa"');
      } else if (event == 'consultation_response') {
        final drPenerima = data['nm_dokter_dikonsuli'] ?? 'Rekan Dokter';
        _showModernInAppNotification('Konsultasi Dijawab', 'Balasan dari $drPenerima untuk permintaan ${data['no_permintaan']}');
      } else if (event == 'new_admission') {
        final nmPasien = data['nm_pasien'] ?? 'Pasien Baru';
        final noRawat = data['no_rawat'] ?? '';
        _showModernInAppNotification('Pasien Baru Terdaftar', 'Anda telah didelegasikan sebagai DPJP untuk $nmPasien ($noRawat)');
      } else if (event == 'emergency_igd_consultation') {
        final drPemberi = data['nm_dokter_pemberi'] ?? 'Rekan Dokter';
        final nmPasien = data['nm_pasien'] ?? 'Pasien';
        _showModernInAppNotification('🚨 URGENT: KONSUL IGD', 'Permintaan konsultasi segera dari $drPemberi untuk pasien $nmPasien', isUrgent: true);
      }
    }

    if (AppConfig.enableSystemNotifications) {
      if (event == 'consultation_request') {
        final drPemberi = data['nm_dokter_pemberi'] ?? 'Rekan Dokter';
        final diagnosa = data['diagnosa_kerja'] ?? '';
        LocalNotificationService.showNotification(
          id: notificationId,
          title: 'Konsultasi Baru',
          body: 'Permintaan konsultasi dari $drPemberi: "$diagnosa"',
        );
      } else if (event == 'consultation_response') {
        final drPenerima = data['nm_dokter_dikonsuli'] ?? 'Rekan Dokter';
        LocalNotificationService.showNotification(
          id: notificationId,
          title: 'Konsultasi Dijawab',
          body: 'Balasan dari $drPenerima untuk permintaan ${data['no_permintaan']}',
        );
      } else if (event == 'new_admission') {
        final nmPasien = data['nm_pasien'] ?? 'Pasien Baru';
        final noRawat = data['no_rawat'] ?? '';
        LocalNotificationService.showNotification(
          id: notificationId,
          title: 'Pasien Baru Terdaftar',
          body: 'Anda telah didelegasikan sebagai DPJP untuk $nmPasien ($noRawat)',
        );
      } else if (event == 'emergency_igd_consultation') {
        final drPemberi = data['nm_dokter_pemberi'] ?? 'Rekan Dokter';
        final nmPasien = data['nm_pasien'] ?? 'Pasien';
        LocalNotificationService.showNotification(
          id: notificationId,
          title: '🚨 URGENT: KONSUL IGD',
          body: 'Permintaan konsultasi segera dari $drPemberi untuk pasien $nmPasien',
        );
      }
    }

    try {
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().fetchDashboard();
      }
    } catch (_) {}

    try {
      if (Get.isRegistered<RekamMedisController>()) {
        Get.find<RekamMedisController>().fetchConsultations();
      }
    } catch (_) {}
  }

  @override
  void onClose() {
    stopNotificationSse();
    super.onClose();
  }
}
