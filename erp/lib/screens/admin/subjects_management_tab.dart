import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subject_provider.dart';

class SubjectsManagementTab extends StatefulWidget {
  const SubjectsManagementTab({super.key});

  @override
  State<SubjectsManagementTab> createState() => _SubjectsManagementTabState();
}

class _SubjectsManagementTabState extends State<SubjectsManagementTab> {
  final TextEditingController _searchController = TextEditingController();

  // Função local para formatar nome da matéria
  String _formatSubjectName(String? type) {
    if (type == null || type.isEmpty) return '';
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

  // Função local para converter para formato válido
  String _toValidSubjectType(String input) {
    return input.toUpperCase().replaceAll(' ', '_');
  }

  @override
  void initState() {
    super.initState();
    // Carregar matérias usando o provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubjectProvider>().fetchSubjects();
    });
  }

  List<Map<String, dynamic>> get _filteredSubjects {
    final subjectProvider = context.watch<SubjectProvider>();
    return subjectProvider.filterSubjects(_searchController.text);
  }

  void _showAddSubjectDialog() {
    String? selectedType;
    bool isEvaluative = true;
    String description = '';
    bool isLoading = false;
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
                        // Campo para nome da matéria
                        TextFormField(
                          controller: customTypeController,
                          onChanged: (v) {
                            selectedType = _toValidSubjectType(v);
                            setState(() {}); // Força a atualização da UI
                          },
                          decoration: const InputDecoration(
                            labelText: 'Nome da Matéria *',
                            border: OutlineInputBorder(),
                            hintText:
                                'Ex: Matemática, Português, História, etc.',
                            helperText: 'Digite o nome da matéria',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Descrição da matéria
                        TextFormField(
                          initialValue: description,
                          onChanged: (v) {
                            description = v;
                            setState(() {}); // Força a atualização da UI
                          },
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
                                '• Nome: ${customTypeController.text.isNotEmpty ? customTypeController.text : 'Digite o nome'}',
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
                          (customTypeController.text.trim().isEmpty ||
                                  isLoading)
                              ? null
                              : () async {
                                setState(() => isLoading = true);

                                try {
                                  final success = await context
                                      .read<SubjectProvider>()
                                      .createSubject(
                                        type: selectedType!,
                                        description: description,
                                        isEvaluative: isEvaluative,
                                      );

                                  if (!context.mounted) return;

                                  if (success) {
                                    Navigator.of(context).pop();
                                    // Forçar atualização da lista
                                    await context
                                        .read<SubjectProvider>()
                                        .fetchSubjects();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Matéria "${_formatSubjectName(selectedType)}" criada com sucesso!',
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  } else {
                                    final error =
                                        context.read<SubjectProvider>().error;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Erro ao criar matéria: $error',
                                        ),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 5),
                                      ),
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
                    'Editar Matéria: ${_formatSubjectName(subject['type'])}',
                  ),
                  content: SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Campo para nome da matéria
                        TextFormField(
                          initialValue: _formatSubjectName(selectedType),
                          onChanged:
                              (v) => selectedType = _toValidSubjectType(v),
                          decoration: const InputDecoration(
                            labelText: 'Nome da Matéria *',
                            border: OutlineInputBorder(),
                            hintText:
                                'Ex: Matemática, Português, História, etc.',
                            helperText: 'Digite o nome da matéria',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Descrição da matéria
                        TextFormField(
                          initialValue: description,
                          onChanged: (v) {
                            description = v;
                            setState(() {}); // Força a atualização da UI
                          },
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
                                  final success = await context
                                      .read<SubjectProvider>()
                                      .updateSubject(
                                        id: subject['id'],
                                        type: selectedType,
                                        description: description,
                                        isEvaluative: isEvaluative,
                                      );

                                  if (!context.mounted) return;

                                  if (success) {
                                    Navigator.of(context).pop();
                                    // Forçar atualização da lista
                                    await context
                                        .read<SubjectProvider>()
                                        .fetchSubjects();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Matéria "${_formatSubjectName(selectedType)}" atualizada com sucesso!',
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  } else {
                                    final error =
                                        context.read<SubjectProvider>().error;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Erro ao atualizar matéria: $error',
                                        ),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 5),
                                      ),
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
            'Não é possível excluir a matéria "${_formatSubjectName(subject['type'])}" pois está sendo usada por ${subject['classCount']} turma(s).',
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
                  'Tem certeza que deseja excluir a matéria "${_formatSubjectName(subject['type'])}"?',
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
      final success = await context.read<SubjectProvider>().deleteSubject(
        subject['id'],
      );

      if (!mounted) return;

      if (success) {
        // Forçar atualização da lista
        await context.read<SubjectProvider>().fetchSubjects();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Matéria "${_formatSubjectName(subject['type'])}" excluída com sucesso!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        final error = context.read<SubjectProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir matéria: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Consumer<SubjectProvider>(
      builder: (context, subjectProvider, child) {
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
                              onPressed: () => subjectProvider.fetchSubjects(),
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
                            onPressed: () => subjectProvider.fetchSubjects(),
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
                  subjectProvider.loading
                      ? const Center(child: CircularProgressIndicator())
                      : subjectProvider.error != null
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
                              subjectProvider.error!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => subjectProvider.fetchSubjects(),
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
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio:
                                      crossAxisCount == 1 ? 1.5 : 2.5,
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
      },
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

  // Função local para formatar nome da matéria
  String _formatSubjectName(String? type) {
    if (type == null || type.isEmpty) return '';
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

  @override
  Widget build(BuildContext context) {
    final description = subject['description'] ?? '';
    final classCount = subject['classCount'] ?? 0;
    final teacherCount = subject['teacherCount'] ?? 0;
    final studentCount = subject['studentCount'] ?? 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do card
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _formatSubjectName(subject['type']),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
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
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Estatísticas
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      label: 'Turmas',
                      value: classCount.toString(),
                      color: classCount > 0 ? Colors.blue : Colors.grey,
                      icon: Icons.class_,
                      isEmpty: classCount == 0,
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey[300]),
                  Expanded(
                    child: _StatItem(
                      label: 'Professores',
                      value: teacherCount.toString(),
                      color: teacherCount > 0 ? Colors.orange : Colors.grey,
                      icon: Icons.person,
                      isEmpty: teacherCount == 0,
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey[300]),
                  Expanded(
                    child: _StatItem(
                      label: 'Alunos',
                      value: studentCount.toString(),
                      color: studentCount > 0 ? Colors.green : Colors.grey,
                      icon: Icons.school,
                      isEmpty: studentCount == 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Mensagem quando não há dados
            if (classCount == 0 && teacherCount == 0 && studentCount == 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta matéria ainda não foi atribuída a nenhuma turma',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber[700],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

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
                            padding: const EdgeInsets.symmetric(vertical: 4),
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
                            padding: const EdgeInsets.symmetric(vertical: 4),
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
                            padding: const EdgeInsets.symmetric(vertical: 4),
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
                            padding: const EdgeInsets.symmetric(vertical: 4),
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
  final IconData? icon;
  final bool isEmpty;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 100;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: isSmall ? 16 : 18,
                color: isEmpty ? Colors.grey[400] : color,
              ),
              const SizedBox(height: 4),
            ],
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmall ? 12 : 14,
                color: isEmpty ? Colors.grey[400] : color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: isSmall ? 7 : 9,
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
