import 'package:get/get.dart';
import '../../../core/network/api_client.dart';

class HarianDokterConfigController extends GetxController {
  final _api = ApiClient();

  final isLoading = false.obs;
  final doctorsList = <Map<String, dynamic>>[].obs;
  final filteredDoctors = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAccessList();
  }

  Future<void> fetchAccessList() async {
    try {
      isLoading.value = true;
      final res = await _api.dio.get('/auth/harian-access');
      if (res.data != null && res.data['success'] == true) {
        final list = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
        doctorsList.value = list;
        filteredDoctors.value = list;
      }
    } catch (_) {} finally {
      isLoading.value = false;
    }
  }

  void filterDoctors(String query) {
    if (query.trim().isEmpty) {
      filteredDoctors.value = doctorsList;
    } else {
      filteredDoctors.value = doctorsList
          .where((doc) =>
              (doc['nm_dokter'] ?? '').toString().toLowerCase().contains(query.toLowerCase()) ||
              (doc['kd_dokter'] ?? '').toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  Future<void> toggleAccess(String kdDokter, bool enabled) async {
    try {
      final res = await _api.dio.put('/auth/harian-access', data: {
        'kd_dokter': kdDokter,
        'harian_dokter': enabled,
      });

      if (res.data != null && res.data['success'] == true) {
        final idx = doctorsList.indexWhere((d) => d['kd_dokter'] == kdDokter);
        if (idx != -1) {
          doctorsList[idx] = {
            ...doctorsList[idx],
            'harian_dokter': enabled,
          };
          doctorsList.refresh();
          final fIdx = filteredDoctors.indexWhere((d) => d['kd_dokter'] == kdDokter);
          if (fIdx != -1) {
            filteredDoctors[fIdx] = {
              ...filteredDoctors[fIdx],
              'harian_dokter': enabled,
            };
            filteredDoctors.refresh();
          }
        }
        Get.snackbar(
          'Sukses',
          'Akses Jasa Medis Dokter berhasil diperbarui',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Gagal memperbarui akses dokter',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
