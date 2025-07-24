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
  // Novo: controle local de marcação manual
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
        title: const Text('Entregas da Atividade'),
        backgroundColor: Colors.orange,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alunos que entregaram:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (alunosEntregaram.isEmpty)
                      const Text('Nenhum aluno entregou ainda.'),
                    ...alunosEntregaram.map((aluno) {
                      final sub = _submissions.firstWhere(
                        (s) => s['studentId'] == aluno['id'],
                        orElse: () => <String, dynamic>{},
                      );
                      return Card(
                        child: ListTile(
                          title: Text(aluno['name'] ?? ''),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (sub['description'] != null &&
                                  sub['description'].toString().isNotEmpty)
                                Text(sub['description']),
                              if (sub['fileUrl'] != null &&
                                  sub['fileUrl'].toString().isNotEmpty)
                                TextButton.icon(
                                  icon: const Icon(Icons.attach_file),
                                  label: const Text('Baixar Arquivo'),
                                  onPressed: () async {
                                    final url = sub['fileUrl'];
                                    final uri = Uri.parse(url);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    }
                                  },
                                ),
                              if (sub.isEmpty &&
                                  !_manuallyMarkedDelivered.contains(
                                    aluno['id'],
                                  ))
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Marcado manualmente',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing:
                              sub.isEmpty
                                  ? IconButton(
                                    icon: const Icon(
                                      Icons.undo,
                                      color: Colors.grey,
                                    ),
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
                    }),
                    const SizedBox(height: 24),
                    Text(
                      'Alunos que NÃO entregaram:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (alunosNaoEntregaram.isEmpty)
                      const Text('Todos os alunos entregaram.'),
                    ...alunosNaoEntregaram.map(
                      (aluno) => ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(aluno['name'] ?? ''),
                        subtitle: Text(aluno['registrationNumber'] ?? ''),
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
                    ),
                  ],
                ),
              ),
    );
  }
}
