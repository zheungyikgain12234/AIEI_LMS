import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';

class FacultyHeader extends StatelessWidget implements PreferredSizeWidget {
  final ValueChanged<String>? onSearch;

  const FacultyHeader({super.key, this.onSearch});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: FacultyColors.surfaceContainerLowest,
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 1))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: FacultyColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('AIEI', style: FacultyTypography.titleSm(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: FacultyColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: FacultyColors.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'FACULTY PORTAL',
                  style: FacultyTypography.labelXs(color: FacultyColors.onSurfaceVariant)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: FacultyColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    onChanged: onSearch,
                    style: FacultyTypography.bodySm(color: FacultyColors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Search courses, curriculum, submissions, students...',
                      hintStyle: FacultyTypography.bodySm(color: FacultyColors.outline),
                      prefixIcon: const Icon(Icons.search, size: 18, color: FacultyColors.outline),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined, size: 22, color: FacultyColors.onSurfaceVariant),
                tooltip: 'Notifications',
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: FacultyColors.error, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: FacultyColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.person, color: FacultyColors.onPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dr. Sarah Lin', style: FacultyTypography.bodySm(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
                  Text('Lead Data Architect • Faculty Instructor', style: FacultyTypography.labelXs()),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
