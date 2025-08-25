import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AttendanceService {
  // URL base da API - agora centralizada
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<Map<String, dynamic>>> getAttendancesByLesson(
    String lessonId,
  ) async {
    final response = await http.get(
      Uri.parse(ApiConfig.getAttendanceUrl('/lesson/$lessonId')),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar frequências da aula');
    }
  }

  static Future<Map<String, dynamic>> updateAttendance(
    String attendanceId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse(ApiConfig.getAttendanceUrl('/$attendanceId')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao atualizar frequência');
    }
  }

  static Future<Map<String, dynamic>> createAttendance(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConfig.getAttendanceUrl('')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao criar frequência');
    }
  }

  static Future<void> deleteAttendance(String attendanceId) async {
    final response = await http.delete(
      Uri.parse(ApiConfig.getAttendanceUrl('/$attendanceId')),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao deletar frequência');
    }
  }

  // Buscar ou criar uma aula
  static Future<Map<String, dynamic>> getOrCreateLesson({
    required String classId,
    required String subjectId,
    required String teacherId,
    required DateTime date,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getLessonsUrl('/get-or-create')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'classId': classId,
          'subjectId': subjectId,
          'teacherId': teacherId,
          'date': date.toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception('Erro ao buscar/criar aula');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Buscar frequência por aula
  static Future<List<Map<String, dynamic>>> getAttendanceByLesson(
    String lessonId,
  ) async {
    final response = await http.get(
      Uri.parse(ApiConfig.getAttendanceUrl('/lesson/$lessonId')),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar frequência da aula');
    }
  }

  // Marcar frequência por aula
  static Future<void> markAttendanceByLesson({
    required String lessonId,
    required List<Map<String, dynamic>> presences,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.getAttendanceUrl('/bulk')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'lessonId': lessonId, 'presences': presences}),
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao marcar frequência');
    }
  }

  static Future<List<Map<String, dynamic>>> getAttendancesByStudent(
    String studentId,
  ) async {
    final response = await http.get(
      Uri.parse(ApiConfig.getAttendanceUrl('/student/$studentId')),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar frequências do aluno');
    }
  }
}
