class Test {
  final String id;
  final String title;
  final String className;
  final String date;
  final String? time;
  final double maxMarks;
  final String status;
  final String? syllabus;
  final String? wing; // 'school' or 'coaching'
  final TestResult? result;
  final String? subjectName;
  final String? teacherName;
  final String? creatorName;
  final String? assignedTeacherName;
  final String? description;
  final String? duration;

  Test({
    required this.id,
    required this.title,
    required this.className,
    required this.date,
    this.time,
    required this.maxMarks,
    required this.status,
    this.syllabus,
    this.wing,
    this.result,
    this.subjectName,
    this.teacherName,
    this.creatorName,
    this.assignedTeacherName,
    this.description,
    this.duration,
  });

  factory Test.fromJson(Map<String, dynamic> json) {
    return Test(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      className: json['class'] ?? json['className'] ?? '',
      date: json['date'] ?? '',
      time: json['time'],
      maxMarks: (json['maxMarks'] ?? 0).toDouble(),
      status: json['status'] ?? 'upcoming',
      syllabus: json['syllabus'],
      wing: json['wing'] ?? 'school',
      result: json['result'] != null ? TestResult.fromJson(Map<String, dynamic>.from(json['result'] as Map)) : null,
      subjectName: json['subjectName'] ?? 'General',
      teacherName: json['teacherName'] ?? 'LM Administration',
      creatorName: json['creatorName'],
      assignedTeacherName: json['assignedTeacherName'],
      description: json['description'],
      duration: json['duration']?.toString(),
    );
  }
}

class TestResult {
  final String testId;
  final String studentId;
  final double score;
  final int? rank;

  TestResult({
    required this.testId,
    required this.studentId,
    required this.score,
    this.rank,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      testId: json['testId'] ?? '',
      studentId: json['studentId'] ?? '',
      score: (json['score'] ?? 0).toDouble(),
      rank: json['rank'],
    );
  }
}
