import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ClassService {
  // URL base da API - agora centralizada
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<Map<String, dynamic>>> getAllClasses() async {
    final response = await http.get(Uri.parse(ApiConfig.getClassesUrl('')));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar turmas');
    }
  }

  static Future<Map<String, dynamic>> getClassById(String id) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getClassesUrl('/$id')),
        headers: {'Content-Type': 'application/json'},
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

  static Future<void> deleteClass(String id) async {
    final response = await http.delete(
      Uri.parse(ApiConfig.getClassesUrl('/$id')),
      headers: {'Content-Type': 'application/json'},
    );

    // Status 204 significa "No Content" - sucesso sem retorno
    if (response.statusCode == 204) {
      return; // Sucesso - turma excluída
    }

    // Para outros status codes, tentar fazer parse do erro
    if (response.statusCode != 200) {
      String errorMessage = 'Erro ao deletar turma';

      try {
        if (response.body.isNotEmpty) {
          final error = jsonDecode(response.body);
          errorMessage = error['error'] ?? errorMessage;
        }
      } catch (e) {
        // Se não conseguir fazer parse do JSON, usar a mensagem padrão
        errorMessage = 'Erro ao deletar turma (Status: ${response.statusCode})';
      }

      throw Exception(errorMessage);
    }
  }
}
