import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/grade.dart';
import '../models/grade_type.dart';

class GradeService {
  final String baseUrl =
      'http://localhost:3000'; // ou o endereço real do seu backend

  Future<List<Grade>> getGradesByStudent(String studentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/grades/student/$studentId'),
    );
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => Grade.fromJson(e)).toList();
    } else {
      throw Exception('Erro ao buscar notas');
    }
  }

  Future<List<GradeType>> getGradeTypes() async {
    final response = await http.get(Uri.parse('$baseUrl/grade-types'));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => GradeType.fromJson(e)).toList();
    } else {
      throw Exception('Erro ao buscar tipos de nota');
    }
  }

  Future<Grade> updateGrade(
    String gradeId, {
    double? value,
    String? concept,
    String? typeId,
    String? periodId,
    DateTime? date,
  }) async {
    final body = <String, dynamic>{
      if (value != null) 'value': value,
      if (concept != null) 'concept': concept,
      if (typeId != null) 'typeId': typeId,
      if (periodId != null) 'periodId': periodId,
      if (date != null) 'date': date.toIso8601String(),
    };
    final response = await http.put(
      Uri.parse('$baseUrl/grades/$gradeId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      return Grade.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erro ao atualizar nota');
    }
  }

  Future<Grade> createGrade({
    required String studentId,
    required String subjectId,
    required String typeId,
    required String periodId,
    double? value,
    String? concept,
    DateTime? date,
  }) async {
    final body = <String, dynamic>{
      'studentId': studentId,
      'subjectId': subjectId,
      'typeId': typeId,
      'periodId': periodId,
      if (value != null) 'value': value,
      if (concept != null) 'concept': concept,
      if (date != null) 'date': date.toIso8601String(),
    };
    final response = await http.post(
      Uri.parse('$baseUrl/grades'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Grade.fromJson(json.decode(response.body));
    } else {
      // Lançar o body detalhado do erro
      throw Exception('Erro ao lançar nota: ${response.body}');
    }
  }

  Future<void> deleteGrade(String gradeId) async {
    final response = await http.delete(Uri.parse('$baseUrl/grades/$gradeId'));
    if (response.statusCode != 204) {
      throw Exception('Erro ao excluir nota');
    }
  }

  // Métodos para lançar/editar nota podem ser adicionados aqui
}
