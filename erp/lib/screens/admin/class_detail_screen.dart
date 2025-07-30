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
        title: Text(
          classData['name'] ?? 'Turma',
          style: const TextStyle(color: Colors.white),
        ),
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
                    // Título do horário semanal
                    const Text(
                      'Horário Semanal de Aulas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2953A5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Widget do horário semanal
                    SizedBox(height: 420, child: _WeeklyScheduleTab()),
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
  List<Map<String, dynamic>> professores = [];
  final List<String> weekDays = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];

  // Lista de horários gerada dinamicamente
  List<String> horarios = [];

  // Duração padrão de cada aula em minutos
  final int duracaoAula = 50;
  final int intervalo = 10;

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
    _gerarHorarios();
    _garantirHorariosMinimos();
    fetchEvents();
    fetchProfessores();

    // Debug: verifica os horários após inicialização
    debugPrint('Horários após initState: $horarios');
  }

  void _gerarHorarios() {
    final parent = context.findAncestorWidgetOfExactType<ClassDetailScreen>();
    final turno = parent?.classData['shift']?.toString().toUpperCase() ?? '';

    int horaInicio;
    int horaFim;

    switch (turno) {
      case 'MATUTINO':
        horaInicio = 6; // 1 hora antes do limite
        horaFim = 13; // 1 hora depois do limite
        break;
      case 'VESPERTINO':
        horaInicio = 12; // 1 hora antes do limite
        horaFim = 18; // 1 hora depois do limite
        break;
      case 'NOTURNO':
        horaInicio = 17; // 1 hora antes do limite
        horaFim = 23; // 1 hora depois do limite
        break;
      case 'INTEGRAL':
        horaInicio = 6; // 1 hora antes do limite
        horaFim = 23; // 1 hora depois do limite
        break;
      default:
        horaInicio = 6;
        horaFim = 13;
    }

    // Gera horários de 30 em 30 minutos
    final Set<String> horariosSet = {};
    for (int hora = horaInicio; hora <= horaFim; hora++) {
      horariosSet.add('${hora.toString().padLeft(2, '0')}:00');
      if (hora < horaFim) {
        horariosSet.add('${hora.toString().padLeft(2, '0')}:30');
      }
    }

    // Adiciona horários existentes nos eventos
    for (var evento in events) {
      final startTime = evento['startTime'];
      final endTime = evento['endTime'];
      if (startTime != null) {
        horariosSet.add(startTime);
      }
      if (endTime != null) {
        horariosSet.add(endTime);
      }
    }

    // Converte para lista ordenada
    horarios = horariosSet.toList()..sort();

    // Debug: verifica se os horários estão sendo gerados
    debugPrint('Horários gerados: $horarios');
    debugPrint('Quantidade de horários: ${horarios.length}');

    // Garante que sempre há pelo menos 2 horários disponíveis
    _garantirHorariosMinimos();
  }

  void _garantirHorariosMinimos() {
    if (horarios.isEmpty) {
      horarios = ['07:00', '07:30'];
    } else if (horarios.length == 1) {
      final primeiroHorario = horarios.first;
      final partes = primeiroHorario.split(':');
      final hora = int.parse(partes[0]);
      final minuto = int.parse(partes[1]);
      final proximoMinuto = minuto + 30;
      final proximaHora = hora + (proximoMinuto ~/ 60);
      final minutoFinal = proximoMinuto % 60;
      horarios.add(
        '${proximaHora.toString().padLeft(2, '0')}:${minutoFinal.toString().padLeft(2, '0')}',
      );
      // Reordena após adicionar
      horarios.sort();
    }
  }

  void _atualizarHorariosComNovoEvento(String startTime, String endTime) {
    // Adiciona horários de início e fim se não existirem
    if (!horarios.contains(startTime)) {
      horarios.add(startTime);
    }
    if (!horarios.contains(endTime)) {
      horarios.add(endTime);
    }

    // Remove duplicatas e ordena
    horarios = horarios.toSet().toList()..sort();
    setState(() {}); // Atualiza a tabela com os novos horários
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
      _gerarHorarios(); // Atualiza a lista de horários após carregar eventos
      _garantirHorariosMinimos();

      // Garante que não há duplicatas após carregar eventos
      setState(() {
        horarios = horarios.toSet().toList()..sort();
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
      _atualizarHorariosComNovoEvento(event['startTime'], event['endTime']);
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
      _atualizarHorariosComNovoEvento(data['startTime'], data['endTime']);
    }
  }

  Future<void> deleteEvent(String id) async {
    final response = await http.delete(
      Uri.parse('http://localhost:3000/classes/events/$id'),
    );
    if (response.statusCode == 204) {
      fetchEvents();
      _gerarHorarios(); // Recarrega os horários após exclusão
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
    // Garante que há horários disponíveis antes de abrir o diálogo
    _garantirHorariosMinimos();

    String? subjectType = evento['title'];
    String? description = evento['description'];
    int dayOfWeek = evento['dayOfWeek'] ?? 1;
    String startTime =
        evento['startTime'] ?? (horarios.isNotEmpty ? horarios.first : '07:00');
    String endTime =
        evento['endTime'] ?? (horarios.length > 1 ? horarios[1] : '07:50');
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
                  value:
                      horarios.contains(startTime)
                          ? startTime
                          : (horarios.isNotEmpty ? horarios.first : null),
                  items:
                      horarios
                          .map(
                            (h) => DropdownMenuItem(value: h, child: Text(h)),
                          )
                          .toList(),
                  onChanged:
                      (v) =>
                          startTime =
                              v ??
                              (horarios.isNotEmpty ? horarios.first : '07:00'),
                  decoration: const InputDecoration(labelText: 'Início'),
                ),
                DropdownButtonFormField<String>(
                  value:
                      horarios.contains(endTime)
                          ? endTime
                          : (horarios.length > 1 ? horarios[1] : null),
                  items:
                      horarios
                          .map(
                            (h) => DropdownMenuItem(value: h, child: Text(h)),
                          )
                          .toList(),
                  onChanged:
                      (v) =>
                          endTime =
                              v ??
                              (horarios.length > 1 ? horarios[1] : '07:50'),
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
    // Garante que sempre há horários disponíveis antes de renderizar
    _garantirHorariosMinimos();

    // Garante que não há duplicatas antes de renderizar
    horarios = horarios.toSet().toList()..sort();

    // Debug: verifica os horários antes de renderizar
    debugPrint('Horários antes de renderizar: $horarios');
    debugPrint('Quantidade de horários: ${horarios.length}');

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
                      columnWidths: const {0: FixedColumnWidth(80)},
                      defaultColumnWidth: FixedColumnWidth(90),
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
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
                              TableCell(
                                child: SizedBox(
                                  height: 45,
                                  width: 80,
                                  child: Center(
                                    child: Text(
                                      horario,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ),
                              ),
                              ...List.generate(7, (dia) {
                                // Verifica se este horário está dentro do intervalo de algum evento
                                Map<String, dynamic>? evento;
                                try {
                                  evento = events.firstWhere((e) {
                                    if (e['dayOfWeek'] != dia + 1 ||
                                        e['date'] != null) {
                                      return false;
                                    }
                                    final startIndex = horarios.indexOf(
                                      e['startTime'],
                                    );
                                    final endIndex = horarios.indexOf(
                                      e['endTime'],
                                    );
                                    final currentIndex = horarios.indexOf(
                                      horario,
                                    );
                                    return startIndex != -1 &&
                                        endIndex != -1 &&
                                        currentIndex >= startIndex &&
                                        currentIndex <= endIndex;
                                  });
                                } catch (e) {
                                  evento = null;
                                }

                                if (evento != null) {
                                  // Renderiza o evento em cada célula do intervalo

                                  return TableCell(
                                    child: GestureDetector(
                                      onDoubleTap:
                                          () => _showEditEventDialog(evento!),
                                      child: Container(
                                        height: 45,
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 1,
                                          horizontal: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF2953A5,
                                          ).withAlpha(100),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF2953A5),
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(1),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              evento['title']?.replaceAll(
                                                    '_',
                                                    ' ',
                                                  ) ??
                                                  '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                            if (evento['description'] != null)
                                              Text(
                                                evento['description'],
                                                style: const TextStyle(
                                                  fontSize: 7,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            Text(
                                              _getTeacherName(evento),
                                              style: const TextStyle(
                                                fontSize: 10,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  // Célula normal vazia
                                  return const TableCell(
                                    child: SizedBox.shrink(),
                                  );
                                }
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

  String _gerarHorarioIntermediario(String horaBase) {
    // Converte a string de hora para minutos
    final partes = horaBase.split(':');
    final horas = int.parse(partes[0]);
    final minutos = int.parse(partes[1]);
    final totalMinutos = horas * 60 + minutos;

    // Adiciona 50 minutos (duração padrão da aula)
    final novoTotalMinutos = totalMinutos + duracaoAula;

    // Converte de volta para formato de hora
    final novaHora = (novoTotalMinutos ~/ 60).toString().padLeft(2, '0');
    final novoMinuto = (novoTotalMinutos % 60).toString().padLeft(2, '0');

    return '$novaHora:$novoMinuto';
  }

  List<String> _gerarOpcoesHorarioFim(String horaInicio) {
    // Garante que há horários disponíveis
    _garantirHorariosMinimos();

    // Retorna todos os horários que vêm depois do horário de início
    final opcoes = horarios.where((h) => h.compareTo(horaInicio) > 0).toList();

    // Se não há opções, gera um horário padrão
    if (opcoes.isEmpty) {
      try {
        final partes = horaInicio.split(':');
        if (partes.length >= 2) {
          final hora = int.parse(partes[0]);
          final minuto = int.parse(partes[1]);
          final proximoMinuto = minuto + 30;
          final proximaHora = hora + (proximoMinuto ~/ 60);
          final minutoFinal = proximoMinuto % 60;
          return [
            '${proximaHora.toString().padLeft(2, '0')}:${minutoFinal.toString().padLeft(2, '0')}',
          ];
        }
      } catch (e) {
        // Se houver erro ao processar o horário, retorna um horário padrão
        debugPrint('Erro ao processar horário: $horaInicio - $e');
      }

      // Fallback: retorna um horário padrão
      return ['07:30'];
    }

    return opcoes;
  }

  Future<void> fetchProfessores() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/teachers'),
      );
      if (response.statusCode == 200) {
        setState(() {
          professores = List<Map<String, dynamic>>.from(
            json.decode(response.body),
          );
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar professores: $e');
    }
  }

  String _getTeacherName(Map<String, dynamic> evento) {
    // Se o evento tem dados do professor diretamente
    if (evento['teacher'] != null && evento['teacher']['name'] != null) {
      return evento['teacher']['name'];
    }

    // Se tem teacherId, busca o professor na lista
    if (evento['teacherId'] != null) {
      final professor = professores.firstWhere(
        (p) => p['id'] == evento['teacherId'],
        orElse: () => {},
      );
      if (professor.isNotEmpty && professor['name'] != null) {
        return professor['name'];
      }
    }

    return 'Professor não definido';
  }

  void _showAddEventDialog() async {
    // Garante que há horários disponíveis antes de abrir o diálogo
    _garantirHorariosMinimos();

    String? subjectType;
    String? teacherId;
    int dayOfWeek = 1;
    String startTime = horarios.isNotEmpty ? horarios.first : '07:00';
    String endTime = horarios.length > 1 ? horarios[1] : '07:30';

    // Buscar subjects (matérias) da turma
    final parent = context.findAncestorWidgetOfExactType<ClassDetailScreen>();
    final turmaId = parent?.classData['id'] ?? '';

    if (!mounted) return;

    final response = await http.get(
      Uri.parse('http://localhost:3000/classes/$turmaId'),
    );

    if (!mounted) return;

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
    if (!mounted) return;

    final eventsResponse = await http.get(
      Uri.parse('http://localhost:3000/classes/$turmaId/events'),
    );

    if (!mounted) return;

    final List<Map<String, dynamic>> eventosExistentes =
        eventsResponse.statusCode == 200
            ? List<Map<String, dynamic>>.from(json.decode(eventsResponse.body))
            : [];

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
                      value:
                          horarios.contains(startTime)
                              ? startTime
                              : (horarios.isNotEmpty ? horarios.first : null),
                      items:
                          horarios
                              .map(
                                (h) =>
                                    DropdownMenuItem(value: h, child: Text(h)),
                              )
                              .toList(),
                      onChanged:
                          (v) => setState(() {
                            startTime = v ?? startTime;
                            if (v != null) {
                              endTime = _gerarHorarioIntermediario(v);
                            }
                          }),
                      decoration: const InputDecoration(labelText: 'Início'),
                    ),
                    DropdownButtonFormField<String>(
                      value:
                          _gerarOpcoesHorarioFim(startTime).contains(endTime)
                              ? endTime
                              : (_gerarOpcoesHorarioFim(startTime).isNotEmpty
                                  ? _gerarOpcoesHorarioFim(startTime).first
                                  : null),
                      items:
                          _gerarOpcoesHorarioFim(startTime)
                              .map(
                                (h) =>
                                    DropdownMenuItem(value: h, child: Text(h)),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => endTime = v ?? endTime),
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
                            Navigator.of(context).pop();
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
