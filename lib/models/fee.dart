class Fee {
  final String id;
  final String studentId;
  final String month;
  final double amount;
  final String? dueDate;
  final String? paidDate;
  final String status; // "paid" or "unpaid"

  Fee({
    required this.id,
    required this.studentId,
    required this.month,
    required this.amount,
    this.dueDate,
    this.paidDate,
    required this.status,
  });

  factory Fee.fromJson(Map<String, dynamic> json) {
    return Fee(
      id: json['id'] ?? json['_id'] ?? '',
      studentId: json['studentId'] ?? '',
      month: json['month'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      dueDate: json['dueDate'],
      paidDate: json['paidDate'],
      status: (json['status'] ?? 'unpaid').toString().toLowerCase(),
    );
  }
}
