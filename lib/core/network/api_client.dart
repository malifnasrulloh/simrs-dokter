import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' as getx;
import '../config/app_config.dart';
import '../utils/app_logger.dart';
import '../../features/auth/controllers/auth_controller.dart';

/// Marks a request as already retried after a silent token refresh, so a
/// second 401 does not loop the refresh flow.
const String _authRetriedExtra = '_authRetried';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  static String? _cachedToken;
  static bool _refreshing = false;

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
    _dio.interceptors.add(buildAuthInterceptor());
  }

  /// The production auth interceptor: attaches the bearer token and, on 401,
  /// silently refreshes the session via POST /auth/refresh (no password) and
  /// retries the request once. Exposed for tests.
  @visibleForTesting
  InterceptorsWrapper buildAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        _cachedToken ??= await _storage.read(key: 'auth_token');
        if (_cachedToken != null) {
          options.headers['Authorization'] = 'Bearer $_cachedToken';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode != 401) {
          AppLogger.error(
            'Api',
            '${error.requestOptions.method} ${error.requestOptions.path} -> '
                '${error.response?.statusCode ?? 'no-response'}: ${error.message}',
          );
        }
        if (error.response?.statusCode == 403 ||
            error.response?.statusCode == 429) {
          _surfaceServerMessage(error);
        }
        if (error.response?.statusCode == 401) {
          // Already retried once with a fresh token — give up on this request
          // (but never swallow a rejection of the refresh call itself: that
          // means the session is gone and the user must log in again).
          final isRefreshCall =
              error.requestOptions.path.contains('/auth/refresh');
          if (error.requestOptions.extra[_authRetriedExtra] == true &&
              !isRefreshCall) {
            return handler.next(error);
          }

          final expiredToken =
              _cachedToken ?? await _storage.read(key: 'auth_token');
          _cachedToken = null;

          if (expiredToken != null) {
            if (_refreshing) {
              // Another request is already refreshing the session; wait for
              // it, then retry once with the fresh token.
              await _waitForRefresh();
              final fresh =
                  _cachedToken ?? await _storage.read(key: 'auth_token');
              if (fresh != null && fresh != expiredToken) {
                final retried = await _retryRequest(error, fresh);
                if (retried != null) return handler.resolve(retried);
              }
            } else {
              _refreshing = true;
              try {
                final token = await _refreshSession(expiredToken);
                if (token != null) {
                  final retried = await _retryRequest(error, token);
                  if (retried != null) return handler.resolve(retried);
                }
              } finally {
                _refreshing = false;
              }
            }
          }

          // Session cannot be recovered → force a clean logout.
          _cachedToken = null;
          await _storage.deleteAll();
          getx.Get.offAllNamed('/login');
        }
        return handler.next(error);
      },
    );
  }

  static String? _lastErrorSnackbar;
  static DateTime _lastErrorShownAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Surfaces the server-provided message for policy/rate-limit errors
  /// (403 write policy, 429 rate limit) without spamming when several
  /// parallel requests fail with the same message.
  void _surfaceServerMessage(DioException error) {
    final data = error.response?.data;
    final serverMessage =
        data is Map ? (data['message']?.toString() ?? '') : '';
    if (serverMessage.isEmpty) return;

    final now = DateTime.now();
    if (_lastErrorSnackbar == serverMessage &&
        now.difference(_lastErrorShownAt) < const Duration(seconds: 3)) {
      return;
    }
    _lastErrorSnackbar = serverMessage;
    _lastErrorShownAt = now;

    try {
      getx.Get.snackbar(
        'Error',
        serverMessage,
        duration: const Duration(seconds: 4),
      );
    } catch (_) {
      // No Get context yet (e.g. pre-login); message is still logged.
    }
  }

  /// Exchanges the expired JWT for a fresh one via POST /auth/refresh.
  /// Returns the new token, or null when the session is beyond the grace
  /// window (user must log in again).
  Future<String?> _refreshSession(String expiredToken) async {
    try {
      final refreshRes = await _dio.post(
        '/auth/refresh',
        data: {'token': expiredToken},
        options: Options(extra: {_authRetriedExtra: true}),
      );
      final token = refreshRes.data?['data']?['token'] as String?;
      if (token == null) return null;

      _cachedToken = token;
      await _storage.write(key: 'auth_token', value: token);

      // Reset notification polling cursor with fresh token
      try {
        if (getx.Get.isRegistered<AuthController>()) {
          getx.Get.find<AuthController>().refreshNotificationPolling();
        }
      } catch (_) {
        // AuthController may not be registered yet
      }
      return token;
    } catch (e, s) {
      AppLogger.error('Api', 'Token refresh failed: $e', s);
      return null;
    }
  }

  Future<Response?> _retryRequest(DioException error, String token) async {
    try {
      final requestOptions = error.requestOptions;
      requestOptions.headers['Authorization'] = 'Bearer $token';
      requestOptions.extra[_authRetriedExtra] = true;
      return await _dio.fetch(requestOptions);
    } catch (_) {
      return null;
    }
  }

  Future<void> _waitForRefresh() async {
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (_refreshing && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Dio get dio => _dio;
}
