import 'package:flutter/material.dart';
import '../services/teacher_service.dart';
import '../services/student_service.dart';
import '../services/user_service.dart';
import '../models/user.dart';

class DataProvider extends ChangeNotifier {
  Map<String, dynamic>? _currentTeacher;
  Map<String, dynamic>? _currentStudent;
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get currentTeacher => _currentTeacher;
  Map<String, dynamic>? get currentStudent => _currentStudent;
  List<Map<String, dynamic>> get teachers => _teachers;
  List<Map<String, dynamic>> get students => _students;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Atualizar dados do professor atual
  Future<void> refreshCurrentTeacher(String teacherId) async {
    _setLoading(true);
    _clearError();
    try {
      final updatedTeacher = await TeacherService.getTeacherById(teacherId);
      _currentTeacher = updatedTeacher;
      _setLoading(false);
    } catch (e) {
      _setError('Erro ao atualizar dados do professor: $e');
      _setLoading(false);
    }
  }

  // Atualizar dados do aluno atual
  Future<void> refreshCurrentStudent(String studentId) async {
    _setLoading(true);
    _clearError();
    try {
      // Buscar aluno da lista atual ou fazer nova requisição
      final allStudents = await StudentService.getAllStudents();
      final student = allStudents.firstWhere((s) => s.id == studentId);
      _currentStudent = {
        'id': student.id,
        'name': student.name,
        'email': student.email,
        'registrationNumber': student.registrationNumber,
        'profilePicture': student.profilePicture,
        'createdAt': student.createdAt?.toIso8601String(),
      };
      _setLoading(false);
    } catch (e) {
      _setError('Erro ao atualizar dados do aluno: $e');
      _setLoading(false);
    }
  }

  // Atualizar lista de professores
  Future<void> refreshTeachers() async {
    _setLoading(true);
    _clearError();
    try {
      final updatedTeachers = await TeacherService.getAllTeachers();
      _teachers = updatedTeachers;
      _setLoading(false);
    } catch (e) {
      _setError('Erro ao atualizar lista de professores: $e');
      _setLoading(false);
    }
  }

  // Atualizar lista de alunos
  Future<void> refreshStudents() async {
    _setLoading(true);
    _clearError();
    try {
      final updatedStudents = await StudentService.getAllStudents();
      _students =
          updatedStudents
              .map(
                (student) => {
                  'id': student.id,
                  'name': student.name,
                  'email': student.email,
                  'registrationNumber': student.registrationNumber,
                  'profilePicture': student.profilePicture,
                  'createdAt': student.createdAt?.toIso8601String(),
                },
              )
              .toList();
      _setLoading(false);
    } catch (e) {
      _setError('Erro ao atualizar lista de alunos: $e');
      _setLoading(false);
    }
  }

  // Atualizar dados após edição
  Future<void> updateTeacherData(
    String teacherId,
    Map<String, dynamic> updatedData,
  ) async {
    _setLoading(true);
    _clearError();
    try {
      final updatedTeacher = await TeacherService.updateTeacher(
        teacherId,
        updatedData,
      );
      _currentTeacher = updatedTeacher;

      // Atualizar na lista também
      final index = _teachers.indexWhere((t) => t['id'] == teacherId);
      if (index != -1) {
        _teachers[index] = updatedTeacher;
      }

      _setLoading(false);
    } catch (e) {
      _setError('Erro ao atualizar dados do professor: $e');
      _setLoading(false);
    }
  }

  // Atualizar foto do professor
  Future<void> updateTeacherPhoto(String teacherId, String photoUrl) async {
    _setLoading(true);
    _clearError();
    try {
      final updatedTeacher = await TeacherService.updateTeacherPhoto(
        teacherId,
        photoUrl,
      );
      _currentTeacher = updatedTeacher;

      // Atualizar na lista também
      final index = _teachers.indexWhere((t) => t['id'] == teacherId);
      if (index != -1) {
        _teachers[index] = updatedTeacher;
      }

      _setLoading(false);
    } catch (e) {
      _setError('Erro ao atualizar foto do professor: $e');
      _setLoading(false);
    }
  }

  // Atualizar dados do usuário
  Future<User> updateUserData(
    String userId,
    Map<String, dynamic> updatedData,
  ) async {
    _setLoading(true);
    _clearError();
    try {
      final updatedUser = await UserService.updateUser(userId, updatedData);
      _setLoading(false);
      return updatedUser;
    } catch (e) {
      _setError('Erro ao atualizar dados do usuário: $e');
      _setLoading(false);
      rethrow;
    }
  }

  // Atualizar foto do usuário
  Future<User> updateUserPhoto(String userId, String photoUrl) async {
    _setLoading(true);
    _clearError();
    try {
      final updatedUser = await UserService.updateUserPhoto(userId, photoUrl);
      _setLoading(false);
      return updatedUser;
    } catch (e) {
      _setError('Erro ao atualizar foto do usuário: $e');
      _setLoading(false);
      rethrow;
    }
  }

  // Definir professor atual
  void setCurrentTeacher(Map<String, dynamic> teacher) {
    _currentTeacher = teacher;
    notifyListeners();
  }

  // Definir aluno atual
  void setCurrentStudent(Map<String, dynamic> student) {
    _currentStudent = student;
    notifyListeners();
  }

  // Limpar dados
  void clearData() {
    _currentTeacher = null;
    _currentStudent = null;
    _teachers = [];
    _students = [];
    _clearError();
  }
}
