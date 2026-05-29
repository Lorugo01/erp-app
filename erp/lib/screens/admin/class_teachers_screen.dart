import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../services/teacher_service.dart';
import '../../providers/auth_provider.dart';

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
          _subjects = turma['subjects'] ?? [];
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _showAddTeacherToClassDialog() async {
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

    final professores = await TeacherService.getAllTeachers(token: token);
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
                          initialValue: selectedTeacherId,
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
                                    Uri.parse(
                                      '${ApiConfig.baseUrl}/subjects',
                                    ),
                                    headers: {
                                      'Content-Type': 'application/json',
                                      'Authorization': 'Bearer $token',
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

  void _showManageTeacherSubjectsDialog({
    required Map<String, dynamic> teacher,
    required List<Map<String, dynamic>> currentSubjects,
  }) async {
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

    // Mapear matérias atuais por tipo para facilitar a busca
    final currentSubjectsMap = <String, Map<String, dynamic>>{};
    for (final subject in currentSubjects) {
      currentSubjectsMap[subject['type']] = subject;
    }

    // Inicializar com as matérias atuais
    final selectedSubjects = <String>{};
    for (final subject in currentSubjects) {
      selectedSubjects.add(subject['type']);
    }

    bool isLoading = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      const Icon(Icons.edit, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Gerenciar Matérias do Professor: ${teacher['name']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: 450,
                    height: 500,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Informações do professor
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withAlpha(80),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.grey[200],
                                backgroundImage:
                                    teacher['photoUrl'] != null
                                        ? NetworkImage(
                                          '${ApiConfig.baseUrl}${teacher['photoUrl']}',
                                        )
                                        : null,
                                child:
                                    teacher['photoUrl'] == null
                                        ? const Icon(
                                          Icons.person,
                                          color: Colors.grey,
                                          size: 16,
                                        )
                                        : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      teacher['name'] ?? 'Professor',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (teacher['email'] != null)
                                      Text(
                                        teacher['email'],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Lista de matérias
                        Expanded(
                          child: ListView(
                            children:
                                subjectTypes.map((type) {
                                  final isCurrentlyAssigned = currentSubjectsMap
                                      .containsKey(type);

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: CheckboxListTile(
                                      value: selectedSubjects.contains(type),
                                      onChanged:
                                          isLoading
                                              ? null
                                              : (v) {
                                                setState(() {
                                                  if (v == true) {
                                                    selectedSubjects.add(type);
                                                  } else {
                                                    selectedSubjects.remove(
                                                      type,
                                                    );
                                                  }
                                                });
                                              },
                                      title: Text(
                                        _formatSubjectType(type),
                                        style: TextStyle(
                                          fontWeight:
                                              isCurrentlyAssigned
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                        ),
                                      ),
                                      subtitle:
                                          isCurrentlyAssigned
                                              ? Text(
                                                'Atualmente atribuída',
                                                style: TextStyle(
                                                  color: Colors.green[700],
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              )
                                              : null,
                                      secondary:
                                          isCurrentlyAssigned
                                              ? Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withAlpha(
                                                    50,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.green
                                                        .withAlpha(100),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'ATIVA',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              )
                                              : null,
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),

                        // Resumo das mudanças
                        if (selectedSubjects.length != currentSubjects.length)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withAlpha(80),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Resumo das Mudanças:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '• Matérias atuais: ${currentSubjects.length}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '• Matérias selecionadas: ${selectedSubjects.length}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (selectedSubjects.length >
                                    currentSubjects.length)
                                  Text(
                                    '• Novas matérias: ${selectedSubjects.length - currentSubjects.length}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                if (selectedSubjects.length <
                                    currentSubjects.length)
                                  Text(
                                    '• Matérias removidas: ${currentSubjects.length - selectedSubjects.length}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red[700],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed:
                          (selectedSubjects.length == currentSubjects.length &&
                                      selectedSubjects.containsAll(
                                        currentSubjects.map((s) => s['type']),
                                      )) ||
                                  isLoading
                              ? null
                              : () async {
                                setState(() => isLoading = true);

                                try {
                                  final teacherId = teacher['id'];
                                  final classId = widget.classData['id'];

                                  // Remover matérias que não estão mais selecionadas
                                  final subjectsToRemove = <String>[];
                                  for (final subject in currentSubjects) {
                                    if (!selectedSubjects.contains(
                                      subject['type'],
                                    )) {
                                      subjectsToRemove.add(subject['id']);
                                    }
                                  }

                                  // Adicionar novas matérias
                                  final subjectsToAdd = <String>[];
                                  for (final subjectType in selectedSubjects) {
                                    if (!currentSubjectsMap.containsKey(
                                      subjectType,
                                    )) {
                                      subjectsToAdd.add(subjectType);
                                    }
                                  }

                                  int removedCount = 0;
                                  int addedCount = 0;

                                  // Remover matérias
                                  for (final subjectId in subjectsToRemove) {
                                    final response = await http.delete(
                                      Uri.parse(
                                        '${ApiConfig.baseUrl}/subjects/$subjectId',
                                      ),
                                      headers: {
                                        'Authorization': 'Bearer $token',
                                      },
                                    );
                                    if (response.statusCode == 200 ||
                                        response.statusCode == 204) {
                                      removedCount++;
                                    }
                                  }

                                  // Adicionar novas matérias
                                  for (final subjectType in subjectsToAdd) {
                                    final response = await http.post(
                                      Uri.parse(
                                        '${ApiConfig.baseUrl}/subjects',
                                      ),
                                      headers: {
                                        'Content-Type': 'application/json',
                                        'Authorization': 'Bearer $token',
                                      },
                                      body: jsonEncode({
                                        'type': subjectType,
                                        'classId': classId,
                                        'teacherId': teacherId,
                                      }),
                                    );
                                    if (response.statusCode == 201 ||
                                        response.statusCode == 200) {
                                      addedCount++;
                                    }
                                  }

                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();
                                  await _fetchSubjects();
                                  if (!mounted) return;

                                  // Mostrar resumo das operações
                                  String message = '';
                                  if (addedCount > 0 && removedCount > 0) {
                                    message =
                                        '$addedCount matéria(s) adicionada(s) e $removedCount removida(s) com sucesso!';
                                  } else if (addedCount > 0) {
                                    message =
                                        '$addedCount matéria(s) adicionada(s) com sucesso!';
                                  } else if (removedCount > 0) {
                                    message =
                                        '$removedCount matéria(s) removida(s) com sucesso!';
                                  }

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(message),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Erro ao gerenciar matérias: $e',
                                      ),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 5),
                                    ),
                                  );
                                } finally {
                                  if (context.mounted) {
                                    setState(() => isLoading = false);
                                  }
                                }
                              },
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Salvar Mudanças'),
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
                                              '${ApiConfig.baseUrl}${teacher['photoUrl']}',
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
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                teacher['name'] ?? 'Professor',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            // Botão de editar matérias do professor
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.blue,
                                                size: 20,
                                              ),
                                              tooltip:
                                                  'Gerenciar matérias do professor',
                                              onPressed:
                                                  () =>
                                                      _showManageTeacherSubjectsDialog(
                                                        teacher: teacher,
                                                        currentSubjects:
                                                            subjects,
                                                      ),
                                            ),
                                          ],
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
