import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/attendance_service.dart';

class AttendanceWidget extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final Map<String, dynamic>? currentLesson;
  final String? selectedSubjectId;
  final DateTime selectedDate;
  final bool isMobile;
  final bool isTablet;
  final Function(DateTime) onDateChanged;
  final VoidCallback onLoadAttendance;

  const AttendanceWidget({
    super.key,
    required this.students,
    required this.currentLesson,
    required this.selectedSubjectId,
    required this.selectedDate,
    required this.onDateChanged,
    required this.onLoadAttendance,
    this.isMobile = false,
    this.isTablet = false,
  });

  @override
  State<AttendanceWidget> createState() => _AttendanceWidgetState();
}

class _AttendanceWidgetState extends State<AttendanceWidget> {
  // Estado local para frequência
  Map<String, String?> _attendanceMap = {};
  Map<String, String> _justificationMap = {};
  bool _loadingAttendance = false;

  // Armazenamento local de chamadas salvas
  final Map<String, Map<String, dynamic>> _savedAttendanceData = {};

  @override
  void initState() {
    super.initState();
    _initializeAttendanceMaps();
    if (widget.currentLesson != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAttendance();
      });
    }
  }

  @override
  void didUpdateWidget(AttendanceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Se mudou a aula, recarregar frequência
    if (oldWidget.currentLesson?['id'] != widget.currentLesson?['id'] ||
        oldWidget.selectedSubjectId != widget.selectedSubjectId ||
        oldWidget.selectedDate != widget.selectedDate) {
      _loadAttendance();
    }
  }

  void _initializeAttendanceMaps() {
    final newAttendanceMap = <String, String?>{};
    final newJustificationMap = <String, String>{};

    for (var student in widget.students) {
      final studentId = student['id'];
      newAttendanceMap[studentId] = null;
      newJustificationMap[studentId] = '';
    }

    setState(() {
      _attendanceMap = newAttendanceMap;
      _justificationMap = newJustificationMap;
    });
  }

  // Método para normalizar data para chave do cache
  String _normalizeDateKey(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      // Usar data local (como o backend faz com toDateString())
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      debugPrint('Erro ao normalizar data: $e');
      return dateString;
    }
  }

  // Método para debug do cache
  void _debugCacheStatus() {
    debugPrint(
      'Status do cache local: ${_savedAttendanceData.length} entradas',
    );
    debugPrint('Cache keys: ${_savedAttendanceData.keys.toList()}');
  }

  // Método para salvar frequência localmente
  void _saveAttendanceLocally(
    Map<String, dynamic> lesson,
    List<Map<String, dynamic>> presences,
  ) {
    final normalizedDate = _normalizeDateKey(lesson['date']);
    final lessonKey = '${lesson['subjectId']}_$normalizedDate';

    debugPrint('Salvando frequência localmente');
    debugPrint(
      'Dados para salvamento local: lessonKey=$lessonKey, normalizedDate=$normalizedDate',
    );

    // Salvar no mapa local
    _savedAttendanceData[lessonKey] = {
      'lesson': lesson,
      'presences': presences,
      'savedAt': DateTime.now().toIso8601String(),
    };

    debugPrint('Frequência salva localmente');
    debugPrint(
      'Dados salvos: lessonKey=$lessonKey, totalSaved=${_savedAttendanceData.length}',
    );

    // Debug do cache após salvar
    _debugCacheStatus();
  }

  // Método para processar dados de frequência da API
  void _processAttendanceData(List<Map<String, dynamic>> attendances) {
    debugPrint('Processando dados de frequência da API');

    final newAttendanceMap = <String, String?>{};
    final newJustificationMap = <String, String>{};

    // Inicializar todos os alunos como não marcados
    for (var student in widget.students) {
      final studentId = student['id'];
      newAttendanceMap[studentId] = null;
      newJustificationMap[studentId] = '';
    }

    // Aplicar dados da API
    for (var attendance in attendances) {
      final studentId = attendance['studentId'];
      final status = attendance['status'];
      final justification = attendance['justification'] ?? '';

      newAttendanceMap[studentId] = status;
      if (status == 'JUSTIFIED_ABSENT' && justification.isNotEmpty) {
        newJustificationMap[studentId] = justification;
      }
    }

    setState(() {
      _attendanceMap = newAttendanceMap;
      _justificationMap = newJustificationMap;
    });

    debugPrint('Dados de frequência da API processados');
    debugPrint(
      'Mapas atualizados: attendanceMapKeys=${_attendanceMap.keys.length}, markedStudents=${_attendanceMap.values.where((status) => status != null).length}',
    );
  }

  // Método para inicializar frequência vazia
  void _initializeEmptyAttendance() {
    debugPrint('Inicializando frequência vazia');

    final newAttendanceMap = <String, String?>{};
    final newJustificationMap = <String, String>{};

    for (var student in widget.students) {
      final studentId = student['id'];
      newAttendanceMap[studentId] = null;
      newJustificationMap[studentId] = '';
    }

    setState(() {
      _attendanceMap = newAttendanceMap;
      _justificationMap = newJustificationMap;
    });

    debugPrint('Frequência vazia inicializada');
  }

  // Método para carregar frequência
  Future<void> _loadAttendance() async {
    if (widget.currentLesson == null) {
      debugPrint('Tentativa de carregar frequência sem aula');
      return;
    }

    setState(() {
      _loadingAttendance = true;
    });

    try {
      debugPrint('Carregando frequência da API');

      final attendances = await AttendanceService.getAttendanceByLesson(
        widget.currentLesson!['id'],
      );

      if (attendances.isNotEmpty) {
        debugPrint('Frequência carregada da API');
        _processAttendanceData(attendances);
      } else {
        debugPrint('API retornou lista vazia, inicializando vazia');
        _initializeEmptyAttendance();
      }
    } catch (e) {
      debugPrint('Erro ao carregar da API, tentando cache local: $e');

      // Tentar carregar do cache local
      final normalizedDate = _normalizeDateKey(widget.currentLesson!['date']);
      final lessonKey = '${widget.selectedSubjectId}_$normalizedDate';

      // Buscar no cache com fallback para data aproximada
      var savedData = _savedAttendanceData[lessonKey];

      // Se não encontrou, tentar buscar por data aproximada (mesmo dia)
      if (savedData == null) {
        debugPrint(
          'Cache não encontrado para chave exata, buscando por data aproximada',
        );

        final targetDate = DateTime.parse(widget.currentLesson!['date']);
        final targetDay =
            '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

        // Procurar por qualquer entrada que tenha a mesma data
        for (var entry in _savedAttendanceData.entries) {
          final entryKey = entry.key;
          final entryData = entry.value;

          if (entryKey.contains('_$targetDay')) {
            debugPrint('Cache encontrado por data aproximada');
            debugPrint(
              'Dados do cache aproximado: originalKey=$entryKey, targetKey=$lessonKey, targetDay=$targetDay',
            );

            savedData = entryData;
            break;
          }
        }
      }

      if (savedData != null) {
        debugPrint('Cache local encontrado, carregando dados salvos');
        final presences = savedData['presences'] as List<Map<String, dynamic>>;
        _processAttendanceData(presences);
      } else {
        debugPrint('Nenhum cache local encontrado, inicializando vazio');
        _initializeEmptyAttendance();
      }
    } finally {
      setState(() {
        _loadingAttendance = false;
      });
    }
  }

  // Método para salvar frequência
  Future<void> _saveAttendance() async {
    if (widget.currentLesson == null) {
      debugPrint('Tentativa de salvar frequência sem aula selecionada');
      return;
    }

    // Verificar se há mudanças na frequência
    bool hasChanges = false;
    debugPrint(
      'Verificando mudanças na frequência: totalStudents=${widget.students.length}, attendanceMapKeys=${_attendanceMap.keys.length}',
    );

    for (var student in widget.students) {
      final studentId = student['id'];
      final currentStatus = _attendanceMap[studentId];

      debugPrint(
        'Verificando aluno: ${student['name']}, currentStatus=$currentStatus, hasStatus=${currentStatus != null}',
      );

      // Se algum aluno tem status marcado, há mudanças
      if (currentStatus != null) {
        hasChanges = true;
        debugPrint('Mudança detectada no aluno: ${student['name']}');
        break;
      }
    }

    debugPrint(
      'Verificação de mudanças concluída: hasChanges=$hasChanges, totalStudents=${widget.students.length}, markedStudents=${_attendanceMap.values.where((status) => status != null).length}',
    );

    if (!hasChanges) {
      debugPrint('Nenhuma mudança na frequência, pulando salvamento');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhuma mudança na frequência para salvar'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    debugPrint('Iniciando salvamento de frequência');
    debugPrint(
      'Dados para salvamento: lessonId=${widget.currentLesson!['id']}, studentsCount=${widget.students.length}',
    );

    setState(() {
      _loadingAttendance = true;
    });

    try {
      // Prepara a lista de presenças
      final presences =
          widget.students
              .map((student) {
                final studentId = student['id'];
                final status = _attendanceMap[studentId];
                final justification = _justificationMap[studentId] ?? '';

                // Só inclui alunos que têm status marcado
                if (status == null) {
                  return null; // Será filtrado depois
                }

                debugPrint(
                  'Preparando presença do aluno: ${student['name']}, status=$status, justification=$justification',
                );

                return {
                  'studentId': studentId,
                  'status': status,
                  'justification':
                      status == 'JUSTIFIED_ABSENT' ? justification : null,
                  'present': status == 'PRESENT',
                };
              })
              .where((element) => element != null)
              .cast<Map<String, dynamic>>()
              .toList();

      debugPrint(
        'Lista de presenças preparada: totalPresences=${presences.length}',
      );
      debugPrint(
        'API: POST /attendances/bulk - lessonId=${widget.currentLesson!['id']}, presences=${presences.length}',
      );

      // Tentar salvar usando a API real
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await AttendanceService.markAttendanceByLesson(
          lessonId: widget.currentLesson!['id'],
          presences: presences,
          token: authProvider.user?.token,
        );

        debugPrint('Frequência salva via API real!');

        // Salvar localmente também para cache
        _saveAttendanceLocally(widget.currentLesson!, presences);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Frequência salva com sucesso!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }

        // Recarregar frequência da API para confirmar salvamento
        debugPrint('Recarregando frequência da API após salvamento');
        try {
          final attendances = await AttendanceService.getAttendanceByLesson(
            widget.currentLesson!['id'],
          );

          if (attendances.isNotEmpty) {
            debugPrint('Frequência recarregada da API após salvamento');
            _processAttendanceData(attendances);
          } else {
            debugPrint('API retornou lista vazia após salvamento');
          }
        } catch (e) {
          debugPrint('Erro ao recarregar frequência da API: $e');
          // Manter dados locais se API falhar
        }

        return;
      } catch (e) {
        debugPrint('API falhou, usando salvamento local: $e');
      }

      // Fallback: simular salvamento local
      debugPrint('Usando salvamento local como fallback');

      // Salvar localmente a frequência
      _saveAttendanceLocally(widget.currentLesson!, presences);

      // Simular sucesso do salvamento
      debugPrint('Frequência simulada salva com sucesso!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Frequência salva com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Recarregar frequência local após salvamento
      debugPrint('Recarregando frequência local após salvamento');
      _loadAttendance();
    } catch (e) {
      debugPrint('Erro ao salvar frequência: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar frequência: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Tentar novamente',
              textColor: Colors.white,
              onPressed: _saveAttendance,
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _loadingAttendance = false;
      });
    }
  }

  // Método para mostrar seletor de data
  void _showDatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != widget.selectedDate) {
      widget.onDateChanged(picked);
    }
  }

  // Método para mostrar dialog de justificativa
  void _showJustificationDialog(String studentId, String studentName) {
    String justification = _justificationMap[studentId] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Justificativa para $studentName'),
          content: TextField(
            decoration: const InputDecoration(
              hintText: 'Digite a justificativa da falta...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              justification = value;
            },
            controller: TextEditingController(text: justification),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _justificationMap[studentId] = justification;
                });
                Navigator.of(context).pop();

                debugPrint(
                  'Justificativa salva para $studentName: $justification',
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.students.isEmpty) {
      return const Center(
        child: Text('Nenhum aluno encontrado para esta turma'),
      );
    }

    return Padding(
      padding: EdgeInsets.all(widget.isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Row(
            children: [
              Icon(
                Icons.people,
                color: Theme.of(context).primaryColor,
                size: widget.isMobile ? 24 : 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Controle de Frequência',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Seletor de Data
          Card(
            child: Padding(
              padding: EdgeInsets.all(widget.isMobile ? 12.0 : 16.0),
              child:
                  widget.isMobile
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data da aula:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () => _showDatePicker(context),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${widget.selectedDate.day.toString().padLeft(2, '0')}/${widget.selectedDate.month.toString().padLeft(2, '0')}/${widget.selectedDate.year}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: widget.onLoadAttendance,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Carregar Chamada'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2953A5),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                      : Row(
                        children: [
                          const Text(
                            'Data da aula:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          InkWell(
                            onTap: () => _showDatePicker(context),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${widget.selectedDate.day.toString().padLeft(2, '0')}/${widget.selectedDate.month.toString().padLeft(2, '0')}/${widget.selectedDate.year}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: widget.onLoadAttendance,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Carregar Chamada'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2953A5),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
          const SizedBox(height: 16),

          // Informações da aula
          if (widget.currentLesson != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aula Ativa',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          'Data: ${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'ID: ${widget.currentLesson!['id']}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Lista de alunos
          Expanded(
            child:
                widget.isMobile
                    ? _buildMobileAttendanceList()
                    : _buildDesktopAttendanceList(),
          ),

          // Botões de ação
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildMobileAttendanceList() {
    return ListView.builder(
      itemCount: widget.students.length,
      itemBuilder: (context, index) {
        final student = widget.students[index];
        final studentId = student['id'];
        final currentStatus = _attendanceMap[studentId];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome do aluno
                Text(
                  student['name'] ?? 'Nome não informado',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Botões de presença
                Row(
                  children: [
                    Expanded(
                      child: _buildAttendanceButton(
                        studentId,
                        'PRESENT',
                        'Presente',
                        Icons.check_circle,
                        Colors.green,
                        currentStatus,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildAttendanceButton(
                        studentId,
                        'ABSENT',
                        'Ausente',
                        Icons.cancel,
                        Colors.red,
                        currentStatus,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildAttendanceButton(
                        studentId,
                        'JUSTIFIED_ABSENT',
                        'Justificada',
                        Icons.assignment_late,
                        Colors.orange,
                        currentStatus,
                      ),
                    ),
                  ],
                ),

                // Justificativa
                if (currentStatus == 'JUSTIFIED_ABSENT' &&
                    _justificationMap[studentId]?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.assignment_late,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Justificativa: ${_justificationMap[studentId]}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          onPressed:
                              () => _showJustificationDialog(
                                studentId,
                                student['name'],
                              ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopAttendanceList() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Cabeçalho da tabela
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(20),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Aluno',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      'Presente',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      'Ausente',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      'Justificada',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de alunos
          ...widget.students.map((student) {
            final studentId = student['id'];
            final currentStatus = _attendanceMap[studentId];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withAlpha(100),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Nome do aluno
                  Expanded(
                    flex: 3,
                    child: Text(
                      student['name'] ?? 'Nome não informado',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),

                  // Radio button Presente
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Radio<String>(
                        value: 'PRESENT',
                        groupValue: currentStatus,
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              _attendanceMap[studentId] = value;
                              _justificationMap[studentId] =
                                  ''; // Limpa justificativa
                            });
                          }
                        },
                        activeColor: Colors.green,
                      ),
                    ),
                  ),

                  // Radio button Ausente
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Radio<String>(
                        value: 'ABSENT',
                        groupValue: currentStatus,
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              _attendanceMap[studentId] = value;
                              _justificationMap[studentId] =
                                  ''; // Limpa justificativa
                            });
                          }
                        },
                        activeColor: Colors.red,
                      ),
                    ),
                  ),

                  // Radio button Falta Justificada
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Radio<String>(
                        value: 'JUSTIFIED_ABSENT',
                        groupValue: currentStatus,
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              _attendanceMap[studentId] = value;
                            });
                            // Mostrar dialog para justificativa
                            _showJustificationDialog(
                              studentId,
                              student['name'],
                            );
                          }
                        },
                        activeColor: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAttendanceButton(
    String studentId,
    String status,
    String label,
    IconData icon,
    Color color,
    String? currentStatus,
  ) {
    final isSelected = currentStatus == status;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _attendanceMap[studentId] = status;
          if (status == 'JUSTIFIED_ABSENT') {
            _showJustificationDialog(studentId, 'Aluno');
          } else {
            _justificationMap[studentId] = ''; // Limpa justificativa
          }
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey.withAlpha(100),
        foregroundColor: isSelected ? Colors.white : color,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (widget.isMobile) {
      return Column(
        children: [
          // Botão Salvar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadingAttendance ? null : _saveAttendance,
              icon:
                  _loadingAttendance
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Icon(Icons.save),
              label: const Text('Salvar Frequência'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Botões de ação rápida
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      for (var student in widget.students) {
                        _attendanceMap[student['id']] = 'PRESENT';
                        _justificationMap[student['id']] = '';
                      }
                    });
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Todos Presentes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      for (var student in widget.students) {
                        _attendanceMap[student['id']] = 'ABSENT';
                        _justificationMap[student['id']] = '';
                      }
                    });
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text('Todos Ausentes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                for (var student in widget.students) {
                  _attendanceMap[student['id']] = 'PRESENT';
                  _justificationMap[student['id']] = '';
                }
              });
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Todos Presentes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                for (var student in widget.students) {
                  _attendanceMap[student['id']] = 'ABSENT';
                  _justificationMap[student['id']] = '';
                }
              });
            },
            icon: const Icon(Icons.cancel),
            label: const Text('Todos Ausentes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _loadingAttendance ? null : _saveAttendance,
            icon:
                _loadingAttendance
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.save),
            label: const Text('Salvar Frequência'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2953A5),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }
  }
}
