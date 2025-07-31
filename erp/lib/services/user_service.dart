import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class UserService {
  static const String baseUrl = 'http://192.168.18.15:3000';
  static const String usersEndpoint = '/users';
  static const String authEndpoint = '/auth';

  // Buscar todos os usuários
  static Future<List<User>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$usersEndpoint'),
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

  // Criar novo usuário
  static Future<User> createUser({
    required String email,
    required String password,
    required String name,
    required Role role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$authEndpoint/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
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

  // Buscar usuário por ID
  static Future<User> getUserById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$usersEndpoint/$id'),
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

  // Atualizar dados do usuário
  static Future<User> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$usersEndpoint/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return User.fromJson(responseData);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Erro ao atualizar usuário');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Atualizar foto do usuário
  static Future<User> updateUserPhoto(String id, String photoUrl) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$usersEndpoint/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'photoUrl': photoUrl}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return User.fromJson(responseData);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Erro ao atualizar foto do usuário');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Excluir usuário
  static Future<void> deleteUser(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$usersEndpoint/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 204) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Erro ao excluir usuário');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
}
