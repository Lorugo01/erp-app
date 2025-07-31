import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendanceService {
  static const String baseUrl = 'http://192.168.18.15:3000';

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

  // Novo método para buscar ou criar uma aula
  static Future<Map<String, dynamic>> getOrCreateLesson({
    required String classId,
    required String subjectId,
    required String teacherId,
    required DateTime date,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/lessons/get-or-create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'classId': classId,
        'subjectId': subjectId,
        'teacherId': teacherId,
        'date': date.toIso8601String(),
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao buscar/criar aula: ${response.body}');
    }
  }

  // Novo método para registrar frequência por aula
  static Future<void> markAttendanceByLesson({
    required String lessonId,
    required List<Map<String, dynamic>> presences,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendances/bulk'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'lessonId': lessonId, 'presences': presences}),
    );
    if (response.statusCode != 201) {
      throw Exception('Erro ao registrar frequência: ${response.body}');
    }
  }

  // Novo método para buscar frequência de uma aula específica
  static Future<List<Map<String, dynamic>>> getAttendanceByLesson(
    String lessonId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/attendances/lesson/$lessonId'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar frequência da aula');
    }
  }

  // Novo método para buscar frequência de um aluno
  static Future<List<Map<String, dynamic>>> getAttendanceByStudent(
    String studentId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/attendances/student/$studentId'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar frequência do aluno');
    }
  }

  // Método para calcular total de faltas de um aluno
  static Future<int> getStudentAbsences(String studentId) async {
    try {
      final attendances = await getAttendanceByStudent(studentId);
      // Conta apenas as faltas (present: false)
      return attendances
          .where((attendance) => attendance['present'] == false)
          .length;
    } catch (e) {
      throw Exception('Erro ao calcular faltas do aluno: $e');
    }
  }

  // Método para buscar estatísticas de frequência do aluno
  static Future<Map<String, dynamic>> getStudentAttendanceStats(
    String studentId,
  ) async {
    try {
      final attendances = await getAttendanceByStudent(studentId);

      final total = attendances.length;
      final present = attendances.where((a) => a['present'] == true).length;
      final absent = attendances.where((a) => a['present'] == false).length;
      final percentage = total > 0 ? (present / total * 100).round() : 0;

      return {
        'total': total,
        'present': present,
        'absent': absent,
        'percentage': percentage,
      };
    } catch (e) {
      throw Exception('Erro ao buscar estatísticas de frequência: $e');
    }
  }
}
