import 'dart:convert';
import 'package:http/http.dart' as http;

class GradeTypeService {
  static const String baseUrl = 'http://192.168.18.15:3000';

  // Buscar todos os tipos de nota
  static Future<List<Map<String, dynamic>>> getAllGradeTypes() async {
    final response = await http.get(Uri.parse('$baseUrl/grade-types'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar tipos de nota');
    }
  }

  // Buscar tipo de nota por ID
  static Future<Map<String, dynamic>> getGradeTypeById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/grade-types/$id'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao buscar tipo de nota');
    }
  }

  // Criar novo tipo de nota
  static Future<Map<String, dynamic>> createGradeType({
    required String name,
    String? description,
    bool isConcept = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/grade-types'),
      headers: {'Content-Type': 'application/json'},
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
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/grade-types/$id'),
      headers: {'Content-Type': 'application/json'},
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
  static Future<void> deleteGradeType(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/grade-types/$id'));
    if (response.statusCode != 204) {
      throw Exception('Erro ao deletar tipo de nota');
    }
  }
}
