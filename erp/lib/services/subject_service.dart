import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class SubjectService {
  // CREATE - Criar nova matéria
  static Future<Map<String, dynamic>> createSubject({
    required String type,
    String? description,
    bool isEvaluative = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getSubjectsUrl('/types')),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'type': type,
          'description': description ?? '',
          'isEvaluative': isEvaluative,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Erro ao criar matéria');
      }
    } catch (e) {
      throw Exception('Erro ao criar matéria: $e');
    }
  }

  // READ - Buscar todas as matérias
  static Future<List<Map<String, dynamic>>> getAllSubjects() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getSubjectsUrl('/types')),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erro ao carregar matérias');
      }
    } catch (e) {
      throw Exception('Erro ao carregar matérias: $e');
    }
  }

  // READ - Buscar matéria por ID
  static Future<Map<String, dynamic>> getSubjectById(String id) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getSubjectsUrl('/types/$id')),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Matéria não encontrada');
      } else {
        throw Exception('Erro ao buscar matéria');
      }
    } catch (e) {
      throw Exception('Erro ao buscar matéria: $e');
    }
  }

  // UPDATE - Atualizar matéria
  static Future<Map<String, dynamic>> updateSubject({
    required String id,
    required String type,
    String? description,
    bool isEvaluative = true,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.getSubjectsUrl('/types/$id')),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'type': type,
          'description': description ?? '',
          'isEvaluative': isEvaluative,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Erro ao atualizar matéria');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar matéria: $e');
    }
  }

  // DELETE - Excluir matéria
  static Future<bool> deleteSubject(String id) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.getSubjectsUrl('/types/$id')),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Erro ao excluir matéria');
      }
    } catch (e) {
      throw Exception('Erro ao excluir matéria: $e');
    }
  }

  // Buscar matérias por turma
  static Future<List<Map<String, dynamic>>> getSubjectsByClass(
    String classId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getSubjectsUrl('/class/$classId')),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erro ao carregar matérias da turma');
      }
    } catch (e) {
      throw Exception('Erro ao carregar matérias da turma: $e');
    }
  }

  // Adicionar matéria a uma turma
  static Future<Map<String, dynamic>> addSubjectToClass({
    required String classId,
    required String subjectTypeId,
    required String teacherId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getSubjectsUrl('/class/$classId')),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'subjectTypeId': subjectTypeId,
          'teacherId': teacherId,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          errorBody['error'] ?? 'Erro ao adicionar matéria à turma',
        );
      }
    } catch (e) {
      throw Exception('Erro ao adicionar matéria à turma: $e');
    }
  }

  // Remover matéria de uma turma
  static Future<bool> removeSubjectFromClass({
    required String classId,
    required String subjectId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.getSubjectsUrl('/class/$classId/$subjectId')),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          errorBody['error'] ?? 'Erro ao remover matéria da turma',
        );
      }
    } catch (e) {
      throw Exception('Erro ao remover matéria da turma: $e');
    }
  }

  // Buscar matérias por professor
  static Future<List<Map<String, dynamic>>> getSubjectsByTeacher(
    String teacherId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getSubjectsUrl('/teacher/$teacherId')),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erro ao carregar matérias do professor');
      }
    } catch (e) {
      throw Exception('Erro ao carregar matérias do professor: $e');
    }
  }

  // Formatar tipo de matéria para exibição
  static String formatSubjectType(String? type) {
    if (type == null) return '';

    // Mapeamento dos tipos padrão
    switch (type) {
      case 'LINGUA_INGLESA':
        return 'Língua Inglesa';
      case 'ARTE':
        return 'Arte';
      case 'EDUCACAO_FISICA':
        return 'Educação Física';
      case 'MATEMATICA':
        return 'Matemática';
      case 'CIENCIAS':
        return 'Ciências';
      case 'HISTORIA':
        return 'História';
      case 'GEOGRAFIA':
        return 'Geografia';
      case 'ENSINO_RELIGIOSO':
        return 'Ensino Religioso';
      case 'BIOLOGIA':
        return 'Biologia';
      case 'FISICA':
        return 'Física';
      case 'QUIMICA':
        return 'Química';
      case 'FILOSOFIA':
        return 'Filosofia';
      case 'SOCIOLOGIA':
        return 'Sociologia';
      case 'CONTEUDO_INTERDISCIPLINAR':
        return 'Conteúdo Interdisciplinar';
      default:
        // Para tipos personalizados, converter de UPPER_CASE para Title Case
        return type
            .toLowerCase()
            .split('_')
            .map(
              (word) =>
                  word.isNotEmpty
                      ? '${word[0].toUpperCase()}${word.substring(1)}'
                      : '',
            )
            .join(' ')
            .trim();
    }
  }

  // Validar se um tipo de matéria é válido
  static bool isValidSubjectType(String type) {
    const validTypes = [
      'LINGUA_INGLESA',
      'ARTE',
      'EDUCACAO_FISICA',
      'MATEMATICA',
      'CIENCIAS',
      'HISTORIA',
      'GEOGRAFIA',
      'ENSINO_RELIGIOSO',
      'BIOLOGIA',
      'FISICA',
      'QUIMICA',
      'FILOSOFIA',
      'SOCIOLOGIA',
      'CONTEUDO_INTERDISCIPLINAR',
    ];
    return validTypes.contains(type);
  }

  // Obter lista de tipos válidos
  static List<String> getValidSubjectTypes() {
    return [
      'LINGUA_INGLESA',
      'ARTE',
      'EDUCACAO_FISICA',
      'MATEMATICA',
      'CIENCIAS',
      'HISTORIA',
      'GEOGRAFIA',
      'ENSINO_RELIGIOSO',
      'BIOLOGIA',
      'FISICA',
      'QUIMICA',
      'FILOSOFIA',
      'SOCIOLOGIA',
      'CONTEUDO_INTERDISCIPLINAR',
    ];
  }

  // Converter string para formato de tipo válido
  static String toValidSubjectType(String input) {
    return input.toUpperCase().replaceAll(' ', '_');
  }
}
