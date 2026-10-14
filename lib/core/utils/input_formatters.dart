import 'package:flutter/services.dart';

/// Upper-cases everything typed or pasted, as the user types — used on every
/// "code" field so codes are always stored in capitals.
class UpperCaseTextFormatter extends TextInputFormatter {
  const UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

/// Number-only fields: typing any other character has no effect.
final List<TextInputFormatter> digitsOnly = [FilteringTextInputFormatter.digitsOnly];

/// Decimal-number fields (one optional decimal point): letters have no effect.
final List<TextInputFormatter> decimalOnly = [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))];

/// Upper bounds for numeric inputs, so an absurd value is rejected with a
/// readable message instead of reaching the database.
const int maxClassCapacity = 1000;
const int maxCredits = 30;
const int maxLecturerCredits = 60;
const int maxExamMinutes = 600;
const double maxMarksLimit = 10000;
