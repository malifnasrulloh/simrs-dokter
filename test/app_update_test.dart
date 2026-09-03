import 'package:flutter_test/flutter_test.dart';
import 'package:simrs_dokter/core/services/app_update_service.dart';

void main() {
  group('AppUpdateService.compareVersions Unit Tests', () {
    test('returns 0 for identical versions', () {
      expect(AppUpdateService.compareVersions('1.3.0', '1.3.0'), equals(0));
      expect(AppUpdateService.compareVersions('2.0.0', '2.0.0'), equals(0));
    });

    test('returns negative when current version is older', () {
      expect(AppUpdateService.compareVersions('1.3.0', '1.3.1'), isNegative);
      expect(AppUpdateService.compareVersions('1.3.0', '1.4.0'), isNegative);
      expect(AppUpdateService.compareVersions('1.3.0', '2.0.0'), isNegative);
    });

    test('returns positive when current version is newer', () {
      expect(AppUpdateService.compareVersions('1.3.1', '1.3.0'), isPositive);
      expect(AppUpdateService.compareVersions('1.4.0', '1.3.9'), isPositive);
      expect(AppUpdateService.compareVersions('2.0.0', '1.9.9'), isPositive);
    });

    test('handles shorter and pre-release version tags cleanly', () {
      expect(AppUpdateService.compareVersions('1.3', '1.3.0'), equals(0));
      expect(AppUpdateService.compareVersions('1.3.0-beta', '1.3.0'), equals(0));
      expect(AppUpdateService.compareVersions('1.3.0', '1.3.1-rc1'), isNegative);
    });
  });
}
