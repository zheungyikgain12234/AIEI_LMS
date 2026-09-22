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
  assignment;

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

  /// Percentage (0–100) this exam/assignment counts toward the class's
  /// final grade. Only meaningful for [ContentBlockType.exam]/
  /// [ContentBlockType.assignment] blocks — null if unset.
  double? get weightage => (content['weightage'] as num?)?.toDouble();

  DateTime? get dueDate {
    final raw = content['dueDate'] as String?;
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
