/// Formats a double as an Indonesian rupiah string with thousand separators,
/// e.g. `Rp 1.234.567`. Shared by money displays across views.
String formatRupiah(double val) {
  if (val == 0) return 'Rp 0';
  final isNegative = val < 0;
  final absVal = val.abs().toInt();
  final str = absVal.toString();
  final buffer = StringBuffer();
  int count = 0;
  for (int i = str.length - 1; i >= 0; i--) {
    buffer.write(str[i]);
    count++;
    if (count % 3 == 0 && i != 0) {
      buffer.write('.');
    }
  }
  final reversed = buffer.toString().split('').reversed.join('');
  return '${isNegative ? '- ' : ''}Rp $reversed';
}
