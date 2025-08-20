import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

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
  // URL base da API - agora centralizada
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<Map<String, dynamic>>> getAllStudents() async {
    final response = await http.get(Uri.parse(ApiConfig.getStudentsUrl('')));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar alunos');
    }
  }

  // Buscar aluno por ID
  static Future<Map<String, dynamic>> getStudentById(String id) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getStudentsUrl('/$id')),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception('Erro ao buscar aluno: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Buscar aluno por ID do usuário
  static Future<Map<String, dynamic>> getStudentByUserId(String userId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getStudentsUrl('/user/$userId')),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception('Erro ao buscar aluno: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Atualizar aluno
  static Future<Map<String, dynamic>> updateStudent(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse(ApiConfig.getStudentsUrl('/$id')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao atualizar aluno');
    }
  }

  // Atualizar foto do aluno
  static Future<Map<String, dynamic>> updateStudentPhoto(
    String id,
    String photoUrl,
  ) async {
    final response = await http.put(
      Uri.parse(ApiConfig.getStudentsUrl('/$id/photo')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'photoUrl': photoUrl}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao atualizar foto do aluno');
    }
  }

  // Deletar aluno
  static Future<void> deleteStudent(String id) async {
    final response = await http.delete(
      Uri.parse(ApiConfig.getStudentsUrl('/$id')),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao deletar aluno');
    }
  }
}
