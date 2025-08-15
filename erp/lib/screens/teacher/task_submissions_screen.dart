import 'package:flutter/material.dart';
import '../../services/assignment_service.dart';
import '../../config/api_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TaskSubmissionsScreen extends StatefulWidget {
  final Map<String, dynamic> assignment;
  final List<Map<String, dynamic>> students;
  const TaskSubmissionsScreen({
    super.key,
    required this.assignment,
    required this.students,
  });

  @override
  State<TaskSubmissionsScreen> createState() => _TaskSubmissionsScreenState();
}

class _TaskSubmissionsScreenState extends State<TaskSubmissionsScreen> {
  List<Map<String, dynamic>> _submissions = [];
  bool _loading = false;
  String? _error;
  // Controle local de marcação manual
  final Set<String> _manuallyMarkedDelivered = {};

  // Para duplicação de atividade
  List<Map<String, dynamic>> _availableClasses = [];
  bool _loadingClasses = false;

  // Cores constantes
  static const _orangeAlpha = Color(0xB5FFA500); // Laranja com alpha 0.7
  static const _redAlpha = Color(0xBFFF0000); // Vermelho com alpha 0.75

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();
    _fetchAvailableClasses();
  }

  Future<void> _fetchSubmissions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final submissions = await AssignmentService.getSubmissionsByAssignment(
        widget.assignment['id'],
      );
      setState(() {
        _submissions = submissions;
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

  // Buscar turmas disponíveis para duplicação
  Future<void> _fetchAvailableClasses() async {
    setState(() {
      _loadingClasses = true;
    });

    try {
      // Buscar turmas onde o professor leciona a mesma disciplina
      // Esta é uma implementação básica - você pode expandir conforme necessário
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/teachers/classes?subjectId=${widget.assignment['subjectId']}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final classes = List<Map<String, dynamic>>.from(data);

        // Filtrar para excluir a turma atual
        final filteredClasses =
            classes
                .where((cls) => cls['id'] != widget.assignment['classId'])
                .toList();

        setState(() {
          _availableClasses = filteredClasses;
          _loadingClasses = false;
        });
      } else {
        setState(() {
          _availableClasses = [];
          _loadingClasses = false;
        });
      }
    } catch (e) {
      print('Erro ao buscar turmas disponíveis: $e');
      setState(() {
        _availableClasses = [];
        _loadingClasses = false;
      });
    }
  }

  // Mostrar dialog de duplicação de atividade
  void _showDuplicateAssignmentDialog() {
    showDialog(
      context: context,
      builder:
          (context) => _DuplicateAssignmentDialog(
            assignment: widget.assignment,
            availableClasses: _availableClasses,
            onDuplicate: (data) {
              _duplicateAssignment(
                targetClassIds: List<String>.from(data['targetClassIds']),
                targetDate: DateTime.parse(data['targetDate']),
              );
            },
          ),
    );
  }

  // Duplicar atividade para outras turmas
  Future<void> _duplicateAssignment({
    required List<String> targetClassIds,
    required DateTime targetDate,
  }) async {
    try {
      // Aqui você implementará a lógica para duplicar a atividade
      // Enviando para o backend
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/assignments/duplicate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sourceAssignmentId': widget.assignment['id'],
          'targetClassIds': targetClassIds,
          'targetDate': targetDate.toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Atividade duplicada com sucesso!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao duplicar atividade: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entregaramIds = _submissions.map((s) => s['studentId']).toSet();
    // Inclui os marcados manualmente
    final allDeliveredIds = {...entregaramIds, ..._manuallyMarkedDelivered};
    final alunosEntregaram =
        widget.students
            .where((s) => allDeliveredIds.contains(s['id']))
            .toList();
    final alunosNaoEntregaram =
        widget.students
            .where((s) => !allDeliveredIds.contains(s['id']))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Entregas da Atividade'),
            Text(
              widget.assignment['description']?.toString().split('\n').first ??
                  '',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2953A5),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _fetchSubmissions,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card com informações da atividade
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.assignment,
                                  color: Color(0xFF2953A5),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.assignment['description']
                                            ?.toString()
                                            .split('\n')
                                            .first ??
                                        'Sem nome',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Botão para duplicar atividade
                                ElevatedButton.icon(
                                  onPressed:
                                      _availableClasses.isNotEmpty
                                          ? () =>
                                              _showDuplicateAssignmentDialog()
                                          : null,
                                  icon: const Icon(Icons.copy),
                                  label: const Text('Duplicar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                                if (_availableClasses.isEmpty &&
                                    !_loadingClasses)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withAlpha(50),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.orange.withAlpha(100),
                                      ),
                                    ),
                                    child: const Text(
                                      'Nenhuma turma disponível para duplicação',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (widget.assignment['dueDate'] != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Entrega até: ${widget.assignment['dueDate'].toString().split('T').first}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                            if (widget.assignment['fileUrl'] != null) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                icon: const Icon(Icons.attach_file),
                                label: const Text('Baixar Anexo'),
                                onPressed: () async {
                                  final fileUrl = widget.assignment['fileUrl'];
                                  final url = '${ApiConfig.baseUrl}$fileUrl';
                                  final uri = Uri.parse(url);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Não foi possível abrir o arquivo',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Estatísticas
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatisticCard(
                                icon: Icons.check_circle,
                                color: Colors.green,
                                title: 'Entregaram',
                                value: alunosEntregaram.length.toString(),
                                total: widget.students.length,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatisticCard(
                                icon: Icons.cancel,
                                color: Colors.red,
                                title: 'Não Entregaram',
                                value: alunosNaoEntregaram.length.toString(),
                                total: widget.students.length,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Lista de alunos que entregaram
                    Text(
                      'Alunos que entregaram (${alunosEntregaram.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (alunosEntregaram.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Nenhum aluno entregou ainda.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: alunosEntregaram.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final aluno = alunosEntregaram[index];
                          final sub = _submissions.firstWhere(
                            (s) => s['studentId'] == aluno['id'],
                            orElse: () => <String, dynamic>{},
                          );
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green,
                                child: Text(
                                  aluno['name']
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      'A',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(aluno['name'] ?? ''),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (aluno['registrationNumber'] != null)
                                    Text(
                                      'Mat: ${aluno['registrationNumber']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  if (sub['description'] != null &&
                                      sub['description'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(sub['description']),
                                    ),
                                  if (sub['fileUrl'] != null &&
                                      sub['fileUrl'].toString().isNotEmpty)
                                    TextButton.icon(
                                      icon: const Icon(
                                        Icons.attach_file,
                                        size: 16,
                                      ),
                                      label: const Text('Baixar Arquivo'),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 0,
                                        ),
                                      ),
                                      onPressed: () async {
                                        final fileUrl = sub['fileUrl'];
                                        final url =
                                            '${ApiConfig.baseUrl}$fileUrl';
                                        final uri = Uri.parse(url);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri);
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Não foi possível abrir o arquivo',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  if (sub.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Marcado manualmente',
                                        style: TextStyle(
                                          color: _orangeAlpha,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing:
                                  sub.isEmpty
                                      ? IconButton(
                                        icon: const Icon(Icons.undo),
                                        tooltip: 'Desmarcar entrega manual',
                                        onPressed: () {
                                          setState(() {
                                            _manuallyMarkedDelivered.remove(
                                              aluno['id'],
                                            );
                                          });
                                        },
                                      )
                                      : null,
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),

                    // Lista de alunos que não entregaram
                    Text(
                      'Alunos que NÃO entregaram (${alunosNaoEntregaram.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (alunosNaoEntregaram.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Todos os alunos entregaram!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: alunosNaoEntregaram.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final aluno = alunosNaoEntregaram[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _redAlpha,
                                child: Text(
                                  aluno['name']
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      'A',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(aluno['name'] ?? ''),
                              subtitle:
                                  aluno['registrationNumber'] != null
                                      ? Text(
                                        'Mat: ${aluno['registrationNumber']}',
                                        style: const TextStyle(fontSize: 12),
                                      )
                                      : null,
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.orange,
                                ),
                                tooltip: 'Marcar como entregue (manual)',
                                onPressed: () {
                                  setState(() {
                                    _manuallyMarkedDelivered.add(aluno['id']);
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final int total;

  const _StatisticCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (int.parse(value) / total * 100).toStringAsFixed(1);

    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 14,
            color: color.withAlpha(204),
          ), // 0.8 * 255 ≈ 204
        ),
      ],
    );
  }
}

class _DuplicateAssignmentDialog extends StatefulWidget {
  final Map<String, dynamic> assignment;
  final List<Map<String, dynamic>> availableClasses;
  final Function(Map<String, dynamic>) onDuplicate;

  const _DuplicateAssignmentDialog({
    required this.assignment,
    required this.availableClasses,
    required this.onDuplicate,
  });

  @override
  State<_DuplicateAssignmentDialog> createState() =>
      _DuplicateAssignmentDialogState();
}

class _DuplicateAssignmentDialogState
    extends State<_DuplicateAssignmentDialog> {
  DateTime _targetDate = DateTime.now();
  List<String> _selectedClasses = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Duplicar Atividade'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Atividade: ${widget.assignment['description']}'),
          const SizedBox(height: 16),
          Text('Turmas disponíveis:'),
          if (widget.availableClasses.isEmpty)
            const Text('Nenhuma turma disponível para duplicação.'),
          if (widget.availableClasses.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.availableClasses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final classInfo = widget.availableClasses[index];
                return CheckboxListTile(
                  title: Text(classInfo['name'] ?? 'Turma Desconhecida'),
                  value: _selectedClasses.contains(classInfo['id']),
                  onChanged: (bool? newValue) {
                    setState(() {
                      if (newValue!) {
                        _selectedClasses.add(classInfo['id']);
                      } else {
                        _selectedClasses.remove(classInfo['id']);
                      }
                    });
                  },
                );
              },
            ),
          const SizedBox(height: 16),
          Text('Data de entrega:'),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _targetDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  _targetDate = date;
                });
              }
            },
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
                    '${_targetDate.day.toString().padLeft(2, '0')}/${_targetDate.month.toString().padLeft(2, '0')}/${_targetDate.year}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed:
              _selectedClasses.isEmpty
                  ? null
                  : () {
                    widget.onDuplicate({
                      'targetClassIds': _selectedClasses,
                      'targetDate': _targetDate.toIso8601String(),
                    });
                    Navigator.of(context).pop();
                  },
          child: const Text('Duplicar'),
        ),
      ],
    );
  }
}
