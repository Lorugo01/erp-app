import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class UserService {
  static const String baseUrl = 'http://localhost:3000';
  static const String usersEndpoint = '/users';

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
