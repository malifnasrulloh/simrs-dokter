import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';

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
    } catch (e, s) { AppLogger.error('HarianConfig', e, s); } finally {
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
    // 1. Optimistic update
    final idx = doctorsList.indexWhere((d) => d['kd_dokter'] == kdDokter);
    final previousState = idx != -1 ? (doctorsList[idx]['harian_dokter'] == true) : !enabled;

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

    try {
      final res = await _api.dio.put('/auth/harian-access', data: {
        'kd_dokter': kdDokter,
        'harian_dokter': enabled,
      });

      if (res.data == null || res.data['success'] != true) {
        throw Exception('Response unsuccessful');
      }
      // Success is completely silent (no toast) per user requirement
    } catch (_) {
      // 2. Rollback to previous state on failure
      if (idx != -1) {
        doctorsList[idx] = {
          ...doctorsList[idx],
          'harian_dokter': previousState,
        };
        doctorsList.refresh();
        final fIdx = filteredDoctors.indexWhere((d) => d['kd_dokter'] == kdDokter);
        if (fIdx != -1) {
          filteredDoctors[fIdx] = {
            ...filteredDoctors[fIdx],
            'harian_dokter': previousState,
          };
          filteredDoctors.refresh();
        }
      }

      // Show error snackbar at the TOP so it does not obstruct UX/switches
      Get.snackbar(
        'Gagal Memperbarui Akses',
        'Tidak dapat mengubah izin akses harian dokter. Periksa jaringan Anda.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF1E293B),
        colorText: Colors.white,
        icon: const Icon(Icons.error_outline_rounded, color: Color(0xFFE11D48)),
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        duration: const Duration(seconds: 4),
      );
    }
  }
}
