import 'environment.dart';

class ApiConfig {
  // Configuração da URL da API
  // Para desenvolvimento local, use o IP da sua máquina
  // Para produção, use o domínio do servidor
  static String get baseUrl => EnvironmentConfig.apiBaseUrl;
  
  // URLs específicas
  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  static const String studentsEndpoint = '/students';
  static const String teachersEndpoint = '/teachers';
  static const String classesEndpoint = '/classes';
  static const String subjectsEndpoint = '/subjects';
  static const String gradesEndpoint = '/grades';
  static const String attendanceEndpoint = '/attendance';
  static const String assignmentsEndpoint = '/assignments';
  static const String chatEndpoint = '/chat';
  
  // Timeout para requisições (em segundos)
  static const int requestTimeout = 30;
  
  // Headers padrão
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };
} 