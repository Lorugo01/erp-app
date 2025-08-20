import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class TeacherService {
  // URL base da API - agora centralizada
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<Map<String, dynamic>>> getAllTeachers() async {
    final response = await http.get(Uri.parse(ApiConfig.getTeachersUrl('')));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar professores');
    }
  }

  // Buscar professor por ID
  static Future<Map<String, dynamic>> getTeacherById(String id) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getTeachersUrl('/$id')),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception('Erro ao buscar professor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<Map<String, dynamic>> updateTeacher(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse(ApiConfig.getTeachersUrl('/$id')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao atualizar professor');
    }
  }

  // Atualizar foto do professor
  static Future<Map<String, dynamic>> updateTeacherPhoto(
    String id,
    String photoUrl,
  ) async {
    final response = await http.put(
      Uri.parse(ApiConfig.getTeachersUrl('/$id/photo')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'photoUrl': photoUrl}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao atualizar foto do professor');
    }
  }

  // Buscar turmas de um professor
  static Future<List<Map<String, dynamic>>> getTeacherClasses(
    String teacherId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getTeachersUrl('/$teacherId/classes')),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Erro ao buscar turmas do professor');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Buscar disciplinas de uma turma por professor
  static Future<List<Map<String, dynamic>>> getSubjectsByClassIdAndTeacher(
    String classId,
    String teacherId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          ApiConfig.getTeachersUrl('/$teacherId/classes/$classId/subjects'),
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Erro ao buscar disciplinas da turma');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Buscar alunos de uma turma
  static Future<List<Map<String, dynamic>>> getClassStudents(
    String classId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getClassesUrl('/$classId/students')),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Erro ao buscar alunos da turma');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
}
