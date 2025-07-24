import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendanceService {
  static const String baseUrl = 'http://localhost:3000';

  static Future<void> markAttendance({
    required String studentId,
    required String classId,
    required bool present,
    required DateTime date,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendances'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'studentId': studentId,
        'classId': classId,
        'present': present,
        'date': date.toIso8601String(),
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Erro ao registrar presença');
    }
  }

  static Future<void> markAllAttendance({
    required String classId,
    required List<String> studentIds,
    required bool present,
    required DateTime date,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendances/bulk'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'classId': classId,
        'studentIds': studentIds,
        'present': present,
        'date': date.toIso8601String(),
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Erro ao registrar presença em massa');
    }
  }

  static Future<List<Map<String, dynamic>>> getAttendanceByClass(
    String classId,
    DateTime date,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/attendances/class/$classId?date=${date.toIso8601String()}',
      ),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar frequência');
    }
  }
}
