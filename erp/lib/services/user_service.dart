import 'dart:convert';
import '../utils/user_friendly_error.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../config/api_config.dart';

class UserService {
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

  static Future<List<User>> getAllUsers({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getUsersUrl('')),
        headers: _getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao buscar usuários: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(userErrorMessage(e));
    }
  }

  static Future<User> getUserById(String id, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getUsersUrl('/$id')),
        headers: _getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Erro ao buscar usuário: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(userErrorMessage(e));
    }
  }

  static Future<User> updateUser(
    String id,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    final response = await http.put(
      Uri.parse(ApiConfig.getUsersUrl('/$id')),
      headers: _getAuthHeaders(token),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao atualizar usuário');
    }
  }

  static Future<User> updateUserPhoto(
    String id,
    String photoUrl, {
    String? token,
  }) async {
    final response = await http.put(
      Uri.parse(ApiConfig.getUsersUrl('/$id/photo')),
      headers: _getAuthHeaders(token),
      body: jsonEncode({'photoUrl': photoUrl}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao atualizar foto do usuário');
    }
  }

  static Future<void> deleteUser(String id, {String? token}) async {
    final response = await http.delete(
      Uri.parse(ApiConfig.getUsersUrl('/$id')),
      headers: _getAuthHeaders(token),
    );

    // 200 OK ou 204 No Content são sucesso para DELETE
    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao deletar usuário');
    }
  }

  static Future<User> createUser({
    required String name,
    required String email,
    required String password,
    required Role role,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getAuthUrl('/register')),
        headers: _getAuthHeaders(token),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role.toString().split('.').last.toUpperCase(),
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Erro ao criar usuário');
      }
    } catch (e) {
      throw Exception(userErrorMessage(e));
    }
  }
}
