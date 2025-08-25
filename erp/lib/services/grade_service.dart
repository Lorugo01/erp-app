import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class GradeService {
  // URL base da API - agora centralizada
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<Map<String, dynamic>>> getGradesByStudent(
    String studentId,
  ) async {
    final response = await http.get(
      Uri.parse(ApiConfig.getGradesUrl('/student/$studentId')),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar notas do aluno');
    }
  }

  static Future<List<Map<String, dynamic>>> getGradesBySubject(
    String subjectId,
  ) async {
    final response = await http.get(
      Uri.parse(ApiConfig.getGradesUrl('/subject/$subjectId')),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar notas da disciplina');
    }
  }

  static Future<Map<String, dynamic>> createGrade(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConfig.getGradesUrl('')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao criar nota');
    }
  }

  static Future<Map<String, dynamic>> updateGrade(
    String gradeId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse(ApiConfig.getGradesUrl('/$gradeId')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao atualizar nota');
    }
  }

  static Future<void> deleteGrade(String gradeId) async {
    final response = await http.delete(
      Uri.parse(ApiConfig.getGradesUrl('/$gradeId')),
      headers: {'Content-Type': 'application/json'},
    );

    // Status 204 significa "No Content" - sucesso sem retorno
    if (response.statusCode == 204) {
      return; // Sucesso - nota excluída
    }

    // Para outros status codes, tentar fazer parse do erro
    if (response.statusCode != 200) {
      String errorMessage = 'Erro ao deletar nota';

      try {
        if (response.body.isNotEmpty) {
          final error = jsonDecode(response.body);
          errorMessage = error['error'] ?? errorMessage;
        }
      } catch (e) {
        // Se não conseguir fazer parse do JSON, usar a mensagem padrão
        errorMessage = 'Erro ao deletar nota (Status: ${response.statusCode})';
      }

      throw Exception(errorMessage);
    }
  }
}
