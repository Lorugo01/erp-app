import 'package:flutter/material.dart';
import '../../utils/user_friendly_error.dart';
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
  List<Map<String, dynamic>> _catalog = [];
  bool _loading = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  static const subjectTypes = [
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

  @override
  void initState() {
    super.initState();
    _fetchCatalog();
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

  String _formatSubjectType(String? type) {
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
        return type ?? '';
    }
  }

  Future<void> _fetchCatalog() async {
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

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/school-subjects'),
        headers: _authHeaders(token),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao carregar matérias (${response.statusCode})');
      }

      final List<dynamic> data = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          _catalog =
              data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = userErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchController.text.isEmpty) return _catalog;
    final search = _searchController.text.toLowerCase();
    return _catalog.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final type = _formatSubjectType(item['type']?.toString()).toLowerCase();
      return name.contains(search) || type.contains(search);
    }).toList();
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _showCreateDialog() async {
    String? selectedType;
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Nova Matéria'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          subjectTypes
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(_formatSubjectType(t)),
                                ),
                              )
                              .toList(),
                      onChanged: (v) {
                        setLocal(() {
                          selectedType = v;
                          if (nameController.text.trim().isEmpty && v != null) {
                            nameController.text = _formatSubjectType(v);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed:
                      saving
                          ? null
                          : () async {
                            if (selectedType == null) {
                              _snack('Selecione o tipo da matéria', error: true);
                              return;
                            }
                            setLocal(() => saving = true);
                            try {
                              final token = _token();
                              final response = await http.post(
                                Uri.parse(
                                  '${ApiConfig.baseUrl}/school-subjects',
                                ),
                                headers: {
                                  ..._authHeaders(token),
                                  'Content-Type': 'application/json',
                                },
                                body: jsonEncode({
                                  'type': selectedType,
                                  'name':
                                      nameController.text.trim().isEmpty
                                          ? _formatSubjectType(selectedType)
                                          : nameController.text.trim(),
                                  'description':
                                      descriptionController.text.trim(),
                                }),
                              );
                              if (response.statusCode != 201) {
                                final body = jsonDecode(response.body);
                                throw Exception(
                                  body['error'] ?? 'Erro ao criar matéria',
                                );
                              }
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                              _snack('Matéria criada no catálogo');
                              await _fetchCatalog();
                            } catch (e) {
                              _snack(userErrorMessage(e), error: true);
                            } finally {
                              setLocal(() => saving = false);
                            }
                          },
                  child:
                      saving
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Criar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showEditDialog(Map<String, dynamic> item) async {
    final offeringCount = item['offeringCount'] as int? ?? 0;
    final nameController = TextEditingController(
      text: item['name']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: item['description']?.toString() ?? '',
    );
    String selectedType = item['type']?.toString() ?? 'MATEMATICA';
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Editar Matéria'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        border: OutlineInputBorder(),
                        helperText:
                            'Tipo só pode mudar se não houver turmas vinculadas',
                      ),
                      items:
                          subjectTypes
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(_formatSubjectType(t)),
                                ),
                              )
                              .toList(),
                      onChanged:
                          offeringCount > 0
                              ? null
                              : (v) {
                                if (v != null) {
                                  setLocal(() => selectedType = v);
                                }
                              },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed:
                      saving
                          ? null
                          : () async {
                            setLocal(() => saving = true);
                            try {
                              final token = _token();
                              final response = await http.put(
                                Uri.parse(
                                  '${ApiConfig.baseUrl}/school-subjects/${item['id']}',
                                ),
                                headers: {
                                  ..._authHeaders(token),
                                  'Content-Type': 'application/json',
                                },
                                body: jsonEncode({
                                  'name': nameController.text.trim(),
                                  'description':
                                      descriptionController.text.trim(),
                                  if (offeringCount == 0) 'type': selectedType,
                                }),
                              );
                              if (response.statusCode != 200) {
                                final body = jsonDecode(response.body);
                                throw Exception(
                                  body['error'] ?? 'Erro ao salvar',
                                );
                              }
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                              _snack('Matéria atualizada');
                              await _fetchCatalog();
                            } catch (e) {
                              _snack(userErrorMessage(e), error: true);
                            } finally {
                              setLocal(() => saving = false);
                            }
                          },
                  child:
                      saving
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showOfferingsDialog(Map<String, dynamic> item) async {
    List<Map<String, dynamic>> classes = [];
    List<Map<String, dynamic>> teachers = [];
    List<Map<String, dynamic>> offerings = List<Map<String, dynamic>>.from(
      (item['offerings'] as List?) ?? const [],
    );
    String? selectedClassId;
    String? selectedTeacherId;
    bool loading = true;
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            Future<void> loadOptions() async {
              final token = _token();
              if (token == null) return;
              final headers = _authHeaders(token);
              final results = await Future.wait([
                http.get(
                  Uri.parse('${ApiConfig.baseUrl}/classes'),
                  headers: headers,
                ),
                http.get(
                  Uri.parse('${ApiConfig.baseUrl}/teachers'),
                  headers: headers,
                ),
                http.get(
                  Uri.parse(
                    '${ApiConfig.baseUrl}/school-subjects/${item['id']}',
                  ),
                  headers: headers,
                ),
              ]);
              if (results[0].statusCode == 200) {
                classes =
                    (jsonDecode(results[0].body) as List)
                        .map((e) => Map<String, dynamic>.from(e as Map))
                        .toList();
              }
              if (results[1].statusCode == 200) {
                teachers =
                    (jsonDecode(results[1].body) as List)
                        .map((e) => Map<String, dynamic>.from(e as Map))
                        .toList();
              }
              if (results[2].statusCode == 200) {
                final detail = jsonDecode(results[2].body) as Map;
                offerings = List<Map<String, dynamic>>.from(
                  (detail['offerings'] as List?) ?? const [],
                );
              }
              setLocal(() => loading = false);
            }

            if (loading) {
              Future.microtask(loadOptions);
            }

            final linkedClassIds =
                offerings.map((o) => o['classId']?.toString()).toSet();
            final availableClasses =
                classes
                    .where((c) => !linkedClassIds.contains(c['id']?.toString()))
                    .toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Turmas — ${item['name'] ?? _formatSubjectType(item['type']?.toString())}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              content: SizedBox(
                width: 420,
                child:
                    loading
                        ? const SizedBox(
                          height: 120,
                          child: Center(child: CircularProgressIndicator()),
                        )
                        : SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Vincular turma',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Turma',
                                  border: OutlineInputBorder(),
                                ),
                                items:
                                    availableClasses
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c['id']?.toString(),
                                            child: Text(
                                              c['name']?.toString() ?? '',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged:
                                    (v) => setLocal(() => selectedClassId = v),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Professor',
                                  border: OutlineInputBorder(),
                                ),
                                items:
                                    teachers
                                        .map(
                                          (t) => DropdownMenuItem(
                                            value: t['id']?.toString(),
                                            child: Text(
                                              t['name']?.toString() ?? '',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged:
                                    (v) =>
                                        setLocal(() => selectedTeacherId = v),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed:
                                    saving
                                        ? null
                                        : () async {
                                          if (selectedClassId == null ||
                                              selectedTeacherId == null) {
                                            _snack(
                                              'Selecione turma e professor',
                                              error: true,
                                            );
                                            return;
                                          }
                                          setLocal(() => saving = true);
                                          try {
                                            final token = _token();
                                            final response = await http.post(
                                              Uri.parse(
                                                '${ApiConfig.baseUrl}/school-subjects/${item['id']}/offerings',
                                              ),
                                              headers: {
                                                ..._authHeaders(token),
                                                'Content-Type':
                                                    'application/json',
                                              },
                                              body: jsonEncode({
                                                'classId': selectedClassId,
                                                'teacherId': selectedTeacherId,
                                              }),
                                            );
                                            if (response.statusCode != 201) {
                                              final body = jsonDecode(
                                                response.body,
                                              );
                                              throw Exception(
                                                body['error'] ??
                                                    'Erro ao vincular',
                                              );
                                            }
                                            selectedClassId = null;
                                            selectedTeacherId = null;
                                            setLocal(() => loading = true);
                                            await loadOptions();
                                            await _fetchCatalog();
                                            _snack('Turma vinculada');
                                          } catch (e) {
                                            _snack(
                                              userErrorMessage(e),
                                              error: true,
                                            );
                                          } finally {
                                            setLocal(() => saving = false);
                                          }
                                        },
                                child: const Text('Vincular'),
                              ),
                              const Divider(height: 24),
                              const Text(
                                'Turmas vinculadas',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              if (offerings.isEmpty)
                                const Text('Nenhuma turma vinculada ainda.')
                              else
                                ...offerings.map((o) {
                                  final className =
                                      o['class']?['name']?.toString() ??
                                      'Turma';
                                  final teacherName =
                                      o['teacher']?['name']?.toString() ??
                                      'Professor';
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(className),
                                    subtitle: Text(teacherName),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.link_off,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Remover vínculo',
                                      onPressed: () async {
                                        final ok = await showDialog<bool>(
                                          context: context,
                                          builder:
                                              (ctx) => AlertDialog(
                                                title: const Text(
                                                  'Remover vínculo',
                                                ),
                                                content: Text(
                                                  'Remover $className desta matéria?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          ctx,
                                                          false,
                                                        ),
                                                    child: const Text(
                                                      'Cancelar',
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          ctx,
                                                          true,
                                                        ),
                                                    child: const Text(
                                                      'Remover',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                        );
                                        if (ok != true) return;
                                        try {
                                          final token = _token();
                                          final response = await http.delete(
                                            Uri.parse(
                                              '${ApiConfig.baseUrl}/school-subjects/offerings/${o['id']}',
                                            ),
                                            headers: _authHeaders(token),
                                          );
                                          if (response.statusCode != 204 &&
                                              response.statusCode != 200) {
                                            final body =
                                                response.body.isNotEmpty
                                                    ? jsonDecode(response.body)
                                                    : {};
                                            throw Exception(
                                              body['error'] ??
                                                  'Erro ao remover',
                                            );
                                          }
                                          setLocal(() => loading = true);
                                          await loadOptions();
                                          await _fetchCatalog();
                                          _snack('Vínculo removido');
                                        } catch (e) {
                                          _snack(
                                            userErrorMessage(e),
                                            error: true,
                                          );
                                        }
                                      },
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Fechar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteCatalogItem(Map<String, dynamic> item) async {
    final name =
        item['name']?.toString() ??
        _formatSubjectType(item['type']?.toString());
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Excluir matéria'),
            content: Text(
              'Excluir "$name" do catálogo?\n\nSó é permitido se não houver turmas vinculadas.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    try {
      final token = _token();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/school-subjects/${item['id']}'),
        headers: _authHeaders(token),
      );
      if (response.statusCode != 204 && response.statusCode != 200) {
        final body =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        throw Exception(body['error'] ?? 'Erro ao excluir');
      }
      _snack('Matéria removida do catálogo');
      await _fetchCatalog();
    } catch (e) {
      _snack(userErrorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gerenciar Matérias',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Catálogo da escola: uma matéria (ex.: Matemática) serve para várias turmas.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text('Nova Matéria'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2953A5),
                foregroundColor: Colors.white,
              ),
            ),
            IconButton(
              onPressed: _fetchCatalog,
              icon: const Icon(Icons.refresh),
              tooltip: 'Atualizar',
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar matérias...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Expanded(
          child:
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _fetchCatalog,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  )
                  : _filtered.isEmpty
                  ? const Center(child: Text('Nenhuma matéria no catálogo'))
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
                              _filtered.map((item) {
                                return SizedBox(
                                  width: cardWidth,
                                  child: _CatalogCard(
                                    item: item,
                                    typeLabel: _formatSubjectType(
                                      item['type']?.toString(),
                                    ),
                                    onEdit: () => _showEditDialog(item),
                                    onManageOfferings:
                                        () => _showOfferingsDialog(item),
                                    onDelete: () => _deleteCatalogItem(item),
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

class _CatalogCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String typeLabel;
  final VoidCallback onEdit;
  final VoidCallback onManageOfferings;
  final VoidCallback onDelete;

  const _CatalogCard({
    required this.item,
    required this.typeLabel,
    required this.onEdit,
    required this.onManageOfferings,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = item['name']?.toString() ?? typeLabel;
    final description = item['description']?.toString() ?? '';
    final classCount = item['classCount'] ?? 0;
    final teacherCount = item['teacherCount'] ?? 0;
    final studentCount = item['studentCount'] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Tipo: $typeLabel',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _meta(Icons.class_, '$classCount turmas'),
                _meta(Icons.school, '$teacherCount professores'),
                _meta(Icons.groups, '$studentCount alunos'),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: onEdit,
                  child: const Text('Editar'),
                ),
                OutlinedButton(
                  onPressed: onManageOfferings,
                  child: const Text('Turmas'),
                ),
                OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Excluir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[700]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }
}
