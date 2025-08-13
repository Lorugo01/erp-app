import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/assignment_service.dart';
import '../../services/attendance_service.dart';
import '../../services/grade_period_service.dart';
import '../../services/grade_service.dart';
import '../../services/grade_type_service.dart';
import '../../services/teacher_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'task_submissions_screen.dart';
import 'package:intl/intl.dart';
import 'teacher_student_detail_screen.dart';

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
  Map<String, bool> _attendanceMap = {};
  String? _errorAttendance;

  // Notas
  List<Map<String, dynamic>> _periods = [];
  List<Map<String, dynamic>> _gradeTypes = [];
  List<Map<String, dynamic>> _grades = [];
  String? _selectedPeriodId;
  bool _loadingGrades = false;
  String? _errorGrades;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchSubjects();
    _fetchStudents();
    _fetchPeriods();
    _fetchGradeTypes();

    _tabController.addListener(() {
      if (_tabController.index == 0 && _assignments.isEmpty) {
        _fetchAssignments();
      } else if (_tabController.index == 2 && _grades.isEmpty) {
        _fetchGrades();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubjects() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final teacherId = authProvider.user?.teacher?.id;

      if (teacherId == null) {
        throw Exception('Professor não encontrado');
      }

      // Buscar apenas as disciplinas que o professor leciona nesta turma
      final subjects = await TeacherService.getSubjectsByClassIdAndTeacher(
        widget.classData['id'],
        teacherId,
      );

      setState(() {
        _subjects = subjects;
        if (subjects.isNotEmpty) {
          _selectedSubjectId = subjects.first['id'];
        }
      });

      if (_selectedSubjectId != null) {
        _fetchAssignments();
      }
    } catch (e) {
      debugPrint('Erro ao carregar disciplinas: $e');
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
    try {
      final students = await TeacherService.getClassStudents(
        widget.classData['id'],
      );
      setState(() {
        _students = students;
        _attendanceMap = {};
      });
    } catch (e) {
      debugPrint('Erro ao carregar alunos: $e');
    }
  }

  Future<void> _fetchPeriods() async {
    try {
      final periods = await GradePeriodService.getAllGradePeriods();
      setState(() {
        _periods = periods;
        if (periods.isNotEmpty && _selectedPeriodId == null) {
          _selectedPeriodId = periods.first['id'];
        }
      });
    } catch (e) {
      debugPrint('Erro ao carregar períodos: $e');
    }
  }

  Future<void> _fetchGradeTypes() async {
    try {
      final types = await GradeTypeService.getAllGradeTypes();
      setState(() {
        _gradeTypes = types;
      });
    } catch (e) {
      debugPrint('Erro ao carregar tipos de nota: $e');
    }
  }

  Future<void> _fetchGrades() async {
    if (_selectedSubjectId == null) return;

    setState(() {
      _loadingGrades = true;
      _errorGrades = null;
    });

    try {
      final grades = await GradeService.getGradesBySubject(_selectedSubjectId!);
      setState(() {
        _grades = grades;
      });
    } catch (e) {
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
    if (_selectedSubjectId == null) return;

    setState(() {
      _loadingAssignments = true;
      _errorAssignments = null;
    });
    try {
      final assignments =
          await AssignmentService.getAssignmentsByClassAndSubject(
            widget.classData['id'],
            _selectedSubjectId!,
          );
      setState(() {
        _assignments = assignments;
      });
    } catch (e) {
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
    if (_selectedSubjectId == null) return;

    setState(() {
      _loadingAttendance = true;
      _errorAttendance = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final teacherId = authProvider.user?.teacher?.id;

      if (teacherId == null) {
        throw Exception('Professor não encontrado');
      }

      // Reset: Inicializa sem valores por padrão
      setState(() {
        _attendanceMap = {};
      });

      // Busca ou cria a aula
      final lesson = await AttendanceService.getOrCreateLesson(
        classId: widget.classData['id'],
        subjectId: _selectedSubjectId!,
        teacherId: teacherId,
        date: _selectedDate,
      );

      setState(() {
        _currentLesson = lesson;
      });

      // Busca a frequência existente
      final attendances = await AttendanceService.getAttendanceByLesson(
        lesson['id'],
      );

      // Atualiza o mapa de presença com os dados existentes da API
      for (var attendance in attendances) {
        _attendanceMap[attendance['studentId']] = attendance['present'];
      }
    } catch (e) {
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
    if (_currentLesson == null) return;

    setState(() {
      _loadingAttendance = true;
    });

    try {
      // Prepara a lista de presenças
      final presences =
          _students.map((student) {
            return {
              'studentId': student['id'],
              'present': _attendanceMap[student['id']] ?? false,
            };
          }).toList();

      await AttendanceService.markAttendanceByLesson(
        lessonId: _currentLesson!['id'],
        presences: presences,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Frequência salva com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Recarrega a frequência
      await _loadAttendance();
    } catch (e) {
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
    setState(() {
      _selectedSubjectId = subjectId;
      _currentLesson = null;
      _attendanceMap = {};
    });

    if (subjectId != null) {
      if (_tabController.index == 0) {
        _fetchAssignments();
      } else if (_tabController.index == 1) {
        _loadAttendance();
      } else if (_tabController.index == 2) {
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
      setState(() {
        _selectedDate = date;
        _currentLesson = null;
        _attendanceMap = {};
      });

      if (_selectedSubjectId != null) {
        _loadAttendance();
      }
    }
  }

  Future<void> _deleteAssignment(String assignmentId) async {
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
      setState(() => _loadingAssignments = true);
      try {
        await AssignmentService.deleteAssignment(assignmentId);
        await _fetchAssignments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Atividade excluída com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
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
    }
  }

  void _showAddAssignmentDialog() async {
    if (_selectedSubjectId == null) {
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

    final result = await showDialog(
      context: context,
      builder:
          (context) => AddAssignmentDialog(
            classId: widget.classData['id'],
            subjectId: _selectedSubjectId!,
          ),
    );
    if (result == true) {
      _fetchAssignments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Turma - ${widget.classData['name'] ?? ''}'),
        backgroundColor: const Color(0xFF2953A5),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Atividades', icon: Icon(Icons.assignment)),
            Tab(text: 'Chamadas', icon: Icon(Icons.how_to_reg)),
            Tab(text: 'Notas', icon: Icon(Icons.grade)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Seletor de disciplinas (se há múltiplas)
          if (_subjects.length > 1)
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.grey.shade100,
              child: Row(
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
                              child: Text(subject['name'] ?? 'Disciplina'),
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
                _buildAssignmentsTab(),
                _buildAttendanceTab(),
                _buildGradesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    if (_selectedSubjectId == null) {
      return const Center(
        child: Text('Selecione uma disciplina para ver as atividades'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Stack(
        children: [
          _loadingAssignments
              ? const Center(child: CircularProgressIndicator())
              : _errorAssignments != null
              ? Center(
                child: Text(
                  _errorAssignments!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
              : _assignments.isEmpty
              ? const Center(child: Text('Nenhuma atividade cadastrada.'))
              : ListView.separated(
                itemCount: _assignments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: ListTile(
                      title: Text(nome),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (descricao.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(descricao),
                            ),
                          if (assignment['dueDate'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Entrega até: ${assignment['dueDate'] != null ? assignment['dueDate'].toString().split('T').first : ''}',
                              ),
                            ),
                          if (assignment['fileUrl'] != null &&
                              assignment['fileUrl'].toString().isNotEmpty)
                            TextButton.icon(
                              icon: const Icon(Icons.attach_file),
                              label: const Text('Baixar Anexo'),
                              onPressed: () async {
                                final url = assignment['fileUrl'];
                                final uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
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
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              backgroundColor: Colors.orange,
              onPressed: _showAddAssignmentDialog,
              child: const Icon(Icons.add, size: 32, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    if (_selectedSubjectId == null) {
      return const Center(
        child: Text('Selecione uma disciplina para fazer a chamada'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seletor de Data
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    'Data da aula:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                          Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed:
                        _selectedSubjectId != null ? _loadAttendance : null,
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
          const SizedBox(height: 24),

          // Lista de Alunos
          Expanded(child: _buildStudentsList()),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
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
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2953A5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Aluno (${_students.length})',
                    style: const TextStyle(
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Falta',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Lista de alunos
          Expanded(
            child: ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                final studentId = student['id'];
                final isPresent = _attendanceMap[studentId];

                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Avatar e nome do aluno
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFF2953A5),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student['name'] ?? 'Aluno',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
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
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                tooltip: 'Ver detalhes do aluno',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) {
                                        final authProvider =
                                            Provider.of<AuthProvider>(
                                              context,
                                              listen: false,
                                            );
                                        final teacherId =
                                            authProvider.user?.teacher?.id;

                                        if (teacherId == null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Erro: Professor não encontrado',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return const SizedBox.shrink();
                                        }

                                        return TeacherStudentDetailScreen(
                                          student: student,
                                          classData: widget.classData,
                                          subjectId: _selectedSubjectId!,
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
                            child: Radio<bool>(
                              value: true,
                              groupValue: isPresent,
                              onChanged: (bool? value) {
                                if (value != null) {
                                  setState(() {
                                    _attendanceMap[studentId] = true;
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
                            child: Radio<bool>(
                              value: false,
                              groupValue: isPresent,
                              onChanged: (bool? value) {
                                if (value != null) {
                                  setState(() {
                                    _attendanceMap[studentId] = false;
                                  });
                                }
                              },
                              activeColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Botões de ação
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      for (var student in _students) {
                        _attendanceMap[student['id']] = true;
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
                        _attendanceMap[student['id']] = false;
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
                  onPressed: _loadingAttendance ? null : _saveAttendance,
                  icon:
                      _loadingAttendance
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
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

  Widget _buildGradesTab() {
    if (_selectedSubjectId == null) {
      return const Center(
        child: Text('Selecione uma disciplina para gerenciar notas'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seletor de Período
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
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
                    onPressed: _selectedPeriodId != null ? _fetchGrades : null,
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
          const SizedBox(height: 24),

          // Tabela de Notas
          Expanded(child: _buildGradesList()),
        ],
      ),
    );
  }

  Widget _buildGradesList() {
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

    return Card(
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
                              student['name']?.substring(0, 1).toUpperCase() ??
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
                        grade != null
                            ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
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
                                  onPressed:
                                      () => _showGradeDialog(student, grade),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  color: Colors.red,
                                  onPressed: () => _deleteGrade(grade['id']),
                                ),
                              ],
                            )
                            : Center(
                              child: IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                color: Colors.green,
                                onPressed:
                                    () => _showGradeDialog(
                                      student,
                                      null,
                                      typeId: type['id'],
                                    ),
                              ),
                            ),
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
                            style: TextStyle(color: Colors.grey, fontSize: 14),
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
      try {
        await GradeService.deleteGrade(gradeId);
        await _fetchGrades();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nota excluída com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir nota: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

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
        await GradeService.updateGrade(
          gradeId: widget.existingGrade!['id'],
          value: _isConcept ? null : double.tryParse(_valueController.text),
          concept: _isConcept ? _conceptController.text : null,
        );
      } else {
        // Criar nova nota
        await GradeService.createGrade(
          studentId: widget.student['id'],
          subjectId: widget.subjectId,
          typeId: widget.typeId,
          periodId: widget.periodId,
          value: _isConcept ? null : double.tryParse(_valueController.text),
          concept: _isConcept ? _conceptController.text : null,
        );
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
