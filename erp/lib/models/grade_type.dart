class GradeType {
  final String id;
  final String name;
  final String? description;

  GradeType({required this.id, required this.name, this.description});

  factory GradeType.fromJson(Map<String, dynamic> json) {
    return GradeType(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}
