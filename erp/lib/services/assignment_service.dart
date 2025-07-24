import 'dart:convert';
import 'package:http/http.dart' as http;

class AssignmentService {
  static const String baseUrl = 'http://localhost:3000';

  static Future<List<Map<String, dynamic>>> getAssignmentsByClass(
    String classId,
  ) async {
    print('Fazendo requisição para: $baseUrl/classes/$classId/assignments');
    final response = await http.get(
      Uri.parse('$baseUrl/classes/$classId/assignments'),
    );
    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      print('Erro na requisição: ${response.statusCode} - ${response.body}');
      throw Exception('Erro ao buscar atividades');
    }
  }

  static Future<void> createAssignment({
    required String classId,
    required String description,
    required DateTime dueDate,
    String? fileUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/classes/$classId/assignments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        if (fileUrl != null) 'fileUrl': fileUrl,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Erro ao criar atividade');
    }
  }
}
