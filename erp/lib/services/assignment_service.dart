import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AssignmentService {
  // URL base da API - agora centralizada
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<Map<String, dynamic>>> getAssignmentsByClass(
    String classId,
  ) async {
    final response = await http.get(
      Uri.parse(ApiConfig.getAssignmentsUrl('?classId=$classId')),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar tarefas da turma');
    }
  }

  // Buscar tarefas por turma e disciplina
  static Future<List<Map<String, dynamic>>> getAssignmentsByClassAndSubject(
    String classId,
    String subjectId,
  ) async {
    final response = await http.get(
      Uri.parse(
        ApiConfig.getAssignmentsUrl('?classId=$classId&subjectId=$subjectId'),
      ),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar tarefas da turma e disciplina');
    }
  }

  static Future<Map<String, dynamic>> createAssignment({
    required String classId,
    required String subjectId,
    required String description,
    required DateTime dueDate,
    String? fileUrl,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.getAssignmentsUrl('')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'classId': classId,
        'subjectId': subjectId,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        'fileUrl': fileUrl,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao criar tarefa');
    }
  }

  static Future<void> deleteAssignment(String assignmentId) async {
    final response = await http.delete(
      Uri.parse(ApiConfig.getAssignmentsUrl('/$assignmentId')),
      headers: {'Content-Type': 'application/json'},
    );

    // 200 OK ou 204 No Content são sucesso para DELETE
    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao deletar tarefa');
    }
  }

  static Future<List<Map<String, dynamic>>> getAssignmentSubmissions(
    String assignmentId,
  ) async {
    final response = await http.get(
      Uri.parse(ApiConfig.getAssignmentsUrl('/$assignmentId/submissions')),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar submissões da tarefa');
    }
  }
}
