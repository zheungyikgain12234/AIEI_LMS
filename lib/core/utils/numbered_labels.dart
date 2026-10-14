// Module / session numbering is derived from position, never stored in the
// name — so adding, deleting or dragging an item renumbers the rest for free.
// The syllabus editor and the student content view must agree on this.

/// "Session 2 : " — the prefix shown before a session's name. Modules carry no
/// number prefix (just their name).
String numberedPrefix(String kind, int n) => kind == 'Module' ? '' : '$kind $n : ';

final _labelPrefixPattern = RegExp(r'^\s*(Module|Lesson|Session)\s*\d*\s*:\s*', caseSensitive: false);

/// [name] without any leading "Module n :" / "Session n :" (or legacy "Lesson n :") label (typed by the
/// user, or left over from older data), so it isn't shown or saved twice.
String bareName(String name) => name.replaceFirst(_labelPrefixPattern, '').trim();

/// The full display label, e.g. "Session 3 : Safety Basics", or just "Safety Basics" for a module.
String numberedLabel(String kind, int position, String name) => '${numberedPrefix(kind, position)}${bareName(name)}';
