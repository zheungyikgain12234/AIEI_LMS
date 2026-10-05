/// Minimal RFC-4180-style CSV parser: handles quoted fields, escaped quotes
/// (`""`), and both `\n` / `\r\n` line endings. Fully blank rows are dropped.
List<List<String>> parseCsv(String content) {
  final rows = <List<String>>[];
  var row = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < content.length; i++) {
    final char = content[i];
    if (inQuotes) {
      if (char == '"') {
        if (i + 1 < content.length && content[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        buffer.write(char);
      }
    } else if (char == '"') {
      inQuotes = true;
    } else if (char == ',') {
      row.add(buffer.toString());
      buffer.clear();
    } else if (char == '\n' || char == '\r') {
      if (char == '\r' && i + 1 < content.length && content[i + 1] == '\n') i++;
      row.add(buffer.toString());
      buffer.clear();
      rows.add(row);
      row = [];
    } else {
      buffer.write(char);
    }
  }
  if (buffer.isNotEmpty || row.isNotEmpty) {
    row.add(buffer.toString());
    rows.add(row);
  }
  return rows.where((r) => r.any((c) => c.trim().isNotEmpty)).toList();
}

/// Quotes [value] for CSV output when it contains a comma, quote or newline.
String csvEscape(String value) =>
    value.contains(RegExp(r'[",\n\r]')) ? '"${value.replaceAll('"', '""')}"' : value;
