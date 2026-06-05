import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/assignment_service.dart';
import '../../services/grade_period_service.dart';
import '../../services/grade_service.dart';
import '../../services/grade_type_service.dart';
import '../../services/teacher_service.dart';
import '../../services/attendance_service.dart';
import '../../config/api_config.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'task_submissions_screen.dart';
import 'package:intl/intl.dart';
import 'teacher_student_detail_screen.dart';

// Classe utilitária para logging estruturado
class TeacherClassLogger {
  static const String _prefix = '🎓 [TeacherClass]';

  static void info(String message) {
    debugPrint('$_prefix ℹ️ $message');
  }

  static void success(String message) {
    debugPrint('$_prefix ✅ $message');
  }

  static void warning(String message) {
    debugPrint('$_prefix ⚠️ $message');
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    debugPrint('$_prefix ❌ $message');
    if (error != null) {
      debugPrint('$_prefix 🔍 Erro detalhado: $error');
    }
    if (stackTrace != null) {
      debugPrint('$_prefix 📍 Stack trace: $stackTrace');
    }
  }

  static void debug(String message, [Map<String, dynamic>? data]) {
    debugPrint('$_prefix 🐛 $message');
    if (data != null) {
      debugPrint('$_prefix 📊 Dados: $data');
    }
  }

  static void api(
    String endpoint,
    String method, [
    Map<String, dynamic>? params,
  ]) {
    debugPrint('$_prefix 🌐 API: $method $endpoint');
    if (params != null) {
      debugPrint('$_prefix 📝 Parâmetros: $params');
    }
  }

  static void state(String message, [Map<String, dynamic>? state]) {
    debugPrint('$_prefix 🔄 Estado: $message');
    if (state != null) {
      debugPrint('$_prefix 📊 Estado atual: $state');
    }
  }

  static void network(String message, [Map<String, dynamic>? data]) {
    debugPrint('$_prefix 🌐 [Rede] $message');
    if (data != null) {
      debugPrint('$_prefix 📊 Dados de rede: $data');
    }
  }
}

class TeacherClassDetailScreen extends StatefulWidget {
  final Map<String, dynamic> classData;
  const TeacherClassDetailScreen({super.key, required this.classData});

  @override
  State<TeacherClassDetailScreen> createState() =>
      _TeacherClassDetailScreenState();
}

