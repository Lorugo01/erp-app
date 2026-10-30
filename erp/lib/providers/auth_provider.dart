import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/user_friendly_error.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    ApiConfig.sessionTokenProvider = () => _user?.token;
  }

  User? _user;
  bool _isLoading = false;
  bool _isRestoring = true;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isRestoring => _isRestoring;
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

  // Atualizar dados do usuário atual do backend sem apagar o token da sessão.
  Future<void> refreshUserData() async {
    if (_user == null) return;

    try {
      final current = _user!;
      final updatedUser = await UserService.getUserById(
        current.id,
        token: current.token,
      );
      _user = updatedUser.withSession(
        token: updatedUser.token ?? current.token,
        schoolId: updatedUser.schoolId ?? current.schoolId,
      );
      await _saveUserToStorage(_user!);
      notifyListeners();
    } catch (e) {
      _setError(userErrorMessage(e, fallback: 'Não foi possível atualizar seus dados.'));
    }
  }

  // Atualizar dados do usuário após edição
  Future<void> updateUserData(User updatedUser) async {
    final current = _user;
    _user = updatedUser.withSession(
      token: updatedUser.token ?? current?.token,
      schoolId: updatedUser.schoolId ?? current?.schoolId,
    );
    await _saveUserToStorage(_user!);
    notifyListeners();
  }

  /// Encerra a sessão local quando a API recusa o token.
  Future<void> expireSession() async {
    _user = null;
    _error = 'Sua sessão expirou. Entre novamente.';
    await _clearUserFromStorage();
    notifyListeners();
  }

  // Carregar usuário do storage e só então liberar o painel.
  Future<void> loadUserFromStorage() async {
    _isRestoring = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson == null) {
        _user = null;
        return;
      }

      final user = User.fromJson(jsonDecode(userJson));
      final token = user.token;
      if (token == null || token.isEmpty || User.isTokenExpired(token)) {
        await _clearUserFromStorage();
        _user = null;
        _error = 'Sua sessão expirou. Entre novamente.';
        return;
      }

      _user = user;
      await _renewSession(user);
    } catch (e) {
      await _clearUserFromStorage();
      _user = null;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> _renewSession(User user) async {
    final token = user.token;
    if (token == null || token.isEmpty) return;

    try {
      final newToken = await AuthService.refreshSession(token);
      _user = user.withSession(token: newToken);
      await _saveUserToStorage(_user!);
    } on AuthSessionException {
      await _clearUserFromStorage();
      _user = null;
      _error = 'Sua sessão expirou. Entre novamente.';
    } catch (e) {
      // Sem rede ou API antiga: mantém o token que ainda não venceu.
      debugPrint('Sessão não renovada: $e');
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
