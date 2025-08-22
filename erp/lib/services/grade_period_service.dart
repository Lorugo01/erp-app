import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class GradePeriodService {
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

  static Future<List<Map<String, dynamic>>> getAllGradePeriods({
    String? token,
  }) async {
    final response = await http.get(
      Uri.parse(ApiConfig.getGradePeriodsUrl('')),
      headers: _getAuthHeaders(token),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar períodos de notas');
    }
  }

  static Future<Map<String, dynamic>> getGradePeriodById(
    String id, {
    String? token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getGradePeriodsUrl('/$id')),
        headers: _getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception(
          'Erro ao buscar período de notas: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Criar novo período
  static Future<Map<String, dynamic>> createGradePeriod({
    required String name,
    required int order,
    DateTime? startDate,
    DateTime? endDate,
    String? token,
  }) async {
    final body = {
      'name': name,
      'order': order,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };

    final response = await http.post(
      Uri.parse('$baseUrl/grade-periods'),
      headers: _getAuthHeaders(token),
      body: jsonEncode(body),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao criar período: ${response.body}');
    }
  }

  // Atualizar período
  static Future<Map<String, dynamic>> updateGradePeriod({
    required String id,
    String? name,
    int? order,
    DateTime? startDate,
    DateTime? endDate,
    String? token,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (order != null) 'order': order,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };

    final response = await http.put(
      Uri.parse('$baseUrl/grade-periods/$id'),
      headers: _getAuthHeaders(token),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao atualizar período: ${response.body}');
    }
  }

  // Deletar período
  static Future<void> deleteGradePeriod(String id, {String? token}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/grade-periods/$id'),
      headers: _getAuthHeaders(token),
    );
    if (response.statusCode != 204) {
      throw Exception('Erro ao deletar período: ${response.body}');
    }
  }
}
