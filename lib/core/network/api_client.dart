import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' as getx;
import '../config/app_config.dart';
import '../../features/auth/controllers/auth_controller.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  static String? _cachedToken;

  static void setCachedToken(String? token) {
    _cachedToken = token;
  }

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConfig.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        _cachedToken ??= await _storage.read(key: 'auth_token');
        if (_cachedToken != null) {
          options.headers['Authorization'] = 'Bearer $_cachedToken';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          _cachedToken = null;
          final username = await _storage.read(key: 'username');
          final password = await _storage.read(key: 'password');

          if (username != null && password != null) {
            try {
              final silentDio = Dio(BaseOptions(
                baseUrl: AppConfig.baseUrl,
                connectTimeout: const Duration(milliseconds: AppConfig.connectTimeout),
                receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
              ));

              final loginRes = await silentDio.post('/auth/login', data: {
                'username': username,
                'password': password,
              });

              if (loginRes.data['success'] == true) {
                final token = loginRes.data['token'];
                _cachedToken = token;
                await _storage.write(key: 'auth_token', value: token);

                // Restart SSE stream with fresh token
                try {
                  if (getx.Get.isRegistered<AuthController>()) {
                    getx.Get.find<AuthController>().initNotificationSse();
                  }
                } catch (_) {
                  // AuthController may not be registered yet
                }

                final requestOptions = error.requestOptions;
                requestOptions.headers['Authorization'] = 'Bearer $token';

                final retryDio = Dio(BaseOptions(
                  baseUrl: AppConfig.baseUrl,
                  connectTimeout: const Duration(milliseconds: AppConfig.connectTimeout),
                  receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
                ));
                final response = await retryDio.fetch(requestOptions);
                return handler.resolve(response);
              }
            } catch (_) {
              _cachedToken = null;
              await _storage.deleteAll();
              getx.Get.offAllNamed('/login');
            }
          } else {
            _cachedToken = null;
            await _storage.deleteAll();
            getx.Get.offAllNamed('/login');
          }
        }
        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;
}
