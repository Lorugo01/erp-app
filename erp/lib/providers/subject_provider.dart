import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class SubjectProvider with ChangeNotifier {
  List<Map<String, dynamic>> _subjects = [];
  bool _loading = false;
  String? _error;

  // Getters
  List<Map<String, dynamic>> get subjects => _subjects;
  bool get loading => _loading;
  String? get error => _error;

  // Buscar todas as matérias
  Future<void> fetchSubjects() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getSubjectsUrl('/types')),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _subjects = data.cast<Map<String, dynamic>>();
        notifyListeners();
      } else {
        throw Exception('Erro ao carregar matérias');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Criar nova matéria
  Future<bool> createSubject({
    required String type,
    String? description,
    bool isEvaluative = true,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getSubjectsUrl('/types')),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'name': type,
          'description': description ?? '',
          'isEvaluative': isEvaluative,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Recarregar a lista após criar
        await fetchSubjects();
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Erro ao criar matéria');
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Atualizar matéria
  Future<bool> updateSubject({
    required String id,
    required String type,
    String? description,
    bool isEvaluative = true,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.put(
        Uri.parse(ApiConfig.getSubjectsUrl('/types/$id')),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'name': type,
          'description': description ?? '',
          'isEvaluative': isEvaluative,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Recarregar a lista após atualizar
        await fetchSubjects();
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Erro ao atualizar matéria');
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Excluir matéria
  Future<bool> deleteSubject(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.getSubjectsUrl('/types/$id')),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Recarregar a lista após excluir
        await fetchSubjects();
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Erro ao excluir matéria');
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Buscar matéria por ID
  Future<Map<String, dynamic>?> getSubjectById(String id) async {
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
      _setError(e.toString());
      return null;
    }
  }

  // Buscar matérias por turma
  Future<List<Map<String, dynamic>>> getSubjectsByClass(String classId) async {
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
      _setError(e.toString());
      return [];
    }
  }

  // Adicionar matéria a uma turma
  Future<bool> addSubjectToClass({
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
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          errorBody['error'] ?? 'Erro ao adicionar matéria à turma',
        );
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Remover matéria de uma turma
  Future<bool> removeSubjectFromClass({
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
      _setError(e.toString());
      return false;
    }
  }

  // Buscar matérias por professor
  Future<List<Map<String, dynamic>>> getSubjectsByTeacher(
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
      _setError(e.toString());
      return [];
    }
  }

  // Filtrar matérias por texto
  List<Map<String, dynamic>> filterSubjects(String searchText) {
    if (searchText.isEmpty) return _subjects;

    return _subjects.where((subject) {
      final name =
          _formatSubjectName(
            subject['name'] ?? subject['type'] ?? '',
          ).toLowerCase();
      final search = searchText.toLowerCase();
      return name.contains(search);
    }).toList();
  }

  // Função local para formatar nome da matéria
  String _formatSubjectName(String? type) {
    if (type == null || type.isEmpty) return '';
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

  // Obter matérias avaliativas
  List<Map<String, dynamic>> get evaluativeSubjects {
    return _subjects
        .where((subject) => subject['isEvaluative'] == true)
        .toList();
  }

  // Obter matérias não-avaliativas
  List<Map<String, dynamic>> get nonEvaluativeSubjects {
    return _subjects
        .where((subject) => subject['isEvaluative'] == false)
        .toList();
  }

  // Obter estatísticas
  Map<String, int> get statistics {
    return {
      'total': _subjects.length,
      'evaluative': evaluativeSubjects.length,
      'nonEvaluative': nonEvaluativeSubjects.length,
      'inUse': _subjects.where((s) => (s['classCount'] ?? 0) > 0).length,
    };
  }

  // Métodos privados
  void _setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Limpar dados
  void clear() {
    _subjects.clear();
    _loading = false;
    _error = null;
    notifyListeners();
  }
}
