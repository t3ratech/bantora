class Idea {
  final String id;
  final String userPhone;
  final String content;
  final String status;
  final String? aiSummary;
  final DateTime createdAt;
  final int upvotes;

  Idea({
    required this.id,
    required this.userPhone,
    required this.content,
    required this.status,
    this.aiSummary,
    required this.createdAt,
    required this.upvotes,
  });

  factory Idea.fromJson(Map<String, dynamic> json) {
    return Idea(
      id: json['id'],
      userPhone: json['userPhone'] ?? 'Anonymous',
      content: json['content'],
      status: json['status'],
      aiSummary: json['aiSummary'],
      createdAt: DateTime.parse(json['createdAt']),
      upvotes: json['upvotes'] ?? 0,
    );
  }
}
