import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/app_logger.dart';
import '../utils/google_fonts.dart';

class AppUpdateService extends GetxService {
  static const MethodChannel _installerChannel =
      MethodChannel('id.khanza.edokter/app_installer');

  final _api = ApiClient();
  final isChecking = false.obs;
  final isDownloading = false.obs;
  final downloadProgress = 0.0.obs;
  final downloadedBytes = 0.obs;
  final totalBytes = 0.obs;
  final updateStatusMessage = ''.obs;

  /// Compare two semantic version strings (e.g. "1.3.1" vs "1.3.0")
  /// Returns:
  ///   < 0 if v1 < v2
  ///   = 0 if v1 == v2
  ///   > 0 if v1 > v2
  static int compareVersions(String v1, String v2) {
    final v1Clean = v1.split('-').first.trim();
    final v2Clean = v2.split('-').first.trim();

    final parts1 = v1Clean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2Clean.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    while (parts1.length < 3) {
      parts1.add(0);
    }
    while (parts2.length < 3) {
      parts2.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (parts1[i] < parts2[i]) return -1;
      if (parts1[i] > parts2[i]) return 1;
    }
    return 0;
  }

  Future<void> checkForUpdates({bool isManual = false}) async {
    if (isChecking.value || isDownloading.value) return;

    try {
      isChecking.value = true;
      final res = await _api.dio.get('/setting/app-version');
      if (res.data != null && res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>?;
        if (data == null) return;

        final serverVersion = (data['version_name'] ?? '').toString();
        final minSupportedVersion =
            (data['min_supported_version'] ?? serverVersion).toString();
        final releaseNotes = (data['release_notes'] ?? '').toString();
        final downloadUrl = (data['download_url'] ?? '').toString();
        final expectedSha256 = (data['sha256_checksum'] ?? '').toString();

        final currentVersion = AppConfig.appVersion;

        // Check if update is needed
        final hasUpdate = compareVersions(currentVersion, serverVersion) < 0;
        final isForceUpdate =
            compareVersions(currentVersion, minSupportedVersion) < 0;

        if (hasUpdate) {
          _showUpdateDialog(
            isForceUpdate: isForceUpdate,
            currentVersion: currentVersion,
            newVersion: serverVersion,
            releaseNotes: releaseNotes,
            downloadUrl: downloadUrl,
            expectedSha256: expectedSha256,
          );
        } else if (isManual) {
          Get.snackbar(
            'Aplikasi Sudah Versi Terbaru',
            'Anda sedang menggunakan versi v$currentVersion yang merupakan rilis terbaru.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppTheme.bgCard,
            colorText: AppTheme.textPrimary,
            margin: const EdgeInsets.all(16),
            borderRadius: 14,
          );
        }
      }
    } catch (e, s) {
      AppLogger.error('AppUpdateService', e, s);
      if (isManual) {
        Get.snackbar(
          'Gagal Memeriksa Pembaruan',
          'Tidak dapat terhubung ke server pembaruan. Coba lagi nanti.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.bgCard,
          colorText: AppTheme.danger,
          margin: const EdgeInsets.all(16),
          borderRadius: 14,
        );
      }
    } finally {
      isChecking.value = false;
    }
  }

