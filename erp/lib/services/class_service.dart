import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ClassService {
  // URL base da API - agora centralizada
  static String get baseUrl => ApiConfig.baseUrl;

  // Obter headers com autenticação
  static Map<String, String> _getAuthHeaders(String? token) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<List<Map<String, dynamic>>> getAllClasses({
    String? token,
  }) async {
    final response = await http.get(
      Uri.parse(ApiConfig.getClassesUrl('')),
      headers: _getAuthHeaders(token),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar turmas');
    }
  }

  static Future<Map<String, dynamic>> getClassById(
    String id, {
    String? token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getClassesUrl('/$id')),
        headers: _getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception('Erro ao buscar turma: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<void> deleteClass(String id, {String? token}) async {
    final response = await http.delete(
      Uri.parse(ApiConfig.getClassesUrl('/$id')),
      headers: _getAuthHeaders(token),
    );

    // 200 OK ou 204 No Content são sucesso para DELETE
    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao deletar turma');
    }
  }
}
