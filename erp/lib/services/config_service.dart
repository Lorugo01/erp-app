import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ConfigService {
  static String get baseUrl => ApiConfig.baseUrl;

  // Buscar todas as configurações
  static Future<Map<String, dynamic>> getConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/config'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Falha ao carregar configurações: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // Atualizar configurações
  static Future<Map<String, dynamic>> updateConfig(
    Map<String, dynamic> configData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/config'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(configData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Falha ao atualizar configurações: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // Resetar configurações para padrão
  static Future<Map<String, dynamic>> resetConfig() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/config/reset'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Falha ao resetar configurações: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // Atualizar configuração específica
  static Future<Map<String, dynamic>> updateConfigByKey(
    String key,
    dynamic value,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/config/$key'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'value': value}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Falha ao atualizar configuração: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // Buscar configuração específica
  static Future<dynamic> getConfigByKey(String key) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/config/$key'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['value'];
      } else {
        throw Exception(
          'Falha ao carregar configuração: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }
}
