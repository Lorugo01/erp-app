class Grade {
  final String id;
  final String studentId;
  final String subjectId;
  final String gradeTypeId;
  final double value;
  final String? period;
  final String? periodId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Grade({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.gradeTypeId,
    required this.value,
    this.period,
    this.periodId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'],
      studentId: json['studentId'],
      subjectId: json['subjectId'],
      gradeTypeId: json['typeId'],
      value: (json['value'] as num).toDouble(),
      period: json['periodId'],
      periodId: json['periodId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
