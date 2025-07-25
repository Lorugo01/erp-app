import 'dart:convert';
import 'package:http/http.dart' as http;

class GradeService {
  static const String baseUrl = 'http://localhost:3000';

  // Buscar todas as notas
  static Future<List<Map<String, dynamic>>> getAllGrades() async {
    final response = await http.get(
      Uri.parse('$baseUrl/grades'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar notas');
    }
  }

  // Buscar notas por aluno
  static Future<List<Map<String, dynamic>>> getGradesByStudent(
    String studentId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/grades/student/$studentId'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar notas do aluno');
    }
  }

  // Buscar notas por disciplina
  static Future<List<Map<String, dynamic>>> getGradesBySubject(
    String subjectId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/grades/subject/$subjectId'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar notas da disciplina');
    }
  }

  // Criar nova nota
  static Future<Map<String, dynamic>> createGrade({
    required String studentId,
    required String subjectId,
    required String typeId,
    required String periodId,
    double? value,
    String? concept,
    DateTime? date,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/grades'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'studentId': studentId,
        'subjectId': subjectId,
        'typeId': typeId,
        'periodId': periodId,
        if (value != null) 'value': value,
        if (concept != null) 'concept': concept,
        if (date != null) 'date': date.toIso8601String(),
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao criar nota: ${response.body}');
    }
  }

  // Atualizar nota
  static Future<Map<String, dynamic>> updateGrade({
    required String gradeId,
    String? studentId,
    String? subjectId,
    String? typeId,
    String? periodId,
    double? value,
    String? concept,
    DateTime? date,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/grades/$gradeId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (studentId != null) 'studentId': studentId,
        if (subjectId != null) 'subjectId': subjectId,
        if (typeId != null) 'typeId': typeId,
        if (periodId != null) 'periodId': periodId,
        if (value != null) 'value': value,
        if (concept != null) 'concept': concept,
        if (date != null) 'date': date.toIso8601String(),
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao atualizar nota: ${response.body}');
    }
  }

  // Deletar nota
  static Future<void> deleteGrade(String gradeId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/grades/$gradeId'),
    );
    if (response.statusCode != 204) {
      throw Exception('Erro ao deletar nota');
    }
  }

  // Buscar boletim completo de um aluno
  static Future<Map<String, dynamic>> getBoletimCompleto(
    String studentId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/grades/boletim/$studentId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao buscar boletim');
    }
  }
}
