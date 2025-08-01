import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../config/api_config.dart';
import 'class_details_screen.dart';
import 'student_calendar_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _selectedIndex = 0;
  bool _isWide = false;

  // Dados do aluno
  Map<String, dynamic>? _studentData;

  // Dados das turmas
  List<Map<String, dynamic>> _classes = [];
  bool _loadingClasses = false;
  String? _errorClasses;

  // Dados de frequência
  List<Map<String, dynamic>> _attendanceData = [];
  bool _loadingAttendance = false;

  // Dados das aulas do dia
  List<Map<String, dynamic>> _todayLessons = [];
  bool _loadingLessons = false;

  // Dados de notas

  @override
  void initState() {
    super.initState();
    _loadStudentData();
    _loadClasses();
    _loadAttendanceData();
    _loadTodayLessons();
    _loadGrades();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recarregar aulas do dia quando a tela for focada novamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadTodayLessons();
      }
    });
  }

  Future<void> _loadStudentData() async {
    setState(() {});

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      debugPrint('🔍 === CARREGANDO DADOS DO ALUNO ===');
      debugPrint('🔍 User: ${user?.toJson()}');
      debugPrint('🔍 Student ID: ${user?.student?.id}');
      debugPrint('🔍 User ID: ${user?.id}');

      if (user?.student?.id != null) {
        debugPrint('🔍 Usando student ID: ${user!.student!.id}');
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/students/${user.student!.id}'),
          headers: ApiConfig.defaultHeaders,
        );

        debugPrint('🔍 Status da resposta: ${response.statusCode}');
        debugPrint('🔍 Corpo da resposta: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          debugPrint('🔍 Dados do aluno carregados: $data');
          setState(() {
            _studentData = data;
          });
        } else {
          throw Exception(
            'Erro ao carregar dados do aluno: ${response.statusCode}',
          );
        }
      } else if (user?.id != null) {
        // Fallback: usar o ID do usuário
        debugPrint('🔍 Usando user ID como fallback: ${user!.id}');
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/students/user/${user.id}'),
          headers: ApiConfig.defaultHeaders,
        );

        debugPrint('🔍 Status da resposta (fallback): ${response.statusCode}');
        debugPrint('🔍 Corpo da resposta (fallback): ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          debugPrint('🔍 Dados do aluno carregados (fallback): $data');
          setState(() {
            _studentData = data;
          });
        } else {
          throw Exception(
            'Erro ao carregar dados do aluno: ${response.statusCode}',
          );
        }
      } else {
        debugPrint('❌ Nenhum ID encontrado');
        throw Exception('ID do aluno não encontrado');
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar dados do aluno: $e');
      setState(() {});
    } finally {
      setState(() {});
    }
  }

  Future<void> _loadClasses() async {
    setState(() {
      _loadingClasses = true;
      _errorClasses = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      debugPrint('🔍 === CARREGANDO TURMAS ===');
      debugPrint('🔍 User: ${user?.toJson()}');
      debugPrint('🔍 Student ID: ${user?.student?.id}');
      debugPrint('🔍 User ID: ${user?.id}');

      String? studentId;

      if (user?.student?.id != null) {
        studentId = user!.student!.id;
        debugPrint('🔍 Usando student ID para buscar turmas: $studentId');
      } else if (user?.id != null) {
        // Se não temos student ID, buscar o student pelo user ID primeiro
        debugPrint('🔍 Buscando student pelo user ID: ${user!.id}');
        final studentResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/students/user/${user.id}'),
          headers: ApiConfig.defaultHeaders,
        );

        if (studentResponse.statusCode == 200) {
          final studentData = jsonDecode(studentResponse.body);
          studentId = studentData['id'];
          debugPrint('🔍 Student ID encontrado: $studentId');
        } else {
          debugPrint('❌ Erro ao buscar student pelo user ID');
          return;
        }
      } else {
        debugPrint('❌ Nenhum ID encontrado para buscar turmas');
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/enrollments/student/$studentId'),
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('🔍 Status da resposta das turmas: ${response.statusCode}');
      debugPrint('🔍 Corpo da resposta das turmas: ${response.body}');

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        debugPrint('🔍 Dados das turmas: $data');
        final classes =
            data.map((e) => Map<String, dynamic>.from(e['class'])).toList();
        debugPrint('🔍 Turmas processadas: $classes');
        setState(() {
          _classes = classes;
        });
      } else {
        debugPrint('❌ Erro ao carregar turmas: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar turmas: $e');
      setState(() {
        _errorClasses = e.toString();
      });
    } finally {
      setState(() {
        _loadingClasses = false;
      });
    }
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      _loadingAttendance = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      debugPrint('🔍 === CARREGANDO FREQUÊNCIA ===');
      debugPrint('🔍 User: ${user?.toJson()}');
      debugPrint('🔍 Student ID: ${user?.student?.id}');
      debugPrint('🔍 User ID: ${user?.id}');

      String? studentId;

      if (user?.student?.id != null) {
        studentId = user!.student!.id;
        debugPrint('🔍 Usando student ID para buscar frequência: $studentId');
      } else if (user?.id != null) {
        // Se não temos student ID, buscar o student pelo user ID primeiro
        debugPrint('🔍 Buscando student pelo user ID: ${user!.id}');
        final studentResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/students/user/${user.id}'),
          headers: ApiConfig.defaultHeaders,
        );

        if (studentResponse.statusCode == 200) {
          final studentData = jsonDecode(studentResponse.body);
          studentId = studentData['id'];
          debugPrint('🔍 Student ID encontrado: $studentId');
        } else {
          debugPrint('❌ Erro ao buscar student pelo user ID');
          return;
        }
      } else {
        debugPrint('❌ Nenhum ID encontrado para buscar frequência');
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/attendances/student/$studentId'),
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('🔍 Status da resposta da frequência: ${response.statusCode}');
      debugPrint('🔍 Corpo da resposta da frequência: ${response.body}');

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        debugPrint('🔍 Dados da frequência: $data');
        setState(() {
          _attendanceData = List<Map<String, dynamic>>.from(data);
        });
      } else {
        debugPrint('❌ Erro ao carregar frequência: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar frequência: $e');
    } finally {
      setState(() {
        _loadingAttendance = false;
      });
    }
  }

  Future<void> _loadTodayLessons() async {
    setState(() {
      _loadingLessons = true;
    });

    try {
      debugPrint('🔍 === CARREGANDO AULAS DO DIA ===');

      // Primeiro, buscar as turmas do aluno
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      String? studentId;

      if (user?.student?.id != null) {
        studentId = user!.student!.id;
      } else if (user?.id != null) {
        final studentResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/students/user/${user!.id}'),
          headers: ApiConfig.defaultHeaders,
        );

        if (studentResponse.statusCode == 200) {
          final studentData = jsonDecode(studentResponse.body);
          studentId = studentData['id'];
        }
      }

      if (studentId == null) {
        debugPrint('❌ ID do aluno não encontrado para carregar aulas do dia');
        return;
      }

      // Buscar matrículas do aluno
      final enrollmentsResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/enrollments/student/$studentId'),
        headers: ApiConfig.defaultHeaders,
      );

      if (enrollmentsResponse.statusCode != 200) {
        debugPrint(
          '❌ Erro ao carregar matrículas: ${enrollmentsResponse.statusCode}',
        );
        return;
      }

      final List enrollments = jsonDecode(enrollmentsResponse.body);
      final currentEnrollments =
          enrollments.where((e) => e['current'] == true).toList();

      if (currentEnrollments.isEmpty) {
        debugPrint('❌ Nenhuma matrícula atual encontrada');
        return;
      }

      // Buscar eventos de todas as turmas do aluno
      List<Map<String, dynamic>> allTodayLessons = [];
      final today = DateTime.now();
      final todayWeekday =
          today.weekday; // 1 = Segunda, 2 = Terça, ..., 7 = Domingo

      for (final enrollment in currentEnrollments) {
        final classId = enrollment['class']['id'];
        debugPrint('🔍 Buscando eventos da turma: $classId');

        final eventsResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/classes/$classId/events'),
          headers: ApiConfig.defaultHeaders,
        );

        if (eventsResponse.statusCode == 200) {
          final List events = jsonDecode(eventsResponse.body);

          // Filtrar eventos recorrentes para o dia da semana atual
          final todayEvents =
              events
                  .where(
                    (event) =>
                        event['date'] == null &&
                        event['dayOfWeek'] == todayWeekday &&
                        event['startTime'] != null &&
                        event['endTime'] != null,
                  )
                  .toList();

          // Adicionar informações da turma aos eventos
          for (final event in todayEvents) {
            event['className'] = enrollment['class']['name'];
            event['classId'] = classId;
          }

          allTodayLessons.addAll(List<Map<String, dynamic>>.from(todayEvents));
        }
      }

      // Ordenar por horário de início
      allTodayLessons.sort((a, b) {
        final timeA = a['startTime'] ?? '';
        final timeB = b['startTime'] ?? '';
        return timeA.compareTo(timeB);
      });

      debugPrint('🔍 Aulas do dia encontradas: ${allTodayLessons.length}');
      setState(() {
        _todayLessons = allTodayLessons;
      });
    } catch (e) {
      debugPrint('❌ Erro ao carregar aulas do dia: $e');
    } finally {
      setState(() {
        _loadingLessons = false;
      });
    }
  }

  Future<void> _loadGrades() async {
    setState(() {});

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user?.student?.id != null || user?.id != null) {
        final studentId = user!.student?.id ?? user.id;
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/grades/student/$studentId'),
          headers: ApiConfig.defaultHeaders,
        );

        if (response.statusCode == 200) {
          jsonDecode(response.body);
          setState(() {});
        }
      }
    } catch (e) {
      // Ignorar erro de notas por enquanto
    } finally {
      setState(() {});
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sair'),
          content: const Text('Tem certeza que deseja sair da aplicação?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    // O AuthFlow automaticamente redirecionará para a tela de login
    // Não precisamos navegar manualmente
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Perfil'),
          content: const Text('Funcionalidade em desenvolvimento...'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showClassDetails(Map<String, dynamic> classData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassDetailsScreen(classData: classData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Detectar se é tela larga
    final screenWidth = MediaQuery.of(context).size.width;
    _isWide = screenWidth > 600;

    return Scaffold(
      body: Row(
        children: [
          if (_isWide) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                if (!_isWide) _buildAppBar(),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isWide ? null : _buildBottomNavBar(),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: const Color(0xFF2953A5),
      child: Column(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            backgroundImage:
                _studentData?['profilePicture'] != null
                    ? NetworkImage(_studentData!['profilePicture'])
                    : null,
            child:
                _studentData?['profilePicture'] == null
                    ? const Icon(
                      Icons.person,
                      size: 60,
                      color: Color(0xFF2953A5),
                    )
                    : null,
          ),
          const SizedBox(height: 16),
          Text(
            _studentData?['name'] ?? 'Aluno',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Matrícula: ${_studentData?['registrationNumber'] ?? 'N/A'}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _SidebarButton(
            icon: Icons.dashboard,
            label: 'Visão Geral',
            selected: _selectedIndex == 0,
            onTap: () => setState(() => _selectedIndex = 0),
          ),
          _SidebarButton(
            icon: Icons.class_,
            label: 'Turmas',
            selected: _selectedIndex == 1,
            onTap: () => setState(() => _selectedIndex = 1),
          ),
          _SidebarButton(
            icon: Icons.calendar_today,
            label: 'Calendário',
            selected: _selectedIndex == 2,
            onTap: () => setState(() => _selectedIndex = 2),
          ),
          const Spacer(),
          _SidebarButton(
            icon: Icons.logout,
            label: 'Sair',
            selected: false,
            onTap: _showLogoutDialog,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      title: Text(_getPageTitle()),
      backgroundColor: const Color(0xFF2953A5),
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _showLogoutDialog,
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      selectedItemColor: const Color(0xFF2953A5),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Visão Geral',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.class_), label: 'Turmas'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Calendário',
        ),
      ],
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Visão Geral';
      case 1:
        return 'Minhas Turmas';
      case 2:
        return 'Calendário';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildClassesTab();
      case 2:
        return _buildCalendarTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do perfil
          _buildProfileHeader(),
          const SizedBox(height: 24),

          // Seção de frequência
          _buildAttendanceSection(),
          const SizedBox(height: 24),

          // Seção de mensagens
          _buildMessagesSection(),
          const SizedBox(height: 24),

          // Seção de aulas do dia
          _buildTodayLessonsSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage:
                  _studentData?['profilePicture'] != null
                      ? NetworkImage(_studentData!['profilePicture'])
                      : null,
              child:
                  _studentData?['profilePicture'] == null
                      ? const Icon(Icons.person, size: 40)
                      : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _studentData?['name'] ?? 'Carregando...',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Matrícula: ${_studentData?['registrationNumber'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _showEditProfileDialog,
              icon: const Icon(Icons.edit),
              tooltip: 'Editar perfil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF2953A5)),
                const SizedBox(width: 8),
                const Text(
                  'Frequência',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_loadingAttendance)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_attendanceData.isNotEmpty) ...[
              _buildAttendanceStats(),
            ] else
              const Text(
                'Nenhum dado de frequência disponível',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStats() {
    // Calcular estatísticas
    final total = _attendanceData.length;
    final presentes = _attendanceData.where((a) => a['present'] == true).length;
    final ausentes = _attendanceData.where((a) => a['present'] == false).length;
    final percentualPresente =
        total > 0 ? (presentes / total * 100).round() : 0;

    return Column(
      children: [
        // Card de percentual
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2953A5).withAlpha(30),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2953A5).withAlpha(100)),
          ),
          child: Column(
            children: [
              Text(
                '$percentualPresente%',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2953A5),
                ),
              ),
              const Text(
                'de presença',
                style: TextStyle(fontSize: 14, color: Color(0xFF2953A5)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Cards de estatísticas
        Row(
          children: [
            Expanded(
              child: _buildAttendanceCard(
                'Total',
                total,
                const Color(0xFF2953A5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAttendanceCard('Presente', presentes, Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAttendanceCard('Ausente', ausentes, Colors.red),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Lista das últimas frequências
        const Text(
          'Últimas frequências:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._attendanceData
            .take(5)
            .map((attendance) => _buildAttendanceItem(attendance)),
      ],
    );
  }

  Widget _buildAttendanceCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 14, color: color)),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(Map<String, dynamic> attendance) {
    final lesson = attendance['lesson'];
    final subject = lesson?['subject']?['name'] ?? 'Disciplina não informada';
    final date = lesson?['date'] ?? '';
    final isPresent = attendance['present'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isPresent ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isPresent
                  ? Colors.green.withAlpha(100)
                  : Colors.red.withAlpha(100),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPresent ? Icons.check_circle : Icons.cancel,
            color: isPresent ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  date,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            isPresent ? 'Presente' : 'Ausente',
            style: TextStyle(
              color: isPresent ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.message, color: Color(0xFF2953A5)),
                const SizedBox(width: 8),
                const Text(
                  'Mensagens',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma mensagem nova',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayLessonsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Color(0xFF2953A5)),
                const SizedBox(width: 8),
                const Text(
                  'Aulas do Dia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_loadingLessons)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_todayLessons.isNotEmpty) ...[
              ..._todayLessons.map((lesson) => _buildLessonCard(lesson)),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Toque em uma aula para ver o calendário completo',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ] else
              Column(
                children: [
                  Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhuma aula programada para hoje',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Verifique o calendário para ver o horário semanal',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonCard(Map<String, dynamic> event) {
    final startTime = event['startTime'] ?? '';
    final endTime = event['endTime'] ?? '';
    final title = event['title'] ?? 'Aula';
    final teacher = event['teacher']?['name'] ?? 'Professor não informado';
    final className = event['className'] ?? 'Turma não informada';
    final description = event['description'] ?? '';
    final classId = event['classId'];

    return GestureDetector(
      onTap: () {
        // Navegar para o calendário com a turma selecionada
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const StudentCalendarScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2953A5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Prof. $teacher',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    className,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$startTime - $endTime',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2953A5),
                    fontSize: 12,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2953A5).withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Hoje',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF2953A5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: const Color(0xFF2953A5).withAlpha(150),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesTab() {
    if (_loadingClasses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorClasses != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar turmas',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorClasses!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadClasses,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_classes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma turma encontrada',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Você ainda não está matriculado em nenhuma turma.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com estatísticas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Color(0xFF2953A5)),
                  const SizedBox(width: 8),
                  const Text(
                    'Minhas Turmas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2953A5).withAlpha(30),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_classes.length} turma${_classes.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Color(0xFF2953A5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Lista de turmas
          ..._classes.map(
            (classData) => _ClassCard(
              classData: classData,
              onTap: () => _showClassDetails(classData),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const StudentCalendarScreen(),
        );
      },
    );
  }
}

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withAlpha(30) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? Colors.white : Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final Map<String, dynamic> classData;
  final VoidCallback onTap;

  const _ClassCard({required this.classData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF2953A5).withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.class_,
                  color: Color(0xFF2953A5),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            classData['name'] ?? 'Turma sem nome',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Badge para turma atual
                        if (classData['current'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'ATUAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Série: ${classData['grade'] ?? 'N/A'} - ${classData['letter'] ?? ''}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ano: ${classData['academicYear'] ?? 'N/A'} | Turno: ${classData['shift'] ?? 'N/A'}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> classData;

  const _ClassDetailsSheet({required this.classData});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2953A5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.class_, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    classData['name'] ?? 'Detalhes da Turma',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem('Nome', classData['name'] ?? 'N/A'),
                  _buildDetailItem(
                    'Série',
                    '${classData['grade'] ?? 'N/A'} - ${classData['letter'] ?? ''}',
                  ),
                  _buildDetailItem(
                    'Ano Letivo',
                    classData['academicYear'] ?? 'N/A',
                  ),
                  _buildDetailItem('Turno', classData['shift'] ?? 'N/A'),
                  _buildDetailItem(
                    'Modelo de Avaliação',
                    classData['evaluationModel'] ?? 'N/A',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Disciplinas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Funcionalidade em desenvolvimento...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
