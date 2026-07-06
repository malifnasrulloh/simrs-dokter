import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/local_notification_service.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../../core/utils/google_fonts.dart';

class RekamMedisController extends GetxController {
  final _api = ApiClient();
  StreamSubscription? _connectivitySubscription;
  late final PageController pageController;
  late final Worker _tabWorker;
  final isLoading = false.obs;
  bool _isSubmitting = false;
  
  Timer? _staggerTimer1;
  Timer? _staggerTimer2;
  Timer? _connectivityDebounce;
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
  
  // Vitals Chart and Offline Queue observables
  final activeChartType = 0.obs;
  final offlineSoapQueue = <Map<String, dynamic>>[].obs;

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
  final isLoadingLab = false.obs;
  final isLoadingRad = false.obs;

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
    
    pageController = PageController(initialPage: activeTab.value);
    _tabWorker = ever(activeTab, (int index) {
      if (pageController.hasClients && pageController.page?.round() != index) {
        pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    // Listen to network transitions to automatically sync offline notes (debounced)
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((event) {
      final isOnline = event.isNotEmpty && !event.contains(ConnectivityResult.none);
      if (isOnline) {
        _connectivityDebounce?.cancel();
        _connectivityDebounce = Timer(const Duration(milliseconds: 500), () {
          if (!isClosed) syncOfflineSoap();
        });
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
    if (pasienData.value == null || noRawat.isEmpty) {
      // Guard: navigated to rekam-medis without valid patient data
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        Get.offAllNamed('/home');
      }
      return;
    }
    fetchAllData();
    initNotificationSse();
    loadDrafts();
    loadOfflineSoapQueue();
  }

  void loadPasien(Map<String, dynamic> data) {
    pasienData.value = data;
    fetchAllData();
    loadDrafts();
  }

  Future<void> fetchAllData() async {
    isLoading.value = true;
    expandedStates.clear();
    try {
      // 1. Core/Primary data: must load to display the initial page content
      await Future.wait([
        _fetchRiwayatMedis(),
        _fetchDiagnosa(),
        _fetchObat(),
        fetchProsedur(),
      ]);
    } finally {
      isLoading.value = false;
    }

    // 2. Secondary/Background data: lazy load and stagger in the background asynchronously
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      Future.wait([
        _fetchLaboratorium(),
        _fetchRadiologi(),
        _fetchBillingInfo(),
        _fetchSbarList(),
        _fetchDpjpList(),
        fetchConsultations(),
        fetchDokterList(),
        fetchResepList(),
      ]);
      return;
    }

    Future.wait([
      _fetchLaboratorium(),
      _fetchRadiologi(),
    ]);

    _staggerTimer1?.cancel();
    _staggerTimer1 = Timer(const Duration(milliseconds: 200), () {
      Future.wait([
        _fetchBillingInfo(),
        _fetchSbarList(),
        _fetchDpjpList(),
      ]);
    });

    _staggerTimer2?.cancel();
    _staggerTimer2 = Timer(const Duration(milliseconds: 400), () {
      Future.wait([
        fetchConsultations(),
        fetchDokterList(),
        fetchResepList(),
      ]);
    });
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
      'nip': raw['nip'] ?? raw['kd_dokter'] ?? raw['nik'] ?? '-',
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
      'lingkar_perut': raw['lingkar_perut'] ?? '-',
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
            .where((e) => e['kode_brng'] != null)
            .map((e) => Map<String, dynamic>.from(e))
            .map((e) => {
                  'kode_brng': e['kode_brng'],
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
    isLoadingLab.value = true;
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
    } catch (_) {} finally {
      isLoadingLab.value = false;
    }
  }

  Future<void> _fetchRadiologi() async {
    isLoadingRad.value = true;
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
    } catch (_) {} finally {
      isLoadingRad.value = false;
    }
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

  Future<bool> validasiSbar({
    required String? noPermintaan,
    required String tglPerawatan,
    required String jamRawat,
    required String respon,
    required String instruksi,
    required String rencana,
  }) async {
    try {
      final authCtrl = Get.find<AuthController>();
      final myNip = authCtrl.user.value?['nip'];
      if (myNip == null) {
        Get.snackbar('Error', 'Dokter tidak teridentifikasi');
        return false;
      }
      final res = await _api.dio.post('/pemeriksaan/validasi', data: {
        'no_permintaan': noPermintaan,
        'no_rawat': noRawat,
        'tgl_perawatan': tglPerawatan,
        'jam_rawat': jamRawat,
        'nik': myNip,
        'respon': respon,
        'instruksi': instruksi,
        'rencana': rencana,
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

  // ─── NEW CLINICAL MODULES METHODS & OBSERVABLES ───

  // Module A: SOAP
  Future<void> loadOfflineSoapQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('offline_soap_queue_$noRawat');
      if (raw != null) {
        final List decoded = jsonDecode(raw);
        offlineSoapQueue.value = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        
        // Inject offline records into UI immediately
        for (var item in offlineSoapQueue) {
          final mockSoap = _normalizeMedisData(item);
          mockSoap['isOfflineDraft'] = true;
          final exists = riwayatMedis.any((x) => x['tanggal'] == mockSoap['tanggal'] && x['jam'] == mockSoap['jam']);
          if (!exists) {
            riwayatMedis.add(mockSoap);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _saveOfflineQueueToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('offline_soap_queue_$noRawat', jsonEncode(offlineSoapQueue));
    } catch (_) {}
  }

  Future<void> syncOfflineSoap() async {
    if (offlineSoapQueue.isEmpty) return;
    
    final conn = await Connectivity().checkConnectivity();
    final isOffline = conn.isEmpty || conn.contains(ConnectivityResult.none);
    if (isOffline) return;

    final toSync = List<Map<String, dynamic>>.from(offlineSoapQueue);
    bool anySuccess = false;

    for (var item in toSync) {
      try {
        final path = item['_tipeRawat'] == 'RANAP' ? '/soap/ranap' : '/soap/ralan';
        final payload = Map<String, dynamic>.from(item)
          ..remove('_tipeRawat')
          ..remove('isOfflineDraft')
          ..remove('isEdit');
        
        dynamic res;
        if (item['isEdit'] == true) {
          res = await _api.dio.put(path, data: payload);
        } else {
          res = await _api.dio.post(path, data: payload);
        }

        if (res.statusCode == 200 || res.statusCode == 201 || (res.data != null && res.data['success'] == true)) {
          offlineSoapQueue.removeWhere((x) => x['tanggal'] == item['tanggal'] && x['jam'] == item['jam']);
          anySuccess = true;
        }
      } catch (_) {}
    }

    if (anySuccess) {
      await _saveOfflineQueueToPrefs();
      Get.snackbar(
        'Sinkronisasi',
        'Data SOAP offline berhasil disinkronkan ke server.',
        backgroundColor: AppTheme.primary,
        colorText: Colors.white,
      );
      await _fetchRiwayatMedis();
    }
  }

  Future<bool> saveSoap({
    required Map<String, dynamic> data,
    bool isEdit = false,
    String? tglPerawatan,
    String? jamRawat,
  }) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    try {
      isLoading.value = true;
      final authCtrl = Get.find<AuthController>();
      final myNip = authCtrl.user.value?['nip'] ?? authCtrl.user.value?['username'] ?? '';
      final myName = authCtrl.user.value?['nama'] ?? authCtrl.user.value?['name'] ?? 'Dokter';
      
      final conn = await Connectivity().checkConnectivity();
      final isOffline = conn.isEmpty || conn.contains(ConnectivityResult.none);
      
      if (isOffline) {
        final now = DateTime.now();
        final tglStr = tglPerawatan ?? '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final jamStr = jamRawat ?? '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
        
        final payload = {
          'no_rawat': noRawat,
          ...data,
          'nip': myNip,
          'tanggal': tglStr,
          'jam': jamStr,
          'tgl_perawatan': tglStr,
          'jam_rawat': jamStr,
          'nm_dokter': myName,
          '_tipeRawat': tipeRawat,
          if (isEdit) 'isEdit': true,
        };

        // Add to offline queue
        offlineSoapQueue.add(payload);
        await _saveOfflineQueueToPrefs();

        // Optimistically show in UI
        final mockSoap = _normalizeMedisData(payload);
        mockSoap['isOfflineDraft'] = true;
        if (isEdit) {
          final idx = riwayatMedis.indexWhere((x) => x['tanggal'] == tglPerawatan && x['jam'] == jamRawat);
          if (idx != -1) {
            riwayatMedis[idx] = mockSoap;
          }
        } else {
          riwayatMedis.add(mockSoap);
        }

        if (!isEdit) {
          await clearSoapDraft();
        }

        Get.snackbar(
          'Mode Offline',
          'Data SOAP disimpan secara lokal di antrean offline.',
          backgroundColor: AppTheme.warning,
          colorText: Colors.white,
        );
        return true;
      }

      final payload = {
        'no_rawat': noRawat,
        ...data,
        'nip': myNip,
      };

      final path = tipeRawat == 'RANAP' ? '/soap/ranap' : '/soap/ralan';
      dynamic res;
      if (isEdit) {
        payload['tgl_perawatan'] = tglPerawatan;
        payload['jam_rawat'] = jamRawat;
        res = await _api.dio.put(path, data: payload);
      } else {
        res = await _api.dio.post(path, data: payload);
      }

      if (res.statusCode == 200 || res.statusCode == 201 || (res.data != null && res.data['success'] == true)) {
        await _fetchRiwayatMedis();
        if (!isEdit) {
          await clearSoapDraft();
        }
        return true;
      }
    } catch (e) {
      if (!isClosed) Get.snackbar('Error', 'Gagal menyimpan data SOAP');
    } finally {
      _isSubmitting = false;
      if (!isClosed) isLoading.value = false;
    }
    return false;
  }

  Future<bool> deleteSoap(String tgl, String jam) async {
    // Confirmation dialog before destructive action
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Text('Hapus Catatan SOAP?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        content: Text('Data SOAP ini akan dihapus secara permanen.', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('Batal', style: GoogleFonts.outfit(color: AppTheme.textMuted))),
          TextButton(onPressed: () => Get.back(result: true), child: Text('Hapus', style: GoogleFonts.outfit(color: AppTheme.danger, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed != true) return false;

    if (_isSubmitting) return false;
    _isSubmitting = true;
    try {
      isLoading.value = true;
      final path = tipeRawat == 'RANAP' ? '/soap/ranap' : '/soap/ralan';
      final res = await _api.dio.delete(path, data: {
        'no_rawat': noRawat,
        'tgl_perawatan': tgl,
        'jam_rawat': jam,
      });
      if (res.statusCode == 200 || (res.data != null && res.data['success'] == true)) {
        if (!isClosed) await _fetchRiwayatMedis();
        return true;
      }
    } catch (e) {
      if (!isClosed) Get.snackbar('Error', 'Gagal menghapus data SOAP');
    } finally {
      _isSubmitting = false;
      if (!isClosed) isLoading.value = false;
    }
    return false;
  }

  // Module B: Consultations
  final incomingConsults = <Map<String, dynamic>>[].obs;
  final outgoingConsults = <Map<String, dynamic>>[].obs;
  final dokterList = <Map<String, dynamic>>[].obs;
  final isLoadingConsult = false.obs;

  Future<void> fetchConsultations() async {
    try {
      isLoadingConsult.value = true;
      final results = await Future.wait([
        _api.dio.get('/konsultasi/masuk', queryParameters: {'no_rawat': noRawat}),
        _api.dio.get('/konsultasi/keluar', queryParameters: {'no_rawat': noRawat}),
      ]);
      
      if (results[0].statusCode == 200 && results[0].data != null && results[0].data['success'] == true) {
        final list = results[0].data['data'] as List? ?? [];
        incomingConsults.value = list
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) => e['no_rawat'] == noRawat)
            .toList();
      }
      
      if (results[1].statusCode == 200 && results[1].data != null && results[1].data['success'] == true) {
        final list = results[1].data['data'] as List? ?? [];
        outgoingConsults.value = list
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) => e['no_rawat'] == noRawat)
            .toList();
      }
    } catch (_) {} finally {
      isLoadingConsult.value = false;
    }
  }

  Future<void> fetchDokterList() async {
    try {
      final res = await _api.dio.get('/konsultasi/dokter-list');
      if (res.statusCode == 200 && res.data != null && res.data['success'] == true) {
        dokterList.value = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
      }
    } catch (_) {}
  }

  Future<bool> sendConsultation({
    required String targetDokter,
    required String jenis,
    required String diagnosa,
    required String uraian,
  }) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    try {
      isLoadingConsult.value = true;
      final res = await _api.dio.post('/konsultasi', data: {
        'no_rawat': noRawat,
        'kd_dokter_dikonsuli': targetDokter,
        'jenis_permintaan': jenis,
        'diagnosa_kerja': diagnosa,
        'uraian_konsultasi': uraian,
      });
      if (res.statusCode == 201 || (res.data != null && res.data['success'] == true)) {
        if (!isClosed) await fetchConsultations();
        return true;
      }
    } catch (_) {
      if (!isClosed) Get.snackbar('Error', 'Gagal mengirim konsultasi');
    } finally {
      _isSubmitting = false;
      if (!isClosed) isLoadingConsult.value = false;
    }
    return false;
  }

  Future<bool> replyConsultation({
    required String noPermintaan,
    required String diagnosa,
    required String uraian,
  }) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    try {
      isLoadingConsult.value = true;
      final res = await _api.dio.post('/konsultasi/jawab', data: {
        'no_permintaan': noPermintaan,
        'diagnosa_kerja': diagnosa,
        'uraian_jawaban': uraian,
      });
      if (res.statusCode == 200 || (res.data != null && res.data['success'] == true)) {
        if (!isClosed) await fetchConsultations();
        return true;
      }
    } catch (_) {
      if (!isClosed) Get.snackbar('Error', 'Gagal membalas konsultasi');
    } finally {
      _isSubmitting = false;
      if (!isClosed) isLoadingConsult.value = false;
    }
    return false;
  }

  // Module C: E-Prescribing
  final searchObatResults = <Map<String, dynamic>>[].obs;
  final prescriptionDraft = <Map<String, dynamic>>[].obs;
  final resepList = <Map<String, dynamic>>[].obs;
  final isLoadingObat = false.obs;

  Future<void> fetchResepList() async {
    try {
      final res = await _api.dio.get('/resep', queryParameters: {'no_rawat': noRawat});
      if (res.statusCode == 200 && res.data != null && res.data['success'] == true) {
        resepList.value = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
      }
    } catch (_) {}
  }

  Future<void> searchObat(String keyword) async {
    if (keyword.trim().isEmpty) {
      searchObatResults.clear();
      return;
    }
    try {
      isLoadingObat.value = true;
      final res = await _api.dio.get('/resep/obat-list', queryParameters: {'keyword': keyword});
      if (res.statusCode == 200 && res.data != null && res.data['success'] == true) {
        final list = res.data['data']['list'] as List? ?? [];
        searchObatResults.value = List<Map<String, dynamic>>.from(list);
      }
    } catch (_) {} finally {
      isLoadingObat.value = false;
    }
  }

  void addToPrescription(Map<String, dynamic> item) {
    final existing = prescriptionDraft.firstWhereOrNull((e) => e['kode_brng'] == item['kode_brng']);
    if (existing != null) {
      existing['jml'] = (existing['jml'] as int) + 1;
      prescriptionDraft.refresh();
    } else {
      prescriptionDraft.add({
        'kode_brng': item['kode_brng'],
        'nama_brng': item['nama_brng'],
        'satuan': item['satuan'],
        'jml': 1,
        'aturan_pakai': '3x1 tablet',
      });
    }
    savePrescriptionDraft();
  }

  void removeFromPrescription(String kodeBrng) {
    prescriptionDraft.removeWhere((e) => e['kode_brng'] == kodeBrng);
    savePrescriptionDraft();
  }

  Future<bool> submitPrescription() async {
    if (prescriptionDraft.isEmpty) return false;
    if (_isSubmitting) return false;
    _isSubmitting = true;
    try {
      isLoading.value = true;
      final res = await _api.dio.post('/resep', data: {
        'no_rawat': noRawat,
        'status': tipeRawat.toLowerCase(),
        'items': prescriptionDraft.map((e) => {
          'kode_brng': e['kode_brng'],
          'jml': e['jml'],
          'aturan_pakai': e['aturan_pakai'],
        }).toList(),
      });
      if (res.statusCode == 201 || (res.data != null && res.data['success'] == true)) {
        await clearPrescriptionDraft();
        if (!isClosed) {
          await Future.wait([
            _fetchObat(),
            fetchResepList(),
          ]);
        }
        return true;
      }
    } catch (_) {
      if (!isClosed) Get.snackbar('Error', 'Gagal mengirim resep');
    } finally {
      _isSubmitting = false;
      if (!isClosed) isLoading.value = false;
    }
    return false;
  }

  Future<bool> deletePrescription(String noResep) async {
    // Confirmation dialog before destructive action
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Text('Hapus Resep?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        content: Text('Resep ini akan dihapus. Resep yang sudah diproses farmasi tidak dapat dihapus.', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('Batal', style: GoogleFonts.outfit(color: AppTheme.textMuted))),
          TextButton(onPressed: () => Get.back(result: true), child: Text('Hapus', style: GoogleFonts.outfit(color: AppTheme.danger, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed != true) return false;

    if (_isSubmitting) return false;
    _isSubmitting = true;
    try {
      isLoading.value = true;
      final res = await _api.dio.delete('/resep/$noResep');
      if (res.statusCode == 200 || (res.data != null && res.data['success'] == true)) {
        if (!isClosed) {
          await Future.wait([
            _fetchObat(),
            fetchResepList(),
          ]);
        }
        return true;
      }
    } catch (_) {
      if (!isClosed) Get.snackbar('Error', 'Gagal menghapus resep (sudah diproses farmasi)');
    } finally {
      _isSubmitting = false;
      if (!isClosed) isLoading.value = false;
    }
    return false;
  }

  // Module D: ICD-10 & ICD-9-CM
  final prosedurList = <Map<String, dynamic>>[].obs;
  final searchICD10Results = <Map<String, dynamic>>[].obs;
  final searchICD9Results = <Map<String, dynamic>>[].obs;
  final isLoadingICD = false.obs;

  Future<void> searchICD10(String keyword) async {
    if (keyword.trim().isEmpty) {
      searchICD10Results.clear();
      return;
    }
    try {
      isLoadingICD.value = true;
      final res = await _api.dio.get('/diagnosa-prosedur/penyakit', queryParameters: {'keyword': keyword});
      if (res.statusCode == 200 && res.data != null && res.data['success'] == true) {
        final list = res.data['data'] as List? ?? [];
        searchICD10Results.value = List<Map<String, dynamic>>.from(list);
      }
    } catch (_) {} finally {
      isLoadingICD.value = false;
    }
  }

  Future<void> searchICD9(String keyword) async {
    if (keyword.trim().isEmpty) {
      searchICD9Results.clear();
      return;
    }
    try {
      isLoadingICD.value = true;
      final res = await _api.dio.get('/diagnosa-prosedur/icd9', queryParameters: {'keyword': keyword});
      if (res.statusCode == 200 && res.data != null && res.data['success'] == true) {
        final list = res.data['data'] as List? ?? [];
        searchICD9Results.value = List<Map<String, dynamic>>.from(list);
      }
    } catch (_) {} finally {
      isLoadingICD.value = false;
    }
  }

  Future<void> fetchProsedur() async {
    try {
      final res = await _api.dio.get('/riwayat/pasien/prosedur', queryParameters: {'no_rawat': noRawat});
      if (res.statusCode == 200 && res.data != null && res.data['success'] == true) {
        prosedurList.value = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
      }
    } catch (_) {}
  }

  Future<bool> addDiagnosa({
    required String kdPenyakit,
    required int prioritas,
    required String statusPenyakit,
  }) async {
    try {
      isLoading.value = true;
      final res = await _api.dio.post('/diagnosa-prosedur/diagnosa', data: {
        'no_rawat': noRawat,
        'kd_penyakit': kdPenyakit,
        'status': tipeRawat.toLowerCase(),
        'prioritas': prioritas,
        'status_penyakit': statusPenyakit,
      });
      if (res.statusCode == 201 || (res.data != null && res.data['success'] == true)) {
        await _fetchDiagnosa();
        return true;
      }
    } catch (_) {
      Get.snackbar('Error', 'Gagal menambahkan diagnosa');
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  Future<bool> deleteDiagnosa(String kdPenyakit) async {
    try {
      isLoading.value = true;
      final res = await _api.dio.delete('/diagnosa-prosedur/diagnosa', data: {
        'no_rawat': noRawat,
        'kd_penyakit': kdPenyakit,
        'status': tipeRawat.toLowerCase(),
      });
      if (res.statusCode == 200 || (res.data != null && res.data['success'] == true)) {
        await _fetchDiagnosa();
        return true;
      }
    } catch (_) {
      Get.snackbar('Error', 'Gagal menghapus diagnosa');
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  Future<bool> addProsedur({
    required String kode,
    required int prioritas,
  }) async {
    try {
      isLoading.value = true;
      final res = await _api.dio.post('/diagnosa-prosedur/prosedur', data: {
        'no_rawat': noRawat,
        'kode': kode,
        'status': tipeRawat.toLowerCase(),
        'prioritas': prioritas,
        'jumlah': 1,
      });
      if (res.statusCode == 201 || (res.data != null && res.data['success'] == true)) {
        await fetchProsedur();
        return true;
      }
    } catch (_) {
      Get.snackbar('Error', 'Gagal menambahkan prosedur');
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  Future<bool> deleteProsedur(String kode) async {
    try {
      isLoading.value = true;
      final res = await _api.dio.delete('/diagnosa-prosedur/prosedur', data: {
        'no_rawat': noRawat,
        'kode': kode,
        'status': tipeRawat.toLowerCase(),
      });
      if (res.statusCode == 200 || (res.data != null && res.data['success'] == true)) {
        await fetchProsedur();
        return true;
      }
    } catch (_) {
      Get.snackbar('Error', 'Gagal menghapus prosedur');
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  // Drafts Local Cache
  final soapDraft = <String, String>{}.obs;

  Future<void> loadDrafts() async {
    if (noRawat.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load SOAP draft
      final soapRaw = prefs.getString('soap_draft_$noRawat');
      if (soapRaw != null) {
        final Map<String, dynamic> decoded = jsonDecode(soapRaw);
        soapDraft.value = decoded.map((key, value) => MapEntry(key, value.toString()));
      } else {
        soapDraft.clear();
      }

      // Load Prescription draft
      final resepRaw = prefs.getString('resep_draft_$noRawat');
      if (resepRaw != null) {
        final List decoded = jsonDecode(resepRaw);
        prescriptionDraft.value = List<Map<String, dynamic>>.from(decoded);
      } else {
        prescriptionDraft.clear();
      }
    } catch (_) {}
  }

  Future<void> saveSoapDraft(Map<String, String> values) async {
    if (noRawat.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      soapDraft.value = values;
      await prefs.setString('soap_draft_$noRawat', jsonEncode(values));
    } catch (_) {}
  }

  Future<void> clearSoapDraft() async {
    if (noRawat.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      soapDraft.value = {};
      await prefs.remove('soap_draft_$noRawat');
    } catch (_) {}
  }

  Future<void> savePrescriptionDraft() async {
    if (noRawat.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('resep_draft_$noRawat', jsonEncode(prescriptionDraft.toList()));
    } catch (_) {}
  }

  Future<void> clearPrescriptionDraft() async {
    if (noRawat.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      prescriptionDraft.clear();
      await prefs.remove('resep_draft_$noRawat');
    } catch (_) {}
  }

  void initNotificationSse() {
    // Managed globally by AuthController
  }

  void _handleSseEvent(String event, dynamic data) {
    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    final isTesting = Platform.environment.containsKey('FLUTTER_TEST');

    if (event == 'consultation_request') {
      final drPemberi = data['nm_dokter_pemberi'] ?? 'Rekan Dokter';
      final diagnosa = data['diagnosa_kerja'] ?? '';
      if (AppConfig.enableInAppNotifications && !isTesting) {
        _showModernInAppNotification(
          'Konsultasi Baru',
          'Permintaan konsultasi dari $drPemberi: "$diagnosa"',
        );
      }
      if (AppConfig.enableSystemNotifications) {
        LocalNotificationService.showNotification(
          id: notificationId,
          title: 'Konsultasi Baru',
          body: 'Permintaan konsultasi dari $drPemberi: "$diagnosa"',
        );
      }
      fetchConsultations();
    } else if (event == 'consultation_response') {
      final drPenerima = data['nm_dokter_dikonsuli'] ?? 'Rekan Dokter';
      if (AppConfig.enableInAppNotifications && !isTesting) {
        _showModernInAppNotification(
          'Konsultasi Dijawab',
          'Balasan dari $drPenerima untuk permintaan ${data['no_permintaan']}',
        );
      }
      if (AppConfig.enableSystemNotifications) {
        LocalNotificationService.showNotification(
          id: notificationId,
          title: 'Konsultasi Dijawab',
          body: 'Balasan dari $drPenerima untuk permintaan ${data['no_permintaan']}',
        );
      }
      fetchConsultations();
    } else if (event == 'new_admission') {
      final nmPasien = data['nm_pasien'] ?? 'Pasien Baru';
      final noRawat = data['no_rawat'] ?? '';
      if (AppConfig.enableInAppNotifications && !isTesting) {
        _showModernInAppNotification(
          'Pasien Baru Terdaftar',
          'Anda telah didelegasikan sebagai DPJP untuk $nmPasien ($noRawat)',
        );
      }
      if (AppConfig.enableSystemNotifications) {
        LocalNotificationService.showNotification(
          id: notificationId,
          title: 'Pasien Baru Terdaftar',
          body: 'Anda telah didelegasikan sebagai DPJP untuk $nmPasien ($noRawat)',
        );
      }
      try {
        if (Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().fetchDashboard();
        }
      } catch (_) {}
    } else if (event == 'emergency_igd_consultation') {
      final drPemberi = data['nm_dokter_pemberi'] ?? 'Rekan Dokter';
      final nmPasien = data['nm_pasien'] ?? 'Pasien';
      if (AppConfig.enableInAppNotifications && !isTesting) {
        _showModernInAppNotification(
          '🚨 URGENT: KONSUL IGD',
          'Permintaan konsultasi segera dari $drPemberi untuk pasien $nmPasien',
          isUrgent: true,
        );
      }
      if (AppConfig.enableSystemNotifications) {
        LocalNotificationService.showNotification(
          id: notificationId,
          title: '🚨 URGENT: KONSUL IGD',
          body: 'Permintaan konsultasi segera dari $drPemberi untuk pasien $nmPasien',
        );
      }
      fetchConsultations();
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

  @visibleForTesting
  void handleSseEventForTesting(String event, dynamic data) {
    _handleSseEvent(event, data);
  }

  @override
  void onClose() {
    _tabWorker.dispose();
    _connectivitySubscription?.cancel();
    _connectivityDebounce?.cancel();
    _staggerTimer1?.cancel();
    _staggerTimer2?.cancel();
    pageController.dispose();
    super.onClose();
  }

  // vitals trend parser
  List<VitalsTrendPoint> get vitalsChartData {
    final List<VitalsTrendPoint> points = [];
    for (var raw in riwayatMedis) {
      final tgl = raw['tanggal']?.toString() ?? '';
      final jam = raw['jam']?.toString() ?? '';
      if (tgl.isEmpty || tgl == '-') continue;
      DateTime? dt;
      try {
        final parsedJam = jam == '-' ? '00:00:00' : jam;
        if (tgl.contains('-')) {
          final parts = tgl.split('-');
          if (parts[0].length == 4) {
            // yyyy-MM-dd
            dt = DateTime.parse('$tgl ${parsedJam.split(' ')[0]}');
          } else {
            // dd-MM-yyyy
            dt = DateTime.parse('${parts[2]}-${parts[1]}-${parts[0]} ${parsedJam.split(' ')[0]}');
          }
        }
      } catch (_) {}
      if (dt == null) continue;

      double? systole;
      double? diastole;
      double? suhu;
      double? nadi;
      double? rr;

      final tensi = raw['td']?.toString().trim() ?? '';
      if (tensi.contains('/')) {
        final parts = tensi.split('/');
        systole = double.tryParse(parts[0].replaceAll(RegExp(r'[^0-9.]'), ''));
        if (parts.length > 1) {
          diastole = double.tryParse(parts[1].replaceAll(RegExp(r'[^0-9.]'), ''));
        }
      }

      suhu = double.tryParse(raw['suhu']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '');
      nadi = double.tryParse(raw['nadi']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '');
      rr = double.tryParse(raw['rr']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '');

      if (systole != null || diastole != null || suhu != null || nadi != null || rr != null) {
        points.add(VitalsTrendPoint(
          dateTime: dt,
          systole: systole,
          diastole: diastole,
          suhu: suhu,
          nadi: nadi,
          rr: rr,
        ));
      }
    }
    return points;
  }
}

class VitalsTrendPoint {
  final DateTime dateTime;
  final double? systole;
  final double? diastole;
  final double? suhu;
  final double? nadi;
  final double? rr;

  VitalsTrendPoint({
    required this.dateTime,
    this.systole,
    this.diastole,
    this.suhu,
    this.nadi,
    this.rr,
  });
}
