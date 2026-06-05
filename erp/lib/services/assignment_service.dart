import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AssignmentService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Map<String, String> _getAuthHeaders([String? token]) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<List<Map<String, dynamic>>> getAssignmentsByClass(
    String classId, [
    String? token,
  ]) async {
    final response = await http.get(
      Uri.parse(ApiConfig.getAssignmentsUrl('/class/$classId')),
      headers: _getAuthHeaders(token),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    }
    throw Exception('Erro ao buscar tarefas da turma');
  }

  static Future<List<Map<String, dynamic>>> getAssignmentsByClassAndSubject(
    String classId,
    String subjectId, [
    String? token,
  ]) async {
    final uri = Uri.parse(
      ApiConfig.getAssignmentsUrl('/class/$classId'),
    ).replace(queryParameters: {'subjectId': subjectId});

    final response = await http.get(uri, headers: _getAuthHeaders(token));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    }
    throw Exception('Erro ao buscar tarefas da turma e disciplina');
  }

  static Future<String> uploadAssignmentFile({
    required Uint8List bytes,
    required String filename,
    String? token,
  }) async {
    final uri = Uri.parse(
      ApiConfig.getStorageUrl('/upload'),
    ).replace(queryParameters: {'category': 'assignments'});

    final request = http.MultipartRequest('POST', uri);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    final body = resp.body.trim();

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      if (body.startsWith('<')) {
        throw Exception(
          'Servidor retornou HTML. Faça deploy da API com o módulo /storage.',
        );
      }
      final data = jsonDecode(body);
      final fileUrl = data['fileUrl'] ?? data['url'] ?? data['publicUrl'];
      if (fileUrl == null || fileUrl.toString().isEmpty) {
        throw Exception('Resposta de upload sem URL do arquivo');
      }
      return fileUrl.toString();
    }

    if (body.startsWith('{')) {
      final error = jsonDecode(body);
      throw Exception(error['error'] ?? 'Erro ao enviar arquivo');
    }
    throw Exception('Erro ao enviar arquivo (${resp.statusCode})');
  }

  static Future<Map<String, dynamic>> createAssignment({
    required String classId,
    required String subjectId,
    required String description,
    required DateTime dueDate,
    String? fileUrl,
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.getAssignmentsUrl('/class/$classId')),
      headers: _getAuthHeaders(token),
      body: jsonEncode({
        'subjectId': subjectId,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        'fileUrl': fileUrl,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    }

    final body = response.body.trim();
    if (body.startsWith('{')) {
      final error = jsonDecode(body);
      throw Exception(error['error'] ?? 'Erro ao criar tarefa');
    }
    throw Exception('Erro ao criar tarefa (${response.statusCode})');
  }

  static Future<void> deleteAssignment(
    String assignmentId, [
    String? token,
  ]) async {
    final response = await http.delete(
      Uri.parse(ApiConfig.getAssignmentsUrl('/$assignmentId')),
      headers: _getAuthHeaders(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final body = response.body.trim();
      if (body.startsWith('{')) {
        final error = jsonDecode(body);
        throw Exception(error['error'] ?? 'Erro ao deletar tarefa');
      }
      throw Exception('Erro ao deletar tarefa (${response.statusCode})');
    }
  }

  static Future<List<Map<String, dynamic>>> getAssignmentSubmissions(
    String assignmentId, [
    String? token,
  ]) async {
    final response = await http.get(
      Uri.parse(ApiConfig.getAssignmentsUrl('/$assignmentId/submissions')),
      headers: _getAuthHeaders(token),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    }
    throw Exception('Erro ao buscar submissões da tarefa');
  }
}
