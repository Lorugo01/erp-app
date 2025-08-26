class ApiConfig {
  // URLs base
  static const String baseUrl = 'http://192.168.18.15:3000';
  static const String tecaAiBaseUrl = 'http://192.168.18.15:5001';

  // Endpoints específicos
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

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration tecaAiTimeout = Duration(seconds: 30);

  // Configurações de arquivo
  static const double maxFileSizeMB = 10.0;
  static const bool enableHttps = false;
  static const bool enableCors = true;

  // Métodos para construir URLs completas
  static String getAuthUrl(String path) => '$baseUrl$authEndpoint$path';
  static String getUsersUrl(String path) => '$baseUrl$usersEndpoint$path';
  static String getStudentsUrl(String path) => '$baseUrl$studentsEndpoint$path';
  static String getTeachersUrl(String path) => '$baseUrl$teachersEndpoint$path';
  static String getClassesUrl(String path) => '$baseUrl$classesEndpoint$path';
  static String getSubjectsUrl(String path) => '$baseUrl$subjectsEndpoint$path';
  static String getAttendancesUrl(String path) =>
      '$baseUrl$attendancesEndpoint$path';
  static String getEnrollmentsUrl(String path) =>
      '$baseUrl$enrollmentsEndpoint$path';
  static String getLessonsUrl(String path) => '$baseUrl$lessonsEndpoint$path';
  static String getGradesUrl(String path) => '$baseUrl$gradesEndpoint$path';
  static String getGradeTypesUrl(String path) =>
      '$baseUrl$gradeTypesEndpoint$path';
  static String getGradePeriodsUrl(String path) =>
      '$baseUrl$gradePeriodsEndpoint$path';
  static String getAssignmentsUrl(String path) =>
      '$baseUrl$assignmentsEndpoint$path';
  static String getChatsUrl(String path) => '$baseUrl$chatsEndpoint$path';

  // Headers padrão
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };

  // Configurações de ambiente
  static const bool isDevelopment = true;
  static const bool enableDebug = true;
  static const String logLevel = 'debug';
}
