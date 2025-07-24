import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/teacher_service.dart';
import '../../services/attendance_service.dart';
import 'package:intl/intl.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  List<Map<String, dynamic>> _teacherClasses = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _attendances = [];

  String? _selectedClassId;
  String? _selectedSubjectId;
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _currentLesson;

  bool _loading = false;
  bool _loadingAttendance = false;
  String? _error;

  // Map para controlar presença/falta de cada aluno
  Map<String, bool> _attendanceMap = {};

  @override
  void initState() {
    super.initState();
    _fetchTeacherClasses();
  }

  Future<void> _fetchTeacherClasses() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final teacherId = authProvider.user?.teacher?.id;

      if (teacherId == null) {
        throw Exception('Professor não encontrado');
      }

      final classes = await TeacherService.getTeacherClasses(teacherId);
      setState(() {
        _teacherClasses = classes;
      });
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

  Future<void> _fetchSubjects() async {
    if (_selectedClassId == null) return;

    setState(() {
      _loading = true;
    });

    try {
      final subjects = await TeacherService.getSubjectsByClassId(
        _selectedClassId!,
      );
      setState(() {
        _subjects = subjects;
        _selectedSubjectId = null; // Reset subject selection
      });
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

  Future<void> _fetchStudents() async {
    if (_selectedClassId == null) return;

    setState(() {
      _loading = true;
    });

    try {
      final students = await TeacherService.getClassStudents(_selectedClassId!);
      setState(() {
        _students = students;
        // Inicializa o mapa de presença (sem valores por padrão)
        _attendanceMap = {};
      });
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

  Future<void> _loadAttendance() async {
    if (_selectedClassId == null || _selectedSubjectId == null) return;

    setState(() {
      _loadingAttendance = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final teacherId = authProvider.user?.teacher?.id;

      if (teacherId == null) {
        throw Exception('Professor não encontrado');
      }

      debugPrint('Criando aula para:');
      debugPrint('ClassId: $_selectedClassId');
      debugPrint('SubjectId: $_selectedSubjectId');
      debugPrint('TeacherId: $teacherId');
      debugPrint('Date: ${_selectedDate.toIso8601String()}');

      // RESET: Inicializa sem valores por padrão
      setState(() {
        _attendanceMap = {};
      });

      // Busca ou cria a aula
      final lesson = await AttendanceService.getOrCreateLesson(
        classId: _selectedClassId!,
        subjectId: _selectedSubjectId!,
        teacherId: teacherId,
        date: _selectedDate,
      );

      debugPrint('Aula criada/encontrada: ${lesson['id']}');

      setState(() {
        _currentLesson = lesson;
      });

      // Busca a frequência existente
      final attendances = await AttendanceService.getAttendanceByLesson(
        lesson['id'],
      );

      debugPrint('Frequências encontradas: ${attendances.length}');

      // Atualiza o mapa de presença com os dados existentes da API
      for (var attendance in attendances) {
        _attendanceMap[attendance['studentId']] = attendance['present'];
      }

      setState(() {
        _attendances = attendances;
      });
    } catch (e) {
      debugPrint('Erro ao carregar chamada: $e');
      setState(() {
        _error = 'Erro ao carregar chamada: $e';
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

      debugPrint('Salvando frequência para aula: ${_currentLesson!['id']}');
      debugPrint('Total de alunos: ${presences.length}');
      debugPrint(
        'Presenças: ${presences.where((p) => p['present'] == true).length}',
      );
      debugPrint(
        'Faltas: ${presences.where((p) => p['present'] == false).length}',
      );

      await AttendanceService.markAttendanceByLesson(
        lessonId: _currentLesson!['id'],
        presences: presences,
      );

      debugPrint('Frequência salva com sucesso!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Frequência salva com sucesso!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Recarrega a frequência
      await _loadAttendance();
    } catch (e) {
      debugPrint('Erro ao salvar frequência: $e');

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

  void _onClassChanged(String? classId) {
    setState(() {
      _selectedClassId = classId;
      _selectedSubjectId = null;
      _subjects = [];
      _students = [];
      _attendances = [];
      _currentLesson = null;
      _attendanceMap = {};
    });

    if (classId != null) {
      _fetchSubjects();
      _fetchStudents();
    }
  }

  void _onSubjectChanged(String? subjectId) {
    debugPrint('Mudando disciplina para: $subjectId');
    setState(() {
      _selectedSubjectId = subjectId;
      _attendances = [];
      _currentLesson = null;
      // Reset o mapa de presença
      _attendanceMap = {};
    });
    debugPrint(
      'Mapa de presença resetado para ${_attendanceMap.length} alunos',
    );

    if (subjectId != null && _selectedClassId != null) {
      _loadAttendance();
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
      debugPrint('Mudando data para: ${DateFormat('dd/MM/yyyy').format(date)}');
      setState(() {
        _selectedDate = date;
        _attendances = [];
        _currentLesson = null;
        // Reset o mapa de presença
        _attendanceMap = {};
      });
      debugPrint(
        'Mapa de presença resetado para ${_attendanceMap.length} alunos',
      );

      if (_selectedClassId != null && _selectedSubjectId != null) {
        _loadAttendance();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Chamadas',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2953A5),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchTeacherClasses,
                tooltip: 'Atualizar',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filtros
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecione a turma, disciplina e data:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Dropdown Turma
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedClassId,
                          decoration: const InputDecoration(
                            labelText: 'Turma',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              _teacherClasses.map((classData) {
                                return DropdownMenuItem<String>(
                                  value: classData['id'],
                                  child: Text(classData['name'] ?? 'Turma'),
                                );
                              }).toList(),
                          onChanged: _onClassChanged,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Dropdown Disciplina
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedSubjectId,
                          decoration: const InputDecoration(
                            labelText: 'Disciplina',
                            border: OutlineInputBorder(),
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
                      const SizedBox(width: 16),

                      // Seletor de Data
                      Expanded(
                        flex: 1,
                        child: InkWell(
                          onTap: _onDateChanged,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
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
                      ),
                    ],
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erro: $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchTeacherClasses,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_selectedClassId == null || _selectedSubjectId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_reg, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Selecione uma turma e disciplina',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Para fazer a chamada, primeiro selecione uma turma e uma disciplina.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
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
            child:
                _loadingAttendance
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final studentId = student['id'];
                        final isPresent = _attendanceMap[studentId];

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
                            child: Row(
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
}
