import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/student_service.dart' as student_service;
import 'student_detail_screen.dart';

class ClassStudentsScreen extends StatefulWidget {
  final Map<String, dynamic> classData;
  const ClassStudentsScreen({required this.classData, super.key});

  @override
  State<ClassStudentsScreen> createState() => _ClassStudentsScreenState();
}

class _ClassStudentsScreenState extends State<ClassStudentsScreen> {
  List<Map<String, dynamic>> _enrollments = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchEnrollments();
  }

  Future<void> _fetchEnrollments() async {
    setState(() => _loading = true);
    final classId = widget.classData['id'];
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/classes/$classId'),
      );
      if (response.statusCode == 200) {
        final turma = jsonDecode(response.body);
        setState(() {
          _enrollments = List<Map<String, dynamic>>.from(
            turma['enrollments'] ?? [],
          );
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _removeEnrollment(String enrollmentId) async {
    await http.delete(
      Uri.parse('http://localhost:3000/enrollments/$enrollmentId'),
    );
    await _fetchEnrollments();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Aluno removido da turma!')));
  }

  void _showAddStudentToClassDialog() async {
    final alunos = await student_service.StudentService.getAllStudents();
    // Filtrar alunos já matriculados
    final idsMatriculados = _enrollments.map((e) => e['student']['id']).toSet();
    final alunosDisponiveis =
        alunos.where((aluno) => !idsMatriculados.contains(aluno.id)).toList();
    final selected = <String>{};
    String search = '';
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              final filteredAlunos =
                  alunosDisponiveis.where((aluno) {
                    final query = search.toLowerCase();
                    return aluno.name.toLowerCase().contains(query) ||
                        (aluno.registrationNumber?.toLowerCase() ?? '')
                            .contains(query);
                  }).toList();
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text('Adicionar Aluno à Turma'),
                content: SizedBox(
                  width: 400,
                  height: 400,
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Buscar por nome ou matrícula',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (v) => setState(() => search = v),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child:
                            filteredAlunos.isEmpty
                                ? const Center(
                                  child: Text('Nenhum aluno disponível.'),
                                )
                                : ListView.builder(
                                  itemCount: filteredAlunos.length,
                                  itemBuilder: (context, i) {
                                    final aluno = filteredAlunos[i];
                                    return CheckboxListTile(
                                      value: selected.contains(aluno.id),
                                      onChanged: (v) {
                                        setState(() {
                                          if (v == true) {
                                            selected.add(aluno.id);
                                          } else {
                                            selected.remove(aluno.id);
                                          }
                                        });
                                      },
                                      title: Text(aluno.name),
                                      subtitle: Text(
                                        aluno.registrationNumber ?? aluno.email,
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed:
                        selected.isEmpty
                            ? null
                            : () async {
                              final classId = widget.classData['id'];
                              final year = widget.classData['academicYear'];
                              int success = 0;
                              for (final studentId in selected) {
                                // Verifica se o aluno já está matriculado em alguma turma no mesmo ano
                                final jaMatriculadoMesmoAno = _enrollments.any(
                                  (e) =>
                                      e['student']['id'] == studentId &&
                                      e['year'] == year,
                                );
                                if (jaMatriculadoMesmoAno) {
                                  if (!context.mounted) return;
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text('Atenção'),
                                          content: Text(
                                            'Este aluno já está matriculado em uma turma no ano $year.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () =>
                                                      Navigator.of(
                                                        context,
                                                      ).pop(),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                  );
                                  continue;
                                }
                                final response = await http.post(
                                  Uri.parse(
                                    'http://localhost:3000/enrollments',
                                  ),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode({
                                    'studentId': studentId,
                                    'classId': classId,
                                    'year': year,
                                    'current': true,
                                  }),
                                );
                                if (!context.mounted) return;
                                if (response.statusCode == 201 ||
                                    response.statusCode == 200) {
                                  success++;
                                }
                              }
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                              await _fetchEnrollments();
                              if (!mounted) return;
                              if (success > 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '$success aluno(s) matriculado(s) com sucesso!',
                                    ),
                                  ),
                                );
                              }
                            },
                    child: const Text('Adicionar'),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2953A5),
        title: Text(widget.classData['name'] ?? 'Alunos da Turma'),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _enrollments.isEmpty
              ? const Center(child: Text('Nenhum aluno na turma.'))
              : ListView.builder(
                itemCount: _enrollments.length,
                itemBuilder: (context, i) {
                  final enrollment = _enrollments[i];
                  final student = enrollment['student'];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => StudentDetailScreen(
                                student: student_service.Student(
                                  id: student['id'] ?? '',
                                  name: student['name'] ?? '',
                                  email: student['email'] ?? '',
                                  registrationNumber:
                                      student['registrationNumber'],
                                  subjects: [],
                                  createdAt: null,
                                  role: null,
                                ),
                              ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xFF2953A5)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student?['name'] ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF2953A5),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  student?['email'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              await _removeEnrollment(enrollment['id']);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.width < 600 ? 80 : 24,
          right: 24,
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.yellow[700],
          onPressed: _showAddStudentToClassDialog,
          child: const Icon(Icons.add, size: 36, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
