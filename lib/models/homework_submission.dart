class HomeworkSubmission {
  final String id;
  final String homeworkId;
  final String studentId;
  final String status; // 'pending', 'submitted'
  final DateTime? submittedAt;
  final String? attachmentUrl;

  HomeworkSubmission({
    required this.id,
    required this.homeworkId,
    required this.studentId,
    required this.status,
    this.submittedAt,
    this.attachmentUrl,
  });

  factory HomeworkSubmission.fromJson(Map<String, dynamic> json) {
    return HomeworkSubmission(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      homeworkId: (json['homeworkId'] ?? '').toString(),
      studentId: (json['studentId'] ?? '').toString(),
      status: json['status'] ?? 'pending',
      submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt']) : null,
      attachmentUrl: json['attachmentUrl'] as String?,
    );
  }
}
