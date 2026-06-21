import 'package:flutter/services.dart';

String requisicaoFormatMoney(num value) => '${value.toStringAsFixed(2)} MT';

String requisicaoFormatQuantity(num value) {
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

String requisicaoFormatDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

String requisicaoFormatDisplayDate(dynamic value) {
  if (value is DateTime) {
    return requisicaoFormatDate(value);
  }
  final normalized = value?.toString().trim() ?? '';
  if (normalized.isEmpty) {
    return '-';
  }
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) {
    return normalized;
  }
  return requisicaoFormatDate(parsed);
}

String requisicaoFormatIsoDate(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

DateTime? requisicaoParseDateInputValue(String? value) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty) {
    return null;
  }

  final parsed = DateTime.tryParse(normalized);
  if (parsed != null) {
    return parsed;
  }

  final match = RegExp(r'^\d{4}-\d{2}-\d{2}').firstMatch(normalized);
  if (match != null) {
    return DateTime.tryParse(match.group(0)!);
  }

  final displayMatch = RegExp(
    r'^(\d{2})/(\d{2})/(\d{4})$',
  ).firstMatch(normalized);
  if (displayMatch != null) {
    final day = int.tryParse(displayMatch.group(1)!);
    final month = int.tryParse(displayMatch.group(2)!);
    final year = int.tryParse(displayMatch.group(3)!);
    if (day != null && month != null && year != null) {
      final parsed = DateTime(year, month, day);
      if (parsed.year == year && parsed.month == month && parsed.day == day) {
        return parsed;
      }
    }
  }

  return null;
}

String requisicaoNormalizeDateInputValue(String? value) {
  final parsed = requisicaoParseDateInputValue(value);
  if (parsed == null) {
    return value?.trim() ?? '';
  }
  return requisicaoFormatDate(parsed);
}

class RequisicaoDateTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitedDigits = digits.length > 8 ? digits.substring(0, 8) : digits;
    final formatted = _formatDigits(limitedDigits);
    final digitsBeforeCursor = _countDigitsBeforeCursor(newValue);
    final selectionOffset = _selectionOffsetForDigits(
      formatted,
      digitsBeforeCursor.clamp(0, limitedDigits.length),
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionOffset),
      composing: TextRange.empty,
    );
  }

  int _countDigitsBeforeCursor(TextEditingValue value) {
    final cursor = value.selection.baseOffset.clamp(0, value.text.length);
    return RegExp(r'\d').allMatches(value.text.substring(0, cursor)).length;
  }

  int _selectionOffsetForDigits(String formatted, int digitsBeforeCursor) {
    if (digitsBeforeCursor <= 0) {
      return 0;
    }

    var seenDigits = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (RegExp(r'\d').hasMatch(formatted[i])) {
        seenDigits++;
        if (seenDigits == digitsBeforeCursor) {
          return i + 1;
        }
      }
    }

    return formatted.length;
  }

  String _formatDigits(String digits) {
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if ((i == 2 || i == 4) && buffer.isNotEmpty) {
        buffer.write('/');
      }
      buffer.write(digits[i]);
    }

    return buffer.toString();
  }
}
