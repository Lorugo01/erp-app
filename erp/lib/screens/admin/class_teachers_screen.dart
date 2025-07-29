import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/teacher_service.dart';

class ClassTeachersScreen extends StatefulWidget {
  final Map<String, dynamic> classData;
  const ClassTeachersScreen({required this.classData, super.key});

  @override
  State<ClassTeachersScreen> createState() => _ClassTeachersScreenState();
}

class _ClassTeachersScreenState extends State<ClassTeachersScreen> {
  List<dynamic> _subjects = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    setState(() => _loading = true);
    final classId = widget.classData['id'];
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/classes/$classId'),
      );
      if (response.statusCode == 200) {
        final turma = jsonDecode(response.body);
        setState(() {
          _subjects = turma['subjects'] ?? [];
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _removeSubject(String subjectId) async {
    await http.delete(Uri.parse('http://localhost:3000/subjects/$subjectId'));
    await _fetchSubjects();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Professor removido da turma!')),
    );
  }

  void _showAddTeacherToClassDialog() async {
    final professores = await TeacherService.getAllTeachers();
    // Filtrar professores já vinculados à turma
    final idsVinculados = _subjects.map((s) => s['teacherId']).toSet();
    final professoresDisponiveis =
        professores
            .where((prof) => !idsVinculados.contains(prof['id']))
            .toList();
    String? selectedTeacherId;
    final subjectTypes = [
      'LINGUA_INGLESA',
      'ARTE',
      'EDUCACAO_FISICA',
      'MATEMATICA',
      'CIENCIAS',
      'HISTORIA',
      'GEOGRAFIA',
      'ENSINO_RELIGIOSO',
      'BIOLOGIA',
      'FISICA',
      'QUIMICA',
      'FILOSOFIA',
      'SOCIOLOGIA',
      'CONTEUDO_INTERDISCIPLINAR',
    ];
    final selectedSubjects = <String>{};
    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Adicionar Professor à Turma'),
                  content: SizedBox(
                    width: 400,
                    height: 500,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        // Seleção de professor
                        DropdownButtonFormField<String>(
                          value: selectedTeacherId,
                          items:
                              professoresDisponiveis
                                  .map<DropdownMenuItem<String>>(
                                    (prof) => DropdownMenuItem(
                                      value: prof['id'],
                                      child: Text(prof['name'] ?? ''),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setState(() => selectedTeacherId = v),
                          decoration: const InputDecoration(
                            labelText: 'Professor',
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Seleção de matérias
                        Expanded(
                          child: ListView(
                            children:
                                subjectTypes.map((type) {
                                  return CheckboxListTile(
                                    value: selectedSubjects.contains(type),
                                    onChanged:
                                        selectedTeacherId == null
                                            ? null
                                            : (v) {
                                              setState(() {
                                                if (v == true) {
                                                  selectedSubjects.add(type);
                                                } else {
                                                  selectedSubjects.remove(type);
                                                }
                                              });
                                            },
                                    title: Text(_formatSubjectType(type)),
                                  );
                                }).toList(),
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
                          selectedTeacherId == null || selectedSubjects.isEmpty
                              ? null
                              : () async {
                                final classId = widget.classData['id'];
                                int success = 0;
                                for (final subjectType in selectedSubjects) {
                                  final response = await http.post(
                                    Uri.parse('http://localhost:3000/subjects'),
                                    headers: {
                                      'Content-Type': 'application/json',
                                    },
                                    body: jsonEncode({
                                      'type': subjectType,
                                      'classId': classId,
                                      'teacherId': selectedTeacherId,
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
                                await _fetchSubjects();
                                if (!mounted) return;
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '$success matéria(s) atribuída(s) ao professor na turma!',
                                    ),
                                  ),
                                );
                              },
                      child: const Text('Adicionar'),
                    ),
                  ],
                ),
          ),
    );
  }

  String _formatSubjectType(String? type) {
    if (type == null) return '';
    switch (type) {
      case 'LINGUA_INGLESA':
        return 'Língua Inglesa';
      case 'ARTE':
        return 'Arte';
      case 'EDUCACAO_FISICA':
        return 'Educação Física';
      case 'MATEMATICA':
        return 'Matemática';
      case 'CIENCIAS':
        return 'Ciências';
      case 'HISTORIA':
        return 'História';
      case 'GEOGRAFIA':
        return 'Geografia';
      case 'ENSINO_RELIGIOSO':
        return 'Ensino Religioso';
      case 'BIOLOGIA':
        return 'Biologia';
      case 'FISICA':
        return 'Física';
      case 'QUIMICA':
        return 'Química';
      case 'FILOSOFIA':
        return 'Filosofia';
      case 'SOCIOLOGIA':
        return 'Sociologia';
      case 'CONTEUDO_INTERDISCIPLINAR':
        return 'Conteúdo Interdisciplinar';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Agrupar subjects por teacherId
    final Map<String, Map<String, dynamic>> professores = {};
    final Map<String, List<Map<String, dynamic>>> materiasPorProfessor = {};
    for (final subject in _subjects) {
      final teacher = subject['teacher'];
      if (teacher == null) continue;
      final teacherId = teacher['id'];
      professores[teacherId] = teacher;
      materiasPorProfessor.putIfAbsent(teacherId, () => []).add(subject);
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text(widget.classData['name'] ?? 'Professores da Turma'),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : professores.isEmpty
              ? const Center(child: Text('Nenhum professor na turma.'))
              : ListView(
                children:
                    professores.entries.map((entry) {
                      final teacher = entry.value;
                      final subjects = materiasPorProfessor[entry.key] ?? [];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage:
                                        teacher['photoUrl'] != null
                                            ? NetworkImage(
                                              'http://localhost:3000${teacher['photoUrl']}',
                                            )
                                            : null,
                                    child:
                                        teacher['photoUrl'] == null
                                            ? const Icon(
                                              Icons.person,
                                              color: Colors.grey,
                                            )
                                            : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          teacher['name'] ?? 'Professor',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (teacher['email'] != null)
                                          Text(
                                            teacher['email'],
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...subjects.map(
                                (subject) => Row(
                                  children: [
                                    const SizedBox(width: 32),
                                    Expanded(
                                      child: Text(
                                        _formatSubjectType(subject['type']),
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => _removeSubject(subject['id']),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.width < 600 ? 80 : 24,
          right: 24,
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.orange,
          onPressed: _showAddTeacherToClassDialog,
          child: const Icon(Icons.add, size: 36, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
