/// The kind of content a single [ContentBlock] holds. A session mixes any
/// number of blocks (e.g. some text, then an embedded video, then a file)
/// rather than being limited to one content shape per row.
enum ContentBlockType {
  text,
  video,
  image,
  link,
  file,
  exam,
  assignment,
  physicalClass;

  static ContentBlockType fromKey(String key) =>
      ContentBlockType.values.firstWhere((t) => t.name == key, orElse: () => ContentBlockType.text);
}

/// One piece of content inside a session (`content_blocks` table).
/// `content` shape depends on [type]:
/// - text: `{"delta": [...quill ops...], "body": "plain-text fallback"}`
/// - video: `{"url": "...", "caption": "...", "thumbnailUrl": "..."}`
/// - image: `{"url": "...", "caption": "..."}`
/// - link: `{"url": "...", "label": "..."}`
/// - file: `{"url": "...", "name": "...", "sizeLabel": "..."}`
/// - exam: `{"title": "...", "description": "...", "instructions": "...",
///   "dueDate": "ISO 8601 string", "mode": "normal|open_book|take_home"}` —
///   points at the exam editor's section/question tree, keyed by [id].
/// - assignment: `{"title": "...", "description": "...", "instructions":
///   "...", "dueDate": "ISO 8601 string"}` — points at the assignment
///   editor, keyed by [id].
/// - physicalClass: `{"title": "...", "description": "...", "scheduledAt":
///   "ISO 8601 string"}` — students tick attendance once while it's on;
///   each tick is a `content_block_submissions` row (status `submitted`).
class ContentBlock {
  final String id;
  final String sessionId;
  final ContentBlockType type;
  final Map<String, dynamic> content;
  final int sorting;

  const ContentBlock({
    required this.id,
    required this.sessionId,
    required this.type,
    required this.content,
    required this.sorting,
  });

  /// Plain-text fallback/preview of the rich text body.
  String get body => content['body'] as String? ?? '';

  /// Quill Delta ops for the rich text body, or null when this block predates
  /// rich text and only has a plain [body].
  List<dynamic>? get delta => content['delta'] as List<dynamic>?;

  String get url => content['url'] as String? ?? '';
  String? get caption => content['caption'] as String?;
  String? get thumbnailUrl => content['thumbnailUrl'] as String?;
  String? get label => content['label'] as String?;
  String? get fileName => content['name'] as String?;
  String? get sizeLabel => content['sizeLabel'] as String?;
  String? get title => content['title'] as String?;
  String? get description => content['description'] as String?;
  String? get instructions => content['instructions'] as String?;
  String? get mode => content['mode'] as String?;

  /// Exam time limit in minutes — the exam-answering screen shows a
  /// persistent countdown and auto-submits at zero. Null means no limit.
  int? get timeLimitMinutes => (content['timeLimitMinutes'] as num?)?.toInt();

  /// Percentage (0–100) this exam/assignment counts toward the class's
  /// final grade. Only meaningful for [ContentBlockType.exam]/
  /// [ContentBlockType.assignment] blocks — null if unset.
  double? get weightage => (content['weightage'] as num?)?.toDouble();

  /// Files the lecturer attached alongside the instructions — each
  /// `{"url": "...", "name": "..."}`. Only meaningful for
  /// [ContentBlockType.exam]/[ContentBlockType.assignment] blocks.
  List<Map<String, dynamic>> get instructionFiles =>
      (content['instructionFiles'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

  DateTime? get dueDate {
    final raw = content['dueDate'] as String?;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// Physical-class-only: the date and time the class takes place.
  DateTime? get scheduledAt {
    final raw = content['scheduledAt'] as String?;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// Physical-class-only: when the class ends. Classes created before an end
  /// was captured fall back to the end of their start day.
  DateTime? get endsAt {
    final raw = content['endsAt'] as String?;
    if (raw != null && raw.isNotEmpty) return DateTime.tryParse(raw);
    final start = scheduledAt;
    return start == null ? null : DateTime(start.year, start.month, start.day + 1);
  }

  /// Physical-class-only: attendance can be ticked from [scheduledAt] until
  /// [endsAt]; after that the class is over.
  bool get isPhysicalClassOver {
    final end = endsAt;
    return end != null && !DateTime.now().isBefore(end);
  }

  /// Exam-only: when attempts open. Before this, the exam-answering screen
  /// shows a "not yet open" state instead of the question form. Null means
  /// open immediately.
  DateTime? get availableFrom {
    final raw = content['availableFrom'] as String?;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  factory ContentBlock.fromMap(Map<String, dynamic> map) {
    return ContentBlock(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      type: ContentBlockType.fromKey(map['block_type'] as String),
      content: Map<String, dynamic>.from(map['block_content'] as Map? ?? {}),
      sorting: map['block_sorting'] as int? ?? 0,
    );
  }
}
