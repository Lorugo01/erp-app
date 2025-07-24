import 'dart:convert';
import 'package:http/http.dart' as http;

class TeacherService {
  static const String baseUrl = 'http://localhost:3000';

  static Future<List<Map<String, dynamic>>> getAllTeachers() async {
    final response = await http.get(Uri.parse('$baseUrl/teachers'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar professores');
    }
  }

  static Future<List<Map<String, dynamic>>> getTeacherClasses(
    String teacherId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/teachers/$teacherId/classes'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar turmas do professor');
    }
  }

  static Future<List<Map<String, dynamic>>> getClassStudents(
    String classId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/classes/$classId/students'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar alunos da turma');
    }
  }
}
