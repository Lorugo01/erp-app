import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import 'package:erp/providers/auth_provider.dart'; // Added missing import
import 'package:provider/provider.dart'; // Added missing import

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

  // Disciplina selecionada
  Map<String, dynamic>? _selectedSubject;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSubjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/subjects/class/$classId'),
        headers: ApiConfig.defaultHeaders,
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
        _errorSubjects = e.toString();
      });
    } finally {
      setState(() {
        _loadingSubjects = false;
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

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/assignments/subject/$subjectId'),
        headers: ApiConfig.defaultHeaders,
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
        _errorAssignments = e.toString();
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

      // Buscar notas do aluno para esta disciplina
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      String? studentId;

      if (user?.student?.id != null) {
        studentId = user!.student!.id;
      } else if (user?.id != null) {
        final studentResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/students/user/${user?.id}'),
          headers: ApiConfig.defaultHeaders,
        );

        if (studentResponse.statusCode == 200) {
          final studentData = jsonDecode(studentResponse.body);
          studentId = studentData['id'];
        }
      }

      if (studentId != null) {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/grades/student/$studentId'),
          headers: ApiConfig.defaultHeaders,
        );

        debugPrint('🔍 Status da resposta das notas: ${response.statusCode}');
        debugPrint('🔍 Corpo da resposta das notas: ${response.body}');

        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          // Filtrar notas da disciplina selecionada
          final subjectGrades =
              data
                  .where(
                    (grade) =>
                        grade['subjectId'] == subjectId ||
                        grade['subject']?['id'] == subjectId,
                  )
                  .toList();
          debugPrint('🔍 Dados das notas: $subjectGrades');
          setState(() {
            _grades = List<Map<String, dynamic>>.from(subjectGrades);
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
        _errorGrades = e.toString();
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
    _loadAssignments(subject['id']);
    _loadGrades(subject['id']);
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
              'Não há notas cadastradas para esta disciplina.',
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
}

class _AssignmentCard extends StatelessWidget {
  final Map<String, dynamic> assignment;

  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final title = assignment['title'] ?? 'Atividade sem título';
    final description = assignment['description'] ?? 'Sem descrição';
    final dueDate = assignment['dueDate'] ?? '';
    final status = assignment['status'] ?? 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: Colors.grey)),
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
                    'Entrega: $dueDate',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'CONCLUÍDA';
      case 'pending':
        return 'PENDENTE';
      case 'overdue':
        return 'ATRASADA';
      default:
        return 'DESCONHECIDO';
    }
  }
}

class _GradeCard extends StatelessWidget {
  final Map<String, dynamic> grade;

  const _GradeCard({required this.grade});

  @override
  Widget build(BuildContext context) {
    final value = grade['value'] ?? 0.0;
    final type = grade['gradeType']?['name'] ?? 'Nota';
    final period = grade['gradePeriod']?['name'] ?? 'Período não informado';
    final subject = grade['subject']?['name'] ?? 'Disciplina não informada';

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
                    type,
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

  Color _getGradeColor(double value) {
    if (value >= 7.0) return Colors.green;
    if (value >= 5.0) return Colors.orange;
    return Colors.red;
  }
}
