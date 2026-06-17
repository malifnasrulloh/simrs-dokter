import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' as getx;
import '../config/app_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConfig.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          final username = await _storage.read(key: 'username');
          final password = await _storage.read(key: 'password');

          if (username != null && password != null) {
            try {
              // Perform silent re-login with a clean Dio instance to avoid interceptor loop
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
                await _storage.write(key: 'auth_token', value: token);

                // Retry original request with updated Bearer token
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
              // Silent re-login failed, wipe credentials and force re-login
              await _storage.deleteAll();
              getx.Get.offAllNamed('/login');
            }
          } else {
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
