// Formatage uniforme des montants: 34 500,00
String formatAmount(double amount, {bool withSuffix = true, String suffix = 'درهم'}) {
  final parts = amount.toStringAsFixed(2).split('.');
  final intPart = parts[0];
  final decPart = parts[1];
  final buffer = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('\u00A0');
    buffer.write(intPart[i]);
  }
  final formatted = '${buffer.toString()},$decPart';
  if (withSuffix) return '$formatted $suffix';
  return formatted;
}

String formatAmountShort(double amount) {
  final intPart = amount.toStringAsFixed(0);
  final buffer = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('\u00A0');
    buffer.write(intPart[i]);
  }
  return buffer.toString();
}
