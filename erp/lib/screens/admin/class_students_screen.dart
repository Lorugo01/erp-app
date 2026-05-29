import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../services/student_service.dart' as student_service;
import '../../providers/auth_provider.dart';
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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.user?.token;

    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/classes/$classId'),
        headers: {'Authorization': 'Bearer $token'},
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

  Future<void> _removeStudent(String enrollmentId) async {
    try {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.user?.token;

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token de autenticação não encontrado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/enrollments/$enrollmentId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      await _fetchEnrollments();

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Aluno removido da turma!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao remover aluno: $e')));
    }
  }

  void _showAddStudentToClassDialog() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.user?.token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token de autenticação não encontrado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final alunos = await student_service.StudentService.getAllStudents(
      token: token,
    );
    if (!mounted) return;

    // Filtrar alunos já matriculados
    final idsMatriculados = _enrollments.map((e) => e['student']['id']).toSet();
    final alunosDisponiveis =
        alunos
            .where((aluno) => !idsMatriculados.contains(aluno['id']))
            .toList();
    final selected = <String>{};
    String search = '';

    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (builderContext, setState) {
              final filteredAlunos =
                  alunosDisponiveis.where((aluno) {
                    final query = search.toLowerCase();
                    return (aluno['name'] ?? '').toLowerCase().contains(
                          query,
                        ) ||
                        (aluno['registrationNumber']?.toLowerCase() ?? '')
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
                                      value: selected.contains(aluno['id']),
                                      onChanged: (v) {
                                        setState(() {
                                          if (v == true) {
                                            selected.add(aluno['id']);
                                          } else {
                                            selected.remove(aluno['id']);
                                          }
                                        });
                                      },
                                      title: Text(aluno['name'] ?? ''),
                                      subtitle: Text(
                                        aluno['registrationNumber'] ??
                                            aluno['email'] ??
                                            '',
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
                    onPressed: () => Navigator.of(dialogContext).pop(),
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

                                // Verifica se o aluno já está matriculado na mesma turma
                                final jaMatriculadoMesmaTurma = _enrollments
                                    .any(
                                      (e) =>
                                          e['student']['id'] == studentId &&
                                          e['classId'] == classId,
                                    );
                                if (jaMatriculadoMesmaTurma) {
                                  if (!mounted) return;
                                  if (!context.mounted) return;
                                  showDialog(
                                    context: context,
                                    builder:
                                        (warningContext) => AlertDialog(
                                          title: const Text('Aviso'),
                                          content: const Text(
                                            'O aluno já está matriculado nesta turma.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () =>
                                                      Navigator.of(
                                                        warningContext,
                                                      ).pop(),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                  );
                                  continue;
                                }

                                if (jaMatriculadoMesmoAno) {
                                  if (!mounted) return;
                                  if (!context.mounted) return;
                                  showDialog(
                                    context: context,
                                    builder:
                                        (warningContext) => AlertDialog(
                                          title: const Text('Aviso'),
                                          content: Text(
                                            'O aluno já está matriculado em uma turma no ano $year.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () =>
                                                      Navigator.of(
                                                        warningContext,
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
                                    '${ApiConfig.baseUrl}/enrollments',
                                  ),
                                  headers: {
                                    'Content-Type': 'application/json',
                                    'Authorization': 'Bearer $token',
                                  },
                                  body: jsonEncode({
                                    'studentId': studentId,
                                    'classId': classId,
                                    'year': year,
                                    'current':
                                        true, // Marcar como matrícula atual
                                  }),
                                );

                                if (!mounted) return;
                                if (response.statusCode == 201 ||
                                    response.statusCode == 200) {
                                  success++;
                                }
                              }

                              if (!mounted) return;
                              // ignore: use_build_context_synchronously
                              Navigator.of(dialogContext).pop();
                              await _fetchEnrollments();

                              if (!mounted) return;
                              if (success > 0) {
                                if (!context.mounted) return;
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
                    onTap: () async {
                      if (!mounted) return;
                      if (!context.mounted) return;
                      final navigator = Navigator.of(context);
                      await navigator.push(
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
                            offset: const Offset(0, 2),
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
                                  ),
                                ),
                                if (student?['registrationNumber'] != null)
                                  Text(
                                    'Matrícula: ${student['registrationNumber']}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              if (!mounted) return;
                              final navigator = Navigator.of(context);

                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder:
                                    (dialogContext) => AlertDialog(
                                      title: const Text('Confirmar Remoção'),
                                      content: const Text(
                                        'Tem certeza que deseja remover este aluno da turma?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => navigator.pop(false),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () => navigator.pop(true),
                                          child: const Text(
                                            'Remover',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                              );

                              if (confirmed == true) {
                                await _removeStudent(enrollment['id']);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStudentToClassDialog,
        backgroundColor: const Color(0xFF2953A5),
        child: const Icon(Icons.add),
      ),
    );
  }
}
