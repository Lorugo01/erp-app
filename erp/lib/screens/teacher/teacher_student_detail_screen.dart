import 'package:flutter/material.dart';
import '../../services/grade_service.dart';
import '../../services/grade_type_service.dart';
import '../../services/attendance_service.dart';
import '../../services/grade_period_service.dart';
import 'package:intl/intl.dart';

// Classe utilitária para logging estruturado
class TeacherStudentDetailLogger {
  static const String _prefix = '👤 [TeacherStudentDetail]';

  static void info(String message) {
    debugPrint('$_prefix ℹ️ $message');
  }

  static void success(String message) {
    debugPrint('$_prefix ✅ $message');
  }

  static void warning(String message) {
    debugPrint('$_prefix ⚠️ $message');
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    debugPrint('$_prefix ❌ $message');
    if (error != null) {
      debugPrint('$_prefix 🔍 Erro detalhado: $error');
    }
    if (stackTrace != null) {
      debugPrint('$_prefix 📍 Stack trace: $stackTrace');
    }
  }

  static void debug(String message, [Map<String, dynamic>? data]) {
    debugPrint('$_prefix 🐛 $message');
    if (data != null) {
      debugPrint('$_prefix 📊 Dados: $data');
    }
  }

  static void api(
    String endpoint,
    String method, [
    Map<String, dynamic>? params,
  ]) {
    debugPrint('$_prefix 🌐 API: $method $endpoint');
    if (params != null) {
      debugPrint('$_prefix 📝 Parâmetros: $params');
    }
  }

  static void state(String message, [Map<String, dynamic>? state]) {
    debugPrint('$_prefix 🔄 Estado: $message');
    if (state != null) {
      debugPrint('$_prefix 📊 Estado atual: $state');
    }
  }
}

class TeacherStudentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  final Map<String, dynamic> classData;
  final String subjectId;
  final String teacherId;

  const TeacherStudentDetailScreen({
    super.key,
    required this.student,
    required this.classData,
    required this.subjectId,
    required this.teacherId,
  });

  @override
  State<TeacherStudentDetailScreen> createState() =>
      _TeacherStudentDetailScreenState();
}

