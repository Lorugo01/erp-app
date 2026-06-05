import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SubjectsManagementTab extends StatefulWidget {
  const SubjectsManagementTab({super.key});

  @override
  State<SubjectsManagementTab> createState() => _SubjectsManagementTabState();
}

class _SubjectsManagementTabState extends State<SubjectsManagementTab> {
  List<Map<String, dynamic>> _subjects = [];
  bool _loading = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  int _countStudentsInClass(Map<String, dynamic>? classData) {
    if (classData == null) return 0;
    final enrollments = classData['enrollments'];
    if (enrollments is! List) return 0;
    return enrollments.where((e) => e['current'] == true).length;
  }

  Map<String, dynamic> _mapSubjectForUi(Map<String, dynamic> subject) {
    final classData = subject['class'] as Map<String, dynamic>?;
    final teacher = subject['teacher'] as Map<String, dynamic>?;
    final type = subject['type']?.toString() ?? '';

    return {
      'id': subject['id'],
      'type': type,
      'name': subject['name'] ?? _formatSubjectType(type),
      'description': teacher?['name'] != null
          ? 'Professor: ${teacher!['name']}'
          : 'Professor não informado',
      'className': classData?['name'] ?? 'Turma não informada',
      'isEvaluative': type != 'EDUCACAO_FISICA',
      'classCount': 1,
      'teacherCount': teacher?['id'] != null ? 1 : 0,
      'studentCount': _countStudentsInClass(classData),
      'raw': subject,
    };
  }

  Future<void> _fetchSubjects() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = _token();
      if (token == null || token.isEmpty) {
        throw Exception('Sessão expirada. Faça login novamente.');
      }

      final headers = _authHeaders(token);
      final subjectsFuture = http.get(
        Uri.parse('${ApiConfig.baseUrl}/subjects'),
        headers: headers,
      );
      final classesFuture = http.get(
        Uri.parse('${ApiConfig.baseUrl}/classes'),
        headers: headers,
      );

      final results = await Future.wait([subjectsFuture, classesFuture]);
      final response = results[0];
      final classesResponse = results[1];

      if (response.statusCode != 200) {
        throw Exception('Erro ao carregar matérias (${response.statusCode})');
      }

      final Map<String, Map<String, dynamic>> classesById = {};
      if (classesResponse.statusCode == 200) {
        final List<dynamic> classes = jsonDecode(classesResponse.body);
        for (final item in classes) {
          final classData = Map<String, dynamic>.from(item);
          classesById[classData['id']] = classData;
        }
      }

      final List<dynamic> data = jsonDecode(response.body);
      final subjects =
          data.map((item) {
            final subject = Map<String, dynamic>.from(item);
            final classId = subject['classId']?.toString();
            if (classId != null && classesById.containsKey(classId)) {
              subject['class'] = classesById[classId];
            }
            return _mapSubjectForUi(subject);
          }).toList();

