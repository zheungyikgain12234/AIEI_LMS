class Student {
  final String id;
  final String name;
  final String studentId;
  final String email;
  final String department;
  final String? title;
  final String programTrack;
  final String cohort;
  final double gpa;

  const Student({
    required this.id,
    required this.name,
    required this.studentId,
    required this.email,
    required this.department,
    this.title,
    required this.programTrack,
    required this.cohort,
    required this.gpa,
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: (map['id'] as num).toString(),
      name: map['name'] as String,
      studentId: map['student_id'] as String,
      email: map['email'] as String,
      department: map['department'] as String,
      title: map['title'] as String?,
      programTrack: map['program_track'] as String,
      cohort: map['cohort'] as String,
      gpa: (map['gpa'] as num).toDouble(),
    );
  }
}
