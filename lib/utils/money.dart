/// Formats integer minor units (stotinki) as a Bulgarian lev amount, e.g.
/// `formatCents(1999, 'bgn')` → "19,99 лв.". Deliberately hand-rolled
/// rather than `NumberFormat.currency(locale: 'bg_BG', ...)` so it doesn't
/// depend on the `intl` package's bundled locale data actually including
/// Bulgarian.
String formatCents(int cents, String currency) {
  final major = (cents / 100).toStringAsFixed(2).replaceFirst('.', ',');
  final symbol = currency.toLowerCase() == 'bgn' ? 'лв.' : currency.toUpperCase();
  return '$major $symbol';
}
