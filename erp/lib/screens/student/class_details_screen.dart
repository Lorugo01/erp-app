import 'package:flutter/material.dart';
import '../../utils/user_friendly_error.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'assignment_details_screen.dart';

class ClassDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> classData;

  const ClassDetailsScreen({super.key, required this.classData});

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dados das disciplinas
  List<Map<String, dynamic>> _subjects = [];
  bool _loadingSubjects = false;
  String? _errorSubjects;

  // Dados das atividades
  List<Map<String, dynamic>> _assignments = [];
  bool _loadingAssignments = false;
  String? _errorAssignments;

  // Dados das notas
  List<Map<String, dynamic>> _grades = [];
  bool _loadingGrades = false;
  String? _errorGrades;

  // Dados dos períodos
  List<Map<String, dynamic>> _gradePeriods = [];
  bool _loadingPeriods = false;
  String? _errorPeriods;

  // Disciplina selecionada
  Map<String, dynamic>? _selectedSubject;
  Map<String, dynamic>? _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSubjects();
    _loadGradePeriods();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, String> _authHeaders(String? token) {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String? _token() {
    return Provider.of<AuthProvider>(context, listen: false).user?.token;
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _loadingSubjects = true;
      _errorSubjects = null;
    });

    try {
      debugPrint('🔍 === CARREGANDO DISCIPLINAS ===');
      final classId = widget.classData['id']?.toString();
      debugPrint('🔍 Class ID: $classId');

      if (classId == null || classId.isEmpty) {
        setState(() {
          _errorSubjects = 'ID da turma não encontrado';
        });
        return;
      }

      final token = _token();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/subjects/class/$classId'),
        headers: _authHeaders(token),
      );

      debugPrint(
        '🔍 Status da resposta das disciplinas: ${response.statusCode}',
      );
      debugPrint('🔍 Corpo da resposta das disciplinas: ${response.body}');

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        debugPrint('🔍 Dados das disciplinas: $data');
        setState(() {
          _subjects = List<Map<String, dynamic>>.from(data);
        });
      } else {
        debugPrint('❌ Erro ao carregar disciplinas: ${response.statusCode}');
        setState(() {
          _errorSubjects = 'Erro ao carregar disciplinas';
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar disciplinas: $e');
      setState(() {
        _errorSubjects = userErrorMessage(e);
      });
    } finally {
      setState(() {
        _loadingSubjects = false;
      });
    }
  }

  Future<void> _loadGradePeriods() async {
    setState(() {
      _loadingPeriods = true;
      _errorPeriods = null;
    });

    try {
      debugPrint('🔍 === CARREGANDO PERÍODOS ===');
      final token = _token();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/grade-periods'),
        headers: _authHeaders(token),
      );

      debugPrint('🔍 Status da resposta dos períodos: ${response.statusCode}');
      debugPrint('🔍 Corpo da resposta dos períodos: ${response.body}');

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        debugPrint('🔍 Dados dos períodos: $data');
        setState(() {
          _gradePeriods = List<Map<String, dynamic>>.from(data);
          // Selecionar o primeiro período por padrão
          if (_gradePeriods.isNotEmpty) {
            _selectedPeriod = _gradePeriods.first;
          }
        });
      } else {
        debugPrint('❌ Erro ao carregar períodos: ${response.statusCode}');
        setState(() {
          _errorPeriods = 'Erro ao carregar períodos';
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar períodos: $e');
      setState(() {
        _errorPeriods = userErrorMessage(e);
      });
    } finally {
      setState(() {
        _loadingPeriods = false;
      });
    }
  }

  Future<void> _loadAssignments(String subjectId) async {
    setState(() {
      _loadingAssignments = true;
      _errorAssignments = null;
    });

    try {
      debugPrint('🔍 === CARREGANDO ATIVIDADES ===');
      debugPrint('🔍 Subject ID: $subjectId');
      debugPrint('🔍 Class ID: ${widget.classData['id']}');

      final token = _token();
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/assignments/class/${widget.classData['id']}?subjectId=$subjectId',
        ),
        headers: _authHeaders(token),
      );

      debugPrint(
        '🔍 Status da resposta das atividades: ${response.statusCode}',
      );
      debugPrint('🔍 Corpo da resposta das atividades: ${response.body}');

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        debugPrint('🔍 Dados das atividades: $data');
        setState(() {
          _assignments = List<Map<String, dynamic>>.from(data);
        });
      } else {
        debugPrint('❌ Erro ao carregar atividades: ${response.statusCode}');
        setState(() {
          _errorAssignments = 'Erro ao carregar atividades';
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar atividades: $e');
      setState(() {
        _errorAssignments = userErrorMessage(e);
      });
    } finally {
      setState(() {
        _loadingAssignments = false;
      });
    }
  }

  Future<void> _loadGrades(String subjectId) async {
    setState(() {
      _loadingGrades = true;
      _errorGrades = null;
    });

    try {
      debugPrint('🔍 === CARREGANDO NOTAS ===');
      debugPrint('🔍 Subject ID: $subjectId');
      debugPrint('🔍 Period ID: ${_selectedPeriod?['id']}');

      // Buscar notas do aluno para esta disciplina
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      final token = user?.token;
      String? studentId;

      if (user?.student?.id != null) {
        studentId = user!.student!.id;
      } else if (user?.id != null) {
        final studentResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/students/user/${user?.id}'),
          headers: _authHeaders(token),
        );

        if (studentResponse.statusCode == 200) {
          final studentData = jsonDecode(studentResponse.body);
          studentId = studentData['id'];
        }
      }

      if (studentId != null) {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/grades/student/$studentId'),
          headers: _authHeaders(token),
        );

        debugPrint('🔍 Status da resposta das notas: ${response.statusCode}');
        debugPrint('🔍 Corpo da resposta das notas: ${response.body}');

        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          // Filtrar notas da disciplina e período selecionados
          final filteredGrades =
              data.where((grade) {
                final isSubjectMatch =
                    grade['subjectId'] == subjectId ||
                    grade['subject']?['id'] == subjectId;
                final isPeriodMatch =
                    _selectedPeriod == null ||
                    grade['periodId'] == _selectedPeriod!['id'] ||
                    grade['gradePeriod']?['id'] == _selectedPeriod!['id'];
                return isSubjectMatch && isPeriodMatch;
              }).toList();

          debugPrint('🔍 Dados das notas filtradas: $filteredGrades');
          setState(() {
            _grades = List<Map<String, dynamic>>.from(filteredGrades);
          });
        } else {
          debugPrint('❌ Erro ao carregar notas: ${response.statusCode}');
          setState(() {
            _errorGrades = 'Erro ao carregar notas';
          });
        }
      } else {
        setState(() {
          _errorGrades = 'ID do aluno não encontrado';
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar notas: $e');
      setState(() {
        _errorGrades = userErrorMessage(e);
      });
    } finally {
      setState(() {
        _loadingGrades = false;
      });
    }
  }

  void _selectSubject(Map<String, dynamic> subject) {
    setState(() {
      _selectedSubject = subject;
    });
    final subjectId = subject['id']?.toString();
    if (subjectId != null && subjectId.isNotEmpty) {
      _loadAssignments(subjectId);
      if (_selectedPeriod != null) {
        _loadGrades(subjectId);
      }
    }
  }

  void _selectPeriod(Map<String, dynamic> period) {
    setState(() {
      _selectedPeriod = period;
    });
    final subjectId = _selectedSubject?['id']?.toString();
    if (subjectId != null && subjectId.isNotEmpty) {
      _loadGrades(subjectId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classData['name'] ?? 'Detalhes da Turma'),
        backgroundColor: const Color(0xFF2953A5),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Atividades'), Tab(text: 'Notas')],
        ),
      ),
      body: Column(
        children: [
          // Informações da turma
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.classData['name'] ?? 'Turma sem nome',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(
                      'Série',
                      '${widget.classData['grade'] ?? 'N/A'} - ${widget.classData['letter'] ?? ''}',
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      'Ano',
                      widget.classData['academicYear']?.toString() ?? 'N/A',
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip('Turno', widget.classData['shift'] ?? 'N/A'),
                  ],
                ),
              ],
            ),
          ),
          // Seletor de disciplinas
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Disciplinas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (_loadingSubjects)
                  const Center(child: CircularProgressIndicator())
                else if (_errorSubjects != null)
                  Center(
                    child: Text(
                      _errorSubjects!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                else if (_subjects.isEmpty)
                  const Center(
                    child: Text(
                      'Nenhuma disciplina encontrada',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _subjects.length,
                      itemBuilder: (context, index) {
                        final subject = _subjects[index];
                        final isSelected =
                            _selectedSubject?['id'] == subject['id'];
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(subject['name'] ?? 'Disciplina'),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                _selectSubject(subject);
                              }
                            },
                            backgroundColor: Colors.grey[200],
                            selectedColor: const Color(0xFF2953A5),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
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
            ),
          ),
          // Conteúdo das abas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildAssignmentsTab(), _buildGradesTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2953A5).withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF2953A5),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    if (_selectedSubject == null) {
      return const Center(
        child: Text(
          'Selecione uma disciplina para ver as atividades',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (_loadingAssignments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorAssignments != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar atividades',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorAssignments!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_assignments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma atividade encontrada',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Não há atividades cadastradas para esta disciplina.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _assignments.length,
      itemBuilder: (context, index) {
        final assignment = _assignments[index];
        return _AssignmentCard(assignment: assignment);
      },
    );
  }

  Widget _buildGradesTab() {
    if (_selectedSubject == null) {
      return const Center(
        child: Text(
          'Selecione uma disciplina para ver as notas',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // Seletor de período
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Período',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_loadingPeriods)
                const Center(child: CircularProgressIndicator())
              else if (_errorPeriods != null)
                Center(
                  child: Text(
                    _errorPeriods!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else if (_gradePeriods.isEmpty)
                const Center(
                  child: Text(
                    'Nenhum período encontrado',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _gradePeriods.length,
                    itemBuilder: (context, index) {
                      final period = _gradePeriods[index];
                      final isSelected = _selectedPeriod?['id'] == period['id'];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(period['name'] ?? 'Período'),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              _selectPeriod(period);
                            }
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: const Color(0xFF2953A5),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
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
          ),
        ),

        // Média atual
        if (_selectedPeriod != null && _grades.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: const Color(0xFF2953A5).withAlpha(30),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calculate,
                      color: Color(0xFF2953A5),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Média do ${_selectedPeriod!['name']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2953A5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _calculateAverage(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2953A5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Lista de notas
        Expanded(child: _buildGradesList()),
      ],
    );
  }

  Widget _buildGradesList() {
    if (_selectedPeriod == null) {
      return const Center(
        child: Text(
          'Selecione um período para ver as notas',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

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
              'Erro ao carregar notas',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorGrades!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_grades.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grade, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma nota encontrada',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Não há notas cadastradas para este período.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _grades.length,
      itemBuilder: (context, index) {
        final grade = _grades[index];
        return _GradeCard(grade: grade);
      },
    );
  }

  String _calculateAverage() {
    if (_grades.isEmpty) return '0.0';

    double total = 0.0;
    int count = 0;

    for (final grade in _grades) {
      final value = grade['value'];
      if (value != null) {
        total += (value is int ? value.toDouble() : value);
        count++;
      }
    }

    if (count == 0) return '0.0';
    return (total / count).toStringAsFixed(1);
  }
}

class _AssignmentCard extends StatelessWidget {
  final Map<String, dynamic> assignment;

  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final description = assignment['description'] ?? 'Atividade sem descrição';
    final dueDate = assignment['dueDate'] ?? '';
    final subject =
        assignment['subject']?['name'] ?? 'Disciplina não informada';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openAssignmentDetails(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subject,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (dueDate.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Entrega: ${DateTime.parse(dueDate).toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openAssignmentDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentDetailsScreen(assignment: assignment),
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  final Map<String, dynamic> grade;

  const _GradeCard({required this.grade});

  @override
  Widget build(BuildContext context) {
    final value = (grade['value'] ?? 0).toDouble();
    final type = grade['type']?['name'] ?? 'Nota';
    final period = grade['period']?['name'] ?? 'Período não informado';
    final subject = grade['subject']?['name'] ?? 'Disciplina não informada';

    // Determinar o tipo específico da nota
    String gradeTypeText = type;
    if (type.toLowerCase().contains('prova')) {
      gradeTypeText =
          type; // Manter como está se já for "Prova 1", "Prova 2", etc.
    } else if (type.toLowerCase().contains('trabalho')) {
      gradeTypeText = type;
    } else if (type.toLowerCase().contains('média')) {
      gradeTypeText = type;
    } else if (type.toLowerCase().contains('recuperação')) {
      gradeTypeText = type;
    } else {
      gradeTypeText =
          type; // Usar o nome original se não for um dos tipos conhecidos
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getGradeColor(value),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gradeTypeText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subject,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    period,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(num value) {
    if (value >= 7.0) return Colors.green;
    if (value >= 5.0) return Colors.orange;
    return Colors.red;
  }
}
