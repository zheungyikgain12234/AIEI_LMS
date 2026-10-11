import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/admin_colors.dart';
import 'package:stitch_aiei_lms/core/theme/admin_typography.dart';
import 'admin_field_label.dart';

/// A labelled date + time picker pair that edits one [DateTime]. Picking a
/// date first defaults the time to [defaultHour]:00.
class AdminDateTimeField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final int defaultHour;

  const AdminDateTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.defaultHour = 0,
  });

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final v = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFieldLabel(label),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _box(
                icon: Icons.calendar_today_outlined,
                text: v == null ? 'Select date' : '${v.year}-${_two(v.month)}-${_two(v.day)}',
                placeholder: v == null,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: v ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked == null) return;
                  onChanged(DateTime(picked.year, picked.month, picked.day, v?.hour ?? defaultHour, v?.minute ?? 0));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _box(
                icon: Icons.schedule,
                text: v == null ? 'Select time' : '${_two(v.hour)}:${_two(v.minute)}',
                placeholder: v == null,
                onTap: v == null
                    ? null
                    : () async {
                        final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: v.hour, minute: v.minute));
                        if (picked == null) return;
                        onChanged(DateTime(v.year, v.month, v.day, picked.hour, picked.minute));
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _box({required IconData icon, required String text, required bool placeholder, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(color: AdminColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AdminColors.onSurfaceVariant),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: AdminTypography.bodyMd(color: placeholder ? AdminColors.outline : AdminColors.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
