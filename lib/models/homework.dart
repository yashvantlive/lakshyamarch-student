class Homework {
  final String id;
  final String classId;
  final String slotId;
  final String title;
  final String subject;
  final String content;
  final String teacherName;
  final String date;
  final String teacherUserId;
  final String subjectId;
  final String status; // From submission status

  Homework({
    required this.id,
    required this.classId,
    required this.slotId,
    required this.title,
    required this.subject,
    required this.subjectId,
    required this.content,
    required this.teacherUserId,
    required this.teacherName,
    required this.date,
    this.status = 'pending',
  });

  factory Homework.fromJson(Map<String, dynamic> json) {
    return Homework(
      id: json['id'] ?? json['_id'] ?? '',
      classId: json['classId']?.toString() ?? '',
      slotId: json['slotId'] ?? '',
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      subjectId: json['subjectId']?.toString() ?? '',
      content: json['content'] ?? '',
      teacherUserId: json['teacherUserId']?.toString() ?? '',
      teacherName: json['teacherName'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }
}
