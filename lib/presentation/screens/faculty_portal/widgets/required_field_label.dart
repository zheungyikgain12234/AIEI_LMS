import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';

/// A form field label with a red "*" appended — the faculty portal's shared
/// convention for marking a compulsory field. Pass to `InputDecoration.label`
/// (not `labelText`, which only accepts plain text) wherever a field must be
/// filled in before the form can be saved.
Widget requiredLabel(String text) {
  return Text.rich(
    TextSpan(
      children: [
        TextSpan(text: text),
        const TextSpan(text: ' *', style: TextStyle(color: FacultyColors.error)),
      ],
    ),
  );
}
