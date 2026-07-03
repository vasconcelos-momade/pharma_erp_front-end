String pdvFormatDate(DateTime? date) {
  if (date == null) return '—';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String pdvFormatMoney(num value) {
  final amount = value.toDouble();
  final hasDecimals = amount != amount.truncateToDouble();
  return '${amount.toStringAsFixed(hasDecimals ? 2 : 0)} MT';
}
