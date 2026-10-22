import 'package:flutter/services.dart';

/// 입력하는 동안 전화번호에 하이픈을 자동으로 넣는다.
/// 02-1234-5678 / 031-123-4567 / 010-1234-5678 / 1588-1234 형식을 지원한다.
class KoreanPhoneFormatter extends TextInputFormatter {
  const KoreanPhoneFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatKoreanPhone(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String _digitsOf(String text) => text.replaceAll(RegExp(r'\D'), '');

/// 숫자만 남기고 지역번호/대표번호 규칙에 맞춰 하이픈을 넣는다.
String formatKoreanPhone(String input) {
  var digits = _digitsOf(input);

  // 1588-1234 같은 대표번호(앞 4자리)는 8자리, 나머지는 지역번호 2~3자리 + 최대 8자리.
  final isRepresentative = RegExp(r'^1[568]').hasMatch(digits);
  final headLength = isRepresentative ? 4 : (digits.startsWith('02') ? 2 : 3);
  final maxDigits = isRepresentative ? 8 : headLength + 8;
  if (digits.length > maxDigits) digits = digits.substring(0, maxDigits);

  if (digits.length <= headLength) return digits;
  final head = digits.substring(0, headLength);
  final rest = digits.substring(headLength);

  if (isRepresentative) return '$head-$rest';
  if (rest.length <= 3) return '$head-$rest';
  // 뒤 번호가 7자리 이하면 3-4, 8자리면 4-4로 나눈다.
  final middleLength = rest.length > 7 ? 4 : 3;
  return '$head-${rest.substring(0, middleLength)}-${rest.substring(middleLength)}';
}

/// 유효한 한국 전화번호 형식인가 (지역번호, 휴대폰, 대표번호).
bool isValidKoreanPhone(String input) {
  final digits = _digitsOf(input);
  if (RegExp(r'^1[568]\d{6}$').hasMatch(digits)) return true;
  if (digits.startsWith('02')) return digits.length == 9 || digits.length == 10;
  return RegExp(r'^0\d{9,10}$').hasMatch(digits);
}
