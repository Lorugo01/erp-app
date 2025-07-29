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

  // Buscar professor por ID
  static Future<Map<String, dynamic>> getTeacherById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teachers/$id'),
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
      Uri.parse('$baseUrl/teachers/$id'),
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
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/teachers/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'photoUrl': photoUrl}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['error'] ?? 'Erro ao atualizar foto do professor',
        );
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Buscar dados atualizados do professor
  static Future<Map<String, dynamic>> refreshTeacherData(String id) async {
    return await getTeacherById(id);
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

  static Future<List<Map<String, dynamic>>> getSubjectsByClassId(
    String classId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/subjects/class/$classId'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar disciplinas da turma');
    }
  }
}
