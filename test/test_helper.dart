import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:simrs_dokter/core/network/api_client.dart';

class TestHelper {
  static final Map<String, String> mockSecureStorage = {};

  static void setupTestMockChannels() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Get.testMode = true;

    // Mock FlutterSecureStorage
    const MethodChannel secureStorageChannel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (MethodCall methodCall) async {
      final args = methodCall.arguments as Map?;
      switch (methodCall.method) {
        case 'read':
          final key = args?['key'] as String?;
          return mockSecureStorage[key];
        case 'write':
          final key = args?['key'] as String?;
          final value = args?['value'] as String?;
          if (key != null && value != null) {
            mockSecureStorage[key] = value;
          }
          return null;
        case 'delete':
          final key = args?['key'] as String?;
          mockSecureStorage.remove(key);
          return null;
        case 'deleteAll':
          mockSecureStorage.clear();
          return null;
        case 'containsKey':
          final key = args?['key'] as String?;
          return mockSecureStorage.containsKey(key);
        case 'readAll':
          return mockSecureStorage;
        default:
          return null;
      }
    });

    // Mock flutter_local_notifications
    const MethodChannel localNotificationsChannel =
        MethodChannel('dexterous.com/flutter/local_notifications');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(localNotificationsChannel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'initialize':
        case 'createNotificationChannel':
        case 'show':
        case 'cancel':
        case 'cancelAll':
        case 'pendingNotificationRequests':
        case 'getActiveNotifications':
        case 'getNotificationAppLaunchDetails':
          return true;
        case 'requestPermission':
          return true;
        default:
          return null;
      }
    });

    // Mock Connectivity
    const MethodChannel connectivityChannel =
        MethodChannel('dev.fluttercommunity.plus/connectivity');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'check') {
        return ['wifi'];
      }
      return null;
    });

    const EventChannel connectivityEventChannel =
        EventChannel('dev.fluttercommunity.plus/connectivity_status');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(connectivityEventChannel, MockConnectivityStreamHandler());
  }

  static void setupMockApi() {
    final dio = ApiClient().dio;
    dio.interceptors.clear();
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final path = options.path;
        final method = options.method.toUpperCase();

        if (path.contains('/auth/login')) {
          final data = options.data as Map?;
          if (data?['username'] == 'D0001' && data?['password'] == 'password123') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'token': 'mock_jwt_token',
                'data': {
                  'kd_dokter': 'D0001',
                  'nm_dokter': 'Dr. Test Provider',
                  'username': 'D0001',
                }
              },
            ));
          } else {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 400,
              data: {
                'success': false,
                'message': 'Username atau password salah',
              },
            ));
          }
        }

        if (path.contains('/setting')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': {
                'nama_instansi': 'RS Islam Aminah',
                'alamat_instansi': 'Jl. Veteran No. 39',
              }
            },
          ));
        }

        if (path.contains('/profile')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': {
                'kd_dokter': 'D0001',
                'nm_dokter': 'Dr. Test Provider',
                'email': 'test@doctor.com',
              }
            },
          ));
        }

        if (path.contains('/list-pasien-ranap')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': [
                {
                  'no_rawat': '2026/06/20/0001',
                  'no_rkm_medis': 'P00001',
                  'nm_pasien': 'Budi Santoso',
                  'kd_dokter': 'D0001',
                  'tgl_masuk': '2026-06-20',
                  'kamar': 'Mawar 01',
                  'dpjp': [
                    {'kd_dokter': 'D0001', 'nm_dokter': 'Dr. Test Provider'}
                  ]
                }
              ]
            },
          ));
        }

        if (path.contains('/list-pasien-ralan')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': [
                {
                  'no_rawat': '2026/06/20/0002',
                  'no_rkm_medis': 'P00002',
                  'nm_pasien': 'Siti Aminah',
                  'kd_dokter': 'D0001',
                  'poliklinik': 'Poli Penyakit Dalam',
                }
              ]
            },
          ));
        }

        if (path.contains('/list-pasien-igd')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': [
                {
                  'no_rawat': '2026/06/20/0003',
                  'no_rkm_medis': 'P00003',
                  'nm_pasien': 'Joko Susilo',
                  'kd_dokter': 'D0001',
                  'status': 'Gawat Darurat',
                }
              ]
            },
          ));
        }

        if (path.contains('/harian-dokter')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': {
                'data': [
                  {
                    'no_rawat': '2026/06/20/0001',
                    'tgl_registrasi': '2026-06-20',
                    'nm_pasien': 'Budi Santoso',
                  }
                ],
                'total': 1,
              }
            },
          ));
        }

        if (path.contains('/bed')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': [
                {
                  'kd_kamar': 'K001',
                  'status_kamar': 'ISI',
                }
              ]
            },
          ));
        }

        if (path.contains('/jadwal-operasi') || path.contains('/jadwal/operasi')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': [
                {
                  'no_rawat': '2026/06/20/0001',
                  'tgl_operasi': '2026-06-21',
                  'nm_operasi': 'Operasi Usus Buntu',
                }
              ]
            },
          ));
        }

        if (path.contains('/rekammedis/pemeriksaan/sbar/validasi')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'Validasi SBAR berhasil disimpan',
            },
          ));
        }

        if (path.contains('/rekammedis/pemeriksaan/sbar')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': [
                {
                  'no_permintaan': 'KM202606200001',
                  'no_rawat': '2026/06/20/0001',
                  'nm_pasien': 'Budi Santoso',
                  's': 'Keluhan sesak nafas',
                  'b': 'Riwayat asma',
                  'a': 'Asma bronkial',
                  'r': 'Berikan nebulizer',
                  'kd_dokter': 'D0001',
                }
              ]
            },
          ));
        }

        if (path.contains('/rekammedis/soap/simpan')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'Pemeriksaan SOAP berhasil disimpan',
            },
          ));
        }

        if (path.contains('/rekammedis/soap/update')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'Pemeriksaan SOAP berhasil diubah',
            },
          ));
        }

        if (path.contains('/rekammedis/soap/hapus')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'Pemeriksaan SOAP berhasil dihapus',
            },
          ));
        }

        if (path.contains('/riwayat/pasien/soap')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': [
                {
                  'no_rawat': '2026/06/20/0001',
                  'keluhan': 'Keluhan sesak',
                  'pemeriksaan': 'Pemeriksaan paru',
                  'suhu': '36.8',
                  'tensi': '120/80',
                  'nadi': '80',
                  'respirasi': '20',
                  'tinggi': '170',
                  'berat': '65',
                  'gcs': '15',
                  'kesadaran': 'Compos Mentis',
                  'rtl': 'Observasi',
                  'penilaian': 'Asma',
                  'instruksi': 'Nebulizer tiap 8 jam',
                  'tgl_perawatan': '2026-06-20',
                  'jam_rawat': '08:00:00',
                  '_type': 'SOAP_RANAP',
                }
              ]
            },
          ));
        }

        // Catch-all mock response for other routes
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'success': true,
            'message': 'Mock successful response',
            'data': [],
          },
        ));
      },
    ));
  }
}

class MockConnectivityStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {
    events.success(['wifi']);
  }

  @override
  void onCancel(Object? arguments) {}
}
