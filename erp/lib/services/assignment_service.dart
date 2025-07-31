import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AssignmentService {
  static const String baseUrl = 'http://192.168.18.15:3000';

  static Future<List<Map<String, dynamic>>> getAssignmentsByClass(
    String classId,
  ) async {
    debugPrint('Buscando atividades da turma: $classId');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/classes/$classId/assignments'),
      );
      debugPrint('Status da resposta: ${response.statusCode}');
      debugPrint('Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        debugPrint('Erro ao buscar atividades: ${response.body}');
        throw Exception('Erro ao buscar atividades');
      }
    } catch (e) {
      debugPrint('Erro ao buscar atividades: $e');
      throw Exception('Erro ao buscar atividades');
    }
  }

  static Future<List<Map<String, dynamic>>> getAssignmentsByClassAndSubject(
    String classId,
    String subjectId,
  ) async {
    debugPrint('Buscando atividades da turma $classId e disciplina $subjectId');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/classes/$classId/assignments?subjectId=$subjectId'),
      );
      debugPrint('Status da resposta: ${response.statusCode}');
      debugPrint('Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        debugPrint('Erro ao buscar atividades: ${response.body}');
        throw Exception('Erro ao buscar atividades');
      }
    } catch (e) {
      debugPrint('Erro ao buscar atividades: $e');
      throw Exception('Erro ao buscar atividades');
    }
  }

  static Future<void> createAssignment({
    required String classId,
    required String subjectId,
    required String description,
    required DateTime dueDate,
    String? fileUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/classes/$classId/assignments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'subjectId': subjectId,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        if (fileUrl != null) 'fileUrl': fileUrl,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Erro ao criar atividade');
    }
  }

  static Future<void> deleteAssignment(String assignmentId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/assignments/$assignmentId'),
    );
    if (response.statusCode != 204) {
      throw Exception('Erro ao excluir atividade');
    }
  }

  static Future<List<Map<String, dynamic>>> getSubmissionsByAssignment(
    String assignmentId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/assignments/$assignmentId/submissions'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar submissões da atividade');
    }
  }
}
