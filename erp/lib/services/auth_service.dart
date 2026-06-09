import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../config/api_config.dart';
import '../utils/api_error.dart';
import 'package:flutter/material.dart';

class AuthService {
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
      }

      debugPrint('❌ Erro HTTP login: ${response.statusCode} - ${response.body}');
      throwApiResponseError(
        response,
        fallback: 'Não foi possível entrar. Verifique e-mail e senha.',
      );
    } on Exception {
      rethrow;
    } catch (e) {
      debugPrint('❌ Erro de conexão login: $e');
      rethrowServiceError(
        e,
        fallback: 'Não foi possível conectar. Verifique sua internet.',
      );
    }
  }

  static Future<User> register({
    required String email,
    required String password,
    required String name,
    required Role role,
    String? schoolId,
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
          if (schoolId != null) 'schoolId': schoolId,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      }

      throwApiResponseError(
        response,
        fallback: 'Não foi possível criar a conta. Tente novamente.',
      );
    } on Exception {
      rethrow;
    } catch (e) {
      rethrowServiceError(
        e,
        fallback: 'Não foi possível conectar. Verifique sua internet.',
      );
    }
  }

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
      }

      throwApiResponseError(
        response,
        fallback: 'Não foi possível criar o administrador.',
      );
    } on Exception {
      rethrow;
    } catch (e) {
      rethrowServiceError(
        e,
        fallback: 'Não foi possível conectar. Verifique sua internet.',
      );
    }
  }

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
