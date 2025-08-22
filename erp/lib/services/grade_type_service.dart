import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class GradeTypeService {
  // URL base da API - agora centralizada
  static String get baseUrl => ApiConfig.baseUrl;

  // Helper para criar headers com autenticação
  static Map<String, String> _getAuthHeaders(String? token) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<List<Map<String, dynamic>>> getAllGradeTypes({
    String? token,
  }) async {
    final response = await http.get(
      Uri.parse(ApiConfig.getGradeTypesUrl('')),
      headers: _getAuthHeaders(token),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar tipos de notas');
    }
  }

  static Future<Map<String, dynamic>> getGradeTypeById(
    String id, {
    String? token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getGradeTypesUrl('/$id')),
        headers: _getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception('Erro ao buscar tipo de nota: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Criar novo tipo de nota
  static Future<Map<String, dynamic>> createGradeType({
    required String name,
    String? description,
    bool isConcept = false,
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/grade-types'),
      headers: _getAuthHeaders(token),
      body: jsonEncode({
        'name': name,
        if (description != null) 'description': description,
        'isConcept': isConcept,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao criar tipo de nota: ${response.body}');
    }
  }

  // Atualizar tipo de nota
  static Future<Map<String, dynamic>> updateGradeType({
    required String id,
    String? name,
    String? description,
    bool? isConcept,
    String? token,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/grade-types/$id'),
      headers: _getAuthHeaders(token),
      body: jsonEncode({
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (isConcept != null) 'isConcept': isConcept,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao atualizar tipo de nota: ${response.body}');
    }
  }

  // Deletar tipo de nota
  static Future<void> deleteGradeType(String id, {String? token}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/grade-types/$id'),
      headers: _getAuthHeaders(token),
    );
    if (response.statusCode != 204) {
      throw Exception('Erro ao deletar tipo de nota: ${response.body}');
    }
  }
}
