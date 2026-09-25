/// Memformat nominal rupiah tanpa pustaka tambahan.
///
/// Nominal selalu bilangan bulat rupiah dan pemisah ribuan memakai titik sesuai
/// kebiasaan Indonesia. Contoh: `45000` menjadi `Rp 45.000`.
String formatRupiah(int amount, {bool withSymbol = true}) {
  final isNegative = amount < 0;
  final digits = amount.abs().toString();
  final buffer = StringBuffer(isNegative ? '-' : '');

  if (withSymbol) {
    buffer.write('Rp ');
  }

  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[index]);
  }

  return buffer.toString();
}
