import 'package:flutter_test/flutter_test.dart';
import 'package:simrs_dokter/core/utils/formatters.dart';

void main() {
  group('formatRupiah Formatter Tests', () {
    test('formats positive amounts correctly', () {
      expect(formatRupiah(50000), 'Rp 50.000');
      expect(formatRupiah(1250000), 'Rp 1.250.000');
      expect(formatRupiah(100), 'Rp 100');
    });

    test('formats zero correctly', () {
      expect(formatRupiah(0), 'Rp 0');
    });

    test('formats negative amounts correctly', () {
      expect(formatRupiah(-25000), '- Rp 25.000');
      expect(formatRupiah(-1500000), '- Rp 1.500.000');
    });

    test('handles double/float values by rounding or truncating properly', () {
      expect(formatRupiah(75000.50), 'Rp 75.000');
    });
  });
}
