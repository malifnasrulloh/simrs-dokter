import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../auth/controllers/auth_controller.dart';

class RekamMedisController extends GetxController {
  final _api = ApiClient();
  final isLoading = false.obs;
  final activeTab = 0.obs;
  final showDetails = false.obs;

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
  final expandedStates = <String, bool>{}.obs;

  // SBAR & DPJP data
  final sbarList = <Map<String, dynamic>>[].obs;
  final dpjpList = <Map<String, dynamic>>[].obs;
  final isLoadingSbar = false.obs;
  final isLoadingDpjp = false.obs;

  // Billing & Perkiraan Biaya
  final totalBilling = 0.0.obs;
  final perkiraanBiaya = 0.0.obs;
  final selisihBiaya = 0.0.obs;
  final hasPerkiraan = false.obs;
  final isLoadingBilling = false.obs;

  String get noRawat => pasienData.value?['no_rawat'] ?? '';
  String get noRkmMedis => pasienData.value?['no_rkm_medis'] ?? pasienData.value?['no_rm'] ?? '';
  String get tipeRawat => pasienData.value?['_type'] ?? 'RANAP';

  String get alergiInfo {
    for (var item in riwayatMedis.reversed) {
      final allergyVal = item['alergi']?.toString().trim() ?? '';
      if (allergyVal.isNotEmpty && allergyVal != '-') {
        return allergyVal;
      }
    }
    return '';
  }

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
    expandedStates.clear();
    try {
      await Future.wait([
        _fetchRiwayatMedis(),
        _fetchDiagnosa(),
        _fetchObat(),
        _fetchLaboratorium(),
        _fetchRadiologi(),
        // _fetchDicomStudies(),
        _fetchBillingInfo(),
        _fetchSbarList(),
        _fetchDpjpList(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<dynamic>> _safeGetList(String endpoint, String noRawat) async {
    try {
      final res = await _api.dio.get(endpoint, queryParameters: {'no_rawat': noRawat});
      if (res.statusCode == 200 && res.data != null && res.data['success'] == true && res.data['data'] is List) {
        return res.data['data'] as List;
      }
    } catch (_) {}
    return [];
  }

  DateTime _parseRecordDateTime(Map<String, dynamic> item) {
    try {
      final tgl = item['tanggal'];
      final jam = item['jam'];
      
      if (tgl != null && tgl.toString() != '-') {
        final parsedDate = DateTime.parse(tgl.toString()).toLocal();
        if (jam != null && jam.toString() != '-') {
          final timeParts = jam.toString().split(':');
          if (timeParts.length >= 3) {
            final hour = int.tryParse(timeParts[0]) ?? 0;
            final minute = int.tryParse(timeParts[1]) ?? 0;
            final second = int.tryParse(timeParts[2]) ?? 0;
            return DateTime(
              parsedDate.year,
              parsedDate.month,
              parsedDate.day,
              hour,
              minute,
              second,
            );
          }
        }
        return parsedDate;
      }
    } catch (_) {}
    return DateTime(1970);
  }

  Future<void> _fetchRiwayatMedis() async {
    try {
      final List<Map<String, dynamic>> combined = [];

      if (tipeRawat == 'RANAP') {
        final results = await Future.wait([
          _safeGetList('/riwayat/pasien/medis-ranap', noRawat),
          _safeGetList('/riwayat/pasien/medis-ranap-neonatus', noRawat),
          _safeGetList('/riwayat/pasien/medis-ranap-kebidanan', noRawat),
          _safeGetList('/riwayat/pasien/soap-ranap', noRawat),
        ]);
        for (var list in results) {
          for (var item in list) {
            combined.add(Map<String, dynamic>.from(item));
          }
        }
      } else if (tipeRawat == 'IGD') {
        final results = await Future.wait([
          _safeGetList('/riwayat/pasien/medis-igd', noRawat),
          _safeGetList('/riwayat/pasien/soap-ralan', noRawat),
        ]);
        for (var list in results) {
          for (var item in list) {
            combined.add(Map<String, dynamic>.from(item));
          }
        }
      } else {
        // RALAN
        final list = await _safeGetList('/riwayat/pasien/soap-ralan', noRawat);
        for (var item in list) {
          combined.add(Map<String, dynamic>.from(item));
        }
      }

      if (combined.isNotEmpty) {
        final normalized = combined.map((e) => _normalizeMedisData(e)).toList();

        // Sort ascending so that view's .reversed results in latest first (descending)
        normalized.sort((a, b) {
          final dtA = _parseRecordDateTime(a);
          final dtB = _parseRecordDateTime(b);
          return dtA.compareTo(dtB);
        });

        riwayatMedis.value = normalized;
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
      'jabatan': raw['jbtn'] ?? '-',
      // SUBJEKTIF
      'keluhan_utama': raw['keluhan_utama'] ?? raw['keluhan'] ?? '-',
      'rps': raw['rps'] ?? raw['anamnesis'] ?? '-',
      'rpd': raw['rpd'] ?? '-',
      'rpk': raw['rpk'] ?? '-',
      'rpo': raw['rpo'] ?? '-',
      'alergi': raw['alergi'] ?? '-',
      'hubungan': raw['hubungan'] ?? '-',
      // OBJEKTIF — pemeriksaan fisik (bukan RPS)
      'pemeriksaan_fisik': raw['pemeriksaan'] ?? '-',
      'kesadaran': raw['kesadaran'] ?? '-',
      'gcs': raw['gcs'] ?? '-',
      'keadaan': raw['keadaan'] ?? '-',
      'bb': raw['bb'] ?? raw['berat'] ?? '-',
      'tb': raw['tb'] ?? raw['tinggi'] ?? '-',
      // Tanda Vital
      'td': raw['td'] ?? raw['tensi'] ?? '-',
      'nadi': raw['nadi'] ?? '-',
      'rr': raw['rr'] ?? raw['respirasi'] ?? '-',
      'suhu': raw['suhu'] ?? raw['suhu_tubuh'] ?? '-',
      'spo': raw['spo'] ?? raw['spo2'] ?? '-',
      // Penunjang
      'lab': raw['lab'] ?? '-',
      'rad': raw['rad'] ?? '-',
      'penunjang': raw['penunjang'] ?? '-',
      // ASSESSMENT
      'diagnosis': raw['diagnosis'] ?? raw['penilaian'] ?? '-',
      // PLAN
      'tata': raw['tata'] ?? raw['rtl'] ?? '-',
      // INSTRUKSI & EVALUASI (SOAP RANAP/RALAN — terpisah)
      'instruksi': raw['instruksi'] ?? '-',
      'evaluasi': raw['evaluasi'] ?? '-',
      // EDUKASI (medis ranap — terpisah dari instruksi)
      'edukasi': raw['edukasi'] ?? '-',
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
            final String nmPerawatan = periksa['nm_perawatan']?.toString() ?? '';
            if (nmPerawatan.toUpperCase().contains('BHP')) {
              continue;
            }
            final nilaiList = periksa['nilai'] as List? ?? [];
            
            final List<Map<String, dynamic>> items = [];
            for (var n in nilaiList) {
              items.add({
                'pemeriksaan': n['Pemeriksaan'] ?? n['pemeriksaan'] ?? '',
                'hasil': n['nilai'] ?? '-',
                'satuan': n['satuan'] ?? '',
                'nilai_normal': n['nilai_rujukan'] ?? '-',
                'keterangan': n['keterangan'] ?? '',
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
                    'keterangan': '',
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

  // Future<void> _fetchDicomStudies() async {
  //   try {
  //     isLoadingDicom.value = true;
  //     final res = await _api.dio.get('/orthanc/studies', queryParameters: {'no_rkm_medis': noRkmMedis});
  //     if (res.statusCode == 200 && res.data != null && res.data['success'] == true) {
  //       final data = res.data['data'] as List? ?? [];
  //       dicomStudies.value = List<Map<String, dynamic>>.from(data);
  //     } else {
  //       dicomStudies.clear();
  //     }
  //   } catch (_) {
  //     dicomStudies.clear();
  //   } finally {
  //     isLoadingDicom.value = false;
  //   }
  // }

  Future<void> _fetchBillingInfo() async {
    try {
      isLoadingBilling.value = true;
      totalBilling.value = 0.0;
      perkiraanBiaya.value = 0.0;
      selisihBiaya.value = 0.0;
      hasPerkiraan.value = false;

      // 1. Fetch total tagihan
      final resBilling = await _api.dio.get('/riwayat/pasien/total-tagihan', queryParameters: {'no_rawat': noRawat});
      if (resBilling.statusCode == 200 && resBilling.data != null && resBilling.data['success'] == true) {
        totalBilling.value = double.tryParse(resBilling.data['data']['total_biaya']?.toString() ?? '') ?? 0.0;
      }

      // 2. If BPJS patient, fetch perkiraan biaya
      final penjamin = pasienData.value?['png_jawab']?.toString() ?? 'Umum';
      final isBpjs = penjamin.toUpperCase().contains('BPJS');
      if (isBpjs) {
        final resPerkiraan = await _api.dio.get('/perkiraan-biaya', queryParameters: {'search': noRawat});
        if (resPerkiraan.statusCode == 200 && resPerkiraan.data != null && resPerkiraan.data['success'] == true && resPerkiraan.data['data'] is List) {
          final list = resPerkiraan.data['data'] as List;
          if (list.isNotEmpty) {
            final item = list[0] as Map<String, dynamic>;
            final costDetails = item['cost_details'] as Map<String, dynamic>?;
            if (costDetails != null) {
              final perkiraan = double.tryParse(costDetails['perkiraan_tarif']?.toString() ?? '') ?? 0.0;
              if (perkiraan > 0) {
                perkiraanBiaya.value = perkiraan;
                selisihBiaya.value = perkiraan - totalBilling.value;
                hasPerkiraan.value = true;
              }
            }
          }
        }
      }
    } catch (_) {
      // Ignore
    } finally {
      isLoadingBilling.value = false;
    }
  }

  Future<String> getDicomViewerUrl(String studyId) async {
    final token = await const FlutterSecureStorage().read(key: 'auth_token');
    final host = AppConfig.baseUrl.replaceAll('/api', '');
    // /api/orthanc-viewer bypasses validateTokenJWT, proxyOhif verifies ?_t internally
    // then strips /orthanc-viewer prefix → proxies to Orthanc /ohif/index.html
    final studyUid = dicomStudies
        .firstWhereOrNull((s) => s['studyId'] == studyId)?['studyInstanceUID'] ?? studyId;
    return '$host/api/orthanc-viewer/ohif/index.html?StudyInstanceUIDs=$studyUid&_t=$token';
  }

  Future<void> _fetchSbarList() async {
    if (tipeRawat != 'RANAP') {
      sbarList.clear();
      return;
    }
    try {
      isLoadingSbar.value = true;
      final res = await _api.dio.get('/pemeriksaan', queryParameters: {'no_rawat': noRawat});
      if (res.statusCode == 200 && res.data != null && res.data['success'] == true && res.data['data'] is List) {
        sbarList.value = List<Map<String, dynamic>>.from(res.data['data']);
      } else {
        sbarList.clear();
      }
    } catch (_) {
      sbarList.clear();
    } finally {
      isLoadingSbar.value = false;
    }
  }

  Future<void> _fetchDpjpList() async {
    if (tipeRawat != 'RANAP') {
      dpjpList.clear();
      return;
    }
    try {
      isLoadingDpjp.value = true;
      final res = await _api.dio.get('/dpjp-ranap', queryParameters: {'no_rawat': noRawat});
      if (res.statusCode == 200 && res.data != null && res.data['success'] == true && res.data['data'] is List) {
        dpjpList.value = List<Map<String, dynamic>>.from(res.data['data']);
      } else {
        dpjpList.clear();
      }
    } catch (_) {
      dpjpList.clear();
    } finally {
      isLoadingDpjp.value = false;
    }
  }

  Future<bool> validasiSbar(String tglPerawatan, String jamRawat) async {
    try {
      final authCtrl = Get.find<AuthController>();
      final myNip = authCtrl.user.value?['nip'];
      if (myNip == null) {
        Get.snackbar('Error', 'Dokter tidak teridentifikasi');
        return false;
      }
      final res = await _api.dio.post('/pemeriksaan/validasi', data: {
        'no_rawat': noRawat,
        'tgl_perawatan': tglPerawatan,
        'jam_rawat': jamRawat,
        'nik': myNip,
      });
      if (res.statusCode == 201 || (res.data != null && res.data['success'] == true)) {
        await _fetchSbarList();
        return true;
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memverifikasi SBAR');
    }
    return false;
  }

  Future<bool> setAsDpjp() async {
    try {
      final authCtrl = Get.find<AuthController>();
      final myNip = authCtrl.user.value?['nip'];
      if (myNip == null) {
        Get.snackbar('Error', 'Dokter tidak teridentifikasi');
        return false;
      }

      List<String> kdDokter = [myNip];
      List<String> pjranapKe = ['1'];

      int index = 2;
      for (var d in dpjpList) {
        final existingKd = d['kd_dokter']?.toString();
        if (existingKd != null && existingKd != myNip) {
          kdDokter.add(existingKd);
          pjranapKe.add(index.toString());
          index++;
        }
      }

      final res = await _api.dio.post('/dpjp-ranap', data: {
        'no_rawat': noRawat,
        'kd_dokter': kdDokter,
        'pjranap_ke': pjranapKe,
      });

      if (res.statusCode == 201 || res.statusCode == 200 || (res.data != null && res.data['success'] == true)) {
        await _fetchDpjpList();
        return true;
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengatur DPJP');
    }
    return false;
  }
}
