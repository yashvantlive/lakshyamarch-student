class Schedule {
  final String id;
  final DateTime date;
  final String className;
  final List<ScheduleSlot> slots;
  final bool isPublished;
  final DateTime? lastUpdated;

  Schedule({
    required this.id,
    required this.date,
    required this.className,
    required this.slots,
    required this.isPublished,
    this.lastUpdated,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] ?? json['_id'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      className: json['className'] ?? '',
      isPublished: json['isPublished'] ?? false,
      lastUpdated: json['_lastUpdated'] != null ? DateTime.parse(json['_lastUpdated']).toLocal() : null,
      slots: (json['slots'] as List? ?? [])
          .map((s) => ScheduleSlot.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList(),
    );
  }
}

class ScheduleSlot {
  final String id;
  final String startTime;
  final String endTime;
  final String subject;
  final String teacherName;
  final String? note;
  final String? wing; // 'school' or 'coaching'

  ScheduleSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.teacherName,
    this.note,
    this.wing,
  });

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) {
    return ScheduleSlot(
      id: (json['id'] ?? json['_id'] ?? '${json['startTime']}_${json['subject']}'.replaceFirst(RegExp(r'\s+'), '')).toString(),
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      subject: json['subject'] ?? '',
      teacherName: json['teacherName'] ?? '',
      note: json['note'],
      wing: json['wing'] ?? 'school',
    );
  }
}
