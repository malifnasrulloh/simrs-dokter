import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:simrs_dokter/core/config/app_config.dart';
import 'package:simrs_dokter/core/network/api_client.dart';
import 'package:simrs_dokter/core/network/app_http_overrides.dart';
import 'package:simrs_dokter/features/auth/controllers/auth_controller.dart';
import 'test_helper.dart';

/// Minimal in-memory HTTP adapter that lets the test script responses by path
/// and call count, so the real auth interceptor (401 → refresh → retry) can
/// be exercised end to end.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter({required this.onFetch});

  final Future<ResponseBody> Function(RequestOptions options) onFetch;
  int dataCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return onFetch(options);
  }

  static ResponseBody json(Object body, int status) {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late List<Interceptor> savedInterceptors;
  late HttpClientAdapter savedAdapter;

  setUpAll(() {
    TestHelper.setupTestMockChannels();
  });

  setUp(() {
    TestHelper.mockSecureStorage.clear();
    final dio = ApiClient().dio;
    savedInterceptors = dio.interceptors.toList();
    savedAdapter = dio.httpClientAdapter;
  });

  tearDown(() {
    final dio = ApiClient().dio;
    dio.interceptors
      ..clear()
      ..addAll(savedInterceptors);
    dio.httpClientAdapter = savedAdapter;
    ApiClient.setCachedToken(null);
    TestHelper.mockSecureStorage.clear();
  });

  test('401 triggers silent refresh and retries the request with the new token',
      () async {
    TestHelper.mockSecureStorage['auth_token'] = 'expired_token';

    final dio = ApiClient().dio;
    dio.interceptors.clear();
    dio.httpClientAdapter = _ScriptedAdapter(onFetch: (options) async {
      if (options.path.contains('/auth/refresh')) {
        return _ScriptedAdapter.json(
          {
            'success': true,
            'data': {'token': 'fresh_token'}
          },
          200,
        );
      }
      if (options.path == '/data' &&
          !options.extra.containsKey('_authRetried')) {
        return _ScriptedAdapter.json(
          {'success': false, 'message': 'Token expired'},
          401,
        );
      }
      return _ScriptedAdapter.json({'success': true, 'data': 'ok'}, 200);
    });
    dio.interceptors.add(ApiClient().buildAuthInterceptor());

    final res = await dio.get('/data');

    expect(res.data['data'], 'ok');
    expect(TestHelper.mockSecureStorage['auth_token'], 'fresh_token');
    expect(ApiClient().dio.options.headers['Authorization'], isNull);
  });

  test('refused refresh clears the session (forced logout)', () async {
    TestHelper.mockSecureStorage['auth_token'] = 'expired_token';

    final dio = ApiClient().dio;
    dio.interceptors.clear();
    dio.httpClientAdapter = _ScriptedAdapter(onFetch: (options) async {
      if (options.path.contains('/auth/refresh')) {
        return _ScriptedAdapter.json(
          {'success': false, 'message': 'Sesi berakhir'},
          401,
        );
      }
      return _ScriptedAdapter.json({'success': false}, 401);
    });
    dio.interceptors.add(ApiClient().buildAuthInterceptor());

    await expectLater(
      dio.get('/data'),
      throwsA(isA<DioException>().having(
        (e) => e.response?.statusCode,
        'statusCode',
        401,
      )),
    );

    expect(TestHelper.mockSecureStorage.containsKey('auth_token'), isFalse);
  });

  test('login no longer persists the password to secure storage', () async {
    TestHelper.setupMockApi();
    Get.put(AuthController());
    final authCtrl = Get.find<AuthController>();
    await authCtrl.login('D0001', 'password123');

    expect(TestHelper.mockSecureStorage.containsKey('password'), isFalse);
    expect(TestHelper.mockSecureStorage.containsKey('username'), isFalse);
    expect(TestHelper.mockSecureStorage['auth_token'], 'mock_jwt_token');

    Get.delete<AuthController>();
  });

  test('AppHttpOverrides overrides global HttpClient userAgent with effectiveUserAgent', () {
    final overrides = AppHttpOverrides();
    final client = overrides.createHttpClient(null);

    expect(client.userAgent, equals(AppConfig.effectiveUserAgent));
    expect(client.userAgent?.contains('SIMRS-Dokter'), isTrue);
  });

  test('ApiClient attaches effective User-Agent and WAF custom headers on outgoing requests',
      () async {
    final dio = ApiClient().dio;
    dio.interceptors.clear();
    dio.interceptors.add(ApiClient().buildAuthInterceptor());

    String? capturedUserAgent;
    String? capturedCustomHeader;
    dio.httpClientAdapter = _ScriptedAdapter(onFetch: (options) async {
      capturedUserAgent = options.headers['User-Agent'] as String?;
      if (AppConfig.wafCustomHeader.isNotEmpty) {
        capturedCustomHeader =
            options.headers[AppConfig.wafCustomHeader] as String?;
      }
      return _ScriptedAdapter.json({'success': true}, 200);
    });

    await dio.get('/test');
    expect(capturedUserAgent, equals(AppConfig.effectiveUserAgent));
    if (AppConfig.wafCustomHeader.isNotEmpty) {
      expect(capturedCustomHeader, equals(AppConfig.wafCustomValue));
    }
  });

  test('AppConfig.effectiveUserAgent includes Token when wafCustomValue is present', () {
    expect(AppConfig.effectiveUserAgent, contains(AppConfig.userAgent));
    if (AppConfig.wafCustomValue.isNotEmpty) {
      expect(AppConfig.effectiveUserAgent, contains('Token:'));
      expect(AppConfig.effectiveUserAgent, contains(AppConfig.wafCustomValue));
    }
  });
}