      if (mounted) {
        setState(() {
          _subjects = subjects;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredSubjects {
    if (_searchController.text.isEmpty) return _subjects;
    return _subjects.where((subject) {
      final name = (subject['name'] ?? '').toString().toLowerCase();
      final type = _formatSubjectType(subject['type']).toLowerCase();
      final className = (subject['className'] ?? '').toString().toLowerCase();
      final search = _searchController.text.toLowerCase();
      return name.contains(search) ||
          type.contains(search) ||
          className.contains(search);
    }).toList();
  }

  void _showAddSubjectDialog() {
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

    String? selectedType;
    String? selectedClassId;
    String? selectedTeacherId;
    List<Map<String, dynamic>> classes = [];
    List<Map<String, dynamic>> teachers = [];
    bool loadingOptions = true;
    bool isLoading = false;

    bool optionsLoaded = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              Future<void> loadOptions() async {
                final token = _token();
                if (token == null) return;
                final headers = _authHeaders(token);
                try {
                  final classesRes = await http.get(
                    Uri.parse('${ApiConfig.baseUrl}/classes'),
                    headers: headers,
                  );
                  final teachersRes = await http.get(
                    Uri.parse('${ApiConfig.baseUrl}/teachers'),
                    headers: headers,
                  );
                  if (classesRes.statusCode == 200) {
                    classes = List<Map<String, dynamic>>.from(
                      jsonDecode(classesRes.body),
                    );
                  }
                  if (teachersRes.statusCode == 200) {
                    teachers = List<Map<String, dynamic>>.from(
                      jsonDecode(teachersRes.body),
                    );
                  }
                } finally {
                  if (context.mounted) {
                    setState(() => loadingOptions = false);
                  }
                }
              }

              if (!optionsLoaded) {
                optionsLoaded = true;
                loadOptions();
              }

              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text('Adicionar Nova Matéria'),
                content: SizedBox(
                  width: 500,
                  child: loadingOptions
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: selectedClassId,
                            items:
                                classes
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c['id']?.toString(),
                                        child: Text(c['name']?.toString() ?? 'Turma'),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => setState(() => selectedClassId = v),
                            decoration: const InputDecoration(
                              labelText: 'Turma *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: selectedTeacherId,
                            items:
                                teachers
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t['id']?.toString(),
                                        child: Text(t['name']?.toString() ?? 'Professor'),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (v) => setState(() => selectedTeacherId = v),
                            decoration: const InputDecoration(
                              labelText: 'Professor *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: selectedType,
                            items:
                                subjectTypes
                                    .map(
                                      (type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(_formatSubjectType(type)),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => setState(() => selectedType = v),
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Matéria *',
                              border: OutlineInputBorder(),
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
                        (selectedType == null ||
                                selectedClassId == null ||
                                selectedTeacherId == null ||
                                isLoading)
                            ? null
                            : () async {
                              setState(() => isLoading = true);
                              try {
                                final token = _token();
                                final response = await http.post(
                                  Uri.parse('${ApiConfig.baseUrl}/subjects'),
                                  headers: _authHeaders(token),
                                  body: jsonEncode({
                                    'type': selectedType,
                                    'classId': selectedClassId,
                                    'teacherId': selectedTeacherId,
                                  }),
                                );

                                if (!context.mounted) return;

                                if (response.statusCode == 201 ||
                                    response.statusCode == 200) {
                                  Navigator.of(context).pop();
                                  await _fetchSubjects();
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Matéria "${_formatSubjectType(selectedType)}" criada com sucesso!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  final body = response.body.trim();
                                  final error =
                                      body.startsWith('{')
                                          ? jsonDecode(body)['error']
                                          : body;
                                  throw Exception(error ?? 'Erro ao criar matéria');
                                }
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro ao criar matéria: $e'),
                                    backgroundColor: Colors.red,
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Criar Matéria'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showEditSubjectDialog(Map<String, dynamic> subject) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              subject['name']?.toString() ?? 'Matéria',
              overflow: TextOverflow.ellipsis,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Turma: ${subject['className'] ?? '-'}'),
                const SizedBox(height: 8),
                Text('Tipo: ${_formatSubjectType(subject['type']?.toString())}'),
                const SizedBox(height: 8),
                Text(subject['description']?.toString() ?? ''),
                const SizedBox(height: 12),
                Text('Alunos na turma: ${subject['studentCount'] ?? 0}'),
              ],
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

  Future<void> _deleteSubject(Map<String, dynamic> subject) async {
    final subjectName =
        subject['name']?.toString() ??
        _formatSubjectType(subject['type']?.toString());

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Confirmar Exclusão'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tem certeza que deseja excluir a matéria "$subjectName"?',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withAlpha(80)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ Esta ação não pode ser desfeita!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• A matéria será removida do sistema',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '• Não afetará turmas existentes',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/subjects/${subject['id']}'),
        headers: _authHeaders(_token()),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await _fetchSubjects();
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Matéria "$subjectName" excluída com sucesso!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        throw Exception('Erro ao excluir matéria');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir matéria: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 600;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSmall) ...[
                  // Layout para telas pequenas
                  const Text(
                    'Gerenciar Matérias',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2953A5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gerencie todas as matérias do sistema, suas propriedades e configurações',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showAddSubjectDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2953A5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Nova Matéria'),
                    ),
                  ),
                ] else ...[
                  // Layout para telas grandes
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gerenciar Matérias',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2953A5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Gerencie todas as matérias do sistema, suas propriedades e configurações',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _showAddSubjectDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2953A5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Nova Matéria'),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Barra de pesquisa e filtros
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 600;
            return Column(
              children: [
                if (isSmall) ...[
                  // Layout para telas pequenas
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Buscar matérias...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _fetchSubjects,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Colors.grey[700],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Atualizar'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Layout para telas grandes
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Buscar matérias...',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _fetchSubjects,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          foregroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Atualizar'),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Conteúdo principal
        Expanded(
          child:
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Erro ao carregar matérias',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchSubjects,
                          child: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  )
                  : _filteredSubjects.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _searchController.text.isEmpty
                              ? 'Nenhuma matéria cadastrada'
                              : 'Nenhuma matéria encontrada',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Clique em "Nova Matéria" para começar'
                              : 'Tente ajustar os termos de busca',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                  : LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount =
                          constraints.maxWidth < 800
                              ? 1
                              : constraints.maxWidth < 1200
                              ? 2
                              : 3;
                      const spacing = 16.0;
                      final cardWidth =
                          (constraints.maxWidth -
                              spacing * (crossAxisCount - 1)) /
                          crossAxisCount;

                      return SingleChildScrollView(
                        child: Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children:
                              _filteredSubjects.map((subject) {
                                return SizedBox(
                                  width: cardWidth,
                                  child: _SubjectCard(
                                    subject: subject,
                                    onEdit:
                                        () => _showEditSubjectDialog(subject),
                                    onDelete: () => _deleteSubject(subject),
                                  ),
                                );
                              }).toList(),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final Map<String, dynamic> subject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectCard({
    required this.subject,
    required this.onEdit,
    required this.onDelete,
  });

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
    final description = subject['description'] ?? '';
    final className = subject['className'] ?? '';
    final title = subject['name']?.toString() ?? _formatSubjectType(subject['type']);
    final classCount = subject['classCount'] ?? 0;
    final teacherCount = subject['teacherCount'] ?? 0;
    final studentCount = subject['studentCount'] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (className.isNotEmpty)
                  Text(
                    className,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Turmas',
                    value: classCount.toString(),
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Professores',
                    value: teacherCount.toString(),
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Alunos',
                    value: studentCount.toString(),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Excluir'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 100;
        return Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmall ? 14 : 16,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: isSmall ? 8 : 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}