  void _showUpdateDialog({
    required bool isForceUpdate,
    required String currentVersion,
    required String newVersion,
    required String releaseNotes,
    required String downloadUrl,
    required String expectedSha256,
  }) {
    Get.dialog(
      PopScope(
        canPop: !isForceUpdate && !isDownloading.value,
        child: AlertDialog(
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isForceUpdate ? AppTheme.danger : AppTheme.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isForceUpdate ? Icons.warning_rounded : Icons.system_update_rounded,
                  color: isForceUpdate ? AppTheme.danger : AppTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isForceUpdate ? 'Pembaruan Wajib' : 'Pembaruan Tersedia',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Obx(() {
            if (isDownloading.value) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    updateStatusMessage.value.isNotEmpty
                        ? updateStatusMessage.value
                        : 'Mengunduh berkas pembaruan...',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: downloadProgress.value > 0 ? downloadProgress.value : null,
                      backgroundColor: AppTheme.divider,
                      color: AppTheme.primary,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(downloadProgress.value * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      if (totalBytes.value > 0)
                        Text(
                          '${(downloadedBytes.value / (1024 * 1024)).toStringAsFixed(1)} MB / ${(totalBytes.value / (1024 * 1024)).toStringAsFixed(1)} MB',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  'Versi $newVersion telah tersedia (versi Anda saat ini: v$currentVersion).',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Catatan Rilis:',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.divider, width: 0.8),
                    ),
                    child: Text(
                      releaseNotes,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
              ],
            );
          }),
          actions: [
            Obx(() {
              if (isDownloading.value) {
                return const SizedBox.shrink();
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isForceUpdate)
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'Nanti Saja',
                        style: GoogleFonts.outfit(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _startDownloadAndInstall(
                      downloadUrl: downloadUrl,
                      expectedSha256: expectedSha256,
                      newVersion: newVersion,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isForceUpdate ? AppTheme.danger : AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text(
                      'Perbarui Sekarang',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _startDownloadAndInstall({
    required String downloadUrl,
    required String expectedSha256,
    required String newVersion,
  }) async {
    try {
      isDownloading.value = true;
      downloadProgress.value = 0.0;
      downloadedBytes.value = 0;
      totalBytes.value = 0;
      updateStatusMessage.value = 'Menyiapkan berkas pembaruan...';

      final dir = await getExternalCacheDirectories().then((dirs) => dirs?.firstOrNull) ??
          await getTemporaryDirectory();
      final savePath = '${dir.path}/edokter-update-$newVersion.apk';
      final file = File(savePath);
      if (file.existsSync()) {
        file.deleteSync();
      }

      // Safely resolve download path to prevent duplicate '/api/api/...' paths
      String resolvedPath = downloadUrl.trim();
      if (!resolvedPath.startsWith('http')) {
        if (AppConfig.baseUrl.endsWith('/api') && resolvedPath.startsWith('/api/')) {
          resolvedPath = resolvedPath.substring(4); // '/api/setting/...' -> '/setting/...'
        }
      }

      updateStatusMessage.value = 'Mengunduh pembaruan dari server...';

      await _api.dio.download(
        resolvedPath,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadedBytes.value = received;
            totalBytes.value = total;
            downloadProgress.value = received / total;
          }
        },
      );

      // Verify SHA-256 integrity if provided by server
      if (expectedSha256.isNotEmpty) {
        updateStatusMessage.value = 'Memverifikasi integritas keamanan berkas...';
        final downloadedBytesList = await file.readAsBytes();
        final actualHash = sha256.convert(downloadedBytesList).toString();

        if (actualHash.toLowerCase() != expectedSha256.toLowerCase()) {
          throw Exception(
              'Verifikasi keamanan gagal: Hash berkas tidak cocok dengan sertifikat server.');
        }
      }

      updateStatusMessage.value = 'Meluncurkan pemasang aplikasi...';

      // Check install permission on Android
      final canInstall = await _checkOrRequestInstallPermission();
      if (!canInstall) {
        updateStatusMessage.value =
            'Izinkan pemasangan aplikasi dari sumber ini untuk melanjutkan.';
        return;
      }

      final launched = await _installerChannel.invokeMethod<bool>('installApk', {
        'filePath': savePath,
      });

      if (launched != true) {
        throw Exception('Gagal membuka paket installer Android.');
      }
    } catch (e, s) {
      AppLogger.error('DownloadInstall', e, s);
      Get.snackbar(
        'Gagal Memperbarui Aplikasi',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.bgCard,
        colorText: AppTheme.danger,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isDownloading.value = false;
      updateStatusMessage.value = '';
    }
  }

  Future<bool> _checkOrRequestInstallPermission() async {
    try {
      final canRequest = await _installerChannel
          .invokeMethod<bool>('canRequestPackageInstalls');
      if (canRequest == false) {
        await _installerChannel.invokeMethod('openInstallPermissionSettings');
        return false;
      }
      return true;
    } catch (_) {
      return true;
    }
  }
}
