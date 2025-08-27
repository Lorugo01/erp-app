import 'environment.dart';

class ApiConfig {
  // Endpoints específicos (sem URLs hardcoded)
  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  static const String studentsEndpoint = '/students';
  static const String teachersEndpoint = '/teachers';
  static const String classesEndpoint = '/classes';
  static const String subjectsEndpoint = '/subjects';
  static const String attendancesEndpoint = '/attendances';
  static const String enrollmentsEndpoint = '/enrollments';
  static const String lessonsEndpoint = '/lessons';
  static const String gradesEndpoint = '/grades';
  static const String gradeTypesEndpoint = '/grade-types';
  static const String gradePeriodsEndpoint = '/grade-periods';
  static const String assignmentsEndpoint = '/assignments';
  static const String chatsEndpoint = '/chats';

  // Métodos para construir URLs completas usando EnvironmentConfig
  static String getAuthUrl(String path) =>
      '${EnvironmentConfig.getApiUrl(authEndpoint)}$path';
  static String getUsersUrl(String path) =>
      '${EnvironmentConfig.getApiUrl(usersEndpoint)}$path';
  static String getStudentsUrl(String path) =>
      '${EnvironmentConfig.getApiUrl(studentsEndpoint)}$path';
  static String getTeachersUrl(String path) =>
      '${EnvironmentConfig.getApiUrl(teachersEndpoint)}$path';
  static String getClassesUrl(String path) =>
      '${EnvironmentConfig.getApiUrl(classesEndpoint)}$path';
  static String getSubjectsUrl(String path) =>
      '${EnvironmentConfig.getApiUrl(subjectsEndpoint)}$path';
  static String getAttendancesUrl(String path) =>
      '${EnvironmentConfig.getApiUrl(attendancesEndpoint)}$path';
  static String getEnrollmentsUrl(String path) =>
      '${EnvironmentConfig.getApiUrl(enrollmentsEndpoint)}$path';
  static String getLessonsUrl(String path) =>
      '${EnvironmentConfig.getApiUrl(lessonsEndpoint)}$path';
  static String getGradesUrl(String path) =>
      '${EnvironmentConfig.getApiUrl(gradesEndpoint)}$path';
  static String getGradeTypesUrl(String path) =>
      '${EnvironmentConfig.getApiUrl(gradeTypesEndpoint)}$path';
  static String getGradePeriodsUrl(String path) =>
      '${EnvironmentConfig.getApiUrl(gradePeriodsEndpoint)}$path';
  static String getAssignmentsUrl(String path) =>
      '${EnvironmentConfig.getApiUrl(assignmentsEndpoint)}$path';
  static String getChatsUrl(String path) =>
      '${EnvironmentConfig.getApiUrl(chatsEndpoint)}$path';

  // Headers padrão
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };

  // Getters para configurações do ambiente (delegando para EnvironmentConfig)
  static String get baseUrl => EnvironmentConfig.apiBaseUrl;
  static String get tecaAiBaseUrl => EnvironmentConfig.tecaaiBaseUrl;
  static Duration get apiTimeout =>
      Duration(seconds: EnvironmentConfig.apiRequestTimeout);
  static Duration get tecaAiTimeout =>
      Duration(seconds: EnvironmentConfig.tecaaiRequestTimeout);
  static double get maxFileSizeMB =>
      EnvironmentConfig.maxFileSize / (1024 * 1024);
  static bool get enableHttps => EnvironmentConfig.enableHttps;
  static bool get enableCors => EnvironmentConfig.enableCors;
  static bool get isDevelopment => EnvironmentConfig.isDevelopment;
  static bool get enableDebug => EnvironmentConfig.isDevelopment;
  static String get logLevel =>
      EnvironmentConfig.isDevelopment ? 'debug' : 'error';
}
