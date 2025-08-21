import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/school.dart';
import '../config/api_config.dart';
import 'package:flutter/material.dart';

class SchoolService {
  // Listar todas as escolas
  static Future<List<School>> getSchools() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/schools'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => School.fromJson(json)).toList();
      } else {
        debugPrint('❌ Erro HTTP: ${response.statusCode} - ${response.body}');
        throw Exception('Erro ao carregar escolas');
      }
    } catch (e) {
      debugPrint('❌ Erro de conexão: $e');
      throw Exception('Erro de conexão: $e');
    }
  }

  // Buscar escola por ID
  static Future<School> getSchoolById(String id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/schools/$id'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return School.fromJson(data);
      } else {
        debugPrint('❌ Erro HTTP: ${response.statusCode} - ${response.body}');
        throw Exception('Escola não encontrada');
      }
    } catch (e) {
      debugPrint('❌ Erro de conexão: $e');
      throw Exception('Erro de conexão: $e');
    }
  }

  // Criar nova escola
  static Future<School> createSchool({
    required String name,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? logo,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/schools'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'address': address,
              'phone': phone,
              'email': email,
              'website': website,
              'logo': logo,
            }),
          )
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return School.fromJson(data);
      } else {
        debugPrint('❌ Erro HTTP: ${response.statusCode} - ${response.body}');
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Erro ao criar escola');
      }
    } catch (e) {
      debugPrint('❌ Erro de conexão: $e');
      throw Exception('Erro de conexão: $e');
    }
  }

  // Atualizar escola
  static Future<School> updateSchool({
    required String id,
    required String name,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? logo,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/schools/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'address': address,
              'phone': phone,
              'email': email,
              'website': website,
              'logo': logo,
            }),
          )
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return School.fromJson(data);
      } else {
        debugPrint('❌ Erro HTTP: ${response.statusCode} - ${response.body}');
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Erro ao atualizar escola');
      }
    } catch (e) {
      debugPrint('❌ Erro de conexão: $e');
      throw Exception('Erro de conexão: $e');
    }
  }

  // Deletar escola
  static Future<void> deleteSchool(String id, {bool force = false}) async {
    try {
      final uri = force 
          ? Uri.parse('${ApiConfig.baseUrl}/schools/$id?force=true')
          : Uri.parse('${ApiConfig.baseUrl}/schools/$id');
          
      final response = await http
          .delete(
            uri,
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      if (response.statusCode != 200) {
        debugPrint('❌ Erro HTTP: ${response.statusCode} - ${response.body}');
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Erro ao deletar escola');
      }
    } catch (e) {
      debugPrint('❌ Erro de conexão: $e');
      throw Exception('Erro de conexão: $e');
    }
  }

  // Obter estatísticas da escola
  static Future<Map<String, dynamic>> getSchoolStats(String id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/schools/$id/stats'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        debugPrint('❌ Erro HTTP: ${response.statusCode} - ${response.body}');
        throw Exception('Erro ao carregar estatísticas');
      }
    } catch (e) {
      debugPrint('❌ Erro de conexão: $e');
      throw Exception('Erro de conexão: $e');
    }
  }
}
