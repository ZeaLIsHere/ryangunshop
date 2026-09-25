import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/format/rupiah.dart';

void main() {
  group('formatRupiah', () {
    test('memakai pemisah ribuan titik', () {
      expect(formatRupiah(0), 'Rp 0');
      expect(formatRupiah(999), 'Rp 999');
      expect(formatRupiah(6000), 'Rp 6.000');
      expect(formatRupiah(175000), 'Rp 175.000');
      expect(formatRupiah(1250000), 'Rp 1.250.000');
    });

    test('menangani nominal negatif dan tanpa simbol', () {
      expect(formatRupiah(-6000), '-Rp 6.000');
      expect(formatRupiah(6000, withSymbol: false), '6.000');
    });
  });
}
