import 'dart:convert';
import 'package:http/http.dart' as http;

class GradePeriodService {
  static const String baseUrl = 'http://192.168.18.15:3000';

  // Buscar todos os períodos
  static Future<List<Map<String, dynamic>>> getAllGradePeriods() async {
    final response = await http.get(Uri.parse('$baseUrl/grade-periods'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar períodos');
    }
  }

  // Buscar período por ID
  static Future<Map<String, dynamic>> getGradePeriodById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/grade-periods/$id'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao buscar período');
    }
  }

  // Criar novo período
  static Future<Map<String, dynamic>> createGradePeriod({
    required String name,
    required int order,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/grade-periods'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'order': order}),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao criar período');
    }
  }

  // Atualizar período
  static Future<Map<String, dynamic>> updateGradePeriod({
    required String id,
    String? name,
    int? order,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/grade-periods/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (name != null) 'name': name,
        if (order != null) 'order': order,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao atualizar período');
    }
  }

  // Deletar período
  static Future<void> deleteGradePeriod(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/grade-periods/$id'));
    if (response.statusCode != 204) {
      throw Exception('Erro ao deletar período');
    }
  }
}
