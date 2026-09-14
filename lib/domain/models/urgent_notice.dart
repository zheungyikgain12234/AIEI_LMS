class UrgentNotice {
  final String title;
  final String subtitle;
  final String badgeText;
  final String dueText;
  final int progressPercentage;
  final String ctaLabel;

  const UrgentNotice({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.dueText,
    required this.progressPercentage,
    required this.ctaLabel,
  });
}
