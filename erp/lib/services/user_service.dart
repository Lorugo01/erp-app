import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../config/api_config.dart';

class UserService {
  // URL base da API - agora centralizada
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<User>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getUsersUrl('')),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao buscar usuários: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<User> getUserById(String id) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getUsersUrl('/$id')),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Erro ao buscar usuário: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<User> updateUser(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse(ApiConfig.getUsersUrl('/$id')),
      headers: {'Content-Type': 'application/json'},
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

  static Future<User> updateUserPhoto(String id, String photoUrl) async {
    final response = await http.put(
      Uri.parse(ApiConfig.getUsersUrl('/$id/photo')),
      headers: {'Content-Type': 'application/json'},
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

  static Future<void> deleteUser(String id) async {
    final response = await http.delete(
      Uri.parse(ApiConfig.getUsersUrl('/$id')),
      headers: {'Content-Type': 'application/json'},
    );

    // Status 204 significa "No Content" - sucesso sem retorno
    if (response.statusCode == 204) {
      return; // Sucesso - usuário excluído
    }

    // Para outros status codes, tentar fazer parse do erro
    if (response.statusCode != 200) {
      String errorMessage = 'Erro ao deletar usuário';

      try {
        if (response.body.isNotEmpty) {
          final error = jsonDecode(response.body);
          errorMessage = error['error'] ?? errorMessage;
        }
      } catch (e) {
        // Se não conseguir fazer parse do JSON, usar a mensagem padrão
        errorMessage = 'Erro ao deletar usuário (Status: ${response.statusCode})';
      }

      throw Exception(errorMessage);
    }
  }

  static Future<User> createUser({
    required String name,
    required String email,
    required String password,
    required Role role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getAuthUrl('/register')),
        headers: {'Content-Type': 'application/json'},
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
      throw Exception('Erro de conexão: $e');
    }
  }
}
