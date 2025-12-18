class Idea {
  final String id;
  final String userPhone;
  final String content;
  final String categoryId;
  final List<String> hashtags;
  final String status;
  final String? aiSummary;
  final DateTime createdAt;
  final int upvotes;

  Idea({
    required this.id,
    required this.userPhone,
    required this.content,
    required this.categoryId,
    required this.hashtags,
    required this.status,
    this.aiSummary,
    required this.createdAt,
    required this.upvotes,
  });

  factory Idea.fromJson(Map<String, dynamic> json) {
    final categoryId = json['categoryId'];
    if (categoryId is! String || categoryId.isEmpty) {
      throw StateError('Idea is missing required field: categoryId');
    }

    final rawHashtags = json['hashtags'];
    if (rawHashtags is! List) {
      throw StateError('Idea is missing required field: hashtags');
    }

    return Idea(
      id: json['id'],
      userPhone: json['userPhone'] ?? 'Anonymous',
      content: json['content'],
      categoryId: categoryId,
      hashtags: rawHashtags.whereType<String>().toList(),
      status: json['status'],
      aiSummary: json['aiSummary'],
      createdAt: DateTime.parse(json['createdAt']),
      upvotes: json['upvotes'] ?? 0,
    );
  }
}
