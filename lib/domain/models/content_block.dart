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
/// - video / image: `{"url": "...", "caption": "..."}`
/// - link: `{"url": "...", "label": "..."}`
/// - file: `{"url": "...", "name": "...", "sizeLabel": "..."}`
/// - exam / assignment: `{"title": "..."}` — a placeholder pointing at the
///   (not yet built) exam/assignment editor, keyed by [id] once created.
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
  String? get label => content['label'] as String?;
  String? get fileName => content['name'] as String?;
  String? get sizeLabel => content['sizeLabel'] as String?;
  String? get title => content['title'] as String?;

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
