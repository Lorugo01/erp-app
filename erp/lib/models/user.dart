enum Role { admin, student, teacher }

class Student {
  final String id;
  final String name;
  final String? registrationNumber;
  final String? profilePicture;

  Student({
    required this.id,
    required this.name,
    this.registrationNumber,
    this.profilePicture,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      registrationNumber: json['registrationNumber'],
      profilePicture: json['profilePicture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'registrationNumber': registrationNumber,
      'profilePicture': profilePicture,
    };
  }
}

class Teacher {
  final String id;
  final String name;

  Teacher({required this.id, required this.name});

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] ?? '', 
      name: json['name'] ?? ''
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class User {
  final String id;
  final String email;
  final Role role;
  final String? photoUrl;
  final Student? student;
  final Teacher? teacher;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.role,
    this.photoUrl,
    this.student,
    this.teacher,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      role: Role.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() ==
            (json['role']?.toString().toLowerCase() ?? ''),
        orElse: () => Role.student, // ou outro valor padrão
      ),
      photoUrl: json['photoUrl'],
      student:
          json['student'] != null ? Student.fromJson(json['student']) : null,
      teacher:
          json['teacher'] != null ? Teacher.fromJson(json['teacher']) : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role.toString().split('.').last,
      'photoUrl': photoUrl,
      'student': student?.toJson(),
      'teacher': teacher?.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get displayName {
    if (student != null) return student!.name;
    if (teacher != null) return teacher!.name;
    return email;
  }

  bool get isAdmin => role == Role.admin;
  bool get isStudent => role == Role.student;
  bool get isTeacher => role == Role.teacher;
}
