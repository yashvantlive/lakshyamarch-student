class Doubt {
  final String id;
  final String studentId;
  final String studentName;
  final String subject;
  final String title;
  final String question;
  final String? attachmentUrl;
  final DateTime createdAt;
  final List<DoubtReply> replies;

  Doubt({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.subject,
    required this.title,
    required this.question,
    this.attachmentUrl,
    required this.createdAt,
    required this.replies,
  });

  factory Doubt.fromJson(Map<String, dynamic> json) {
    var repliesList = json['replies'] as List? ?? [];
    return Doubt(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      studentId: (json['studentId'] ?? '').toString(),
      studentName: json['studentName'] ?? 'Student',
      subject: json['subject'] ?? 'General',
      title: json['title'] ?? '',
      question: json['question'] ?? '',
      attachmentUrl: json['attachmentUrl'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      replies: repliesList.map((r) => DoubtReply.fromJson(Map<String, dynamic>.from(r as Map))).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'subject': subject,
    'title': title,
    'question': question,
    'attachmentUrl': attachmentUrl,
    'createdAt': createdAt.toIso8601String(),
    'replies': replies.map((r) => r.toJson()).toList(),
  };
}

class DoubtReply {
  final String id;
  final String authorId;
  final String authorName;
  final String authorRole; // 'student' or 'teacher'
  final String reply;
  final DateTime createdAt;

  DoubtReply({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.reply,
    required this.createdAt,
  });

  factory DoubtReply.fromJson(Map<String, dynamic> json) {
    return DoubtReply(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      authorId: (json['authorId'] ?? '').toString(),
      authorName: json['authorName'] ?? 'User',
      authorRole: json['authorRole'] ?? 'student',
      reply: json['reply'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorId': authorId,
    'authorName': authorName,
    'authorRole': authorRole,
    'reply': reply,
    'createdAt': createdAt.toIso8601String(),
  };
}
