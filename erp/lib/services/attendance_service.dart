import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AttendanceService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Map<String, String> _getAuthHeaders([String? token]) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<List<Map<String, dynamic>>> getAttendancesByLesson(
    String lessonId, [
    String? token,
  ]) async {
    return getAttendanceByLesson(lessonId, token);
  }

  static Future<Map<String, dynamic>> updateAttendance(
    String attendanceId,
    Map<String, dynamic> data, [
    String? token,
  ]) async {
    final response = await http.put(
      Uri.parse(ApiConfig.getAttendanceUrl('/$attendanceId')),
      headers: _getAuthHeaders(token),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return Map<String, dynamic>.from(decoded);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao atualizar frequência');
    }
  }

  static Future<Map<String, dynamic>> createAttendance(
    Map<String, dynamic> data, [
    String? token,
  ]) async {
    final response = await http.post(
      Uri.parse(ApiConfig.getAttendanceUrl('')),
      headers: _getAuthHeaders(token),
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      return Map<String, dynamic>.from(decoded);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao criar frequência');
    }
  }

  static Future<void> deleteAttendance(
    String attendanceId, [
    String? token,
  ]) async {
    final response = await http.delete(
      Uri.parse(ApiConfig.getAttendanceUrl('/$attendanceId')),
      headers: _getAuthHeaders(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao deletar frequência');
    }
  }

  /// Busca ou cria a aula para a turma/disciplina/data informadas.
  static Future<Map<String, dynamic>> getOrCreateLesson({
    required String classId,
    required String subjectId,
    required String teacherId,
    required DateTime date,
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.getLessonsUrl('/get-or-create')),
      headers: _getAuthHeaders(token),
      body: jsonEncode({
        'classId': classId,
        'subjectId': subjectId,
        'teacherId': teacherId,
        'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      return Map<String, dynamic>.from(decoded);
    }

    throw Exception(
      'Erro ao buscar/criar aula (${response.statusCode}): ${response.body}',
    );
  }

  static Future<List<Map<String, dynamic>>> getAttendanceByLesson(
    String lessonId, [
    String? token,
  ]) async {
    final response = await http.get(
      Uri.parse(ApiConfig.getAttendanceUrl('/lesson/$lessonId')),
      headers: _getAuthHeaders(token),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    }
    throw Exception(
      'Erro ao buscar frequência da aula (${response.statusCode})',
    );
  }

  /// Salva a chamada em lote para uma aula.
  static Future<void> markAttendanceByLesson({
    required String lessonId,
    required List<Map<String, dynamic>> presences,
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.getAttendanceUrl('/bulk')),
      headers: _getAuthHeaders(token),
      body: jsonEncode({'lessonId': lessonId, 'presences': presences}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Erro ao marcar frequência');
      } catch (_) {
        throw Exception(
          'Erro ao marcar frequência (${response.statusCode}): ${response.body}',
        );
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getAttendancesByStudent(
    String studentId, [
    String? token,
  ]) async {
    final response = await http.get(
      Uri.parse(ApiConfig.getAttendanceUrl('/student/$studentId')),
      headers: _getAuthHeaders(token),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    }
    throw Exception('Erro ao buscar frequências do aluno');
  }
}
