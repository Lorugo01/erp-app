import 'environment.dart';

class ApiConfig {
  // Configuração da URL da API - agora centralizada
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
  static const String enrollmentsEndpoint = '/enrollments';
  static const String lessonsEndpoint = '/lessons';
  static const String gradeTypesEndpoint = '/grade-types';
  static const String gradePeriodsEndpoint = '/grade-periods';
  
  // Timeout para requisições - agora centralizado
  static int get requestTimeout => EnvironmentConfig.apiRequestTimeout;
  
  // Headers padrão
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };

  // Métodos utilitários para construir URLs completas
  static String getAuthUrl(String endpoint) => EnvironmentConfig.getApiUrl('$authEndpoint$endpoint');
  static String getUsersUrl(String endpoint) => EnvironmentConfig.getApiUrl('$usersEndpoint$endpoint');
  static String getStudentsUrl(String endpoint) => EnvironmentConfig.getApiUrl('$studentsEndpoint$endpoint');
  static String getTeachersUrl(String endpoint) => EnvironmentConfig.getApiUrl('$teachersEndpoint$endpoint');
  static String getClassesUrl(String endpoint) => EnvironmentConfig.getApiUrl('$classesEndpoint$endpoint');
  static String getSubjectsUrl(String endpoint) => EnvironmentConfig.getApiUrl('$subjectsEndpoint$endpoint');
  static String getGradesUrl(String endpoint) => EnvironmentConfig.getApiUrl('$gradesEndpoint$endpoint');
  static String getAttendanceUrl(String endpoint) => EnvironmentConfig.getApiUrl('$attendanceEndpoint$endpoint');
  static String getAssignmentsUrl(String endpoint) => EnvironmentConfig.getApiUrl('$assignmentsEndpoint$endpoint');
  static String getChatUrl(String endpoint) => EnvironmentConfig.getApiUrl('$chatEndpoint$endpoint');
  static String getEnrollmentsUrl(String endpoint) => EnvironmentConfig.getApiUrl('$enrollmentsEndpoint$endpoint');
  static String getLessonsUrl(String endpoint) => EnvironmentConfig.getApiUrl('$lessonsEndpoint$endpoint');
  static String getGradeTypesUrl(String endpoint) => EnvironmentConfig.getApiUrl('$gradeTypesEndpoint$endpoint');
  static String getGradePeriodsUrl(String endpoint) => EnvironmentConfig.getApiUrl('$gradePeriodsEndpoint$endpoint');
} 