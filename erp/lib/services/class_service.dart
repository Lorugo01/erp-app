import 'dart:convert';
import 'package:http/http.dart' as http;

class ClassService {
  static const String baseUrl = 'http://192.168.18.15:3000';

  static Future<List<Map<String, dynamic>>> getAllClasses() async {
    final response = await http.get(Uri.parse('$baseUrl/classes'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erro ao buscar turmas');
    }
  }

  static Future<void> deleteClass(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/classes/$id'));
    if (response.statusCode != 204) {
      throw Exception('Erro ao excluir turma');
    }
  }
}
