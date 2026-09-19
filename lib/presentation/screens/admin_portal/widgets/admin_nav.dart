import 'package:flutter/material.dart';
import 'admin_sidebar.dart';
import 'admin_mobile_bottom_nav.dart';
import '../manage_lecturers_screen.dart';
import '../lecturer_allocation_screen.dart';
import '../manage_students_screen.dart';
import '../manage_courses_screen.dart';
import '../manage_classes_screen.dart';
import '../manage_badges_screen.dart';
import '../role_course_mapping_screen.dart';
import '../department_course_mapping_screen.dart';
import '../track_course_mapping_screen.dart';
import '../course_enrollment_screen.dart';
import '../manage_departments_screen.dart';
import '../manage_program_tracks_screen.dart';
import '../manage_cohorts_screen.dart';
import '../manage_lecturer_departments_screen.dart';
import '../manage_specializations_screen.dart';
import '../manage_roles_screen.dart';

/// Centralized sidebar navigation for every Admin Portal screen — pushes the
/// screen for [dest], or does nothing if it's already the [current] screen.
void handleAdminNav(BuildContext context, AdminNavDestination current, AdminNavDestination dest) {
  if (dest == current) return;
  final Widget screen = switch (dest) {
    AdminNavDestination.manageLecturers => const ManageLecturersScreen(),
    AdminNavDestination.lecturerAllocation => const LecturerAllocationScreen(),
    AdminNavDestination.manageStudents => const ManageStudentsScreen(),
    AdminNavDestination.manageCourses => const ManageCoursesScreen(),
    AdminNavDestination.manageClasses => const ManageClassesScreen(),
    AdminNavDestination.manageBadges => const ManageBadgesScreen(),
    AdminNavDestination.roleCourseMapping => const RoleCourseMappingScreen(),
    AdminNavDestination.departmentCourseMapping => const DepartmentCourseMappingScreen(),
    AdminNavDestination.trackCourseMapping => const TrackCourseMappingScreen(),
    AdminNavDestination.courseEnrollment => const CourseEnrollmentScreen(),
    AdminNavDestination.manageDepartments => const ManageDepartmentsScreen(),
    AdminNavDestination.manageProgramTracks => const ManageProgramTracksScreen(),
    AdminNavDestination.manageCohorts => const ManageCohortsScreen(),
    AdminNavDestination.manageLecturerDepartments => const ManageLecturerDepartmentsScreen(),
    AdminNavDestination.manageSpecializations => const ManageSpecializationsScreen(),
    AdminNavDestination.manageRoles => const ManageRolesScreen(),
  };
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

/// Root mobile bottom-nav tap handling — pushes the screen for [tab], or
/// does nothing if it's already the [current] screen. Mirrors
/// [handleAdminNav] but for the 3-tab [AdminMobileBottomNav].
void handleAdminMobileTab(BuildContext context, AdminMobileTab current, AdminMobileTab tab) {
  if (tab == current) return;
  final Widget screen = switch (tab) {
    AdminMobileTab.lecturers => const ManageLecturersScreen(),
    AdminMobileTab.students => const ManageStudentsScreen(),
    AdminMobileTab.courses => const ManageCoursesScreen(),
  };
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}
