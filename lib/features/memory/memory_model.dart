class MemoryEntry {
  final String id;
  final String title;
  final String content;
  final String? sourceApp;
  final String? ocrText;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  MemoryEntry({
    required this.id,
    required this.title,
    required this.content,
    this.sourceApp,
    this.ocrText,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'sourceApp': sourceApp,
    'ocrText': ocrText,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory MemoryEntry.fromJson(Map<String, dynamic> json) => MemoryEntry(
    id: json['id'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    sourceApp: json['sourceApp'] as String?,
    ocrText: json['ocrText'] as String?,
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

class MemorySearchResult {
  final MemoryEntry memoryEntry;
  final double score;

  MemorySearchResult({required this.memoryEntry, required this.score});
}
