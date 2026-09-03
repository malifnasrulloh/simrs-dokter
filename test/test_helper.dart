import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simrs_dokter/core/network/api_client.dart';

class TestHelper {
  static final Map<String, String> mockSecureStorage = {};

  /// Flip to true to simulate a server that grants mobile write access.
  static bool mockWriteAccess = false;

  static void setupTestMockChannels() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Get.testMode = true;

    // Mock SharedPreferences (draft persistence in RekamMedisController)
    SharedPreferences.setMockInitialValues({});

    // Mock FlutterSecureStorage
    const MethodChannel secureStorageChannel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel,
            (MethodCall methodCall) async {
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

    // Mock Connectivity
    const MethodChannel connectivityChannel =
        MethodChannel('dev.fluttercommunity.plus/connectivity');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel,
            (MethodCall methodCall) async {
      if (methodCall.method == 'check') {
        return ['wifi'];
      }
      return null;
    });

    const EventChannel connectivityEventChannel =
        EventChannel('dev.fluttercommunity.plus/connectivity_status');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
            connectivityEventChannel, MockConnectivityStreamHandler());
  }

  static void setupMockApi() {
    final dio = ApiClient().dio;
    dio.interceptors.clear();
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final path = options.path;

        if (path.contains('/auth/login')) {
          final data = options.data as Map?;
          if (data?['username'] == 'D0001' &&
              data?['password'] == 'password123') {
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

        if (path.contains('/auth/harian-access')) {
          if (options.method == 'GET') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': [
                  {
                    'kd_dokter': 'D0001',
                    'nm_dokter': 'Dr. Test Provider',
                    'spesialis': 'Spesialis Anak',
                    'harian_dokter': true
                  }
                ]
              },
            ));
          } else if (options.method == 'PUT') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'message': 'Akses Harian Dokter berhasil diperbarui'
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

        // Must precede the broader `/harian-dokter` match below:
        // cara-bayar returns a bare list, not the paginated envelope.
        if (path.contains('/harian-dokter/cara-bayar')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': [
                {'kd_pj': '1', 'png_jawab': 'Umum'},
                {'kd_pj': '2', 'png_jawab': 'BPJS'},
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

        if (path.contains('/jadwal/operasi')) {
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

        if (path.contains('/pemeriksaan/dokter')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': [
                {
                  'no_permintaan': 'KM202606200002',
                  'no_rawat': '2026/06/20/0002',
                  'nm_pasien': 'Siti Rahayu',
                  'tgl_perawatan': '2026-06-20',
                  'jam_rawat': '08:30:00',
                  'situation': 'Pasien mengeluh nyeri dada',
                  'petugas': {'nik': 'N001', 'nama': 'Suster Ani'},
                  'validasi': {'status_validasi': null},
                }
              ]
            },
          ));
        }

        if (path.contains('/pemeriksaan/validasi')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 201,
            data: {
              'success': true,
              'message': 'Validasi SBAR berhasil disimpan',
            },
          ));
        }

        if (path.contains('/pemeriksaan')) {
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

        if (path.contains('/soap/ranap') || path.contains('/soap/ralan')) {
          if (options.method == 'DELETE') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'message': 'Pemeriksaan SOAP berhasil dihapus',
              },
            ));
          }
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 201,
            data: {
              'success': true,
              'message': 'Pemeriksaan SOAP berhasil disimpan',
            },
          ));
        }

        if (path.contains('/riwayat/pasien/igd-kebidanan')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': {
                'kebidanan': {
                  'no_rawat': '2026/06/20/0001',
                  'tanggal': '2026-06-20 08:45:00',
                  'gcs': '15',
                  'td': '110/70',
                  'nadi': '88',
                  'rr': '22',
                  'suhu': '36.9',
                  'bb': '60',
                  'tb': '158',
                  'tfu': '32',
                  'letak': 'Memanjang',
                  'presentasi': 'Kepala',
                  'bjj': '144',
                  'ket_bjj': 'Teratur',
                  'ctg': 'Dilakukan',
                  'inspekulo': 'Tidak',
                  'skala_nyeri': '4',
                  'lokasi': 'Perut bawah',
                  'nama_petugas': 'Bidan Rina',
                },
                'masalah_kebidanan': [
                  'Kontraksi teratur',
                  'Usia kehamilan 37 minggu'
                ],
                'rencana_kebidanan': ['Observasi his', 'Monitoring BJJ'],
              }
            },
          ));
        }

        if (path.contains('/riwayat/pasien/pemberian-obat')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': {
                'list': [
                  {
                    'kode_brng': 'OBT001',
                    'nama_brng': 'Paracetamol 500mg',
                    'jml': 10,
                    'satuan': 'tablet',
                    'aturan': '3x sehari',
                    'tgl_perawatan': '2026-06-20',
                    'jam': '08:00:00',
                  }
                ],
                'total_biaya': 5000,
              }
            },
          ));
        }

        if (path.contains('/riwayat/pasien/laboratorium')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': {
                'list': [
                  {
                    'nm_perawatan': 'Cek Darah Lengkap',
                    'tgl_periksa': '2026-06-20',
                    'jam': '08:00:00',
                    'periksa': [
                      {
                        'nm_perawatan': 'Hematologi',
                        'nilai': [
                          {
                            'Pemeriksaan': 'Hemoglobin',
                            'nilai': '13.5',
                            'satuan': 'g/dL',
                            'nilai_rujukan': '12-16',
                          }
                        ],
                      }
                    ],
                  }
                ],
                'total_biaya': 75000,
              }
            },
          ));
        }

        if (path.contains('/riwayat/pasien/radiologi')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': {
                'list': [
                  {
                    'nm_perawatan': 'Foto Thorax',
                    'tgl_periksa': '2026-06-20',
                    'jam': '08:00:00',
                  }
                ],
                'total_biaya': 120000,
              }
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

        if (path.contains('/auth/capabilities')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': {
                'write_access': TestHelper.mockWriteAccess,
                'write_endpoints': [
                  '/soap',
                  '/resep',
                  '/konsultasi',
                  '/diagnosa-prosedur'
                ],
                'notifications_enabled': true,
                'read_only': !TestHelper.mockWriteAccess,
              }
            },
          ));
        }

        // Backend paginated envelope: {list, pagination} under `data`.
        // Regression lock for the ICD search contract fix.
        if (path.contains('/diagnosa-prosedur/penyakit')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': {
                'list': [
                  {'kd_penyakit': 'J45', 'nm_penyakit': 'Asma'},
                  {
                    'kd_penyakit': 'J45.9',
                    'nm_penyakit': 'Asma, tidak spesifik'
                  },
                ],
                'pagination': {
                  'total': 2,
                  'page': 1,
                  'limit': 50,
                  'total_pages': 1
                },
              }
            },
          ));
        }

        if (path.contains('/diagnosa-prosedur/icd9')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': {
                'list': [
                  {'kode': '01.01', 'deskripsi_panjang': 'Insisi kulit'},
                ],
                'pagination': {
                  'total': 1,
                  'page': 1,
                  'limit': 50,
                  'total_pages': 1
                },
              }
            },
          ));
        }

        if (path.contains('/resep/obat-list')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': {
                'list': [
                  {
                    'kode_brng': 'OBT001',
                    'nama_brng': 'Paracetamol 500mg',
                    'total_stok': '100',
                    'satuan': 'tablet',
                  },
                ],
              },
            },
          ));
        }

        if (path.contains('/konsultasi/dokter-list')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': [
                {'kd_dokter': '2021101713', 'nm_dokter': 'dr. Aisyah'},
              ],
            },
          ));
        }

        if (path.contains('/konsultasi/masuk') ||
            path.contains('/konsultasi/keluar')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': [
                {
                  'no_permintaan': 'KM001',
                  'no_rawat': '2026/08/24/000002',
                  'kd_dokter_pemberi': 'D001',
                  'nm_dokter_pemberi': 'dr. Setiawan',
                  'kd_dokter_peminta': 'D002',
                  'nm_dokter_peminta': 'dr. Aisyah',
                  'status': 'Sudah Dijawab',
                  'jawaban': 'Lanjutkan terapi',
                },
              ],
            },
          ));
        }

        if (path.contains('/resep')) {
          if (options.method == 'POST') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 201,
              data: {
                'success': true,
                'data': {'no_resep': '202608260001'},
              },
            ));
          }
        }

        if (path.contains('/konsultasi/jawab')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'Konsultasi berhasil dijawab',
            },
          ));
        }

        if (path.contains('/konsultasi')) {
          if (options.method == 'POST') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 201,
              data: {
                'success': true,
                'data': {'no_permintaan': 'KM202608260001'},
              },
            ));
          }
        }

        if (path.contains('/setting/app-version')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': {
                'version_name': '1.3.0',
                'version_code': 1,
                'min_supported_version': '1.0.0',
                'release_notes': 'Mock release notes',
                'download_url': '/api/setting/app-download',
                'sha256_checksum': 'mock_hash',
              },
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
