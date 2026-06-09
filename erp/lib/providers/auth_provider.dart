import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/user_friendly_error.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

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

  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      final user = await AuthService.login(email, password);
      _user = user;
      await _saveUserToStorage(user);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(userErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  // Registro
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required Role role,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final user = await AuthService.register(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      _user = user;
      await _saveUserToStorage(user);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(userErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _user = null;
    await _clearUserFromStorage();
    notifyListeners();
  }

  // Atualizar dados do usuário atual do backend
  Future<void> refreshUserData() async {
    if (_user == null) return;

    try {
      final updatedUser = await UserService.getUserById(_user!.id);
      _user = updatedUser;
      await _saveUserToStorage(updatedUser);
      notifyListeners();
    } catch (e) {
      _setError(userErrorMessage(e, fallback: 'Não foi possível atualizar seus dados.'));
    }
  }

  // Atualizar dados do usuário após edição
  Future<void> updateUserData(User updatedUser) async {
    _user = updatedUser;
    await _saveUserToStorage(updatedUser);
    notifyListeners();
  }

  // Carregar usuário do storage
  Future<void> loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson != null) {
        final userData = jsonDecode(userJson);
        _user = User.fromJson(userData);
        notifyListeners();
      }
    } catch (e) {
      // Se houver erro ao carregar usuário do storage, limpar dados corrompidos
      await _clearUserFromStorage();
      _user = null;
      notifyListeners();
    }
  }

  Future<void> _saveUserToStorage(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  Future<void> _clearUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
  }
}
