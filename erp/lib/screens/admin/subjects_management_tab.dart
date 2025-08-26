import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';

class SubjectsManagementTab extends StatefulWidget {
  const SubjectsManagementTab({super.key});

  @override
  State<SubjectsManagementTab> createState() => _SubjectsManagementTabState();
}

class _SubjectsManagementTabState extends State<SubjectsManagementTab> {
  List<Map<String, dynamic>> _subjects = [];
  List<String> _availableTypes = []; // Lista dinâmica de tipos disponíveis
  bool _loading = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getSubjectsUrl('/types')),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _subjects = data.cast<Map<String, dynamic>>();
          // Extrair tipos únicos das matérias existentes
          _availableTypes =
              data.map<String>((subject) => subject['type'] as String).toList();
          _error = null;
        });
      } else {
        throw Exception('Erro ao carregar matérias');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredSubjects {
    if (_searchController.text.isEmpty) return _subjects;
    return _subjects.where((subject) {
      final name = _formatSubjectType(subject['type']).toLowerCase();
      final search = _searchController.text.toLowerCase();
      return name.contains(search);
    }).toList();
  }

  void _showAddSubjectDialog() {
    String? selectedType;
    bool isEvaluative = true;
    String description = '';
    bool isLoading = false;
    bool isCustomType = false;
    final TextEditingController customTypeController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Adicionar Nova Matéria'),
                  content: SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Checkbox para tipo personalizado
                        CheckboxListTile(
                          value: isCustomType,
                          onChanged: (v) {
                            setState(() {
                              isCustomType = v ?? false;
                              if (isCustomType) {
                                selectedType = null;
                              }
                            });
                          },
                          title: const Text('Criar novo tipo de matéria'),
                          subtitle: const Text(
                            'Marque para criar um tipo personalizado',
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        const SizedBox(height: 16),

                        if (!isCustomType) ...[
                          // Seleção de tipo existente
                          DropdownButtonFormField<String>(
                            value: selectedType,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Selecione um tipo'),
                              ),
                              ..._availableTypes.map<DropdownMenuItem<String>>(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(_formatSubjectType(type)),
                                ),
                              ),
                            ],
                            onChanged: (v) => setState(() => selectedType = v),
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Matéria *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ] else ...[
                          // Campo para tipo personalizado
                          TextFormField(
                            controller: customTypeController,
                            onChanged:
                                (v) =>
                                    selectedType = v.toUpperCase().replaceAll(
                                      ' ',
                                      '_',
                                    ),
                            decoration: const InputDecoration(
                              labelText: 'Nome do novo tipo *',
                              border: OutlineInputBorder(),
                              hintText: 'Ex: INFORMATICA, LITERATURA, etc.',
                              helperText: 'Use letras maiúsculas e underscores',
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Descrição da matéria
                        TextFormField(
                          initialValue: description,
                          onChanged: (v) => description = v,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Descrição (opcional)',
                            border: OutlineInputBorder(),
                            hintText:
                                'Descreva os objetivos e conteúdo da matéria...',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Checkbox para matéria avaliativa
                        CheckboxListTile(
                          value: isEvaluative,
                          onChanged:
                              (v) => setState(() => isEvaluative = v ?? true),
                          title: const Text('Matéria Avaliativa'),
                          subtitle: const Text(
                            'Esta matéria será avaliada com notas',
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),

                        // Informações adicionais
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withAlpha(80),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Informações da Matéria',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '• Tipo: ${selectedType != null ? _formatSubjectType(selectedType) : 'Selecione'}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                '• Avaliativa: ${isEvaluative ? 'Sim' : 'Não'}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              if (description.isNotEmpty)
                                Text(
                                  '• Descrição: ${description.length > 50 ? '${description.substring(0, 50)}...' : description}',
                                  style: const TextStyle(fontSize: 11),
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
                          (selectedType == null ||
                                  selectedType!.isEmpty ||
                                  isLoading)
                              ? null
                              : () async {
                                setState(() => isLoading = true);

                                try {
                                  final response = await http.post(
                                    Uri.parse(
                                      ApiConfig.getSubjectsUrl('/types'),
                                    ),
                                    headers: {
                                      'Content-Type': 'application/json',
                                    },
                                    body: jsonEncode({
                                      'type': selectedType,
                                      'description': description,
                                      'isEvaluative': isEvaluative,
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
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  } else {
                                    final errorBody = jsonDecode(response.body);
                                    throw Exception(
                                      errorBody['message'] ??
                                          'Erro ao criar matéria',
                                    );
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Erro ao criar matéria: $e',
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
                              : const Text('Criar Matéria'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showEditSubjectDialog(Map<String, dynamic> subject) {
    String selectedType = subject['type'] ?? '';
    bool isEvaluative = subject['isEvaluative'] ?? true;
    String description = subject['description'] ?? '';
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
                  title: Text(
                    'Editar Matéria: ${_formatSubjectType(subject['type'])}',
                  ),
                  content: SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Seleção de tipo de matéria (incluindo o tipo atual)
                        DropdownButtonFormField<String>(
                          value: selectedType,
                          items: [
                            ..._availableTypes.map<DropdownMenuItem<String>>(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(_formatSubjectType(type)),
                              ),
                            ),
                            // Incluir o tipo atual caso não esteja na lista
                            if (!_availableTypes.contains(selectedType))
                              DropdownMenuItem(
                                value: selectedType,
                                child: Text(_formatSubjectType(selectedType)),
                              ),
                          ],
                          onChanged:
                              (v) => setState(() => selectedType = v ?? ''),
                          decoration: const InputDecoration(
                            labelText: 'Tipo de Matéria *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Descrição da matéria
                        TextFormField(
                          initialValue: description,
                          onChanged: (v) => description = v,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Descrição (opcional)',
                            border: OutlineInputBorder(),
                            hintText:
                                'Descreva os objetivos e conteúdo da matéria...',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Checkbox para matéria avaliativa
                        CheckboxListTile(
                          value: isEvaluative,
                          onChanged:
                              (v) => setState(() => isEvaluative = v ?? true),
                          title: const Text('Matéria Avaliativa'),
                          subtitle: const Text(
                            'Esta matéria será avaliada com notas',
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),

                        // Estatísticas da matéria
                        Container(
                          padding: const EdgeInsets.all(8),
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
                                'Estatísticas da Matéria',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '• Turmas que usam: ${subject['classCount'] ?? 0}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                '• Professores: ${subject['teacherCount'] ?? 0}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                '• Alunos: ${subject['studentCount'] ?? 0}',
                                style: const TextStyle(fontSize: 11),
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
                          (selectedType.isEmpty || isLoading)
                              ? null
                              : () async {
                                setState(() => isLoading = true);

                                try {
                                  final response = await http.put(
                                    Uri.parse(
                                      ApiConfig.getSubjectsUrl(
                                        '/types/${subject['id']}',
                                      ),
                                    ),
                                    headers: {
                                      'Content-Type': 'application/json',
                                    },
                                    body: jsonEncode({
                                      'type': selectedType,
                                      'description': description,
                                      'isEvaluative': isEvaluative,
                                    }),
                                  );

                                  if (!context.mounted) return;

                                  if (response.statusCode == 200 ||
                                      response.statusCode == 201) {
                                    Navigator.of(context).pop();
                                    await _fetchSubjects();
                                    if (!mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Matéria "${_formatSubjectType(selectedType)}" atualizada com sucesso!',
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  } else {
                                    final errorBody = jsonDecode(response.body);
                                    throw Exception(
                                      errorBody['message'] ??
                                          'Erro ao atualizar matéria',
                                    );
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Erro ao atualizar matéria: $e',
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
                              : const Text('Salvar Alterações'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _deleteSubject(Map<String, dynamic> subject) async {
    // Verificar se a matéria está sendo usada
    final isInUse = subject['classCount'] != null && subject['classCount'] > 0;

    if (isInUse) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não é possível excluir a matéria "${_formatSubjectType(subject['type'])}" pois está sendo usada por ${subject['classCount']} turma(s).',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

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
                  'Tem certeza que deseja excluir a matéria "${_formatSubjectType(subject['type'])}"?',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
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
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• A matéria será removida do sistema',
                        style: TextStyle(fontSize: 11),
                      ),
                      Text(
                        '• Não afetará turmas existentes',
                        style: TextStyle(fontSize: 11),
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
        Uri.parse(ApiConfig.getSubjectsUrl('/types/${subject['id']}')),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await _fetchSubjects();
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Matéria "${_formatSubjectType(subject['type'])}" excluída com sucesso!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Erro ao excluir matéria');
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

    // Mapeamento dos tipos padrão
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
        // Para tipos personalizados, converter de UPPER_CASE para Title Case
        return type
            .toLowerCase()
            .split('_')
            .map(
              (word) =>
                  word.isNotEmpty
                      ? '${word[0].toUpperCase()}${word.substring(1)}'
                      : '',
            )
            .join(' ')
            .trim();
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
                      ElevatedButton.icon(
                        onPressed: _showAddSubjectDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Nova Matéria'),
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
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 12),

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
                      prefixIcon: const Icon(Icons.search),
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
                            prefixIcon: const Icon(Icons.search),
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
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
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
                        Icon(
                          Icons.book_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
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
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: crossAxisCount == 1 ? 1.5 : 1.2,
                        ),
                        itemCount: _filteredSubjects.length,
                        itemBuilder: (context, index) {
                          final subject = _filteredSubjects[index];
                          return _SubjectCard(
                            subject: subject,
                            onEdit: () => _showEditSubjectDialog(subject),
                            onDelete: () => _deleteSubject(subject),
                          );
                        },
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

  @override
  Widget build(BuildContext context) {
    final isEvaluative = subject['isEvaluative'] ?? true;
    final description = subject['description'] ?? '';
    final classCount = subject['classCount'] ?? 0;
    final teacherCount = subject['teacherCount'] ?? 0;
    final studentCount = subject['studentCount'] ?? 0;

    // Função local para formatação (usa a mesma lógica da classe principal)
    String formatSubjectType(String? type) {
      if (type == null) return '';

      // Mapeamento dos tipos padrão
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
          // Para tipos personalizados, converter de UPPER_CASE para Title Case
          return type
              .toLowerCase()
              .split('_')
              .map(
                (word) =>
                    word.isNotEmpty
                        ? '${word[0].toUpperCase()}${word.substring(1)}'
                        : '',
              )
              .join(' ')
              .trim();
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do card
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isEvaluative
                            ? Colors.green.withAlpha(50)
                            : Colors.grey.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isEvaluative ? 'A' : 'N',
                    style: TextStyle(
                      color: isEvaluative ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatSubjectType(subject['type']),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Estatísticas
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
            const SizedBox(height: 16),

            // Botões de ação
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 300;
                if (isSmall) {
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
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
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
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
                  );
                } else {
                  return Row(
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
                  );
                }
              },
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
