import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/enrolled_course.dart';
import '../../domain/models/course_stats.dart';
import '../../domain/models/urgent_notice.dart';

class MockCoursesDataSource {
  static const List<EnrolledCourse> courses = [
    EnrolledCourse(
      id: 'c1-python',
      title: 'Python for Enterprise Data Analysis & Automation',
      category: CourseCategory.techData,
      instructorOrBoard: 'Dr. Sarah Lin',
      instructorIcon: Icons.school_outlined,
      instructorIconColor: AppColors.secondary,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBkaSQDBQPtWkABa_7PiXVJsRQkHv4xgrG3XiijLhyOTArutGaZK0X05nOVBtjVuJfyRPlFsX9CH0dAMh-kx6LJBba5UjVvkgHx5DOI9Jq8mn98t5FTMg3L8kc9RCcKIG7CvAj6jJG6F1WcCNuMwb1VZ8bFd3wBHxt2crG1xV0Yn7d8UFxNqLPsaE7O7-5zfbPXeU7V1GlQc8GTHdFWmJWqy8fK7RQkfMAqZPyOXl0HpxOWd1hm7qGgiA',
      tags: [
        CourseTag(
          label: 'MANDATORY',
          backgroundColor: AppColors.primary,
          textColor: AppColors.onPrimary,
        ),
        CourseTag(
          label: 'Q4 Talent Competency',
          backgroundColor: Color(0xE6FFFFFF),
          textColor: AppColors.secondary,
        ),
      ],
      durationText: '6.5 hrs total',
      trackTypeText: 'Verified Badge Track',
      progressPercentage: 70,
      completedLessons: 7,
      totalLessons: 10,
      nextLessonOrStatus: 'Next: Building Automated Data Pipelines',
      isWarningNextLesson: false,
      unlockBadgeTitle: 'Unlocks: Python Automation Specialist',
      unlockBadgeIcon: Icons.military_tech_outlined,
      deadlineDays: 25,
      ctaButtonText: 'Continue Course',
      isCompleted: false,
    ),
    EnrolledCourse(
      id: 'c2-oshe',
      title: 'OSHE Workplace Safety & Compliance 2025',
      category: CourseCategory.compliance,
      instructorOrBoard: 'Accredited Enterprise Safety Board',
      instructorIcon: Icons.verified_outlined,
      instructorIconColor: AppColors.onTertiaryContainer,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB2OyYsvS_sX1hJ5qFZkMotA7KvbsvzTYWCF8WfETZtN0WSlfNQVhkrHsE2TUvzXjLriYi6LpI1QlVqk-bwOrvw91ojbYoLwM_Zr1ruloQ8yjzkvpR7-HcehL4qrnDrVs_4iMRN5WxJy9eG3JC6tjt3dVRM0B2lNuBugzLz-hsSE78-Mtrn1GPEA4LaZQxrCS24MIdweDmd2qWKW32UpGdY9ti9Vl7Dt6P7vfqp7Sdl2_U4kIgeIc1PhQ',
      tags: [
        CourseTag(
          label: 'Quiz Pending',
          backgroundColor: AppColors.errorContainer,
          textColor: AppColors.onErrorContainer,
        ),
        CourseTag(
          label: 'Annual Compliance',
          backgroundColor: Color(0xE6FFFFFF),
          textColor: AppColors.onSurfaceVariant,
        ),
      ],
      durationText: '3.2 hrs total',
      progressPercentage: 38,
      completedLessons: 3,
      totalLessons: 8,
      nextLessonOrStatus: 'Next: Complete Lesson 4 Compliance Quiz',
      isWarningNextLesson: true,
      unlockBadgeTitle: 'Unlocks: Certified Safety Officer',
      unlockBadgeIcon: Icons.workspace_premium_outlined,
      deadlineDays: 14,
      ctaButtonText: 'Continue Course',
      isCompleted: false,
    ),
    EnrolledCourse(
      id: 'c3-genai',
      title: 'ChatGPT & Generative AI Prompt Engineering',
      category: CourseCategory.aiTools,
      instructorOrBoard: 'Marcus Vance',
      instructorIcon: Icons.account_circle_outlined,
      instructorIconColor: AppColors.secondary,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuA4mqWaPlwERSIsIsGlYTZJKCU-zBC91ZVEnzlYmMkcczWZma3JM6Xd_Bxldqi1F87AM_47pV1nWrNbB8_vSI4EgHd-tc9HZTk6oa-8f_DZaUcTrY0U4_TjYRMT3wj1UfvWbLv9Nqo1l7eMPy0V9-fXJakk4e2YAd6AmDfbAMjOTkGMm2YK-zWpw8XIKcFMOPC2lGhe2TLfHCk_j_677br9FSzmugZx2bQc1dk61ey-EtLnrgvHPojdLw',
      tags: [
        CourseTag(
          label: 'AI UPSKILLING',
          backgroundColor: AppColors.secondaryContainer,
          textColor: AppColors.onSecondaryContainer,
        ),
      ],
      durationText: '4.0 hrs total',
      progressPercentage: 40,
      completedLessons: 4,
      totalLessons: 10,
      nextLessonOrStatus: 'Next: Few-Shot Prompting & Workflow Automation',
      isWarningNextLesson: false,
      unlockBadgeTitle: 'Unlocks: Enterprise AI Practitioner',
      unlockBadgeIcon: Icons.psychology_outlined,
      deadlineDays: 30,
      ctaButtonText: 'Continue Course',
      isCompleted: false,
    ),
    EnrolledCourse(
      id: 'c4-finance',
      title: 'Advanced Financial Modeling in Microsoft Excel',
      category: CourseCategory.techData,
      instructorOrBoard: 'Elena Rostova',
      instructorIcon: Icons.school_outlined,
      instructorIconColor: AppColors.secondary,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAR1qa-PQ_EQITTA9fg1r6hu8Tvtdvs1ekcbF5AZPoioMdMTY50_5YruGcysD0SJ6-8HZaOLG_Qi1RpOlkHkhFcFym36_cBZbIzw4jDEtFbKK7ESumokNXWXZQa9jPJ2O4ZxIX8U6iLHNgQlhgiLKciKZmlz6PPi5p7ZCw7-f3gXnx9lREsaOhXDu8f5Q4C42QheRdnHGkL1PjQ_kaMlv2_fAxXfViXwLZTcxB1OlLDwfONXI1h56Jmag',
      tags: [
        CourseTag(
          label: 'Core Finance',
          backgroundColor: Color(0xE6FFFFFF),
          textColor: AppColors.onSurface,
        ),
      ],
      durationText: '8.0 hrs total',
      progressPercentage: 20,
      completedLessons: 2,
      totalLessons: 10,
      nextLessonOrStatus: 'Next: Dynamic Financial Statement Forecasting',
      isWarningNextLesson: false,
      unlockBadgeTitle: 'Unlocks: FP&A Certified Analyst',
      unlockBadgeIcon: Icons.query_stats_outlined,
      deadlineDays: 45,
      ctaButtonText: 'Continue Course',
      isCompleted: false,
    ),
    EnrolledCourse(
      id: 'c5-cyber',
      title: 'Corporate Cybersecurity & Phishing Defense',
      category: CourseCategory.compliance,
      instructorOrBoard: 'SecOps Corporate Division',
      instructorIcon: Icons.security_outlined,
      instructorIconColor: AppColors.error,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDXYkMiYXMEX1qK60nUL9gN1pOR3niSrz2k0TccpqxYLosexsrNqafST6KNh4sd_FbxmX-hH9xnHXbRHt13RwK13JgerDi7uZodQ2pDceEI7qvo_-wfHo8dt9ziLjMaEqyFqDr5fKmWhqtY_6q0VBYW0l9fHm_k4wGuXId41QByjT4bpKuozhC1gCtNDrGxyK-cVfV2b8RrGZDXA6ClJmu73mcMOwNQSF_OxxRkT6Lq8q4OOYKGNJkLKg',
      tags: [
        CourseTag(
          label: 'SECURITY MANDATORY',
          backgroundColor: AppColors.error,
          textColor: AppColors.onError,
        ),
        CourseTag(
          label: 'Deadline: 5 Days',
          backgroundColor: AppColors.surfaceContainerLowest,
          textColor: AppColors.error,
        ),
      ],
      scoreText: 'High Urgency',
      progressPercentage: 85,
      completedLessons: 6,
      totalLessons: 7,
      nextLessonOrStatus: 'Next: Incident Escalation Simulation',
      isWarningNextLesson: true,
      unlockBadgeTitle: 'Unlocks: Certified Cyber Sentinel',
      unlockBadgeIcon: Icons.shield_outlined,
      deadlineDays: 5,
      ctaButtonText: 'Continue Course',
      isCompleted: false,
    ),
    EnrolledCourse(
      id: 'c6-exec',
      title: 'Effective Executive Communication & Stakeholder Alignment',
      category: CourseCategory.productivity,
      instructorOrBoard: 'Soft Skills Mastery Program',
      instructorIcon: Icons.record_voice_over_outlined,
      instructorIconColor: AppColors.onTertiaryContainer,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAcMjKgfoHEa8G_VzTvz5W-lpWL88zl5gWlksr1wM5y1Xty2v2vyzFbfxeqrX4zS0yP5kTUyqnf8-SakPJEFx-Kzlrnm-6JxqKczG3nftxgNbS2pjH7BNOSUt0j7QnD8hzJE_KcL2EXk87-27cu8uHdG1igavFS1cWXoTyByUiEHo8KL9bipIN0eO8qitDVg30oxij7-vnE9uEDXLEdnUbJU07Uvz2EBfaV3x7C4mGS2oySo_Ai59eOyQ',
      tags: [
        CourseTag(
          label: 'Completed',
          backgroundColor: AppColors.tertiaryContainer,
          textColor: AppColors.onTertiaryContainer,
          hasCheckIcon: true,
        ),
        CourseTag(
          label: 'Executive Track',
          backgroundColor: Color(0xE6FFFFFF),
          textColor: AppColors.onSurfaceVariant,
        ),
      ],
      scoreText: 'Final Defense Passed',
      progressPercentage: 100,
      completedLessons: 6,
      totalLessons: 6,
      nextLessonOrStatus: 'All case studies and capstones approved',
      isWarningNextLesson: false,
      unlockBadgeTitle: 'Badge: Leadership Communicator',
      unlockBadgeIcon: Icons.stars_outlined,
      deadlineDays: 180,
      ctaButtonText: 'Review Course / View Badge',
      isCompleted: true,
    ),
  ];

  static const CourseStats stats = CourseStats(
    enrolledCourses: 6,
    inProgressCourses: 5,
    completedCourses: 1,
    completedLessons: 19,
    totalLessons: 52,
    badgesEarned: 1,
  );

  static const UrgentNotice urgentNotice = UrgentNotice(
    title: 'Corporate Cybersecurity & Phishing Defense',
    subtitle: 'Lesson 7 Incident Escalation Simulation pending final sign-off.',
    badgeText: 'Critical Action',
    dueText: 'Due in 5 Days',
    progressPercentage: 85,
    ctaLabel: 'Resume',
  );
}
