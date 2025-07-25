import 'package:flutter/material.dart';
import '../../services/assignment_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
  Set<String> _manuallyMarkedDelivered = {};

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();
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
                                  final url = widget.assignment['fileUrl'];
                                  final uri = Uri.parse(url);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
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
                                        final url = sub['fileUrl'];
                                        final uri = Uri.parse(url);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri);
                                        }
                                      },
                                    ),
                                  if (sub.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Marcado manualmente',
                                        style: TextStyle(
                                          color: Colors.orange,
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
                                backgroundColor: Colors.red.withOpacity(0.8),
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
          style: TextStyle(fontSize: 14, color: color.withOpacity(0.8)),
        ),
      ],
    );
  }
}
