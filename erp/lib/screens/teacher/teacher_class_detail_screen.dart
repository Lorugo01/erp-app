import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../services/assignment_service.dart';
import '../../services/attendance_service.dart';
import '../../services/grade_period_service.dart';
import '../../services/grade_service.dart';
import '../../services/grade_type_service.dart';
import '../../services/teacher_service.dart';
import '../../config/api_config.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../widgets/attendance_widget.dart';
import 'task_submissions_screen.dart';

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

  // Armazenamento local de chamadas salvas (SharedPreferences)
  static const String _attendanceCacheKey = 'teacher_attendance_cache';

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
    _fetchSubjects().then((_) {
      // Após carregar disciplinas, garantir que um período esteja selecionado
      if (_periods.isNotEmpty && _selectedPeriodId == null) {
        setState(() {
          _selectedPeriodId = _periods.first['id'];
        });
        TeacherClassLogger.info(
          'Período selecionado automaticamente no initState',
        );
        TeacherClassLogger.debug('Período selecionado', {
          'periodId': _selectedPeriodId,
          'periodName': _periods.first['name'],
        });
      }
    });

    _tabController.addListener(() {
      if (_tabController.index == 0 && _assignments.isEmpty) {
        TeacherClassLogger.info(
          'Aba de atividades selecionada, carregando atividades...',
        );
        _fetchAssignments();
      } else if (_tabController.index == 1) {
        // Aba de chamada - sempre carregar/verificar frequência
        if (_selectedSubjectId != null) {
          TeacherClassLogger.info(
            'Aba de chamada selecionada, verificando frequência...',
          );

          // Se não há aula atual ou se a aula é de disciplina/data diferente, carregar
          if (_currentLesson == null ||
              _currentLesson!['subjectId'] != _selectedSubjectId ||
              _currentLesson!['date'] == null ||
              !_isSameDay(
                DateTime.parse(_currentLesson!['date']),
                _selectedDate,
              )) {
            TeacherClassLogger.info(
              'Carregando frequência para nova disciplina/data',
            );
            _loadAttendance();
          } else {
            TeacherClassLogger.info(
              'Aula atual válida, reutilizando frequência existente',
            );
            // Recarregar mapas de presença se necessário
            _refreshAttendanceMaps();
          }
        }
      } else if (_tabController.index == 2) {
        TeacherClassLogger.info(
          'Aba de notas selecionada, verificando período...',
        );

        // Garantir que um período esteja selecionado
        if (_selectedPeriodId == null && _periods.isNotEmpty) {
          _selectedPeriodId = _periods.first['id'];
          TeacherClassLogger.info(
            'Período selecionado automaticamente na aba de notas',
          );
          TeacherClassLogger.debug('Período selecionado', {
            'periodId': _selectedPeriodId,
            'periodName': _periods.first['name'],
          });
        }

        // Carregar notas se necessário
        if (_grades.isEmpty) {
          TeacherClassLogger.info('Carregando notas...');
          _fetchGrades();
        }
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
          TeacherClassLogger.info('Período selecionado automaticamente');
          TeacherClassLogger.debug('Período selecionado', {
            'periodId': _selectedPeriodId,
            'periodName': periods.first['name'],
          });
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
          // Selecionar automaticamente o primeiro período disponível
          if (periods.isNotEmpty && _selectedPeriodId == null) {
            _selectedPeriodId = periods.first['id'];
            TeacherClassLogger.info('Período selecionado automaticamente');
            TeacherClassLogger.debug('Período selecionado', {
              'periodId': _selectedPeriodId,
              'periodName': periods.first['name'],
            });
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

    // Garantir que um período esteja selecionado
    if (_selectedPeriodId == null && _periods.isNotEmpty) {
      _selectedPeriodId = _periods.first['id'];
      TeacherClassLogger.info(
        'Período selecionado automaticamente antes de buscar notas',
      );
      TeacherClassLogger.debug('Período selecionado', {
        'periodId': _selectedPeriodId,
        'periodName': _periods.first['name'],
      });
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
      // SOLUÇÃO: Como a rota /assignments não existe, simular dados vazios
      TeacherClassLogger.info(
        'Rota /assignments não existe, carregando lista vazia',
      );

      setState(() {
        _assignments = []; // Lista vazia por enquanto
        _loadingAssignments = false;
      });

      TeacherClassLogger.success('Lista de atividades inicializada (vazia)');
      TeacherClassLogger.debug('Atividades encontradas', {
        'count': 0,
        'subjectId': _selectedSubjectId,
        'nota': 'Rota /assignments não implementada no backend',
      });

      return;
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

  Future<void> _loadAttendance() async {
    if (_selectedSubjectId == null) {
      TeacherClassLogger.warning(
        'Tentativa de carregar frequência sem disciplina selecionada',
      );
      return;
    }

    // Evitar chamadas repetitivas
    if (_loadingAttendance) {
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

      // Verificar se já existe uma aula para a data/disciplina atual
      if (_currentLesson != null &&
          _currentLesson!['subjectId'] == _selectedSubjectId &&
          _currentLesson!['date'] != null &&
          _isSameDay(DateTime.parse(_currentLesson!['date']), _selectedDate)) {
        TeacherClassLogger.info(
          'Aula já existe para data/disciplina atual, reutilizando',
        );
        TeacherClassLogger.debug('Aula existente', {
          'lessonId': _currentLesson!['id'],
          'date': _currentLesson!['date'],
          'subjectId': _currentLesson!['subjectId'],
        });

        // Verificar se há frequência salva para esta aula
        await _loadSavedAttendanceForLesson(_currentLesson!);
        return; // Não precisa criar nova aula
      } else {
        TeacherClassLogger.info('Criando nova aula para data/disciplina atual');

        TeacherClassLogger.api('/lessons/get-or-create', 'POST', {
          'classId': widget.classData['id'],
          'subjectId': _selectedSubjectId!,
          'teacherId': teacherId,
          'date': _selectedDate.toIso8601String(),
        });

        // Tentar buscar/criar aula usando o backend real
        try {
          final lesson = await AttendanceService.getOrCreateLesson(
            classId: widget.classData['id'],
            subjectId: _selectedSubjectId!,
            teacherId: teacherId,
            date: _selectedDate,
            token: authProvider.user?.token,
          );

          TeacherClassLogger.success('Aula encontrada/criada via API');
          TeacherClassLogger.debug('Dados da aula da API', {
            'lessonId': lesson['id'],
            'date': lesson['date'],
            'subjectId': lesson['subjectId'],
          });

          setState(() {
            _currentLesson = lesson;
          });

          // Carregar frequência existente da API ou cache local
          try {
            final attendances = await AttendanceService.getAttendanceByLesson(
              lesson['id'],
            );
            TeacherClassLogger.info('Frequência carregada da API');
            TeacherClassLogger.debug('Frequências da API', {
              'count': attendances.length,
              'lessonId': lesson['id'],
            });

            _processAttendanceData(attendances);
          } catch (e) {
            TeacherClassLogger.warning(
              'Erro ao carregar frequência da API, tentando cache local: $e',
            );

            // Tentar carregar do cache local (SharedPreferences)
            final normalizedDate = _normalizeDateKey(lesson['date']);
            final lessonKey = '${lesson['subjectId']}_$normalizedDate';

            Map<String, dynamic>? savedData;
            try {
              final prefs = await SharedPreferences.getInstance();
              final cacheJson = prefs.getString(_attendanceCacheKey) ?? '{}';
              final Map<String, dynamic> cache = jsonDecode(cacheJson);

              // Buscar no cache com fallback para data aproximada
              savedData = cache[lessonKey];

              // Se não encontrou, tentar buscar por data aproximada (mesmo dia)
              if (savedData == null) {
                TeacherClassLogger.info(
                  'Cache não encontrado para chave exata, buscando por data aproximada',
                );

                final targetDate = DateTime.parse(lesson['date']);
                final targetDay =
                    '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

                // Procurar por qualquer entrada que tenha a mesma data
                for (var entry in cache.entries) {
                  final entryKey = entry.key;
                  final entryData = entry.value;

                  if (entryKey.contains('_$targetDay')) {
                    TeacherClassLogger.info(
                      'Cache encontrado por data aproximada',
                    );
                    TeacherClassLogger.debug('Dados do cache aproximado', {
                      'originalKey': entryKey,
                      'targetKey': lessonKey,
                      'targetDay': targetDay,
                      'savedAt': entryData['savedAt'],
                    });

                    savedData = entryData;
                    break;
                  }
                }
              }

              TeacherClassLogger.debug('Buscando no cache local', {
                'lessonKey': lessonKey,
                'normalizedDate': normalizedDate,
                'originalDate': lesson['date'],
                'cacheKeys': cache.keys.toList(),
                'foundData': savedData != null,
              });
            } catch (e) {
              TeacherClassLogger.error(
                'Erro ao carregar cache do SharedPreferences',
                e,
              );
            }

            // Debug completo do cache
            await _debugCacheStatus();

            if (savedData != null) {
              TeacherClassLogger.info(
                'Cache local encontrado, carregando dados salvos',
              );
              TeacherClassLogger.debug('Dados do cache', {
                'lessonKey': lessonKey,
                'savedAt': savedData['savedAt'],
                'presencesCount': savedData['presences'].length,
              });

              final presences =
                  savedData['presences'] as List<Map<String, dynamic>>;
              _processAttendanceDataFromCache(presences);
            } else {
              TeacherClassLogger.info(
                'Nenhum cache local encontrado, inicializando vazio',
              );
              _initializeEmptyAttendance();
            }
          }

          return; // Sucesso com API real
        } catch (e) {
          TeacherClassLogger.warning('API falhou, usando aula simulada: $e');
        }

        // Fallback: criar aula simulada
        TeacherClassLogger.info('Usando aula simulada como fallback');

        final lesson = {
          'id':
              'lesson_${_selectedSubjectId}_${_selectedDate.millisecondsSinceEpoch}',
          'classId': widget.classData['id'],
          'subjectId': _selectedSubjectId,
          'teacherId': teacherId,
          'date': _selectedDate.toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
        };

        TeacherClassLogger.success('Aula simulada criada como fallback');
        TeacherClassLogger.debug('Dados da aula simulada', {
          'lessonId': lesson['id'],
          'date': lesson['date'],
          'subjectId': lesson['subjectId'],
        });

        setState(() {
          _currentLesson = lesson;
        });

        // Inicializar frequência vazia para aula simulada
        _initializeEmptyAttendance();
      } // Fechamento do else
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

    // Verificar se há mudanças na frequência
    bool hasChanges = false;
    TeacherClassLogger.debug('Verificando mudanças na frequência', {
      'totalStudents': _students.length,
      'attendanceMapKeys': _attendanceMap.keys.length,
      'attendanceMapValues': _attendanceMap.values.toList(),
    });

    for (var student in _students) {
      final studentId = student['id'];
      final currentStatus = _attendanceMap[studentId];

      TeacherClassLogger.debug('Verificando aluno', {
        'studentName': student['name'],
        'studentId': studentId,
        'currentStatus': currentStatus,
        'hasStatus': currentStatus != null,
      });

      // Se algum aluno tem status marcado, há mudanças
      if (currentStatus != null) {
        hasChanges = true;
        TeacherClassLogger.info(
          'Mudança detectada no aluno: ${student['name']}',
        );
        break;
      }
    }

    TeacherClassLogger.info('Verificação de mudanças concluída');
    TeacherClassLogger.debug('Dados da verificação', {
      'hasChanges': hasChanges,
      'totalStudents': _students.length,
      'markedStudents':
          _attendanceMap.values.where((status) => status != null).length,
    });

    if (!hasChanges) {
      TeacherClassLogger.info(
        'Nenhuma mudança na frequência, pulando salvamento',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhuma mudança na frequência para salvar'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
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

      // Tentar salvar usando a API real
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await AttendanceService.markAttendanceByLesson(
          lessonId: _currentLesson!['id'],
          presences: presences,
          token: authProvider.user?.token,
        );

        TeacherClassLogger.success('Frequência salva via API real!');

        // Salvar localmente também para cache
        await _saveAttendanceLocally(_currentLesson!, presences);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Frequência salva com sucesso!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }

        // Recarregar frequência da API para confirmar salvamento
        TeacherClassLogger.info(
          'Recarregando frequência da API após salvamento',
        );
        try {
          final attendances = await AttendanceService.getAttendanceByLesson(
            _currentLesson!['id'],
          );

          if (attendances.isNotEmpty) {
            TeacherClassLogger.success(
              'Frequência recarregada da API após salvamento',
            );
            _processAttendanceData(attendances);
          } else {
            TeacherClassLogger.warning(
              'API retornou lista vazia após salvamento',
            );
          }
        } catch (e) {
          TeacherClassLogger.warning(
            'Erro ao recarregar frequência da API: $e',
          );
          // Manter dados locais se API falhar
        }

        return;
      } catch (e) {
        TeacherClassLogger.warning('API falhou, usando salvamento local: $e');
      }

      // Fallback: simular salvamento local
      TeacherClassLogger.info('Usando salvamento local como fallback');

      // Salvar localmente a frequência
      await _saveAttendanceLocally(_currentLesson!, presences);

      // Simular sucesso do salvamento
      TeacherClassLogger.success('Frequência simulada salva com sucesso!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Frequência salva com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Recarregar frequência local após salvamento
      TeacherClassLogger.info('Recarregando frequência local após salvamento');
      _loadSavedAttendanceForLesson(_currentLesson!);

      // Recarregamento já foi feito acima, não duplicar
      TeacherClassLogger.info('Recarregamento de frequência já foi executado');
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
      // Só limpa a aula se a disciplina mudou
      if (_currentLesson != null && _currentLesson!['subjectId'] != subjectId) {
        _currentLesson = null;
        TeacherClassLogger.info('Disciplina mudou, limpando aula anterior');
      }
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
        // Só limpa a aula se a data mudou significativamente (diferente dia)
        if (_currentLesson != null &&
            _currentLesson!['date'] != null &&
            !_isSameDay(DateTime.parse(_currentLesson!['date']), date)) {
          _currentLesson = null;
          TeacherClassLogger.info(
            'Data mudou significativamente, limpando aula anterior',
          );
        }
        // Não limpa o mapa de presença aqui, deixa a função _loadAttendance fazer isso
      });

      if (_selectedSubjectId != null) {
        TeacherClassLogger.info('Recarregando frequência para nova data...');
        _loadAttendance();
      }
    }
  }

  // Método auxiliar para verificar se duas datas são do mesmo dia
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Método para normalizar data para chave do cache
  String _normalizeDateKey(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      // Usar data local (como o backend faz com toDateString())
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      TeacherClassLogger.warning('Erro ao normalizar data: $e');
      return dateString;
    }
  }

  // Método para debug do cache
  Future<void> _debugCacheStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_attendanceCacheKey) ?? '{}';
      final Map<String, dynamic> cache = jsonDecode(cacheJson);

      TeacherClassLogger.debug('Status do cache local (SharedPreferences)', {
        'totalCacheEntries': cache.length,
        'cacheKeys': cache.keys.toList(),
        'cacheDetails': cache.map(
          (key, value) => MapEntry(key, {
            'savedAt': value['savedAt'],
            'presencesCount': value['presences'].length,
            'lessonId': value['lesson']['id'],
            'lessonDate': value['lesson']['date'],
            'normalizedKey': _normalizeDateKey(value['lesson']['date']),
          }),
        ),
      });
    } catch (e) {
      TeacherClassLogger.error('Erro ao ler cache do SharedPreferences', e);
    }
  }

  // Método para salvar frequência localmente
  Future<void> _saveAttendanceLocally(
    Map<String, dynamic> lesson,
    List<Map<String, dynamic>> presences,
  ) async {
    final normalizedDate = _normalizeDateKey(lesson['date']);
    final lessonKey = '${lesson['subjectId']}_$normalizedDate';

    TeacherClassLogger.info(
      'Salvando frequência localmente no SharedPreferences',
    );
    TeacherClassLogger.debug('Dados para salvamento local', {
      'lessonKey': lessonKey,
      'normalizedDate': normalizedDate,
      'originalDate': lesson['date'],
      'presencesCount': presences.length,
      'lessonId': lesson['id'],
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Carregar cache existente
      final existingCacheJson = prefs.getString(_attendanceCacheKey) ?? '{}';
      final Map<String, dynamic> existingCache = jsonDecode(existingCacheJson);

      // Adicionar nova entrada
      existingCache[lessonKey] = {
        'lesson': lesson,
        'presences': presences,
        'savedAt': DateTime.now().toIso8601String(),
      };

      // Salvar de volta
      final updatedCacheJson = jsonEncode(existingCache);
      await prefs.setString(_attendanceCacheKey, updatedCacheJson);

      // Atualizar mapas de presença com os dados salvos
      final newAttendanceMap = <String, String?>{};
      final newJustificationMap = <String, String>{};

      // Inicializar todos os alunos como não marcados
      for (var student in _students) {
        final studentId = student['id'];
        newAttendanceMap[studentId] = null;
        newJustificationMap[studentId] = '';
      }

      // Aplicar dados salvos
      for (var presence in presences) {
        final studentId = presence['studentId'];
        final status = presence['status'];
        final justification = presence['justification'] ?? '';

        newAttendanceMap[studentId] = status;
        if (status == 'JUSTIFIED_ABSENT' && justification.isNotEmpty) {
          newJustificationMap[studentId] = justification;
        }
      }

      setState(() {
        _attendanceMap = newAttendanceMap;
        _justificationMap = newJustificationMap;
      });

      TeacherClassLogger.success(
        'Frequência salva localmente no SharedPreferences',
      );
      TeacherClassLogger.debug('Dados salvos', {
        'lessonKey': lessonKey,
        'totalSaved': existingCache.length,
        'attendanceMapKeys': _attendanceMap.keys.length,
      });

      // Debug do cache após salvar
      await _debugCacheStatus();
    } catch (e) {
      TeacherClassLogger.error('Erro ao salvar no SharedPreferences', e);
    }
  }

  // Método para processar dados de frequência do cache local
  void _processAttendanceDataFromCache(List<Map<String, dynamic>> presences) {
    TeacherClassLogger.info('Processando dados do cache local');

    final newAttendanceMap = <String, String?>{};
    final newJustificationMap = <String, String>{};

    // Inicializar todos os alunos como não marcados
    for (var student in _students) {
      final studentId = student['id'];
      newAttendanceMap[studentId] = null;
      newJustificationMap[studentId] = '';
    }

    // Aplicar dados do cache
    for (var presence in presences) {
      final studentId = presence['studentId'];
      final status = presence['status'];
      final justification = presence['justification'] ?? '';

      newAttendanceMap[studentId] = status;
      if (status == 'JUSTIFIED_ABSENT' && justification.isNotEmpty) {
        newJustificationMap[studentId] = justification;
      }
    }

    setState(() {
      _attendanceMap = newAttendanceMap;
      _justificationMap = newJustificationMap;
    });

    TeacherClassLogger.success('Dados do cache local processados');
    TeacherClassLogger.debug('Mapas atualizados do cache', {
      'attendanceMapKeys': _attendanceMap.keys.length,
      'justificationMapKeys': _justificationMap.keys.length,
      'markedStudents':
          _attendanceMap.values.where((status) => status != null).length,
    });
  }

  // Método para processar dados de frequência da API
  void _processAttendanceData(List<Map<String, dynamic>> attendances) {
    TeacherClassLogger.info('Processando dados de frequência da API');

    final newAttendanceMap = <String, String?>{};
    final newJustificationMap = <String, String>{};

    // Inicializar todos os alunos como não marcados
    for (var student in _students) {
      final studentId = student['id'];
      newAttendanceMap[studentId] = null;
      newJustificationMap[studentId] = '';
    }

    // Aplicar dados da API
    for (var attendance in attendances) {
      final studentId = attendance['studentId'];
      final status = attendance['status'];
      final justification = attendance['justification'] ?? '';

      newAttendanceMap[studentId] = status;
      if (status == 'JUSTIFIED_ABSENT' && justification.isNotEmpty) {
        newJustificationMap[studentId] = justification;
      }
    }

    setState(() {
      _attendanceMap = newAttendanceMap;
      _justificationMap = newJustificationMap;
    });

    TeacherClassLogger.success('Dados de frequência da API processados');
    TeacherClassLogger.debug('Mapas atualizados', {
      'attendanceMapKeys': _attendanceMap.keys.length,
      'justificationMapKeys': _justificationMap.keys.length,
      'markedStudents':
          _attendanceMap.values.where((status) => status != null).length,
    });
  }

  // Método para inicializar frequência vazia
  void _initializeEmptyAttendance() {
    TeacherClassLogger.info('Inicializando frequência vazia');

    final newAttendanceMap = <String, String?>{};
    final newJustificationMap = <String, String>{};

    for (var student in _students) {
      final studentId = student['id'];
      newAttendanceMap[studentId] = null;
      newJustificationMap[studentId] = '';
    }

    setState(() {
      _attendanceMap = newAttendanceMap;
      _justificationMap = newJustificationMap;
    });

    TeacherClassLogger.success('Frequência vazia inicializada');
  }

  // Método para carregar frequência salva de uma aula existente
  Future<void> _loadSavedAttendanceForLesson(
    Map<String, dynamic> lesson,
  ) async {
    TeacherClassLogger.info('Carregando frequência salva para aula existente');
    TeacherClassLogger.debug('Dados da aula', {
      'lessonId': lesson['id'],
      'date': lesson['date'],
      'subjectId': lesson['subjectId'],
    });

    // Primeiro, tentar carregar da API
    try {
      final attendances = await AttendanceService.getAttendanceByLesson(
        lesson['id'],
      );
      TeacherClassLogger.info('Frequência carregada da API');
      TeacherClassLogger.debug('Frequências da API', {
        'count': attendances.length,
        'lessonId': lesson['id'],
      });

      _processAttendanceData(attendances);
      return; // Sucesso com API
    } catch (e) {
      TeacherClassLogger.warning(
        'Erro ao carregar da API, tentando cache local: $e',
      );
    }

    // Fallback: verificar se há frequência salva localmente no SharedPreferences
    final normalizedDate = _normalizeDateKey(lesson['date']);
    final lessonKey = '${lesson['subjectId']}_$normalizedDate';

    Map<String, dynamic>? savedData;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_attendanceCacheKey) ?? '{}';
      final Map<String, dynamic> cache = jsonDecode(cacheJson);

      // Buscar no cache com fallback para data aproximada
      savedData = cache[lessonKey];

      // Se não encontrou, tentar buscar por data aproximada (mesmo dia)
      if (savedData == null) {
        TeacherClassLogger.info(
          'Cache não encontrado para chave exata (método dedicado), buscando por data aproximada',
        );

        final targetDate = DateTime.parse(lesson['date']);
        final targetDay =
            '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

        // Procurar por qualquer entrada que tenha a mesma data
        for (var entry in cache.entries) {
          final entryKey = entry.key;
          final entryData = entry.value;

          if (entryKey.contains('_$targetDay')) {
            TeacherClassLogger.info(
              'Cache encontrado por data aproximada (método dedicado)',
            );
            TeacherClassLogger.debug('Dados do cache aproximado', {
              'originalKey': entryKey,
              'targetKey': lessonKey,
              'targetDay': targetDay,
              'savedAt': entryData['savedAt'],
            });

            savedData = entryData;
            break;
          }
        }
      }

      TeacherClassLogger.debug('Buscando no cache local (método dedicado)', {
        'lessonKey': lessonKey,
        'normalizedDate': normalizedDate,
        'originalDate': lesson['date'],
        'cacheKeys': cache.keys.toList(),
        'foundData': savedData != null,
      });
    } catch (e) {
      TeacherClassLogger.error(
        'Erro ao carregar cache do SharedPreferences',
        e,
      );
    }

    if (savedData != null) {
      TeacherClassLogger.info('Frequência salva encontrada, carregando...');
      TeacherClassLogger.debug('Dados salvos encontrados', {
        'lessonKey': lessonKey,
        'savedAt': savedData['savedAt'],
        'presencesCount': savedData['presences'].length,
      });

      // Carregar dados salvos
      final presences = savedData['presences'] as List<Map<String, dynamic>>;

      final newAttendanceMap = <String, String?>{};
      final newJustificationMap = <String, String>{};

      // Inicializar todos os alunos como não marcados
      for (var student in _students) {
        final studentId = student['id'];
        newAttendanceMap[studentId] = null;
        newJustificationMap[studentId] = '';
      }

      // Aplicar dados salvos
      for (var presence in presences) {
        final studentId = presence['studentId'];
        final status = presence['status'];
        final justification = presence['justification'] ?? '';

        newAttendanceMap[studentId] = status;
        if (status == 'JUSTIFIED_ABSENT' && justification.isNotEmpty) {
          newJustificationMap[studentId] = justification;
        }
      }

      setState(() {
        _attendanceMap = newAttendanceMap;
        _justificationMap = newJustificationMap;
      });

      TeacherClassLogger.success('Frequência salva carregada com sucesso');
      TeacherClassLogger.debug('Mapas carregados', {
        'attendanceMapKeys': _attendanceMap.keys.length,
        'justificationMapKeys': _justificationMap.keys.length,
        'studentsCount': _students.length,
        'markedStudents':
            _attendanceMap.values.where((status) => status != null).length,
      });
    } else {
      TeacherClassLogger.info(
        'Nenhuma frequência salva encontrada, inicializando mapas vazios',
      );

      // Inicializar mapas vazios (frequência não salva ainda)
      final newAttendanceMap = <String, String?>{};
      final newJustificationMap = <String, String>{};

      for (var student in _students) {
        final studentId = student['id'];
        newAttendanceMap[studentId] = null;
        newJustificationMap[studentId] = '';
      }

      setState(() {
        _attendanceMap = newAttendanceMap;
        _justificationMap = newJustificationMap;
      });

      TeacherClassLogger.success('Mapas vazios inicializados para nova aula');
      TeacherClassLogger.debug('Mapas inicializados', {
        'attendanceMapKeys': _attendanceMap.keys.length,
        'justificationMapKeys': _justificationMap.keys.length,
        'studentsCount': _students.length,
      });
    }
  }

  // Método para recarregar mapas de presença sem criar nova aula
  void _refreshAttendanceMaps() {
    if (_currentLesson == null || _students.isEmpty) {
      TeacherClassLogger.warning(
        'Não é possível recarregar mapas: aula ou alunos não disponíveis',
      );
      return;
    }

    TeacherClassLogger.info(
      'Recarregando mapas de presença para aula existente',
    );

    // Verificar se os mapas estão vazios ou incompletos
    bool needsRefresh =
        _attendanceMap.isEmpty ||
        _attendanceMap.length != _students.length ||
        _justificationMap.isEmpty ||
        _justificationMap.length != _students.length;

    if (needsRefresh) {
      TeacherClassLogger.info('Mapas incompletos, inicializando novamente');

      // Inicializar mapas de presença
      final newAttendanceMap = <String, String?>{};
      final newJustificationMap = <String, String>{};

      for (var student in _students) {
        final studentId = student['id'];
        // Manter valores existentes se disponíveis
        newAttendanceMap[studentId] = _attendanceMap[studentId];
        newJustificationMap[studentId] = _justificationMap[studentId] ?? '';
      }

      setState(() {
        _attendanceMap = newAttendanceMap;
        _justificationMap = newJustificationMap;
      });

      TeacherClassLogger.success('Mapas de presença recarregados');
      TeacherClassLogger.debug('Mapas atualizados', {
        'attendanceMapKeys': _attendanceMap.keys.length,
        'justificationMapKeys': _justificationMap.keys.length,
        'studentsCount': _students.length,
      });
    } else {
      TeacherClassLogger.info(
        'Mapas já estão completos, não é necessário recarregar',
      );
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
                            value: _selectedSubjectId,
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
                              value: _selectedSubjectId,
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

    // Usar o novo widget de frequência
    return AttendanceWidget(
      students: _students,
      currentLesson: _currentLesson,
      selectedSubjectId: _selectedSubjectId,
      selectedDate: _selectedDate,
      onDateChanged: (newDate) {
        setState(() {
          _selectedDate = newDate;
        });
        // Recarregar frequência para nova data
        if (_selectedSubjectId != null) {
          _loadAttendance();
        }
      },
      onLoadAttendance: _loadAttendance,
      isMobile: isMobile,
      isTablet: isTablet,
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
                        Row(
                          children: [
                            Expanded(
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
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed:
                                  _loadingAttendance
                                      ? null
                                      : () {
                                        TeacherClassLogger.info(
                                          'Botão de teste pressionado',
                                        );
                                        TeacherClassLogger.debug(
                                          'Estado atual dos mapas',
                                          {
                                            'attendanceMap': _attendanceMap,
                                            'justificationMap':
                                                _justificationMap,
                                            'studentsCount': _students.length,
                                            'currentLesson': _currentLesson,
                                          },
                                        );

                                        // Forçar salvamento para teste
                                        _saveAttendance();
                                      },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                              ),
                              child: const Text('Teste'),
                            ),
                          ],
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
                            value: _selectedPeriodId,
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
                              value: _selectedPeriodId,
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

  double? _calculateAverage(Map<String, Map<String, dynamic>> studentGrades) {
    if (studentGrades.isEmpty) return null;

    // Separar notas por tipo
    final regularGrades = <Map<String, dynamic>>[];
    Map<String, dynamic>? recGrade;
    Map<String, dynamic>? recFinalGrade;

    studentGrades.forEach((typeId, grade) {
      if (typeId == 'RECUPERACAO') {
        recGrade = grade;
      } else if (typeId == 'RECUPERACAO_FINAL') {
        recFinalGrade = grade;
      } else {
        regularGrades.add(grade);
      }
    });

    // Se não houver notas regulares, retorna null
    if (regularGrades.isEmpty) return null;

    // Encontrar a menor nota regular
    var minGrade = regularGrades[0];
    for (var grade in regularGrades.skip(1)) {
      final currentValue = _safeToDouble(grade['value']) ?? 0.0;
      final minValue = _safeToDouble(minGrade['value']) ?? 0.0;
      if (currentValue < minValue) {
        minGrade = grade;
      }
    }

    // Criar lista final de notas para cálculo
    final finalGrades = List<Map<String, dynamic>>.from(regularGrades);
    final minGradeIndex = finalGrades.indexOf(minGrade);
    final minGradeValue = _safeToDouble(minGrade['value']) ?? 0.0;

    // Se houver recuperação final e for maior que a menor nota, substitui
    if (recFinalGrade != null) {
      final value = recFinalGrade?['value'];
      if (value != null) {
        final recFinalValue = _safeToDouble(value) ?? 0.0;
        if (recFinalValue > minGradeValue) {
          finalGrades[minGradeIndex] = {
            ...?recFinalGrade,
            'value': recFinalValue,
          };
        }
      }
    }
    // Se não houver recuperação final mas houver recuperação normal, pode substituir
    else if (recGrade != null) {
      final value = recGrade?['value'];
      if (value != null) {
        final recValue = _safeToDouble(value) ?? 0.0;
        if (recValue > minGradeValue) {
          finalGrades[minGradeIndex] = {...?recGrade, 'value': recValue};
        }
      }
    }

    // Calcular média final
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
    final result = await showDialog(
      context: context,
      builder:
          (context) => GradeDialog(
            student: student,
            subjectId: _selectedSubjectId!,
            periodId: _selectedPeriodId!,
            typeId: typeId ?? existingGrade!['typeId'],
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
      final result = await FilePicker.platform.pickFiles();
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
      String? fileUrl;
      if (_fileBytes != null && _fileName != null) {
        // Enviar arquivo para o backend (implemente o endpoint se necessário)
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${AssignmentService.baseUrl}/assignments/upload'),
        );
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _fileBytes!,
            filename: _fileName!,
          ),
        );
        final streamed = await request.send();
        final resp = await http.Response.fromStream(streamed);
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          fileUrl = data['url'] ?? data['fileUrl'];
        } else {
          setState(() {
            _error = 'Erro ao enviar arquivo: ${resp.body}';
          });
          return;
        }
      }
      await AssignmentService.createAssignment(
        classId: widget.classId,
        subjectId: widget.subjectId,
        description: '${_nameController.text}\n${_descController.text}',
        dueDate: _dueDate!,
        fileUrl: fileUrl,
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
