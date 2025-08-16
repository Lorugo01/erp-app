import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../config/api_config.dart';
import 'package:flutter/material.dart';

class AuthService {
  // Login
  static Future<User> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authEndpoint}/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        debugPrint('❌ Erro HTTP: ${response.statusCode} - ${response.body}');
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Erro no login');
      }
    } catch (e) {
      debugPrint('❌ Erro de conexão: $e');
      throw Exception('Erro de conexão: $e');
    }
  }

  // Registro de usuário
  static Future<User> register({
    required String email,
    required String password,
    required String name,
    required Role role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authEndpoint}/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'role': role.toString().split('.').last.toUpperCase(),
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Erro no registro');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Registro de admin
  static Future<User> registerAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.authEndpoint}/register/admin',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Erro no registro de admin');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Verificar se a API está online
  static Future<bool> checkApiConnection() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
