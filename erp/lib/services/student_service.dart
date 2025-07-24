import 'dart:convert';
import 'package:http/http.dart' as http;

class Student {
  final String id;
  final String name;
  final String? registrationNumber;
  final List<String>? subjects;
  final String email;
  final DateTime? createdAt;
  final String? role;
  final String? profilePicture;

  Student({
    required this.id,
    required this.name,
    required this.email,
    this.registrationNumber,
    this.subjects,
    this.createdAt,
    this.role,
    this.profilePicture,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      registrationNumber: json['registrationNumber'],
      subjects: (json['subjects'] as List?)?.map((e) => e.toString()).toList(),
      email: json['email'] ?? (json['user']?['email'] ?? ''),
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'])
              : null,
      role: json['user']?['role'],
      profilePicture: json['profilePicture'],
    );
  }
}

class StudentService {
  static const String baseUrl = 'http://localhost:3000';

  static Future<List<Student>> getAllStudents() async {
    final response = await http.get(Uri.parse('$baseUrl/students'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Student.fromJson(e)).toList();
    } else {
      throw Exception('Erro ao buscar alunos');
    }
  }

  static Future<List<Student>> searchStudentsByName(String name) async {
    final response = await http.get(
      Uri.parse('$baseUrl/students/search/$name'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Student.fromJson(e)).toList();
    } else {
      throw Exception('Erro ao buscar alunos por nome');
    }
  }
}