class _TeacherStudentDetailScreenState
    extends State<TeacherStudentDetailScreen> {
  final bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _periods = [];
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _attendances = [];
  List<Map<String, dynamic>> _gradeTypes = [];
  bool _showAllAttendances = false;

  @override
  void initState() {
    super.initState();
    TeacherStudentDetailLogger.info('Inicializando tela de detalhes do aluno');
    TeacherStudentDetailLogger.debug('Dados recebidos', {
      'studentId': widget.student['id'],
      'studentName': widget.student['name'],
      'classId': widget.classData['id'],
      'className': widget.classData['name'],
      'subjectId': widget.subjectId,
      'teacherId': widget.teacherId,
    });

    _fetchPeriods();
    _fetchGradeTypes();
    _fetchGrades();
    _fetchAttendances();
  }

  Future<void> _fetchPeriods() async {
    TeacherStudentDetailLogger.info(
      'Iniciando busca por períodos de avaliação',
    );

    try {
      final periods = await GradePeriodService.getAllGradePeriods();

      TeacherStudentDetailLogger.success('Períodos carregados com sucesso');
      TeacherStudentDetailLogger.debug('Períodos encontrados', {
        'count': periods.length,
        'periods':
            periods.map((p) => {'id': p['id'], 'name': p['name']}).toList(),
      });

      setState(() {
        _periods = periods;
      });
    } catch (e, stackTrace) {
      TeacherStudentDetailLogger.error(
        'Erro ao carregar períodos',
        e,
        stackTrace,
      );
    }
  }

  Future<void> _fetchGradeTypes() async {
    TeacherStudentDetailLogger.info('Iniciando busca por tipos de nota');

    try {
      final types = await GradeTypeService.getAllGradeTypes();

      TeacherStudentDetailLogger.success(
        'Tipos de nota carregados com sucesso',
      );
      TeacherStudentDetailLogger.debug('Tipos encontrados', {
        'count': types.length,
        'types':
            types
                .map(
                  (t) => {
                    'id': t['id'],
                    'name': t['name'],
                    'isConcept': t['isConcept'],
                  },
                )
                .toList(),
      });

      setState(() {
        _gradeTypes = types;
      });
    } catch (e, stackTrace) {
      TeacherStudentDetailLogger.error(
        'Erro ao carregar tipos de nota',
        e,
        stackTrace,
      );
    }
  }

  Future<void> _fetchGrades() async {
    TeacherStudentDetailLogger.info('Iniciando busca por notas do aluno');
    TeacherStudentDetailLogger.debug('Parâmetros da busca', {
      'studentId': widget.student['id'],
      'subjectId': widget.subjectId,
    });

    try {
      final grades = await GradeService.getGradesByStudent(
        widget.student['id'],
      );

      TeacherStudentDetailLogger.success('Notas carregadas com sucesso');
      TeacherStudentDetailLogger.debug('Notas encontradas', {
        'totalCount': grades.length,
        'filteredCount':
            grades.where((g) => g['subjectId'] == widget.subjectId).length,
        'subjectId': widget.subjectId,
      });

      setState(() {
        _grades =
            grades.where((g) => g['subjectId'] == widget.subjectId).toList();
      });
    } catch (e, stackTrace) {
      TeacherStudentDetailLogger.error('Erro ao carregar notas', e, stackTrace);
    }
  }

  Future<void> _fetchAttendances() async {
    TeacherStudentDetailLogger.info('Iniciando busca por frequências do aluno');
    TeacherStudentDetailLogger.debug('Parâmetros da busca', {
      'studentId': widget.student['id'],
      'subjectId': widget.subjectId,
    });

    try {
      final attendances = await AttendanceService.getAttendancesByStudent(
        widget.student['id'],
      );

      TeacherStudentDetailLogger.success('Frequências carregadas com sucesso');
      TeacherStudentDetailLogger.debug('Frequências encontradas', {
        'totalCount': attendances.length,
        'filteredCount':
            attendances
                .where((a) => a['lesson']['subjectId'] == widget.subjectId)
                .length,
        'subjectId': widget.subjectId,
      });

      setState(() {
        // Filtrar apenas as frequências da disciplina atual
        _attendances =
            attendances
                .where((a) => a['lesson']['subjectId'] == widget.subjectId)
                .toList();
      });
    } catch (e, stackTrace) {
      TeacherStudentDetailLogger.error(
        'Erro ao carregar frequências',
        e,
        stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text('Ficha do Aluno: ${widget.student['name']}'),
        backgroundColor: const Color(0xFF2953A5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(fontSize: 16, color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Re-fetch student details if error is related to student data
                        // For now, we'll just show the error message
                      },
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildSection(
                      title: 'Informações Pessoais',
                      icon: Icons.person,
                      children: [
                        _buildInfoRow(
                          'Nome',
                          widget.student['name'] ?? 'Não informado',
                        ),
                        _buildInfoRow(
                          'Email',
                          widget.student['email'] ?? 'Não informado',
                        ),
                        _buildInfoRow(
                          'Matrícula',
                          widget.student['registrationNumber'] ??
                              'Não informado',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Desempenho na Disciplina',
                      icon: Icons.school,
                      children: [
                        _buildGradesCard(),
                        const SizedBox(height: 16),
                        _buildAttendanceCard(),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildHeader() {
    final photoUrl =
        widget.student['profilePicture'] != null
            ? 'http://192.168.18.15:3000${widget.student['profilePicture']}'
            : null;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2953A5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child:
                photoUrl == null
                    ? const Icon(
                      Icons.person,
                      size: 50,
                      color: Color(0xFF2953A5),
                    )
                    : null,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.student['name'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.student['email'] ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                if (widget.student['registrationNumber'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Matrícula: ${widget.student['registrationNumber']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF2953A5), size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2953A5),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildGradesCard() {
    if (_grades.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Text(
          'Nenhuma nota registrada para esta disciplina',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      );
    }

    // Agrupar notas por período
    final gradesByPeriod = <String, List<Map<String, dynamic>>>{};
    for (var grade in _grades) {
      final periodId = grade['periodId'];
      if (!gradesByPeriod.containsKey(periodId)) {
        gradesByPeriod[periodId] = [];
      }
      gradesByPeriod[periodId]!.add(grade);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Notas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2953A5),
            ),
          ),
        ),
        ...gradesByPeriod.entries.map((entry) {
          final period = _periods.firstWhere(
            (p) => p['id'] == entry.key,
            orElse: () => {'name': 'Período não encontrado'},
          );

          // Ordenar notas: regulares primeiro, depois recuperação, por último recuperação final
          final sortedGrades = List<Map<String, dynamic>>.from(entry.value)
            ..sort((a, b) {
              final aType = a['typeId'];
              final bType = b['typeId'];
              if (aType == 'RECUPERACAO_FINAL') return 1;
              if (bType == 'RECUPERACAO_FINAL') return -1;
              if (aType == 'RECUPERACAO') return 1;
              if (bType == 'RECUPERACAO') return -1;
              return 0;
            });

          // Separar notas por tipo
          final regularGrades =
              sortedGrades
                  .where(
                    (g) =>
                        ![
                          'RECUPERACAO',
                          'RECUPERACAO_FINAL',
                        ].contains(g['typeId']),
                  )
                  .toList();

          final recoveryGrade = sortedGrades.firstWhere(
            (g) => g['typeId'] == 'RECUPERACAO',
            orElse: () => <String, dynamic>{},
          );

          final finalRecoveryGrade = sortedGrades.firstWhere(
            (g) => g['typeId'] == 'RECUPERACAO_FINAL',
            orElse: () => <String, dynamic>{},
          );

          // Encontrar a menor nota regular
          final minRegularGrade =
              regularGrades.isEmpty
                  ? null
                  : regularGrades.reduce(
                    (a, b) => (a['value'] ?? 0.0) < (b['value'] ?? 0.0) ? a : b,
                  );

          // Calcular média
          double calculatedAverage = 0.0;
          if (regularGrades.isNotEmpty) {
            // Criar uma cópia das notas regulares
            final gradesToAverage = List<Map<String, dynamic>>.from(
              regularGrades,
            );

            // Se houver nota de recuperação maior que a menor nota regular
            if (minRegularGrade != null) {
              final minRegularValue = minRegularGrade['value'] ?? 0.0;

              // Verificar recuperação final primeiro
              if (finalRecoveryGrade.isNotEmpty) {
                final finalRecoveryValue = finalRecoveryGrade['value'] ?? 0.0;
                if (finalRecoveryValue > minRegularValue) {
                  // Substituir a menor nota pela recuperação final
                  final index = gradesToAverage.indexOf(minRegularGrade);
                  if (index != -1) {
                    gradesToAverage[index] = {
                      ...finalRecoveryGrade,
                      'replacedGrade': true,
                    };
                  }
                }
              }
              // Se não substituiu com recuperação final, tentar com recuperação normal
              else if (recoveryGrade.isNotEmpty) {
                final recoveryValue = recoveryGrade['value'] ?? 0.0;
                if (recoveryValue > minRegularValue) {
                  // Substituir a menor nota pela recuperação
                  final index = gradesToAverage.indexOf(minRegularGrade);
                  if (index != -1) {
                    gradesToAverage[index] = {
                      ...recoveryGrade,
                      'replacedGrade': true,
                    };
                  }
                }
              }
            }

            // Calcular a média com as notas após possível substituição
            final sum = gradesToAverage.fold<double>(
              0.0,
              (sum, grade) => sum + (grade['value'] ?? 0.0),
            );
            calculatedAverage = sum / gradesToAverage.length;
          }

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        period['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getGradeColor({'value': calculatedAverage}),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Média: ${calculatedAverage.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ...sortedGrades.map((grade) {
                  final gradeType = _gradeTypes.firstWhere(
                    (t) => t['id'] == grade['typeId'],
                    orElse: () => {'name': 'Tipo não encontrado'},
                  );

                  final isRecovery =
                      grade['typeId'] == 'RECUPERACAO' ||
                      grade['typeId'] == 'RECUPERACAO_FINAL';

                  final isReplacingGrade =
                      isRecovery && grade['replacedGrade'] == true;
                  final isBeingReplaced =
                      minRegularGrade != null &&
                      grade == minRegularGrade &&
                      sortedGrades.any(
                        (g) =>
                            (g['typeId'] == 'RECUPERACAO' ||
                                g['typeId'] == 'RECUPERACAO_FINAL') &&
                            g['replacedGrade'] == true,
                      );

                  return ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            gradeType['name'],
                            style: TextStyle(
                              fontStyle:
                                  isRecovery
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                              decoration:
                                  isBeingReplaced
                                      ? TextDecoration.lineThrough
                                      : null,
                            ),
                          ),
                        ),
                        if (isReplacingGrade)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(
                                51,
                              ), // 0.2 * 255 ≈ 51
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Substituindo',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getGradeColor(grade),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getGradeDisplayText(grade),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          decoration:
                              isBeingReplaced
                                  ? TextDecoration.lineThrough
                                  : null,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAttendanceCard() {
    if (_attendances.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Text(
          'Nenhuma frequência registrada para esta disciplina',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      );
    }

    // Calcular estatísticas
    final totalLessons = _attendances.length;
    final presentCount = _attendances.where((a) => a['present'] == true).length;
    final absentCount = totalLessons - presentCount;
    final attendanceRate =
        totalLessons > 0 ? (presentCount / totalLessons * 100) : 0.0;

    // Ordenar por data mais recente
    final sortedAttendances = List<Map<String, dynamic>>.from(_attendances);
    sortedAttendances.sort((a, b) {
      final dateA = DateTime.parse(a['lesson']['date']);
      final dateB = DateTime.parse(b['lesson']['date']);
      return dateB.compareTo(dateA); // Mais recente primeiro
    });

    // Determinar quantos registros mostrar
    final maxRecords = _showAllAttendances ? totalLessons : 5;
    final visibleAttendances = sortedAttendances.take(maxRecords).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header com título e estatísticas
        Container(
          margin: const EdgeInsets.all(20.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF2953A5).withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2953A5).withAlpha(50)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Frequência',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2953A5),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatChip(
                    icon: Icons.check_circle,
                    label: 'Presenças',
                    value: '$presentCount',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    icon: Icons.cancel,
                    label: 'Faltas',
                    value: '$absentCount',
                    color: Colors.red,
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    icon: Icons.percent,
                    label: 'Taxa',
                    value: '${attendanceRate.toStringAsFixed(1)}%',
                    color: attendanceRate >= 75 ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Lista de registros de frequência
        ...visibleAttendances.map((attendance) {
          final present = attendance['present'] == true;
          final lesson = attendance['lesson'];
          final date = DateTime.parse(lesson['date']);

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color:
                  present
                      ? Colors.green.withAlpha(20)
                      : Colors.red.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    present
                        ? Colors.green.withAlpha(60)
                        : Colors.red.withAlpha(60),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  present ? Icons.check_circle : Icons.cancel,
                  color: present ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy - EEE', 'pt_BR').format(date),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: present ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    present ? 'P' : 'F',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        // Botão para mostrar mais/menos registros
        if (totalLessons > 5)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _showAllAttendances = !_showAllAttendances;
                });
              },
              icon: Icon(
                _showAllAttendances ? Icons.expand_less : Icons.expand_more,
                color: const Color(0xFF2953A5),
              ),
              label: Text(
                _showAllAttendances
                    ? 'Mostrar menos'
                    : 'Mostrar todos (${totalLessons - 5} mais)',
                style: const TextStyle(
                  color: Color(0xFF2953A5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withAlpha(180),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(Map<String, dynamic> grade) {
    if (grade['concept'] != null) {
      final concept = grade['concept'].toString().toUpperCase();
      switch (concept) {
        case 'A':
        case 'MB':
          return Colors.green.withAlpha(204);
        case 'B':
          return Colors.blue.withAlpha(204);
        case 'C':
        case 'R':
          return Colors.orange.withAlpha(204);
        case 'D':
        case 'I':
          return Colors.red.withAlpha(204);
        default:
          return Colors.grey.withAlpha(204);
      }
    } else if (grade['value'] != null) {
      final value = (grade['value'] as num).toDouble();
      if (value >= 7.0) {
        return Colors.green.withAlpha(204);
      } else if (value >= 5.0) {
        return Colors.orange.withAlpha(204);
      } else {
        return Colors.red.withAlpha(204);
      }
    }
    return Colors.grey.withAlpha(204);
  }

  String _getGradeDisplayText(Map<String, dynamic> grade) {
    if (grade['concept'] != null) {
      return grade['concept'].toString();
    } else if (grade['value'] != null) {
      return (grade['value'] as num).toStringAsFixed(1);
    }
    return '-';
  }
}
