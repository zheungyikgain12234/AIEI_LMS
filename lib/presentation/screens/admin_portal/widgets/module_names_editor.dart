import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';

/// Holds the editable module-name rows for [ModuleNamesEditor] so a parent
/// form can read, replace or reset them. Always keeps at least one row.
class ModuleNamesController extends ChangeNotifier {
  final List<TextEditingController> _rows = [TextEditingController()];

  List<TextEditingController> get rows => List.unmodifiable(_rows);

  /// Trimmed, non-blank module names in order.
  List<String> get names => [for (final c in _rows) if (c.text.trim().isNotEmpty) c.text.trim()];

  void add() {
    _rows.add(TextEditingController());
    notifyListeners();
  }

  /// Removes row [index]; the last remaining row is cleared instead, so the
  /// form never has zero rows.
  void remove(int index) {
    if (_rows.length == 1) {
      _rows.first.clear();
    } else {
      _rows.removeAt(index).dispose();
    }
    notifyListeners();
  }

  void setNames(List<String> names) {
    for (final c in _rows) {
      c.dispose();
    }
    _rows
      ..clear()
      ..addAll([for (final n in names) TextEditingController(text: n)]);
    if (_rows.isEmpty) _rows.add(TextEditingController());
    notifyListeners();
  }

  void clear() => setNames(const []);

  /// Lets [ModuleNamesEditor] tell listeners a row's text changed.
  void textChanged() => notifyListeners();

  @override
  void dispose() {
    for (final c in _rows) {
      c.dispose();
    }
    super.dispose();
  }
}

/// A list of module-name text fields, each with a remove button, plus an
/// "Add module" button.
class ModuleNamesEditor extends StatelessWidget {
  final ModuleNamesController controller;
  final VoidCallback? onChanged;

  const ModuleNamesEditor({super.key, required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final rows = controller.rows;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < rows.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(width: 28, child: Text('${i + 1}.', style: AdminTypography.labelSm())),
                    Expanded(
                      child: TextField(
                        controller: rows[i],
                        onChanged: (_) => onChanged?.call(),
                        style: AdminTypography.bodyMd(color: AdminColors.onSurface),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: AdminColors.surfaceContainerLow,
                          hintText: 'Module name',
                          hintStyle: AdminTypography.bodySm(color: AdminColors.outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        controller.remove(i);
                        onChanged?.call();
                      },
                      icon: const Icon(Icons.close, size: 18, color: AdminColors.onSurfaceVariant),
                      tooltip: 'Remove module',
                    ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: () {
                controller.add();
                onChanged?.call();
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add module'),
            ),
          ],
        );
      },
    );
  }
}
