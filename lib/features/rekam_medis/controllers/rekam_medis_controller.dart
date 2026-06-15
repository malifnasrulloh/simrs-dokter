import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';

class RekamMedisController extends GetxController {
  final _api = ApiClient();
  final isLoading = false.obs;
  final activeTab = 0.obs;

  // Pasien info
  final pasienData = Rxn<Map<String, dynamic>>();

  // Rekam medis data
  final riwayatMedis = <Map<String, dynamic>>[].obs;
  final diagnosa = <Map<String, dynamic>>[].obs;
  final obat = <Map<String, dynamic>>[].obs;
  final laboratorium = <Map<String, dynamic>>[].obs;
  final radiologi = <Map<String, dynamic>>[].obs;
  final vitalSigns = <Map<String, dynamic>>[].obs;
  final dicomStudies = <Map<String, dynamic>>[].obs;
  final isLoadingDicom = false.obs;

  String get noRawat => pasienData.value?['no_rawat'] ?? '';
  String get noRkmMedis => pasienData.value?['no_rkm_medis'] ?? pasienData.value?['no_rm'] ?? '';
  String get tipeRawat => pasienData.value?['_type'] ?? 'RANAP';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      pasienData.value = args;
    }
  }

  @override
  void onReady() {
    super.onReady();
    if (pasienData.value != null) {
      fetchAllData();
    }
  }

  void loadPasien(Map<String, dynamic> data) {
    pasienData.value = data;
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _fetchRiwayatMedis(),
        _fetchDiagnosa(),
        _fetchObat(),
        _fetchLaboratorium(),
        _fetchRadiologi(),
        _fetchDicomStudies(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchRiwayatMedis() async {
    try {
      String endpoint = '/riwayat/pasien/medis-ranap';
      if (tipeRawat == 'IGD') {
        endpoint = '/riwayat/pasien/medis-igd';
      } else if (tipeRawat == 'RALAN') {
        endpoint = '/riwayat/pasien/soap-ralan';
      }

      var res = await _api.dio.get(endpoint, queryParameters: {'no_rawat': noRawat});
      bool hasData = res.statusCode == 200 &&
          res.data != null &&
          res.data['success'] == true &&
          res.data['data'] is List &&
          (res.data['data'] as List).isNotEmpty;

      if (!hasData && tipeRawat != 'RALAN') {
        final fallbackEndpoint = tipeRawat == 'RANAP' ? '/riwayat/pasien/soap-ranap' : '/riwayat/pasien/soap-ralan';
        res = await _api.dio.get(fallbackEndpoint, queryParameters: {'no_rawat': noRawat});
        hasData = res.statusCode == 200 &&
            res.data != null &&
            res.data['success'] == true &&
            res.data['data'] is List &&
            (res.data['data'] as List).isNotEmpty;
      }

      if (hasData) {
        final data = res.data['data'] as List;
        riwayatMedis.value = data
            .map((e) => Map<String, dynamic>.from(e))
            .map((e) => _normalizeMedisData(e))
            .toList();
      } else {
        riwayatMedis.clear();
      }
    } catch (_) {
      riwayatMedis.clear();
    }
  }

  Map<String, dynamic> _normalizeMedisData(Map<String, dynamic> raw) {
    return {
      'tanggal': raw['tanggal'] ?? raw['tgl_perawatan'] ?? '-',
      'jam': raw['jam_rawat'] ?? '-',
      'petugas': raw['nm_dokter'] ?? raw['nama'] ?? raw['nip'] ?? '-',
      'keluhan_utama': raw['keluhan_utama'] ?? raw['keluhan'] ?? '-',
      'rps': raw['rps'] ?? raw['pemeriksaan'] ?? '-',
      'rpd': raw['rpd'] ?? '-',
      'alergi': raw['alergi'] ?? '-',
      'td': raw['td'] ?? raw['tensi'] ?? '-',
      'nadi': raw['nadi'] ?? '-',
      'rr': raw['rr'] ?? raw['respirasi'] ?? '-',
      'suhu': raw['suhu'] ?? raw['suhu_tubuh'] ?? '-',
      'spo': raw['spo'] ?? raw['spo2'] ?? '-',
      'diagnosis': raw['diagnosis'] ?? raw['penilaian'] ?? '-',
      'tata': raw['tata'] ?? raw['rtl'] ?? '-',
      'edukasi': raw['edukasi'] ?? raw['instruksi'] ?? raw['evaluasi'] ?? '-',
    };
  }

  Future<void> _fetchDiagnosa() async {
    try {
      final res = await _api.dio.get('/riwayat/pasien/diagnosa', queryParameters: {'no_rawat': noRawat});
      if (res.data['success'] == true) {
        diagnosa.value = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
      }
    } catch (_) {}
  }

  Future<void> _fetchObat() async {
    try {
      final res = await _api.dio.get('/riwayat/pasien/pemberian-obat', queryParameters: {'no_rawat': noRawat});
      if (res.data['success'] == true && res.data['data'] != null) {
        final list = res.data['data']['list'] as List? ?? [];
        obat.value = list
            .where((e) => e['kode_brng'] != null) // Filter out summary/retur details if not item
            .map((e) => Map<String, dynamic>.from(e))
            .map((e) => {
                  'nama_obat': e['nama_brng'],
                  'jumlah': e['jml'],
                  'satuan': e['satuan'],
                  'aturan': e['aturan'],
                  'tgl_perawatan': e['tgl_perawatan'],
                  'jam': e['jam'],
                })
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _fetchLaboratorium() async {
    try {
      final res = await _api.dio.get('/riwayat/pasien/laboratorium', queryParameters: {'no_rawat': noRawat});
      if (res.data['success'] == true && res.data['data'] != null) {
        final listData = res.data['data']['list'] as List? ?? [];
        final List<Map<String, dynamic>> groupedLab = [];
        for (var group in listData) {
          final periksaList = group['periksa'] as List? ?? [];
          for (var periksa in periksaList) {
            final nmPerawatan = periksa['nm_perawatan'] ?? '';
            final nilaiList = periksa['nilai'] as List? ?? [];
            
            final List<Map<String, dynamic>> items = [];
            for (var n in nilaiList) {
              items.add({
                'pemeriksaan': n['Pemeriksaan'] ?? n['pemeriksaan'] ?? '',
                'hasil': n['nilai'] ?? '-',
                'satuan': n['satuan'] ?? '',
                'nilai_normal': n['nilai_rujukan'] ?? '-',
              });
            }
            
            if (items.isNotEmpty) {
              groupedLab.add({
                'group_name': nmPerawatan,
                'items': items,
              });
            } else if (nmPerawatan.toString().isNotEmpty) {
              groupedLab.add({
                'group_name': nmPerawatan,
                'items': [
                  {
                    'pemeriksaan': nmPerawatan,
                    'hasil': '-',
                    'satuan': '',
                    'nilai_normal': '-',
                  }
                ],
              });
            }
          }
        }
        laboratorium.value = groupedLab;
      }
    } catch (_) {}
  }

  Future<void> _fetchRadiologi() async {
    try {
      final res = await _api.dio.get('/riwayat/pasien/radiologi', queryParameters: {'no_rawat': noRawat});
      if (res.data['success'] == true && res.data['data'] != null) {
        final listData = res.data['data']['list'] as List? ?? [];
        radiologi.value = listData.map((e) {
          final map = Map<String, dynamic>.from(e);
          final nmPerawatan = map['nm_perawatan'];
          String nmPeriksa = '';
          if (nmPerawatan is List) {
            nmPeriksa = nmPerawatan.join(', ');
          } else {
            nmPeriksa = nmPerawatan?.toString() ?? '';
          }
          return {
            'nm_periksa': nmPeriksa,
            'keterangan': map['hasil'] ?? '-',
            'foto': map['lokasi_gambar'],
          };
        }).toList();
      }
    } catch (_) {}
  }

  Future<void> _fetchDicomStudies() async {
    try {
      isLoadingDicom.value = true;
      final res = await _api.dio.get('/orthanc/studies', queryParameters: {'no_rkm_medis': noRkmMedis});
      if (res.statusCode == 200 && res.data != null && res.data['success'] == true) {
        final data = res.data['data'] as List? ?? [];
        dicomStudies.value = List<Map<String, dynamic>>.from(data);
      } else {
        dicomStudies.clear();
      }
    } catch (_) {
      dicomStudies.clear();
    } finally {
      isLoadingDicom.value = false;
    }
  }

  Future<String> getDicomViewerUrl(String studyId) async {
    final token = await const FlutterSecureStorage().read(key: 'auth_token');
    final host = AppConfig.baseUrl.replaceAll('/api', '');
    return '$host/orthanc-viewer/stone-webviewer/index.html?study=$studyId&_t=$token';
  }
}
