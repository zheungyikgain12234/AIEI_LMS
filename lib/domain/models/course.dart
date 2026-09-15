class Course {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? imageUrl;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.imageUrl,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as String,
      title: map['course_title'] as String,
      description: map['course_description'] as String,
      category: map['category'] as String? ?? 'techData',
      imageUrl: map['image_url'] as String?,
    );
  }
}
