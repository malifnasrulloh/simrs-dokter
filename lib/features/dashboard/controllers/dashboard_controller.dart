import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../auth/controllers/auth_controller.dart';

class DashboardController extends GetxController {
  final _api = ApiClient();
  final isLoading = false.obs;
  final listPasienRanap = <Map<String, dynamic>>[].obs;
  final listPasienRalan = <Map<String, dynamic>>[].obs;
  final listPasienIGD = <Map<String, dynamic>>[].obs;
  final totalRanap = 0.obs;
  final totalRalan = 0.obs;
  final totalIGD = 0.obs;

  final currentNavIndex = 0.obs;
  final selectedTab = 0.obs;
  final listJadwalOperasi = <Map<String, dynamic>>[].obs;
  final totalOperasi = 0.obs;
  final bedDetails = <Map<String, dynamic>>[].obs;
  final bedClasses = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    try {
      isLoading.value = true;
      await Future.wait([
        _fetchPasienRanap(),
        _fetchPasienRalan(),
        _fetchPasienIGD(),
        _fetchJadwalOperasi(),
        _fetchBedAvailability(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchPasienRanap() async {
    try {
      final res = await _api.dio.get('/list-pasien-ranap', queryParameters: {
        'belumpulang': 'true',
        'statusbayar': 'semua',
      });
      if (res.data['success'] == true) {
        var data = List<Map<String, dynamic>>.from(res.data['data'] ?? [])
            .map((e) => {...e, '_type': 'RANAP'})
            .toList();
        final authCtrl = Get.find<AuthController>();
        final loggedInDoctorId = authCtrl.user.value?['nip'];
        if (loggedInDoctorId != null && loggedInDoctorId.toString().isNotEmpty) {
          data = data.where((e) {
            final dpjpList = e['dpjp'] as List? ?? [];
            return dpjpList.any((d) => d['kd_dokter'] == loggedInDoctorId);
          }).toList();
        }
        listPasienRanap.value = data;
        totalRanap.value = data.length;
      }
    } catch (_) {}
  }

  Future<void> _fetchPasienRalan() async {
    try {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final res = await _api.dio.get('/list-pasien-ralan', queryParameters: {
        'tglawal': todayStr,
        'tglakhir': todayStr,
      });
      if (res.data['success'] == true) {
        var data = List<Map<String, dynamic>>.from(res.data['data'] ?? [])
            .map((e) => {...e, '_type': 'RALAN'})
            .toList();
        final authCtrl = Get.find<AuthController>();
        final loggedInDoctorId = authCtrl.user.value?['nip'];
        if (loggedInDoctorId != null && loggedInDoctorId.toString().isNotEmpty) {
          data = data.where((e) => e['kd_dokter'] == loggedInDoctorId).toList();
        }
        listPasienRalan.value = data;
        totalRalan.value = data.length;
      }
    } catch (_) {}
  }

  Future<void> _fetchPasienIGD() async {
    try {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final res = await _api.dio.get('/list-pasien-igd', queryParameters: {
        'tglawal': todayStr,
        'tglakhir': todayStr,
        'statuslanjut': 'semua',
      });
      if (res.data['success'] == true) {
        var data = List<Map<String, dynamic>>.from(res.data['data'] ?? [])
            .map((e) => {...e, '_type': 'IGD'})
            .toList();
        final authCtrl = Get.find<AuthController>();
        final loggedInDoctorId = authCtrl.user.value?['nip'];
        if (loggedInDoctorId != null && loggedInDoctorId.toString().isNotEmpty) {
          data = data.where((e) => e['kd_dokter'] == loggedInDoctorId).toList();
        }
        listPasienIGD.value = data;
        totalIGD.value = data.length;
      }
    } catch (_) {}
  }

  Future<void> _fetchJadwalOperasi() async {
    try {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final authCtrl = Get.find<AuthController>();
      final loggedInDoctorId = authCtrl.user.value?['nip'];

      final res = await _api.dio.get('/jadwal/operasi', queryParameters: {
        'tanggal': todayStr,
        if (loggedInDoctorId != null && loggedInDoctorId.toString().isNotEmpty)
          'kd_dokter': loggedInDoctorId,
      });

      if (res.statusCode == 200 && res.data['success'] == true) {
        final data = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
        listJadwalOperasi.value = data;
        totalOperasi.value = data.length;
      } else {
        listJadwalOperasi.clear();
        totalOperasi.value = 0;
      }
    } catch (_) {
      listJadwalOperasi.clear();
      totalOperasi.value = 0;
    }
  }

  Future<void> _fetchBedAvailability() async {
    try {
      final res = await _api.dio.get('/jadwal/bed');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final details = List<Map<String, dynamic>>.from(res.data['data']?['bedDetails'] ?? []);
        final classes = List<Map<String, dynamic>>.from(res.data['data']?['bedClasses'] ?? []);
        bedDetails.value = details;
        bedClasses.value = classes;
      } else {
        bedDetails.clear();
        bedClasses.clear();
      }
    } catch (_) {
      bedDetails.clear();
      bedClasses.clear();
    }
  }
}
