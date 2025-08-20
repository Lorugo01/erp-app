import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherCalendarScreen extends StatefulWidget {
  const TeacherCalendarScreen({super.key});

  @override
  State<TeacherCalendarScreen> createState() => _TeacherCalendarScreenState();
}

class _TeacherCalendarScreenState extends State<TeacherCalendarScreen> {
  // Dados das turmas do professor
  List<Map<String, dynamic>> _classes = [];
  bool _loadingClasses = false;
  String? _errorClasses;

  // Turma selecionada
  Map<String, dynamic>? _selectedClass;
  String? _selectedClassId;

  // Dados das aulas
  List<Map<String, dynamic>> _lessons = [];
  bool _loadingLessons = false;
  String? _errorLessons;

  // Data selecionada
  DateTime _selectedDate = DateTime.now();

  // Calendário
  late PageController _pageController;
  late DateTime _currentMonth;

  // Configurações
  bool _notificationsEnabled = false;
  bool _syncEnabled = false;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      _syncEnabled = prefs.getBool('sync_enabled') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('sync_enabled', _syncEnabled);
  }

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    _pageController = PageController(initialPage: 0);
    _loadClasses();
    _loadSettings();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _loadingClasses = true;
      _errorClasses = null;
    });

    try {
      debugPrint('🔍 === CARREGANDO TURMAS DO PROFESSOR ===');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      String? teacherId;

      if (user?.teacher?.id != null) {
        teacherId = user!.teacher!.id;
      } else if (user?.id != null) {
        final teacherResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/teachers/user/${user?.id}'),
          headers: ApiConfig.defaultHeaders,
        );

        if (teacherResponse.statusCode == 200) {
          final teacherData = jsonDecode(teacherResponse.body);
          teacherId = teacherData['id'];
        }
      }

      if (teacherId != null) {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/teachers/$teacherId/classes'),
          headers: ApiConfig.defaultHeaders,
        );

        debugPrint('🔍 Status da resposta das turmas: ${response.statusCode}');
        debugPrint('🔍 Corpo da resposta das turmas: ${response.body}');

        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          debugPrint('🔍 Dados das turmas: $data');

          setState(() {
            _classes = List<Map<String, dynamic>>.from(data);
            if (_classes.isNotEmpty && _selectedClass == null) {
              _selectedClass = _classes.first;
              _selectedClassId = _selectedClass!['id'];
              _loadLessons();
            }
          });
        } else {
          debugPrint('❌ Erro ao carregar turmas: ${response.statusCode}');
          setState(() {
            _errorClasses = 'Erro ao carregar turmas';
          });
        }
      } else {
        setState(() {
          _errorClasses = 'ID do professor não encontrado';
        });
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

  Future<void> _loadLessons() async {
    if (_selectedClassId == null) return;

    setState(() {
      _loadingLessons = true;
      _errorLessons = null;
    });

    try {
      debugPrint('🔍 === CARREGANDO EVENTOS DA TURMA ===');
      debugPrint('🔍 Class ID: $_selectedClassId');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/classes/$_selectedClassId/events'),
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('🔍 Status da resposta dos eventos: ${response.statusCode}');
      debugPrint('🔍 Corpo da resposta dos eventos: ${response.body}');

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        debugPrint('🔍 Dados dos eventos: $data');

        // Filtrar apenas eventos recorrentes (sem data específica)
        final recurringEvents =
            data
                .where(
                  (event) =>
                      event['date'] == null &&
                      event['dayOfWeek'] != null &&
                      event['startTime'] != null &&
                      event['endTime'] != null,
                )
                .toList();

        setState(() {
          _lessons = List<Map<String, dynamic>>.from(recurringEvents);
        });
      } else {
        debugPrint('❌ Erro ao carregar eventos: ${response.statusCode}');
        setState(() {
          _errorLessons = 'Erro ao carregar eventos';
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar eventos: $e');
      setState(() {
        _errorLessons = e.toString();
      });
    } finally {
      setState(() {
        _loadingLessons = false;
      });
    }
  }

  void _selectClass(Map<String, dynamic> classData) {
    setState(() {
      _selectedClass = classData;
      _selectedClassId = classData['id'];
    });
    _loadLessons();
  }

  void _onDateSelected(DateTime selectedDate, DateTime focusedDate) {
    setState(() {
      _selectedDate = selectedDate;
    });
  }

  void _onPageChanged(DateTime month) {
    setState(() {
      _currentMonth = month;
    });
    _loadLessons();
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Ajuda - Agenda'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Como usar a agenda:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Selecione uma turma para ver o horário'),
                  const Text('• Os dias com aulas são marcados em verde'),
                  const Text(
                    '• Toque em um dia para ver os detalhes das aulas',
                  ),
                  const Text('• Use as setas para navegar entre os meses'),
                  const SizedBox(height: 16),
                  const Text(
                    'Legenda:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(50),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Dia com aulas'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(50),
                          border: Border.all(color: Colors.orange),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Dia atual'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2953A5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Dia selecionado'),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendi'),
              ),
            ],
          ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Configurações da Agenda'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notificações'),
                    subtitle: const Text('Receber lembretes de aulas'),
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) async {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        await _saveSettings();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? 'Notificações ativadas'
                                    : 'Notificações desativadas',
                              ),
                              backgroundColor:
                                  value ? Colors.green : Colors.grey,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.sync),
                    title: const Text('Sincronização'),
                    subtitle: const Text('Sincronizar com outros calendários'),
                    trailing: Switch(
                      value: _syncEnabled,
                      onChanged: (value) async {
                        setState(() {
                          _syncEnabled = value;
                        });
                        await _saveSettings();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? 'Sincronização ativada'
                                    : 'Sincronização desativada',
                              ),
                              backgroundColor:
                                  value ? Colors.green : Colors.grey,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }

  List<Map<String, dynamic>> _getLessonsForDate(DateTime date) {
    return _lessons.where((event) {
      // Verifica se o evento é para o dia da semana da data selecionada
      // dayOfWeek: 1 = Segunda, 2 = Terça, ..., 7 = Domingo
      // weekday: 1 = Segunda, 2 = Terça, ..., 7 = Domingo
      return event['dayOfWeek'] == date.weekday;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Seletor de turma
          Container(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMobile) ...[
                      Text(
                        'Selecione a Turma para Ver o Horário',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_loadingClasses)
                      const Center(child: CircularProgressIndicator())
                    else if (_errorClasses != null)
                      Center(
                        child: Text(
                          _errorClasses!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    else if (_classes.isEmpty)
                      const Center(
                        child: Text(
                          'Nenhuma turma encontrada',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else if (isMobile)
                      // Layout mobile: dropdown simples
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedClass?['id'],
                            isExpanded: true,
                            hint: const Text('Selecione uma turma'),
                            items:
                                _classes.map((classData) {
                                  return DropdownMenuItem<String>(
                                    value: classData['id'],
                                    child: Text(
                                      classData['name'] ?? 'Turma',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                final selectedClass = _classes.firstWhere(
                                  (c) => c['id'] == value,
                                );
                                _selectClass(selectedClass);
                              }
                            },
                          ),
                        ),
                      )
                    else
                      // Layout desktop: chips horizontais
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _classes.length,
                          itemBuilder: (context, index) {
                            final classData = _classes[index];
                            final isSelected =
                                _selectedClass?['id'] == classData['id'];
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(classData['name'] ?? 'Turma'),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    _selectClass(classData);
                                  }
                                },
                                backgroundColor: Colors.grey[200],
                                selectedColor: const Color(0xFF2953A5),
                                labelStyle: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Calendário e detalhes
          Expanded(
            child:
                _selectedClass == null
                    ? const Center(
                      child: Text(
                        'Selecione uma turma para ver o horário semanal',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : LayoutBuilder(
                      builder: (context, constraints) {
                        // Verifica se é mobile (largura < 600px)
                        final isMobile = constraints.maxWidth < 600;

                        if (isMobile) {
                          // Layout mobile: coluna única
                          return Column(
                            children: [
                              // Cabeçalho do calendário
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        final previousMonth = DateTime(
                                          _currentMonth.year,
                                          _currentMonth.month - 1,
                                        );
                                        setState(() {
                                          _currentMonth = previousMonth;
                                        });
                                        _loadLessons();
                                      },
                                      icon: const Icon(Icons.chevron_left),
                                    ),
                                    Expanded(
                                      child: Text(
                                        DateFormat(
                                          'MMMM yyyy',
                                          'pt_BR',
                                        ).format(_currentMonth),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        final nextMonth = DateTime(
                                          _currentMonth.year,
                                          _currentMonth.month + 1,
                                        );
                                        setState(() {
                                          _currentMonth = nextMonth;
                                        });
                                        _loadLessons();
                                      },
                                      icon: const Icon(Icons.chevron_right),
                                    ),
                                  ],
                                ),
                              ),

                              // Calendário (50% da altura)
                              Expanded(flex: 5, child: _buildCalendar()),

                              // Detalhes das aulas (50% da altura)
                              Expanded(flex: 5, child: _buildLessonDetails()),
                            ],
                          );
                        } else {
                          // Layout desktop: linha dividida
                          return Row(
                            children: [
                              // Calendário (2/3 da tela)
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    // Cabeçalho do calendário
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              final previousMonth = DateTime(
                                                _currentMonth.year,
                                                _currentMonth.month - 1,
                                              );
                                              setState(() {
                                                _currentMonth = previousMonth;
                                              });
                                              _loadLessons();
                                            },
                                            icon: const Icon(
                                              Icons.chevron_left,
                                            ),
                                          ),
                                          Text(
                                            DateFormat(
                                              'MMMM yyyy',
                                              'pt_BR',
                                            ).format(_currentMonth),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              final nextMonth = DateTime(
                                                _currentMonth.year,
                                                _currentMonth.month + 1,
                                              );
                                              setState(() {
                                                _currentMonth = nextMonth;
                                              });
                                              _loadLessons();
                                            },
                                            icon: const Icon(
                                              Icons.chevron_right,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Calendário
                                    Expanded(child: _buildCalendar()),
                                  ],
                                ),
                              ),

                              // Detalhes das aulas (1/3 da tela)
                              Expanded(flex: 1, child: _buildLessonDetails()),
                            ],
                          );
                        }
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Column(
          children: [
            // Dias da semana
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 16,
                vertical: isMobile ? 4 : 8,
              ),
              child: Row(
                children:
                    ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb']
                        .map(
                          (day) => Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2953A5),
                                  fontSize: isMobile ? 10 : 12,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),

            // Grade do calendário
            Expanded(child: _buildCalendarGrid()),
          ],
        );
      },
    );
  }

  Widget _buildCalendarGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final firstDayOfMonth = DateTime(
          _currentMonth.year,
          _currentMonth.month,
          1,
        );
        final lastDayOfMonth = DateTime(
          _currentMonth.year,
          _currentMonth.month + 1,
          0,
        );
        final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Domingo

        final daysInMonth = lastDayOfMonth.day;
        final totalCells = firstWeekday + daysInMonth;
        final weeks = (totalCells / 7).ceil();

        return ListView.builder(
          itemCount: weeks,
          itemBuilder: (context, weekIndex) {
            return Row(
              children: List.generate(7, (dayIndex) {
                final cellIndex = weekIndex * 7 + dayIndex;
                final dayNumber = cellIndex - firstWeekday + 1;

                if (cellIndex < firstWeekday || dayNumber > daysInMonth) {
                  return Expanded(child: Container());
                }

                final date = DateTime(
                  _currentMonth.year,
                  _currentMonth.month,
                  dayNumber,
                );
                final isSelected =
                    date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day;
                final isToday =
                    date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;

                final lessonsForDay = _getLessonsForDate(date);
                final hasLessons = lessonsForDay.isNotEmpty;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onDateSelected(date, date),
                    child: Container(
                      margin: EdgeInsets.all(isMobile ? 1 : 2),
                      height: isMobile ? 35 : 45,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? const Color(0xFF2953A5)
                                : isToday
                                ? Colors.orange.withAlpha(50)
                                : hasLessons
                                ? Colors.green.withAlpha(50)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(isMobile ? 4 : 8),
                        border:
                            isToday
                                ? Border.all(
                                  color: Colors.orange,
                                  width: isMobile ? 1 : 2,
                                )
                                : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayNumber.toString(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight:
                                  isToday ? FontWeight.bold : FontWeight.normal,
                              fontSize: isMobile ? 12 : 14,
                            ),
                          ),
                          if (hasLessons)
                            Container(
                              width: isMobile ? 4 : 6,
                              height: isMobile ? 4 : 6,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }

  Widget _buildLessonDetails() {
    final lessonsForSelectedDate = _getLessonsForDate(_selectedDate);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border:
                isMobile
                    ? null
                    : Border(left: BorderSide(color: Colors.grey[300]!)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat(
                          'EEEE, dd/MM/yyyy',
                          'pt_BR',
                        ).format(_selectedDate),
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isMobile)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2953A5).withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${lessonsForSelectedDate.length} aula${lessonsForSelectedDate.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2953A5),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: isMobile ? 12 : 16),
                if (_loadingLessons)
                  const Center(child: CircularProgressIndicator())
                else if (_errorLessons != null)
                  Center(
                    child: Text(
                      _errorLessons!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                else if (lessonsForSelectedDate.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: isMobile ? 40 : 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhuma aula programada',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'para este dia da semana',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Selecione outro dia para ver as aulas',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: isMobile ? 10 : 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children:
                        lessonsForSelectedDate.map((event) {
                          final title = event['title'] ?? 'Aula';
                          final description = event['description'] ?? '';
                          final startTime = event['startTime'] ?? '';
                          final endTime = event['endTime'] ?? '';
                          final subject = event['subject'];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 8 : 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: isMobile ? 32 : 40,
                                        height: isMobile ? 32 : 40,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF2953A5,
                                          ).withAlpha(30),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.book,
                                          color: const Color(0xFF2953A5),
                                          size: isMobile ? 16 : 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title
                                                  .replaceAll('_', ' ')
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                fontSize: isMobile ? 14 : 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (subject != null &&
                                                subject['name'] != null)
                                              Text(
                                                'Disciplina: ${subject['name']}',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: isMobile ? 12 : 14,
                                                ),
                                              ),
                                            if (description.isNotEmpty)
                                              Text(
                                                description,
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: isMobile ? 10 : 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: isMobile ? 14 : 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$startTime - $endTime',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: isMobile ? 10 : 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
