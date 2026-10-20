import 'package:flutter/material.dart';

String _dropdownLabel<T>(DropdownMenuItem<T> item) {
  final child = item.child;
  if (child is Text) return child.data ?? child.textSpan?.toPlainText() ?? '${item.value}';
  return '${item.value}';
}

/// A–Z, case-insensitive, with numbers inside a label compared as numbers
/// (so "2" sorts before "10").
int compareDropdownLabels(String a, String b) {
  final chunk = RegExp(r'\d+|\D+');
  final left = chunk.allMatches(a.toLowerCase()).map((m) => m[0]!).toList();
  final right = chunk.allMatches(b.toLowerCase()).map((m) => m[0]!).toList();
  for (var i = 0; i < left.length && i < right.length; i++) {
    final l = left[i];
    final r = right[i];
    final ln = int.tryParse(l);
    final rn = int.tryParse(r);
    final cmp = ln != null && rn != null ? ln.compareTo(rn) : l.compareTo(r);
    if (cmp != 0) return cmp;
  }
  return left.length.compareTo(right.length);
}

/// Every dropdown in the app lists its options A–Z. An "All …" option stays
/// first, since it means "no filter" rather than being a choice among the rest.
List<DropdownMenuItem<T>> sortDropdownItems<T>(List<DropdownMenuItem<T>> items) {
  bool isAll(DropdownMenuItem<T> i) {
    final label = _dropdownLabel(i).trim().toLowerCase();
    return label == 'all' || label.startsWith('all ');
  }

  final sorted = [...items];
  sorted.sort((a, b) {
    final aAll = isAll(a);
    final bAll = isAll(b);
    if (aAll != bAll) return aAll ? -1 : 1;
    return compareDropdownLabels(_dropdownLabel(a), _dropdownLabel(b));
  });
  return sorted;
}
