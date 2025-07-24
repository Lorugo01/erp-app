import 'package:flutter/material.dart';
import 'class_students_screen.dart';
import 'class_teachers_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ClassDetailScreen extends StatelessWidget {
  final Map<String, dynamic> classData;
  const ClassDetailScreen({required this.classData, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2953A5),
        title: Text(classData['name'] ?? 'Turma'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classData['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Ano: ${classData['academicYear'] ?? ''}'),
                    Text(
                      'Série: ${classData['grade'] ?? ''}${classData['letter'] ?? ''}',
                    ),
                    Text('Turno: ${classData['shift'] ?? ''}'),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => ClassStudentsScreen(
                                        classData: classData,
                                      ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.groups),
                            label: const Text('Ver Alunos'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2953A5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              textStyle: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => ClassTeachersScreen(
                                        classData: classData,
                                      ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.school),
                            label: const Text('Ver Professores'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              textStyle: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Abas para calendário semanal e anual
                    DefaultTabController(
                      length: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TabBar(
                            labelColor: const Color(0xFF2953A5),
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: const Color(0xFF2953A5),
                            tabs: const [
                              Tab(text: 'Horário Semanal de Aulas'),
                              Tab(text: 'Eventos do Ano Letivo'),
                            ],
                          ),
                          SizedBox(
                            height: 420,
                            child: TabBarView(
                              children: [
                                _WeeklyScheduleTab(),
                                _AnnualEventsTab(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Aba: Horário Semanal de Aulas
class _WeeklyScheduleTab extends StatefulWidget {
  @override
  State<_WeeklyScheduleTab> createState() => _WeeklyScheduleTabState();
}

class _WeeklyScheduleTabState extends State<_WeeklyScheduleTab> {
  List<Map<String, dynamic>> events = [];
  final List<String> weekDays = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];
  final horarios = ['07:00', '07:50', '08:40', '09:50', '10:40'];
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

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    final parent = context.findAncestorWidgetOfExactType<ClassDetailScreen>();
    final turmaId = parent?.classData['id'] ?? '';
    final response = await http.get(
      Uri.parse('http://localhost:3000/classes/$turmaId/events'),
    );
    if (response.statusCode == 200) {
      setState(() {
        events = List<Map<String, dynamic>>.from(json.decode(response.body));
      });
    }
  }

  Future<void> addEvent(Map<String, dynamic> event) async {
    debugPrint('Enviando evento para o backend: $event');
    final parent = context.findAncestorWidgetOfExactType<ClassDetailScreen>();
    final turmaId = parent?.classData['id'] ?? '';
    final response = await http.post(
      Uri.parse('http://localhost:3000/classes/$turmaId/events'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(event),
    );
    debugPrint('Status da resposta: ${response.statusCode}');
    if (response.statusCode == 201) {
      fetchEvents();
    } else {
      // Mostra alerta de erro
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Erro ao salvar evento'),
                content: Text(
                  'Status: ${response.statusCode}\n${response.body}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    }
  }

  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('http://localhost:3000/classes/events/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      fetchEvents();
    }
  }

  Future<void> deleteEvent(String id) async {
    final response = await http.delete(
      Uri.parse('http://localhost:3000/classes/events/$id'),
    );
    if (response.statusCode == 204) {
      fetchEvents();
    }
  }

  void _confirmDeleteEvent(String eventId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Excluir evento'),
            content: const Text('Tem certeza que deseja excluir este evento?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await deleteEvent(eventId);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Excluir'),
              ),
            ],
          ),
    );
  }

  void _showEditEventDialog(Map<String, dynamic> evento) {
    String? subjectType = evento['title'];
    String? description = evento['description'];
    int dayOfWeek = evento['dayOfWeek'] ?? 1;
    String startTime = evento['startTime'] ?? horarios.first;
    String endTime = evento['endTime'] ?? horarios[1];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Aula'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: subjectType,
                  items:
                      subjectTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                type.replaceAll('_', ' ').toUpperCase(),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => subjectType = v,
                  decoration: const InputDecoration(labelText: 'Disciplina'),
                  validator: (v) => v == null ? 'Selecione a disciplina' : null,
                ),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Professor/Descrição',
                  ),
                  controller: TextEditingController(text: description),
                  onChanged: (v) => description = v,
                ),
                DropdownButtonFormField<int>(
                  value: dayOfWeek,
                  items: List.generate(
                    7,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(weekDays[i]),
                    ),
                  ),
                  onChanged: (v) => dayOfWeek = v ?? 1,
                  decoration: const InputDecoration(labelText: 'Dia da Semana'),
                ),
                DropdownButtonFormField<String>(
                  value: startTime,
                  items:
                      horarios
                          .map(
                            (h) => DropdownMenuItem(value: h, child: Text(h)),
                          )
                          .toList(),
                  onChanged: (v) => startTime = v ?? horarios.first,
                  decoration: const InputDecoration(labelText: 'Início'),
                ),
                DropdownButtonFormField<String>(
                  value: endTime,
                  items:
                      horarios
                          .map(
                            (h) => DropdownMenuItem(value: h, child: Text(h)),
                          )
                          .toList(),
                  onChanged: (v) => endTime = v ?? horarios[1],
                  decoration: const InputDecoration(labelText: 'Fim'),
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
              onPressed: () {
                if (subjectType != null && subjectType!.isNotEmpty) {
                  updateEvent(evento['id'], {
                    'title': subjectType,
                    'description': description,
                    'dayOfWeek': dayOfWeek,
                    'startTime': startTime,
                    'endTime': endTime,
                    'date': null,
                  });
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text('Salvar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await deleteEvent(evento['id']);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Adicionar Aula',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2953A5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                elevation: 4,
              ),
              onPressed: _showAddEventDialog,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Table(
                      border: TableBorder.all(color: Colors.grey[300]!),
                      defaultColumnWidth: FixedColumnWidth(120),
                      children: [
                        TableRow(
                          children: [
                            const TableCell(
                              child: Center(
                                child: Text(
                                  'Horário',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            ...weekDays.map(
                              (d) => TableCell(
                                child: Center(
                                  child: Text(
                                    d,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        ...horarios.map((horario) {
                          return TableRow(
                            children: [
                              TableCell(child: Center(child: Text(horario))),
                              ...List.generate(7, (dia) {
                                final celulaEventos =
                                    events
                                        .where(
                                          (e) =>
                                              e['dayOfWeek'] == dia + 1 &&
                                              e['startTime'] == horario &&
                                              e['date'] == null,
                                        )
                                        .toList();
                                return TableCell(
                                  child:
                                      celulaEventos.isEmpty
                                          ? const SizedBox.shrink()
                                          : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children:
                                                celulaEventos
                                                    .map(
                                                      (evento) => Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 2,
                                                            ),
                                                        child: GestureDetector(
                                                          onDoubleTap:
                                                              () =>
                                                                  _showEditEventDialog(
                                                                    evento,
                                                                  ),
                                                          child: Text(
                                                            evento['title']
                                                                    ?.replaceAll(
                                                                      '_',
                                                                      ' ',
                                                                    ) ??
                                                                '',
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                          ),
                                );
                              }),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddEventDialog() async {
    String? subjectType;
    String? teacherId;
    int dayOfWeek = 1;
    String startTime = horarios.first;
    String endTime = horarios[1];

    // Buscar subjects (matérias) da turma
    final parent = context.findAncestorWidgetOfExactType<ClassDetailScreen>();
    final turmaId = parent?.classData['id'] ?? '';
    final response = await http.get(
      Uri.parse('http://localhost:3000/classes/$turmaId'),
    );
    final turma = response.statusCode == 200 ? json.decode(response.body) : {};
    final List subjects = turma['subjects'] ?? [];
    final Map<String, List<Map<String, dynamic>>> professoresPorMateria = {};
    for (final subject in subjects) {
      final type = subject['type'];
      final teacher = subject['teacher'];
      if (type != null && teacher != null) {
        professoresPorMateria.putIfAbsent(type, () => []).add(teacher);
      }
    }
    final subjectTypesDisponiveis = professoresPorMateria.keys.toList();

    // Buscar eventos já cadastrados para a turma
    final eventsResponse = await http.get(
      Uri.parse('http://localhost:3000/classes/$turmaId/events'),
    );
    final List<Map<String, dynamic>> eventosExistentes =
        eventsResponse.statusCode == 200
            ? List<Map<String, dynamic>>.from(json.decode(eventsResponse.body))
            : [];

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final professoresDisponiveis =
                subjectType != null
                    ? professoresPorMateria[subjectType] ?? []
                    : [];
            return AlertDialog(
              title: const Text('Adicionar Aula'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: subjectType,
                      items:
                          subjectTypesDisponiveis
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type.replaceAll('_', ' ').toUpperCase(),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (v) {
                        setState(() {
                          subjectType = v;
                          teacherId = null;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Disciplina',
                      ),
                      validator:
                          (v) => v == null ? 'Selecione a disciplina' : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: teacherId,
                      items:
                          professoresDisponiveis
                              .map<DropdownMenuItem<String>>(
                                (t) => DropdownMenuItem(
                                  value: t['id'],
                                  child: Text(t['name']),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => teacherId = v),
                      decoration: const InputDecoration(labelText: 'Professor'),
                      validator:
                          (v) => v == null ? 'Selecione o professor' : null,
                    ),
                    DropdownButtonFormField<int>(
                      value: dayOfWeek,
                      items: List.generate(
                        7,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(weekDays[i]),
                        ),
                      ),
                      onChanged: (v) => setState(() => dayOfWeek = v ?? 1),
                      decoration: const InputDecoration(
                        labelText: 'Dia da Semana',
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: startTime,
                      items:
                          horarios
                              .map(
                                (h) =>
                                    DropdownMenuItem(value: h, child: Text(h)),
                              )
                              .toList(),
                      onChanged:
                          (v) =>
                              setState(() => startTime = v ?? horarios.first),
                      decoration: const InputDecoration(labelText: 'Início'),
                    ),
                    DropdownButtonFormField<String>(
                      value: endTime,
                      items:
                          horarios
                              .map(
                                (h) =>
                                    DropdownMenuItem(value: h, child: Text(h)),
                              )
                              .toList(),
                      onChanged:
                          (v) => setState(() => endTime = v ?? horarios[1]),
                      decoration: const InputDecoration(labelText: 'Fim'),
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
                      subjectType != null && teacherId != null
                          ? () {
                            // Validação: não pode haver duas aulas no mesmo dia e horário
                            final conflito = eventosExistentes.any(
                              (evento) =>
                                  evento['dayOfWeek'] == dayOfWeek &&
                                  evento['startTime'] == startTime &&
                                  evento['date'] == null,
                            );
                            if (conflito) {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('Conflito de Horário'),
                                      content: const Text(
                                        'Já existe uma aula cadastrada para este dia e horário nesta turma.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                              );
                              return;
                            }
                            addEvent({
                              'title': subjectType,
                              'teacherId': teacherId,
                              'dayOfWeek': dayOfWeek,
                              'startTime': startTime,
                              'endTime': endTime,
                              'date': null,
                            });
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          }
                          : null,
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Aba: Eventos do Ano Letivo
class _AnnualEventsTab extends StatefulWidget {
  @override
  State<_AnnualEventsTab> createState() => _AnnualEventsTabState();
}

class _AnnualEventsTabState extends State<_AnnualEventsTab> {
  List<Map<String, dynamic>> events = [];

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    final parent = context.findAncestorWidgetOfExactType<ClassDetailScreen>();
    final turmaId = parent?.classData['id'] ?? '';
    final response = await http.get(
      Uri.parse('http://localhost:3000/classes/$turmaId/events'),
    );
    if (response.statusCode == 200) {
      setState(() {
        events = List<Map<String, dynamic>>.from(json.decode(response.body));
      });
    }
  }

  Future<void> addEvent(Map<String, dynamic> event) async {
    final parent = context.findAncestorWidgetOfExactType<ClassDetailScreen>();
    final turmaId = parent?.classData['id'] ?? '';
    final response = await http.post(
      Uri.parse('http://localhost:3000/classes/$turmaId/events'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(event),
    );
    if (response.statusCode == 201) {
      fetchEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventosAnuais = events.where((e) => e['date'] != null).toList();
    return Column(
      children: [
        Expanded(
          child:
              eventosAnuais.isEmpty
                  ? const Center(child: Text('Nenhum evento anual cadastrado.'))
                  : ListView.builder(
                    itemCount: eventosAnuais.length,
                    itemBuilder: (context, i) {
                      final evento = eventosAnuais[i];
                      return ListTile(
                        leading: const Icon(Icons.event),
                        title: Text(evento['title'] ?? ''),
                        subtitle: Text(
                          (evento['description'] ?? '') +
                              (evento['date'] != null
                                  ? '\n${_formatDate(evento['date'])}'
                                  : ''),
                        ),
                      );
                    },
                  ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Adicionar Evento Anual'),
          onPressed: _showAddAnnualEventDialog,
        ),
      ],
    );
  }

  void _showAddAnnualEventDialog() {
    String? title;
    String? description;
    DateTime? date;
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Evento Anual'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Título'),
                  onChanged: (v) => title = v,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  onChanged: (v) => description = v,
                ),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(DateTime.now().year),
                      lastDate: DateTime(DateTime.now().year + 1),
                    );
                    if (picked != null) {
                      setState(() => date = picked);
                    }
                  },
                  child: Text(
                    date == null ? 'Selecionar Data' : _formatDate(date),
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
              onPressed: () {
                if (title != null && title!.isNotEmpty && date != null) {
                  addEvent({
                    'title': title,
                    'description': description,
                    'date': date!.toIso8601String(),
                    'teacherId': null,
                    'startTime': null,
                    'endTime': null,
                    'dayOfWeek': null,
                  });
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(dynamic date) {
    if (date is DateTime) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    if (date is String) {
      final d = DateTime.tryParse(date);
      if (d != null) {
        return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      }
    }
    return '';
  }
}