class _TeacherClassDetailScreenState extends State<TeacherClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Disciplinas do professor nesta sala
  List<Map<String, dynamic>> _subjects = [];
  String? _selectedSubjectId;

  // Atividades
  List<Map<String, dynamic>> _assignments = [];
  bool _loadingAssignments = false;
  String? _errorAssignments;

  // Chamadas
  List<Map<String, dynamic>> _students = [];
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _currentLesson;
  bool _loadingAttendance = false;
  Map<String, String?> _attendanceMap =
      {}; // null = não marcado, 'PRESENT', 'ABSENT', 'JUSTIFIED_ABSENT'
  Map<String, String> _justificationMap =
      {}; // Justificativas para faltas justificadas
  String? _errorAttendance;

  // Notas
  List<Map<String, dynamic>> _periods = [];
  List<Map<String, dynamic>> _gradeTypes = [];
  List<Map<String, dynamic>> _grades = [];
  String? _selectedPeriodId;
  bool _loadingGrades = false;
  String? _errorGrades;

  // Duplicação de aula

  @override
  void initState() {
    super.initState();

    // Garantir que a data seja inicializada corretamente
    _selectedDate = DateTime.now();
    TeacherClassLogger.info('Inicializando tela de detalhes da turma');
    TeacherClassLogger.debug('Dados da turma recebidos', {
      'classId': widget.classData['id'],
      'className': widget.classData['name'],
      'selectedDate': _selectedDate.toIso8601String(),
    });

    _tabController = TabController(length: 3, vsync: this);

    // Testar conectividade antes de carregar dados
    _testApiConnectivity();

    // Carregar apenas disciplinas - que carregará o resto automaticamente
    _fetchSubjects();

    _tabController.addListener(() {
      if (_tabController.index == 0 && _assignments.isEmpty) {
        TeacherClassLogger.info(
          'Aba de atividades selecionada, carregando atividades...',
        );
        _fetchAssignments();
      } else if (_tabController.index == 1 && _currentLesson == null) {
        // Aba de chamada - carregar frequência se houver disciplina selecionada
        if (_selectedSubjectId != null) {
          TeacherClassLogger.info(
            'Aba de chamada selecionada, carregando frequência...',
          );
          _loadAttendance();
        }
      } else if (_tabController.index == 2 && _grades.isEmpty) {
        TeacherClassLogger.info(
          'Aba de notas selecionada, carregando notas...',
        );
        _fetchGrades();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Método para testar conectividade com a API
  Future<void> _testApiConnectivity() async {
    TeacherClassLogger.network('Iniciando teste de conectividade com a API');

    try {
      // Teste básico de conectividade
      TeacherClassLogger.network('Testando endpoint de health check');
      final healthResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/health'),
        headers: {'Content-Type': 'application/json'},
      );

      TeacherClassLogger.network('Health check bem-sucedido', {
        'statusCode': healthResponse.statusCode,
        'body': healthResponse.body,
        'url': '${ApiConfig.baseUrl}/health',
      });
    } catch (e) {
      TeacherClassLogger.network('Falha no health check', {
        'error': e.toString(),
        'url': '${ApiConfig.baseUrl}/health',
        'baseUrl': ApiConfig.baseUrl,
      });
    }

    // Teste de conectividade com endpoint específico
    try {
      TeacherClassLogger.network('Testando endpoint de turmas');
      final classesResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/classes'),
        headers: {'Content-Type': 'application/json'},
      );

      TeacherClassLogger.network('Endpoint de turmas responde', {
        'statusCode': classesResponse.statusCode,
        'url': '${ApiConfig.baseUrl}/classes',
      });
    } catch (e) {
      TeacherClassLogger.network('Falha no endpoint de turmas', {
        'error': e.toString(),
        'url': '${ApiConfig.baseUrl}/classes',
      });
    }

    // Teste de autenticação com token
    try {
      TeacherClassLogger.network('Testando autenticação com token');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.user?.token;

      if (token != null) {
        final authResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/classes'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        TeacherClassLogger.network('Teste de autenticação com token', {
          'statusCode': authResponse.statusCode,
          'url': '${ApiConfig.baseUrl}/classes',
          'body': authResponse.body,
          'hasToken': true,
          'tokenLength': token.length,
          'tokenPreview': token.substring(0, 20),
        });
      } else {
        TeacherClassLogger.network('Teste de autenticação sem token', {
          'hasToken': false,
          'url': '${ApiConfig.baseUrl}/classes',
        });
      }
    } catch (e) {
      TeacherClassLogger.network('Falha no teste de autenticação', {
        'error': e.toString(),
        'url': '${ApiConfig.baseUrl}/classes',
      });
    }

    // Teste de todas as rotas necessárias
    await _testAllRequiredRoutes();
  }

  // Método para testar todas as rotas necessárias
  Future<void> _testAllRequiredRoutes() async {
    TeacherClassLogger.network('Testando todas as rotas necessárias');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.user?.token;
    final headers =
        token != null
            ? {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            }
            : {'Content-Type': 'application/json'};

    final routesToTest = [
      '/teachers',
      '/students',
      '/grade-periods',
      '/grade-types',
      '/subjects',
      '/classes',
      '/attendances',
      '/grades',
      '/assignments',
    ];

    for (final route in routesToTest) {
      try {
        TeacherClassLogger.network('Testando rota: $route');
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}$route'),
          headers: headers,
        );

        TeacherClassLogger.network('Resposta da rota $route', {
          'statusCode': response.statusCode,
          'url': '${ApiConfig.baseUrl}$route',
          'hasData': response.body.isNotEmpty,
          'bodyPreview':
              response.body.length > 100
                  ? '${response.body.substring(0, 100)}...'
                  : response.body,
        });
      } catch (e) {
        TeacherClassLogger.network('Falha na rota $route', {
          'error': e.toString(),
          'url': '${ApiConfig.baseUrl}$route',
        });
      }
    }
  }

  Future<void> _fetchSubjects() async {
    TeacherClassLogger.info('Iniciando busca por disciplinas do professor');

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final teacherId = authProvider.user?.teacher?.id;

      if (teacherId == null) {
        TeacherClassLogger.error(
          'Professor não encontrado no contexto de autenticação',
        );
        throw Exception('Professor não encontrado');
      }

      // Log detalhado da configuração
      TeacherClassLogger.debug('Configuração da requisição', {
        'teacherId': teacherId,
        'classId': widget.classData['id'],
        'hasToken': authProvider.user?.token != null,
        'tokenLength': authProvider.user?.token?.length ?? 0,
        'tokenPreview': authProvider.user?.token?.substring(0, 20) ?? 'N/A',
        'baseUrl': ApiConfig.baseUrl,
        'fullUrl': '${ApiConfig.baseUrl}/classes',
      });

      TeacherClassLogger.api('/classes', 'GET', {
        'classId': widget.classData['id'],
        'teacherId': teacherId,
      });

      // SOLUÇÃO: Usar a rota /classes que sabemos que funciona
      TeacherClassLogger.info(
        'Usando rota /classes que retorna todos os dados',
      );
      try {
        final classesResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/classes'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${authProvider.user?.token}',
          },
        );

        if (classesResponse.statusCode == 200) {
          final classesData = json.decode(classesResponse.body) as List;

          // Encontrar a turma específica
          final classData = classesData.firstWhere(
            (classItem) => classItem['id'] == widget.classData['id'],
            orElse: () => null,
          );

          if (classData != null && classData['subjects'] != null) {
            // Filtrar disciplinas do professor atual
            final teacherSubjects =
                (classData['subjects'] as List)
                    .where((subject) => subject['teacherId'] == teacherId)
                    .cast<Map<String, dynamic>>()
                    .toList();

            TeacherClassLogger.success('Disciplinas encontradas via /classes');
            TeacherClassLogger.debug('Dados da turma', {
              'className': classData['name'],
              'totalSubjects': classData['subjects'].length,
              'teacherSubjects': teacherSubjects.length,
            });

            if (teacherSubjects.isNotEmpty) {
              setState(() {
                _subjects = teacherSubjects;
                _selectedSubjectId = teacherSubjects.first['id'];
              });

              TeacherClassLogger.success('Disciplinas carregadas com sucesso');
              TeacherClassLogger.debug('Total de disciplinas', {
                'count': teacherSubjects.length,
              });

              // Também carregar alunos da turma
              if (classData['enrollments'] != null) {
                final students =
                    (classData['enrollments'] as List)
                        .map((enrollment) => enrollment['student'])
                        .cast<Map<String, dynamic>>()
                        .toList();

                setState(() {
                  _students = students;
                  // Inicializa o mapa de presença
                  _attendanceMap = Map.fromEntries(
                    students.map((student) => MapEntry(student['id'], null)),
                  );
                  _justificationMap = Map.fromEntries(
                    students.map((student) => MapEntry(student['id'], '')),
                  );
                });

                TeacherClassLogger.success('Alunos carregados via /classes');
                TeacherClassLogger.debug('Total de alunos', {
                  'count': students.length,
                });
              }

              // Carregar outras informações necessárias usando rotas diretas
              _fetchPeriodsFromAPI();
              _fetchGradeTypesFromAPI();

              // Carregar alunos também (já temos os dados, mas precisamos inicializar mapas)
              _fetchStudents();

              return; // Sucesso, não precisa continuar
            }
          }
        }

        TeacherClassLogger.warning(
          'Rota /classes não retornou dados da turma específica',
        );
      } catch (e) {
        TeacherClassLogger.error('Falha na rota /classes', e);
      }

      // Fallback: tentar o serviço original
      TeacherClassLogger.info('Tentando fallback com TeacherService');
      try {
        final subjects = await TeacherService.getSubjectsByClassIdAndTeacher(
          widget.classData['id'],
          teacherId,
          token: authProvider.user?.token,
        );

        TeacherClassLogger.success('Disciplinas carregadas com sucesso');
        TeacherClassLogger.debug('Disciplinas encontradas', {
          'count': subjects.length,
          'subjects':
              subjects.map((s) => {'id': s['id'], 'name': s['name']}).toList(),
        });

        setState(() {
          _subjects = subjects;
          if (subjects.isNotEmpty) {
            _selectedSubjectId = subjects.first['id'];
          }
        });

        if (_selectedSubjectId != null) {
          TeacherClassLogger.info(
            'Disciplina selecionada automaticamente: $_selectedSubjectId',
          );
          _fetchAssignments();

          // Se estiver na aba de chamada, carregar frequência automaticamente
          if (_tabController.index == 1) {
            TeacherClassLogger.info(
              'Aba de chamada detectada, carregando frequência automaticamente...',
            );
            _loadAttendance();
          }
        } else {
          TeacherClassLogger.warning(
            'Nenhuma disciplina encontrada para o professor nesta turma',
          );
        }
      } catch (e) {
        TeacherClassLogger.error('Erro no TeacherService', e);
      }
    } catch (e, stackTrace) {
      TeacherClassLogger.error('Erro ao carregar disciplinas', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar disciplinas: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _fetchStudents() async {
    TeacherClassLogger.info('Iniciando busca por alunos da turma');

    // Se já temos alunos carregados, apenas inicializar mapas
    if (_students.isNotEmpty) {
      TeacherClassLogger.info(
        'Alunos já carregados, inicializando mapas de presença',
      );

      TeacherClassLogger.debug('Alunos disponíveis', {
        'count': _students.length,
        'students':
            _students.map((s) => {'id': s['id'], 'name': s['name']}).toList(),
      });

      setState(() {
        // Inicializa o mapa de presença com valores nulos (não marcado)
        _attendanceMap = Map.fromEntries(
          _students.map((student) => MapEntry(student['id'], null)),
        );
        // Inicializa o mapa de justificativas vazio
        _justificationMap = Map.fromEntries(
          _students.map((student) => MapEntry(student['id'], '')),
        );
      });

      TeacherClassLogger.success(
        'Mapas de presença inicializados com alunos existentes',
      );
      TeacherClassLogger.debug('Mapas inicializados', {
        'attendanceMapKeys': _attendanceMap.keys.length,
        'justificationMapKeys': _justificationMap.keys.length,
      });
      return;
    }

    try {
      TeacherClassLogger.debug('Parâmetros para busca de alunos', {
        'classId': widget.classData['id'],
        'baseUrl': ApiConfig.baseUrl,
      });

      final students = await TeacherService.getClassStudents(
        widget.classData['id'],
      );

      TeacherClassLogger.success('Alunos carregados com sucesso');
      TeacherClassLogger.debug('Alunos encontrados', {
        'count': students.length,
        'classId': widget.classData['id'],
      });

      setState(() {
        _students = students;
        // Inicializa o mapa de presença com valores nulos (não marcado)
        _attendanceMap = Map.fromEntries(
          students.map((student) => MapEntry(student['id'], null)),
        );
        // Inicializa o mapa de justificativas vazio
        _justificationMap = Map.fromEntries(
          students.map((student) => MapEntry(student['id'], '')),
        );
      });

      TeacherClassLogger.debug('Mapas de presença inicializados', {
        'attendanceMapKeys': _attendanceMap.keys.length,
        'justificationMapKeys': _justificationMap.keys.length,
      });
    } catch (e, stackTrace) {
      TeacherClassLogger.error('Erro ao carregar alunos', e, stackTrace);
    }
  }

  Future<void> _fetchPeriods() async {
    TeacherClassLogger.info('Iniciando busca por períodos de avaliação');

    // Se já temos períodos carregados, não fazer nada
    if (_periods.isNotEmpty) {
      TeacherClassLogger.info('Períodos já carregados, pulando busca');
      return;
    }

    try {
      TeacherClassLogger.debug('Parâmetros para busca de períodos', {
        'baseUrl': ApiConfig.baseUrl,
        'endpoint': '/grade-periods',
      });

      final periods = await GradePeriodService.getAllGradePeriods();

      TeacherClassLogger.success('Períodos carregados com sucesso');
      TeacherClassLogger.debug('Períodos encontrados', {
        'count': periods.length,
        'periods':
            periods.map((p) => {'id': p['id'], 'name': p['name']}).toList(),
      });

      setState(() {
        _periods = periods;
        if (periods.isNotEmpty && _selectedPeriodId == null) {
          _selectedPeriodId = periods.first['id'];
        }
      });
    } catch (e, stackTrace) {
      TeacherClassLogger.error('Erro ao carregar períodos', e, stackTrace);
    }
  }

  Future<void> _fetchGradeTypes() async {
    TeacherClassLogger.info('Iniciando busca por tipos de nota');

    // Se já temos tipos de nota carregados, não fazer nada
    if (_gradeTypes.isNotEmpty) {
      TeacherClassLogger.info('Tipos de nota já carregados, pulando busca');
      return;
    }

    try {
      TeacherClassLogger.debug('Parâmetros para busca de tipos de nota', {
        'baseUrl': ApiConfig.baseUrl,
        'endpoint': '/grade-types',
      });

      final types = await GradeTypeService.getAllGradeTypes();

      TeacherClassLogger.success('Tipos de nota carregados com sucesso');
      TeacherClassLogger.debug('Tipos encontrados', {
        'count': types.length,
        'types':
            types
                .map(
                  (t) => {
                    'id': t['id'],
                    'name': t['name'],
                    'isConcept': t['isConcept'],
                  },
                )
                .toList(),
      });

      setState(() {
        _gradeTypes = types;
      });
    } catch (e, stackTrace) {
      TeacherClassLogger.error('Erro ao carregar tipos de nota', e, stackTrace);
    }
  }

  // Método para buscar períodos diretamente da API
  Future<void> _fetchPeriodsFromAPI() async {
    if (_periods.isNotEmpty) {
      TeacherClassLogger.info('Períodos já carregados, pulando busca');
      return;
    }

    TeacherClassLogger.info('Buscando períodos diretamente da API');

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/grade-periods'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.user?.token}',
        },
      );

      if (response.statusCode == 200) {
        final periods = json.decode(response.body) as List;
        setState(() {
          _periods = periods.cast<Map<String, dynamic>>();
          if (_periods.isNotEmpty && _selectedPeriodId == null) {
            _selectedPeriodId = _periods.first['id'];
          }
        });

        TeacherClassLogger.success('Períodos carregados via API direta');
        TeacherClassLogger.debug('Períodos encontrados', {
          'count': periods.length,
        });
      } else {
        TeacherClassLogger.warning(
          'API retornou status ${response.statusCode}',
        );
        // Criar períodos padrão se necessário
        setState(() {
          _periods = [];
        });
      }
    } catch (e) {
      TeacherClassLogger.error('Erro ao buscar períodos via API', e);
      setState(() {
        _periods = [];
      });
    }
  }

  // Método para buscar tipos de nota diretamente da API
  Future<void> _fetchGradeTypesFromAPI() async {
    if (_gradeTypes.isNotEmpty) {
      TeacherClassLogger.info('Tipos de nota já carregados, pulando busca');
      return;
    }

    TeacherClassLogger.info('Buscando tipos de nota diretamente da API');

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/grade-types'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.user?.token}',
        },
      );

      if (response.statusCode == 200) {
        final types = json.decode(response.body) as List;
        setState(() {
          _gradeTypes = types.cast<Map<String, dynamic>>();
        });

        TeacherClassLogger.success('Tipos de nota carregados via API direta');
        TeacherClassLogger.debug('Tipos encontrados', {'count': types.length});
      } else {
        TeacherClassLogger.warning(
          'API retornou status ${response.statusCode}',
        );
        // Criar tipos padrão se necessário
        setState(() {
          _gradeTypes = [];
        });
      }
    } catch (e) {
      TeacherClassLogger.error('Erro ao buscar tipos via API', e);
      setState(() {
        _gradeTypes = [];
      });
    }
  }

  Future<void> _fetchGrades() async {
    if (_selectedSubjectId == null) {
      TeacherClassLogger.warning(
        'Tentativa de buscar notas sem disciplina selecionada',
      );
      return;
    }

    TeacherClassLogger.info('Iniciando busca por notas da disciplina');
    TeacherClassLogger.debug('Parâmetros da busca', {
      'subjectId': _selectedSubjectId,
      'periodId': _selectedPeriodId,
    });

    setState(() {
      _loadingGrades = true;
      _errorGrades = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final grades = await GradeService.getGradesBySubject(
        _selectedSubjectId!,
        authProvider.user?.token,
      );

      TeacherClassLogger.success('Notas carregadas com sucesso');
      TeacherClassLogger.debug('Notas encontradas', {
        'count': grades.length,
        'subjectId': _selectedSubjectId,
      });

      setState(() {
        _grades = grades;
      });
    } catch (e, stackTrace) {
      TeacherClassLogger.error('Erro ao carregar notas', e, stackTrace);
      setState(() {
        _errorGrades = e.toString();
      });
    } finally {
      setState(() {
        _loadingGrades = false;
      });
    }
  }

  Future<void> _fetchAssignments() async {
    if (_selectedSubjectId == null) {
      TeacherClassLogger.warning(
        'Tentativa de buscar atividades sem disciplina selecionada',
      );
      return;
    }

    TeacherClassLogger.info('Iniciando busca por atividades da disciplina');
    TeacherClassLogger.debug('Parâmetros da busca', {
      'classId': widget.classData['id'],
      'subjectId': _selectedSubjectId,
    });

    setState(() {
      _loadingAssignments = true;
      _errorAssignments = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.user?.token;

      final assignments = await AssignmentService.getAssignmentsByClassAndSubject(
        widget.classData['id'],
        _selectedSubjectId!,
        token,
      );

      setState(() {
        _assignments = assignments;
      });

      TeacherClassLogger.success('Atividades carregadas com sucesso');
      TeacherClassLogger.debug('Atividades encontradas', {
        'count': assignments.length,
        'subjectId': _selectedSubjectId,
      });
    } catch (e, stackTrace) {
      TeacherClassLogger.error('Erro ao carregar atividades', e, stackTrace);
      setState(() {
        _errorAssignments = e.toString();
      });
    } finally {
      setState(() {
        _loadingAssignments = false;
      });
    }
  }

  Future<void> _loadAttendance({bool force = false}) async {
    if (_selectedSubjectId == null) {
      TeacherClassLogger.warning(
        'Tentativa de carregar frequência sem disciplina selecionada',
      );
      return;
    }

    if (!force && _loadingAttendance) {
      TeacherClassLogger.info(
        'Carregamento de frequência já em andamento, pulando...',
      );
      return;
    }

    TeacherClassLogger.info('Iniciando carregamento de frequência');
    TeacherClassLogger.debug('Parâmetros da frequência', {
      'subjectId': _selectedSubjectId,
      'selectedDate': _selectedDate.toIso8601String(),
      'classId': widget.classData['id'],
    });

    setState(() {
      _loadingAttendance = true;
      _errorAttendance = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final teacherId = authProvider.user?.teacher?.id;

      if (teacherId == null) {
        TeacherClassLogger.error(
          'Professor não encontrado no contexto de autenticação',
        );
        throw Exception('Professor não encontrado');
      }

      TeacherClassLogger.api('/lessons/get-or-create', 'POST', {
        'classId': widget.classData['id'],
        'subjectId': _selectedSubjectId!,
        'teacherId': teacherId,
        'date': _selectedDate.toIso8601String(),
      });

      final token = authProvider.user?.token;
      final lesson = await AttendanceService.getOrCreateLesson(
        classId: widget.classData['id'],
        subjectId: _selectedSubjectId!,
        teacherId: teacherId,
        date: _selectedDate,
        token: token,
      );

      TeacherClassLogger.success('Aula encontrada/criada com sucesso');
      TeacherClassLogger.debug('Dados da aula', {
        'lessonId': lesson['id'],
        'date': lesson['date'],
        'subjectId': lesson['subjectId'],
      });

      setState(() {
        _currentLesson = lesson;
      });

      final attendances = await AttendanceService.getAttendanceByLesson(
        lesson['id'],
        token,
      );

      TeacherClassLogger.debug('Frequências encontradas', {
        'count': attendances.length,
        'lessonId': lesson['id'],
      });

      // Inicializa os mapas de presença e justificativa sem valores marcados
      final newAttendanceMap = <String, String?>{};
      final newJustificationMap = <String, String>{};

      // Por padrão, todos os alunos começam sem marcação
      for (var student in _students) {
        newAttendanceMap[student['id']] = null;
        newJustificationMap[student['id']] = '';
      }

      // Sobrescreve com os dados existentes da API
      for (var attendance in attendances) {
        final studentId = attendance['studentId'];
        // Determinar status baseado nos novos campos ou compatibilidade
        String? status = attendance['status'];
        if (status == null) {
          final present = attendance['present'];
          status = present == true ? 'PRESENT' : 'ABSENT';
        }
        newAttendanceMap[studentId] = status;
        newJustificationMap[studentId] = attendance['justification'] ?? '';
      }

      setState(() {
        _attendanceMap = newAttendanceMap;
        _justificationMap = newJustificationMap;
      });

      TeacherClassLogger.debug('Mapas de frequência atualizados', {
        'attendanceMap': _attendanceMap,
        'justificationMap': _justificationMap,
      });
    } catch (e, stackTrace) {
      TeacherClassLogger.error('Erro ao carregar frequência', e, stackTrace);
      setState(() {
        _errorAttendance = 'Erro ao carregar chamada: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar chamada: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _loadingAttendance = false;
      });
    }
  }

  Future<void> _saveAttendance() async {
    if (_currentLesson == null) {
      TeacherClassLogger.warning(
        'Tentativa de salvar frequência sem aula selecionada',
      );
      return;
    }

    TeacherClassLogger.info('Iniciando salvamento de frequência');
    TeacherClassLogger.debug('Dados para salvamento', {
      'lessonId': _currentLesson!['id'],
      'attendanceMap': _attendanceMap,
      'studentsCount': _students.length,
    });

    setState(() {
      _loadingAttendance = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.user?.token;

      // Prepara a lista de presenças
      final presences =
          _students
              .map((student) {
                final studentId = student['id'];
                final status = _attendanceMap[studentId];
                final justification = _justificationMap[studentId] ?? '';

                // Só inclui alunos que têm status marcado
                if (status == null) {
                  return null; // Será filtrado depois
                }

                TeacherClassLogger.debug('Preparando presença do aluno', {
                  'studentName': student['name'],
                  'studentId': studentId,
                  'status': status,
                  'justification': justification,
                });

                return {
                  'studentId': studentId,
                  'status': status,
                  'justification':
                      status == 'JUSTIFIED_ABSENT' ? justification : null,
                  // Manter compatibilidade com campo antigo
                  'present': status == 'PRESENT',
                };
              })
              .where((element) => element != null)
              .cast<Map<String, dynamic>>()
              .toList();

      TeacherClassLogger.debug('Lista de presenças preparada', {
        'totalPresences': presences.length,
        'presences': presences,
      });

      TeacherClassLogger.api('/attendances/bulk', 'POST', {
        'lessonId': _currentLesson!['id'],
        'presences': presences,
      });

      await AttendanceService.markAttendanceByLesson(
        lessonId: _currentLesson!['id'],
        presences: presences,
        token: token,
      );

      TeacherClassLogger.success('Frequência salva com sucesso!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Frequência salva com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Recarrega a frequência salva no servidor
      await _loadAttendance(force: true);
    } catch (e, stackTrace) {
      TeacherClassLogger.error('Erro ao salvar frequência', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar frequência: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Tentar novamente',
              textColor: Colors.white,
              onPressed: _saveAttendance,
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _loadingAttendance = false;
      });
    }
  }

  void _onSubjectChanged(String? subjectId) {
    TeacherClassLogger.info('Disciplina alterada');
    TeacherClassLogger.debug('Mudança de disciplina', {
      'oldSubjectId': _selectedSubjectId,
      'newSubjectId': subjectId,
      'currentTab': _tabController.index,
    });

    setState(() {
      _selectedSubjectId = subjectId;
      _currentLesson = null;
      // Não limpa o mapa de presença aqui, deixa a função _loadAttendance fazer isso
    });

    if (subjectId != null) {
      if (_tabController.index == 0) {
        TeacherClassLogger.info(
          'Carregando atividades para nova disciplina...',
        );
        _fetchAssignments();
      } else if (_tabController.index == 1) {
        TeacherClassLogger.info(
          'Carregando frequência para nova disciplina...',
        );
        _loadAttendance();
      } else if (_tabController.index == 2) {
        TeacherClassLogger.info('Carregando notas para nova disciplina...');
        _fetchGrades();
      }
    }
  }

  void _onDateChanged() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      TeacherClassLogger.info('Data alterada');
      TeacherClassLogger.debug('Mudança de data', {
        'oldDate': _selectedDate.toIso8601String(),
        'newDate': date.toIso8601String(),
        'subjectId': _selectedSubjectId,
      });

      setState(() {
        _selectedDate = date;
        _currentLesson = null;
        // Não limpa o mapa de presença aqui, deixa a função _loadAttendance fazer isso
      });

      if (_selectedSubjectId != null) {
        TeacherClassLogger.info('Recarregando frequência para nova data...');
        _loadAttendance();
      }
    }
  }

  Future<void> _deleteAssignment(String assignmentId) async {
    TeacherClassLogger.info('Iniciando exclusão de atividade');
    TeacherClassLogger.debug('Dados da exclusão', {
      'assignmentId': assignmentId,
      'assignmentsCount': _assignments.length,
    });

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Excluir Atividade'),
            content: const Text(
              'Tem certeza que deseja excluir esta atividade?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      TeacherClassLogger.info('Confirmação recebida, excluindo atividade...');

      setState(() => _loadingAssignments = true);
      try {
        await AssignmentService.deleteAssignment(assignmentId);

        TeacherClassLogger.success('Atividade excluída com sucesso');

        await _fetchAssignments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Atividade excluída com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e, stackTrace) {
        TeacherClassLogger.error('Erro ao excluir atividade', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _loadingAssignments = false);
      }
    } else {
      TeacherClassLogger.info('Exclusão cancelada pelo usuário');
    }
  }

  void _showAddAssignmentDialog() async {
    if (_selectedSubjectId == null) {
      TeacherClassLogger.warning(
        'Tentativa de criar atividade sem disciplina selecionada',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione uma disciplina antes de criar uma atividade',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    TeacherClassLogger.info('Abrindo diálogo para criar nova atividade');
    TeacherClassLogger.debug('Parâmetros para nova atividade', {
      'classId': widget.classData['id'],
      'subjectId': _selectedSubjectId!,
    });

    final result = await showDialog(
      context: context,
      builder:
          (context) => AddAssignmentDialog(
            classId: widget.classData['id'],
            subjectId: _selectedSubjectId!,
          ),
    );

    if (result == true) {
      TeacherClassLogger.info('Nova atividade criada, recarregando lista...');
      _fetchAssignments();
    } else {
      TeacherClassLogger.info('Criação de atividade cancelada');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet =
        MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 1200;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Turma - ${widget.classData['name'] ?? ''}',
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2953A5),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: isMobile, // Permite scroll horizontal em telas pequenas
          tabs: [
            Tab(
              text: isMobile ? 'Ativ.' : 'Atividades',
              icon: const Icon(Icons.assignment),
            ),
            Tab(
              text: isMobile ? 'Cham.' : 'Chamadas',
              icon: const Icon(Icons.how_to_reg),
            ),
            Tab(
              text: isMobile ? 'Notas' : 'Notas',
              icon: const Icon(Icons.grade),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Seletor de disciplinas (se há múltiplas)
          if (_subjects.length > 1)
            Container(
              padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
              color: Colors.grey.shade100,
              child:
                  isMobile
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Disciplina:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedSubjectId,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items:
                                _subjects.map((subject) {
                                  return DropdownMenuItem<String>(
                                    value: subject['id'],
                                    child: Text(
                                      subject['name'] ?? 'Disciplina',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                            onChanged: _onSubjectChanged,
                          ),
                        ],
                      )
                      : Row(
                        children: [
                          const Text(
                            'Disciplina:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedSubjectId,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items:
                                  _subjects.map((subject) {
                                    return DropdownMenuItem<String>(
                                      value: subject['id'],
                                      child: Text(
                                        subject['name'] ?? 'Disciplina',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                              onChanged: _onSubjectChanged,
                            ),
                          ),
                        ],
                      ),
            ),

          // Conteúdo das abas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAssignmentsTab(isMobile: isMobile, isTablet: isTablet),
                _buildAttendanceTab(isMobile: isMobile, isTablet: isTablet),
                _buildGradesTab(isMobile: isMobile, isTablet: isTablet),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsTab({bool isMobile = false, bool isTablet = false}) {
    if (_selectedSubjectId == null) {
      return const Center(
        child: Text('Selecione uma disciplina para ver as atividades'),
      );
    }

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Stack(
        children: [
          _loadingAssignments
              ? const Center(child: CircularProgressIndicator())
              : _errorAssignments != null
              ? Center(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                  child: Text(
                    _errorAssignments!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              : _assignments.isEmpty
              ? const Center(child: Text('Nenhuma atividade cadastrada.'))
              : ListView.separated(
                itemCount: _assignments.length,
                separatorBuilder:
                    (_, __) => SizedBox(height: isMobile ? 12 : 16),
                itemBuilder: (context, index) {
                  final assignment = _assignments[index];
                  final desc = assignment['description'] ?? '';
                  final parts = desc.split('\n');
                  final nome =
                      parts.isNotEmpty && parts[0].trim().isNotEmpty
                          ? parts[0]
                          : 'Sem nome';
                  final descricao =
                      parts.length > 1 ? parts.sublist(1).join('\n') : '';
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                    ),
                    elevation: isMobile ? 2 : 3,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
                      title: Text(
                        nome,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (descricao.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(
                                top: isMobile ? 4.0 : 8.0,
                              ),
                              child: Text(
                                descricao,
                                style: TextStyle(fontSize: isMobile ? 14 : 16),
                              ),
                            ),
                          if (assignment['dueDate'] != null)
                            Padding(
                              padding: EdgeInsets.only(
                                top: isMobile ? 4.0 : 8.0,
                              ),
                              child: Text(
                                'Entrega até: ${assignment['dueDate'] != null ? assignment['dueDate'].toString().split('T').first : ''}',
                                style: TextStyle(
                                  fontSize: isMobile ? 12 : 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          if (assignment['fileUrl'] != null &&
                              assignment['fileUrl'].toString().isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(
                                top: isMobile ? 8.0 : 12.0,
                              ),
                              child: TextButton.icon(
                                icon: Icon(
                                  Icons.attach_file,
                                  size: isMobile ? 18 : 20,
                                ),
                                label: Text(
                                  'Baixar Anexo',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                ),
                                onPressed: () async {
                                  final fileUrl = assignment['fileUrl'];
                                  final url = '${ApiConfig.baseUrl}$fileUrl';
                                  final uri = Uri.parse(url);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Não foi possível abrir o arquivo',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: isMobile ? 20 : 24,
                        ),
                        tooltip: 'Excluir atividade',
                        onPressed: () => _deleteAssignment(assignment['id']),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => TaskSubmissionsScreen(
                                  assignment: assignment,
                                  students: _students,
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
          Positioned(
            bottom: isMobile ? 16 : 24,
            right: isMobile ? 16 : 24,
            child: FloatingActionButton(
              backgroundColor: Colors.orange,
              onPressed: _showAddAssignmentDialog,
              child: Icon(
                Icons.add,
                size: isMobile ? 24 : 32,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab({bool isMobile = false, bool isTablet = false}) {
    if (_selectedSubjectId == null) {
      return const Center(
        child: Text('Selecione uma disciplina para fazer a chamada'),
      );
    }

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seletor de Data
          Card(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
              child:
                  isMobile
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data da aula:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _onDateChanged,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_selectedDate),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _selectedSubjectId != null
                                      ? _loadAttendance
                                      : null,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Carregar Chamada'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2953A5),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                      : Row(
                        children: [
                          const Text(
                            'Data da aula:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          InkWell(
                            onTap: _onDateChanged,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_selectedDate),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed:
                                _selectedSubjectId != null
                                    ? _loadAttendance
                                    : null,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Carregar Chamada'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2953A5),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),

          // Lista de Alunos
          Expanded(
            child: _buildStudentsList(isMobile: isMobile, isTablet: isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList({bool isMobile = false, bool isTablet = false}) {
    if (_loadingAttendance) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorAttendance != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorAttendance!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAttendance,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_students.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum aluno encontrado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Esta turma não possui alunos matriculados.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          // Header da lista
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: const BoxDecoration(
              color: Color(0xFF2953A5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child:
                isMobile
                    ? Column(
                      children: [
                        Text(
                          'Aluno (${_students.length})',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Presente',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 10 : 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Falta',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 10 : 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'F. Justif.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 10 : 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                    : Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Aluno (${_students.length})',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Presente',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Falta',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'F. Justif.',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
          ),

          // Lista de alunos
          Expanded(
            child:
                _students.isEmpty
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Nenhum aluno encontrado',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        // Log para debug
                        if (index == 0) {
                          TeacherClassLogger.debug(
                            'Renderizando lista de alunos',
                            {
                              'totalStudents': _students.length,
                              'firstStudent':
                                  _students.isNotEmpty
                                      ? _students[0]['name']
                                      : 'N/A',
                            },
                          );
                        }

                        final student = _students[index];
                        final studentId = student['id'];
                        final currentStatus = _attendanceMap[studentId];

                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // Avatar e nome do aluno
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: const Color(
                                              0xFF2953A5,
                                            ),
                                            child: Text(
                                              student['name']
                                                      ?.substring(0, 1)
                                                      .toUpperCase() ??
                                                  'A',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  student['name'] ?? 'Aluno',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (student['registrationNumber'] !=
                                                    null)
                                                  Text(
                                                    'Mat: ${student['registrationNumber']}',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.visibility),
                                            tooltip: 'Ver detalhes do aluno',
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) {
                                                    final authProvider =
                                                        Provider.of<
                                                          AuthProvider
                                                        >(
                                                          context,
                                                          listen: false,
                                                        );
                                                    final teacherId =
                                                        authProvider
                                                            .user
                                                            ?.teacher
                                                            ?.id;

                                                    if (teacherId == null) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Erro: Professor não encontrado',
                                                          ),
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                      );
                                                      return const SizedBox.shrink();
                                                    }

                                                    return TeacherStudentDetailScreen(
                                                      student: student,
                                                      classData:
                                                          widget.classData,
                                                      subjectId:
                                                          _selectedSubjectId!,
                                                      teacherId: teacherId,
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Radio button Presente
                                    Expanded(
                                      flex: 1,
                                      child: Center(
                                        child: Radio<String>(
                                          value: 'PRESENT',
                                          groupValue: currentStatus,
                                          onChanged: (String? value) {
                                            if (value != null) {
                                              setState(() {
                                                _attendanceMap[studentId] =
                                                    value;
                                                _justificationMap[studentId] =
                                                    ''; // Limpa justificativa
                                              });
                                            }
                                          },
                                          activeColor: Colors.green,
                                        ),
                                      ),
                                    ),

                                    // Radio button Falta
                                    Expanded(
                                      flex: 1,
                                      child: Center(
                                        child: Radio<String>(
                                          value: 'ABSENT',
                                          groupValue: currentStatus,
                                          onChanged: (String? value) {
                                            if (value != null) {
                                              setState(() {
                                                _attendanceMap[studentId] =
                                                    value;
                                                _justificationMap[studentId] =
                                                    ''; // Limpa justificativa
                                              });
                                            }
                                          },
                                          activeColor: Colors.red,
                                        ),
                                      ),
                                    ),

                                    // Radio button Falta Justificada
                                    Expanded(
                                      flex: 1,
                                      child: Center(
                                        child: Radio<String>(
                                          value: 'JUSTIFIED_ABSENT',
                                          groupValue: currentStatus,
                                          onChanged: (String? value) {
                                            if (value != null) {
                                              setState(() {
                                                _attendanceMap[studentId] =
                                                    value;
                                              });
                                              // Mostrar dialog para justificativa
                                              _showJustificationDialog(
                                                studentId,
                                                student['name'],
                                              );
                                            }
                                          },
                                          activeColor: Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Mostrar justificativa se houver
                                if (currentStatus == 'JUSTIFIED_ABSENT' &&
                                    _justificationMap[studentId]?.isNotEmpty ==
                                        true) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withAlpha(20),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.orange.withAlpha(80),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.assignment_late,
                                          size: 16,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Justificativa: ${_justificationMap[studentId]}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 16,
                                          ),
                                          onPressed:
                                              () => _showJustificationDialog(
                                                studentId,
                                                student['name'],
                                              ),
                                          color: Colors.orange,
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),

          // Botões de ação
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child:
                isMobile
                    ? Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    for (var student in _students) {
                                      _attendanceMap[student['id']] = 'PRESENT';
                                      _justificationMap[student['id']] = '';
                                    }
                                  });
                                },
                                icon: const Icon(Icons.check_circle, size: 18),
                                label: Text(
                                  'Todos Presentes',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    for (var student in _students) {
                                      _attendanceMap[student['id']] = 'ABSENT';
                                      _justificationMap[student['id']] = '';
                                    }
                                  });
                                },
                                icon: const Icon(Icons.cancel, size: 18),
                                label: Text(
                                  'Todos Ausentes',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _loadingAttendance ? null : _saveAttendance,
                            icon:
                                _loadingAttendance
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.save),
                            label: const Text('Salvar Chamada'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2953A5),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              for (var student in _students) {
                                _attendanceMap[student['id']] = 'PRESENT';
                                _justificationMap[student['id']] = '';
                              }
                            });
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Todos Presentes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              for (var student in _students) {
                                _attendanceMap[student['id']] = 'ABSENT';
                                _justificationMap[student['id']] = '';
                              }
                            });
                          },
                          icon: const Icon(Icons.cancel),
                          label: const Text('Todos Ausentes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed:
                              _loadingAttendance ? null : _saveAttendance,
                          icon:
                              _loadingAttendance
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.save),
                          label: const Text('Salvar Chamada'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2953A5),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradesTab({bool isMobile = false, bool isTablet = false}) {
    if (_selectedSubjectId == null) {
      return const Center(
        child: Text('Selecione uma disciplina para gerenciar notas'),
      );
    }

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seletor de Período
          Card(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
              child:
                  isMobile
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _selectedPeriodId,
                            decoration: const InputDecoration(
                              labelText: 'Período',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                _periods.map((period) {
                                  return DropdownMenuItem<String>(
                                    value: period['id'],
                                    child: Text(period['name'] ?? 'Período'),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPeriodId = value;
                              });
                              _fetchGrades();
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _selectedPeriodId != null
                                      ? _fetchGrades
                                      : null,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Atualizar Notas'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2953A5),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                      : Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedPeriodId,
                              decoration: const InputDecoration(
                                labelText: 'Período',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  _periods.map((period) {
                                    return DropdownMenuItem<String>(
                                      value: period['id'],
                                      child: Text(period['name'] ?? 'Período'),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPeriodId = value;
                                });
                                _fetchGrades();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed:
                                _selectedPeriodId != null ? _fetchGrades : null,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Atualizar Notas'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2953A5),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),

          // Tabela de Notas
          Expanded(
            child: _buildGradesList(isMobile: isMobile, isTablet: isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildGradesList({bool isMobile = false, bool isTablet = false}) {
    if (_loadingGrades) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorGrades != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorGrades!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchGrades,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_students.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum aluno encontrado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Esta turma não possui alunos matriculados.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Criar mapa de notas por aluno e tipo
    final gradesByStudent = <String, Map<String, Map<String, dynamic>>>{};
    for (var grade in _grades) {
      if (grade['periodId'] == _selectedPeriodId) {
        final studentId = grade['studentId'];
        final typeId = grade['typeId'];

        if (!gradesByStudent.containsKey(studentId)) {
          gradesByStudent[studentId] = {};
        }
        gradesByStudent[studentId]![typeId] = grade;
      }
    }

    return isMobile
        ? _buildMobileGradesList(gradesByStudent)
        : Card(
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF2953A5)),
              columns: [
                const DataColumn(
                  label: Text(
                    'Aluno',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ..._gradeTypes.map(
                  (type) => DataColumn(
                    label: Text(
                      type['name'] ?? 'Tipo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'Média',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              rows:
                  _students.map((student) {
                    final studentId = student['id'];
                    final studentGrades = gradesByStudent[studentId] ?? {};
                    final average = _calculateAverage(studentGrades);

                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF2953A5),
                                child: Text(
                                  student['name']
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      'A',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student['name'] ?? 'Aluno',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (student['registrationNumber'] != null)
                                      Text(
                                        'Mat: ${student['registrationNumber']}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        ..._gradeTypes.map((type) {
                          final grade = studentGrades[type['id']];
                          return DataCell(
                            _buildGradeCell(student, grade, type),
                          );
                        }),
                        // Célula da média
                        DataCell(
                          average != null
                              ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getGradeColor({'value': average}),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  average.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                              : const Text(
                                '-',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        );
  }

  Widget _buildMobileGradesList(
    Map<String, Map<String, Map<String, dynamic>>> gradesByStudent,
  ) {
    return ListView.builder(
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final studentId = student['id'];
        final studentGrades = gradesByStudent[studentId] ?? {};
        final average = _calculateAverage(studentGrades);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header do aluno
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF2953A5),
                      child: Text(
                        student['name']?.substring(0, 1).toUpperCase() ?? 'A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student['name'] ?? 'Aluno',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (student['registrationNumber'] != null)
                            Text(
                              'Mat: ${student['registrationNumber']}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Média
                    if (average != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getGradeColor({'value': average}),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Média',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              average.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notas por tipo
                if (_gradeTypes.isNotEmpty) ...[
                  const Text(
                    'Notas:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF2953A5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _gradeTypes.map((type) {
                          final grade = studentGrades[type['id']];
                          return _buildMobileGradeChip(student, grade, type);
                        }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileGradeChip(
    Map<String, dynamic> student,
    Map<String, dynamic>? grade,
    Map<String, dynamic> type,
  ) {
    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            type['name'] ?? 'Tipo',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2953A5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          if (grade != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getGradeColor(grade),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getGradeDisplayText(grade),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _showGradeDialog(student, grade),
                  child: const Icon(Icons.edit, size: 16, color: Colors.blue),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _deleteGrade(grade['id']),
                  child: const Icon(Icons.delete, size: 16, color: Colors.red),
                ),
              ],
            )
          else
            GestureDetector(
              onTap: () => _showGradeDialog(student, null, typeId: type['id']),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: const Icon(Icons.add, size: 16, color: Colors.green),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGradeCell(
    Map<String, dynamic> student,
    Map<String, dynamic>? grade,
    Map<String, dynamic> type,
  ) {
    if (grade != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getGradeColor(grade),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getGradeDisplayText(grade),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            color: Colors.blue,
            onPressed: () => _showGradeDialog(student, grade),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            color: Colors.red,
            onPressed: () => _deleteGrade(grade['id']),
          ),
        ],
      );
    } else {
      return Center(
        child: IconButton(
          icon: const Icon(Icons.add_circle_outline),
          color: Colors.green,
          onPressed: () => _showGradeDialog(student, null, typeId: type['id']),
        ),
      );
    }
  }

  double? _safeToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  bool _isRecoveryType(String? typeId) {
    if (typeId == null) return false;
    if (typeId == 'RECUPERACAO' || typeId == 'RECUPERACAO_FINAL') {
      return true;
    }
    for (final type in _gradeTypes) {
      if (type['id'] == typeId) {
        return type['isRecovery'] == true;
      }
    }
    return false;
  }

  double? _calculateAverage(Map<String, Map<String, dynamic>> studentGrades) {
    if (studentGrades.isEmpty) return null;

    final regularGrades = <Map<String, dynamic>>[];
    final recoveryGrades = <Map<String, dynamic>>[];

    studentGrades.forEach((typeId, grade) {
      if (_isRecoveryType(typeId)) {
        recoveryGrades.add(grade);
      } else {
        regularGrades.add(grade);
      }
    });

    if (regularGrades.isEmpty) return null;

    var minGrade = regularGrades[0];
    for (var grade in regularGrades.skip(1)) {
      final currentValue = _safeToDouble(grade['value']) ?? 0.0;
      final minValue = _safeToDouble(minGrade['value']) ?? 0.0;
      if (currentValue < minValue) {
        minGrade = grade;
      }
    }

    final finalGrades = List<Map<String, dynamic>>.from(regularGrades);
    final minGradeIndex = finalGrades.indexOf(minGrade);
    final minGradeValue = _safeToDouble(minGrade['value']) ?? 0.0;

    Map<String, dynamic>? bestRecovery;
    for (final grade in recoveryGrades) {
      final value = _safeToDouble(grade['value']);
      if (value == null) continue;
      final bestValue = _safeToDouble(bestRecovery?['value']);
      if (bestRecovery == null || bestValue == null || value > bestValue) {
        bestRecovery = grade;
      }
    }

    if (bestRecovery != null) {
      final recValue = _safeToDouble(bestRecovery['value']) ?? 0.0;
      if (recValue > minGradeValue) {
        finalGrades[minGradeIndex] = {...bestRecovery, 'value': recValue};
      }
    }

    double sum = 0;
    int count = 0;
    for (var grade in finalGrades) {
      final value = _safeToDouble(grade['value']);
      if (value != null) {
        sum += value;
        count++;
      }
    }

    return count > 0 ? sum / count : null;
  }

  Color _getGradeColor(Map<String, dynamic> grade) {
    if (grade['concept'] != null) {
      // Conceito
      final concept = grade['concept'].toString().toUpperCase();
      switch (concept) {
        case 'A':
        case 'MB':
          return Colors.green;
        case 'B':
          return Colors.blue;
        case 'C':
        case 'R':
          return Colors.orange;
        case 'D':
        case 'I':
          return Colors.red;
        default:
          return Colors.grey;
      }
    } else if (grade['value'] != null) {
      // Nota numérica
      final value = _safeToDouble(grade['value']) ?? 0.0;
      if (value >= 8.0) return Colors.green;
      if (value >= 6.0) return Colors.blue;
      if (value >= 4.0) return Colors.orange;
      return Colors.red;
    }
    return Colors.grey;
  }

  String _getGradeDisplayText(Map<String, dynamic> grade) {
    if (grade['concept'] != null) {
      return grade['concept'].toString();
    } else if (grade['value'] != null) {
      final value = _safeToDouble(grade['value']);
      return value?.toStringAsFixed(1) ?? '-';
    }
    return '-';
  }

  void _showGradeDialog(
    Map<String, dynamic> student,
    Map<String, dynamic>? existingGrade, {
    String? typeId,
  }) async {
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma disciplina antes de adicionar a nota.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedPeriodId == null) {
      if (_periods.isEmpty) {
        await _fetchPeriodsFromAPI();
      }
      if (_periods.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nenhum período disponível. Cadastre um período primeiro.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      setState(() {
        _selectedPeriodId = _periods.first['id'];
      });
    }

    final resolvedTypeId =
        typeId ??
        existingGrade?['typeId'] ??
        (existingGrade?['type'] is Map
            ? existingGrade!['type']['id']?.toString()
            : null);

    if (resolvedTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tipo de nota não identificado.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showDialog(
      context: context,
      builder:
          (context) => GradeDialog(
            student: student,
            subjectId: _selectedSubjectId!,
            periodId: _selectedPeriodId!,
            typeId: resolvedTypeId,
            gradeTypes: _gradeTypes,
            existingGrade: existingGrade,
          ),
    );
    if (result == true) {
      _fetchGrades();
    }
  }

  Future<void> _deleteGrade(String gradeId) async {
    TeacherClassLogger.info('Iniciando exclusão de nota');
    TeacherClassLogger.debug('Dados da exclusão', {
      'gradeId': gradeId,
      'selectedSubjectId': _selectedSubjectId,
      'selectedPeriodId': _selectedPeriodId,
    });

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar Exclusão'),
            content: const Text('Tem certeza que deseja excluir esta nota?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      TeacherClassLogger.info('Confirmação recebida, excluindo nota...');
      try {
        TeacherClassLogger.api('/grades/$gradeId', 'DELETE', {
          'gradeId': gradeId,
        });

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await GradeService.deleteGrade(gradeId, authProvider.user?.token);

        TeacherClassLogger.success('Nota excluída com sucesso');

        await _fetchGrades();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nota excluída com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e, stackTrace) {
        TeacherClassLogger.error('Erro ao excluir nota', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir nota: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      TeacherClassLogger.info('Exclusão de nota cancelada pelo usuário');
    }
  }

  // Função para mostrar dialog de justificativa
  void _showJustificationDialog(String studentId, String? studentName) {
    TeacherClassLogger.info('Abrindo diálogo de justificativa');
    TeacherClassLogger.debug('Dados da justificativa', {
      'studentId': studentId,
      'studentName': studentName,
      'currentJustification': _justificationMap[studentId] ?? '',
    });

    final currentJustification = _justificationMap[studentId] ?? '';
    final controller = TextEditingController(text: currentJustification);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Justificar Falta - ${studentName ?? 'Aluno'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Descreva o motivo da falta justificada:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Ex: Atestado médico, compromisso familiar...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                TeacherClassLogger.info('Justificativa cancelada pelo usuário');
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final justification = controller.text.trim();
                if (justification.isNotEmpty) {
                  TeacherClassLogger.info('Justificativa salva com sucesso');
                  TeacherClassLogger.debug('Justificativa salva', {
                    'studentId': studentId,
                    'studentName': studentName,
                    'justification': justification,
                  });

                  setState(() {
                    _justificationMap[studentId] = justification;
                  });
                  Navigator.pop(context);
                } else {
                  TeacherClassLogger.warning(
                    'Tentativa de salvar justificativa vazia',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, informe uma justificativa'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}

// Dialog para duplicar aula

// Dialog para adicionar/editar nota
class GradeDialog extends StatefulWidget {
  final Map<String, dynamic> student;
  final String subjectId;
  final String periodId;
  final String typeId;
  final List<Map<String, dynamic>> gradeTypes;
  final Map<String, dynamic>? existingGrade;

  const GradeDialog({
    super.key,
    required this.student,
    required this.subjectId,
    required this.periodId,
    required this.typeId,
    required this.gradeTypes,
    this.existingGrade,
  });

  @override
  State<GradeDialog> createState() => _GradeDialogState();
}

class _GradeDialogState extends State<GradeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _conceptController = TextEditingController();
  bool _loading = false;
  String? _error;
  late bool _isConcept;

  @override
  void initState() {
    super.initState();

    // Encontrar o tipo de nota selecionado
    final gradeType = widget.gradeTypes.firstWhere(
      (type) => type['id'] == widget.typeId,
      orElse: () => {'isConcept': false},
    );
    _isConcept = gradeType['isConcept'] == true;

    // Preencher campos se editando
    if (widget.existingGrade != null) {
      if (_isConcept && widget.existingGrade!['concept'] != null) {
        _conceptController.text = widget.existingGrade!['concept'];
      } else if (!_isConcept && widget.existingGrade!['value'] != null) {
        _valueController.text = widget.existingGrade!['value'].toString();
      }
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _conceptController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (widget.existingGrade != null) {
        // Atualizar nota existente
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await GradeService.updateGrade(widget.existingGrade!['id'], {
          'value': _isConcept ? null : double.tryParse(_valueController.text),
          'concept': _isConcept ? _conceptController.text : null,
        }, authProvider.user?.token);
      } else {
        // Criar nova nota
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await GradeService.createGrade({
          'studentId': widget.student['id'],
          'subjectId': widget.subjectId,
          'typeId': widget.typeId,
          'periodId': widget.periodId,
          'value': _isConcept ? null : double.tryParse(_valueController.text),
          'concept': _isConcept ? _conceptController.text : null,
        }, authProvider.user?.token);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existingGrade != null
            ? 'Editar Nota - ${widget.student['name']}'
            : 'Nova Nota - ${widget.student['name']}',
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isConcept)
              TextFormField(
                controller: _conceptController,
                decoration: const InputDecoration(
                  labelText: 'Conceito (A, B, C, D, etc.)',
                ),
                validator:
                    (v) => v == null || v.isEmpty ? 'Informe o conceito' : null,
              )
            else
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(labelText: 'Nota (0-10)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe a nota';
                  final value = double.tryParse(v);
                  if (value == null) return 'Nota deve ser um número';
                  if (value < 0 || value > 10) {
                    return 'Nota deve estar entre 0 e 10';
                  }
                  return null;
                },
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child:
              _loading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Salvar'),
        ),
      ],
    );
  }
}

// Diálogo de adicionar atividade
class AddAssignmentDialog extends StatefulWidget {
  final String classId;
  final String subjectId;
  const AddAssignmentDialog({
    super.key,
    required this.classId,
    required this.subjectId,
  });

  @override
  State<AddAssignmentDialog> createState() => _AddAssignmentDialogState();
}

class _AddAssignmentDialogState extends State<AddAssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _dueDate;
  bool _loading = false;
  String? _error;
  String? _fileName;
  Uint8List? _fileBytes;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _fileName = result.files.single.name;
          _fileBytes = result.files.single.bytes;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao selecionar arquivo: $e';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _dueDate == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final dialogContext = context;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.user?.token;

      String? fileUrl;
      if (_fileBytes != null && _fileName != null) {
        fileUrl = await AssignmentService.uploadAssignmentFile(
          bytes: _fileBytes!,
          filename: _fileName!,
          token: token,
        );
      }
      await AssignmentService.createAssignment(
        classId: widget.classId,
        subjectId: widget.subjectId,
        description: '${_nameController.text}\n${_descController.text}',
        dueDate: _dueDate!,
        fileUrl: fileUrl,
        token: token,
      );
      if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova Atividade'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome da Atividade'),
              validator:
                  (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Descrição'),
              validator:
                  (v) => v == null || v.isEmpty ? 'Informe a descrição' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Data de Entrega:'),
                const SizedBox(width: 8),
                Text(
                  _dueDate == null
                      ? 'Selecione'
                      : _dueDate!.toString().split(' ')[0],
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _dueDate = picked);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Anexar Arquivo'),
                ),
                const SizedBox(width: 8),
                if (_fileName != null)
                  Flexible(
                    child: Text(
                      _fileName!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Colors.green),
                    ),
                  ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child:
              _loading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Salvar'),
        ),
      ],
    );
  }
}
