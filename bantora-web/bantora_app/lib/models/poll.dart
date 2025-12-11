class Poll {
  final String id;
  final String title;
  final String description;
  final String creatorPhone;
  final String? category;
  final String scope;
  final String? region;
  final String? countryCode;
  final String status;
  final DateTime createdAt;
  final DateTime? startTime;
  final DateTime? endTime;
  final List<PollOption> options;

  Poll({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorPhone,
    this.category,
    required this.scope,
    this.region,
    this.countryCode,
    required this.status,
    required this.createdAt,
    this.startTime,
    this.endTime,
    required this.options,
  });

  int get totalVotes => options.fold(0, (sum, item) => sum + item.votesCount);

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      creatorPhone: json['creatorPhone'],
      category: json['category'],
      scope: json['scope'],
      region: json['region'],
      countryCode: json['countryCode'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      options: (json['options'] as List)
          .map((option) => PollOption.fromJson(option))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'creatorPhone': creatorPhone,
      'scope': scope,
      'region': region,
      'countryCode': countryCode,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'options': options.map((option) => option.toJson()).toList(),
    };
  }
}

class PollOption {
  final String id;
  final String pollId;
  final String optionText;
  final int optionOrder;
  final int votesCount;

  PollOption({
    required this.id,
    required this.pollId,
    required this.optionText,
    required this.optionOrder,
    required this.votesCount,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'],
      pollId: json['pollId'],
      optionText: json['optionText'],
      optionOrder: json['optionOrder'],
      votesCount: json['votesCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pollId': pollId,
      'optionText': optionText,
      'optionOrder': optionOrder,
      'votesCount': votesCount,
    };
  }
}
