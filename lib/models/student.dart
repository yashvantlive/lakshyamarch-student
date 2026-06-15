class Student {
  final String id;
  final String userId;
  final String admissionNo;
  final String name;
  final String? rollNo;
  final String gender;
  final String? dob;
  final String? admissionDate;
  final String className; // renamed from 'class' as it is a reserved word
  final String? classId;
  final String? section;
  final String? fatherName;
  final String? fatherPhone;
  final String? wing; // 'school' or 'coaching'
  final String? coachingClass;
  final String? coachingClassId;
  final String status;
  final double? totalFee;
  final String? feeRemarks;

  Student({
    required this.id,
    required this.userId,
    required this.admissionNo,
    required this.name,
    this.rollNo,
    required this.gender,
    this.dob,
    this.admissionDate,
    required this.className,
    this.classId,
    this.section,
    this.fatherName,
    this.fatherPhone,
    this.wing,
    this.coachingClass,
    this.coachingClassId,
    required this.status,
    this.totalFee,
    this.feeRemarks,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      admissionNo: json['admissionNo'] ?? '',
      name: json['name'] ?? '',
      rollNo: json['rollNo'],
      gender: json['gender'] ?? '',
      dob: json['dob'],
      admissionDate: json['admissionDate'],
      className: json['class'] ?? '',
      classId: json['classId'] is Map ? json['classId']['_id'] : json['classId'],
      section: json['section'],
      fatherName: json['fatherName'],
      fatherPhone: json['fatherPhone'],
      wing: (json['wing'] as String?)?.toLowerCase() ?? 'coaching',
      coachingClass: json['coachingClass'],
      coachingClassId: json['coachingClassId'] is Map ? json['coachingClassId']['_id'] : json['coachingClassId'],
      status: json['status'] ?? 'active',
      totalFee: (json['totalFee'] ?? 0).toDouble(),
      feeRemarks: json['feeRemarks'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'admissionNo': admissionNo,
    'name': name,
    'rollNo': rollNo,
    'gender': gender,
    'dob': dob,
    'admissionDate': admissionDate,
    'class': className,
    'classId': classId,
    'section': section,
    'fatherName': fatherName,
    'fatherPhone': fatherPhone,
    'wing': wing,
    'coachingClass': coachingClass,
    'coachingClassId': coachingClassId,
    'status': status,
    'totalFee': totalFee,
    'feeRemarks': feeRemarks,
  };
}
