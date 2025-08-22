import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class GradeService {
  // URL base da API - agora centralizada
  static String get baseUrl => ApiConfig.baseUrl;

  // Helper para criar headers com autenticação
  static Map<String, String> _getAuthHeaders([String? token]) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

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
    String subjectId, [
    String? token,
  ]) async {
    final response = await http.get(
      Uri.parse(ApiConfig.getGradesUrl('/subject/$subjectId')),
      headers: _getAuthHeaders(token),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar notas da disciplina');
    }
  }

  static Future<Map<String, dynamic>> createGrade(
    Map<String, dynamic> data, [
    String? token,
  ]) async {
    final response = await http.post(
      Uri.parse(ApiConfig.getGradesUrl('')),
      headers: _getAuthHeaders(token),
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
    Map<String, dynamic> data, [
    String? token,
  ]) async {
    final response = await http.put(
      Uri.parse(ApiConfig.getGradesUrl('/$gradeId')),
      headers: _getAuthHeaders(token),
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

  static Future<void> deleteGrade(String gradeId, [String? token]) async {
    final response = await http.delete(
      Uri.parse(ApiConfig.getGradesUrl('/$gradeId')),
      headers: _getAuthHeaders(token),
    );

    // 200 OK ou 204 No Content são sucesso para DELETE
    if (response.statusCode != 200 && response.statusCode != 204) {
      // Tentar decodificar erro se houver conteúdo
      if (response.body.isNotEmpty) {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Erro ao deletar nota');
        } catch (e) {
          // Se não conseguir decodificar, usar mensagem genérica
          throw Exception('Erro ao deletar nota: ${response.statusCode}');
        }
      } else {
        throw Exception('Erro ao deletar nota: ${response.statusCode}');
      }
    }

    // Sucesso: 200 OK - não precisa decodificar resposta vazia
  }
}
