// Module / session numbering is derived from position, never stored in the
// name — so adding, deleting or dragging an item renumbers the rest for free.
// The syllabus editor and the student content view must agree on this.

/// "Module 3 : " / "Lesson 2 : " — the prefix shown before an item's name.
String numberedPrefix(String kind, int n) => '$kind $n : ';

final _labelPrefixPattern = RegExp(r'^\s*(Module|Lesson)\s*\d*\s*:\s*', caseSensitive: false);

/// [name] without any leading "Module n :" / "Lesson n :" label (typed by the
/// user, or left over from older data), so it isn't shown or saved twice.
String bareName(String name) => name.replaceFirst(_labelPrefixPattern, '').trim();

/// The full display label, e.g. "Module 3 : Safety Basics".
String numberedLabel(String kind, int position, String name) => '${numberedPrefix(kind, position)}${bareName(name)}';
