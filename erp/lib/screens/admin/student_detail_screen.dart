import 'package:flutter/material.dart';
import '../../utils/user_friendly_error.dart';
import '../../config/api_config.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../services/student_service.dart' as student_service;
import '../../services/grade_service.dart';
import '../../services/grade_type_service.dart';
import '../../models/grade.dart';
import '../../providers/auth_provider.dart';

class StudentDetailScreen extends StatefulWidget {
  final student_service.Student student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  bool _loading = false;
  Map<String, dynamic>? _studentDetails;
  String? _error;
  Map<String, dynamic>? _lessonsById; // Novo: cache de lessons
  List<Map<String, dynamic>> periods = [];
  String? periodId;
  String? newPeriodId;
  // Adicionar variável de estado para turma selecionada
  String? selectedClassId;

  // Variáveis para filtros de frequência
  String? selectedSubjectIdForAttendance;
  int maxAttendancesToShow = 10;
  bool showAllAttendances = false;

  @override
  void initState() {
    super.initState();
    _fetchPeriods();
    _fetchStudentDetails();
  }

  Future<void> _fetchStudentDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Obter token de autenticação
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.user?.token;

      if (token == null) {
        setState(() {
          _error = 'Token de autenticação não encontrado';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/students/${widget.student.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _studentDetails = data;
          // Definir turma selecionada automaticamente na primeira vez
          if (selectedClassId == null &&
              data['enrollments'] != null &&
              (data['enrollments'] as List).isNotEmpty) {
            selectedClassId = data['enrollments'][0]['class']['id'];
          }
        });
        // Buscar lessons das attendances
        await _fetchLessonsForAttendances(data['attendances'] ?? []);
      } else {
        setState(() {
          _error = 'Erro ao carregar detalhes do aluno';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = userErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchLessonsForAttendances(List attendances) async {
    // Coletar todos os lessonIds únicos
    final lessonIds = attendances.map((a) => a['lessonId']).toSet().toList();
    if (lessonIds.isEmpty) return;

    // Obter token de autenticação
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.user?.token;

    if (token == null) return; // Se não há token, não busca lessons

    Map<String, dynamic> lessonsMap = {};
    for (final lessonId in lessonIds) {
      if (lessonId == null) continue;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/lessons/$lessonId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final lesson = jsonDecode(response.body);
        lessonsMap[lessonId] = lesson;
      }
    }
    setState(() {
      _lessonsById = lessonsMap;
    });
  }

  Future<void> _fetchPeriods() async {
    // Obter token de autenticação
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.user?.token;

    if (token == null) return; // Se não há token, não busca períodos

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/grade-periods'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      setState(() {
        periods = List<Map<String, dynamic>>.from(json.decode(response.body));
      });
    } else {
      throw Exception('Erro ao buscar períodos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text('Ficha do Aluno: ${widget.student.name}'),
        backgroundColor: const Color(0xFF2953A5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _showEditDialog),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(),
          ),
        ],
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
                      onPressed: _fetchStudentDetails,
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
                    // Cabeçalho com foto e informações básicas
                    _buildHeader(),
                    const SizedBox(height: 32),

                    // Informações pessoais
                    _buildSection(
                      title: 'Informações Pessoais',
                      icon: Icons.person,
                      children: [
                        _buildInfoRow(
                          'Nome',
                          widget.student.name.isNotEmpty
                              ? widget.student.name
                              : 'Não informado',
                        ),
                        _buildInfoRow(
                          'Email',
                          widget.student.email.isNotEmpty
                              ? widget.student.email
                              : 'Não informado',
                        ),
                        _buildInfoRow(
                          'Matrícula',
                          widget.student.registrationNumber?.isNotEmpty == true
                              ? widget.student.registrationNumber!
                              : 'Não informado',
                        ),
                        _buildInfoRow(
                          'Telefone',
                          _studentDetails?['phone']?.toString().isNotEmpty ==
                                  true
                              ? _studentDetails!['phone']
                              : 'Não informado',
                        ),
                        _buildInfoRow(
                          'Endereço',
                          _studentDetails?['address']?.toString().isNotEmpty ==
                                  true
                              ? _studentDetails!['address']
                              : 'Não informado',
                        ),
                        _buildInfoRow(
                          'Data de Nascimento',
                          _studentDetails?['birthDate'] != null &&
                                  _studentDetails!['birthDate']
                                      .toString()
                                      .isNotEmpty
                              ? _formatDate(_studentDetails!['birthDate'])
                              : 'Não informado',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Informações acadêmicas
                    _buildSection(
                      title: 'Informações Acadêmicas',
                      icon: Icons.school,
                      children: [
                        // Turmas matriculadas
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 20.0,
                            right: 20.0,
                            top: 20.0,
                            bottom: 8.0,
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.class_, color: Color(0xFF2953A5)),
                              SizedBox(width: 8),
                              Text(
                                'Turmas Matriculadas',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2953A5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 8.0,
                          ),
                          child: Text(
                            'A matrícula "atual" é definida pelo ano mais recente. As demais são históricas.',
                            style: TextStyle(
                              color: Colors.blueGrey[700],
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        if (_studentDetails != null &&
                            _studentDetails!['enrollments'] != null)
                          ...(_studentDetails!['enrollments'] as List)
                              .map<Widget>((enrollment) {
                                final allEnrollments =
                                    (_studentDetails!['enrollments'] as List);
                                final maxYear = allEnrollments
                                    .map((e) => e['year'] as int? ?? 0)
                                    .fold<int>(0, (a, b) => a > b ? a : b);
                                final isCurrent = enrollment['year'] == maxYear;
                                return Stack(
                                  children: [
                                    _buildEnrollmentCard(enrollment),
                                    if (isCurrent)
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green[600],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Text(
                                            'Atual',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              })
                        else
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Nenhuma turma matriculada',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        const Divider(),
                        // Disciplinas
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 20.0,
                            right: 20.0,
                            top: 16.0,
                            bottom: 8.0,
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.book, color: Color(0xFF2953A5)),
                              SizedBox(width: 8),
                              Text(
                                'Disciplinas',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2953A5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue:
                                selectedClassId ??
                                ((_studentDetails!['enrollments'] as List)
                                        .isNotEmpty
                                    ? (_studentDetails!['enrollments']
                                        as List)[0]['class']['id']
                                    : null),
                            hint: const Text(
                              'Selecione a turma',
                              overflow: TextOverflow.ellipsis,
                            ),
                            items:
                                (_studentDetails!['enrollments'] as List)
                                    .map<DropdownMenuItem<String>>((
                                      enrollment,
                                    ) {
                                      final classData = enrollment['class'];
                                      return DropdownMenuItem<String>(
                                        value: classData['id'],
                                        child: Text(
                                          _formatClassLabel(classData),
                                          style: const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      );
                                    })
                                    .toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedClassId = newValue;
                              });
                            },
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              overflow: TextOverflow.ellipsis,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blue[400]!,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              prefixIcon: Icon(
                                Icons.school,
                                color: Colors.blue[600],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_studentDetails != null &&
                            _studentDetails!['enrollments'] != null)
                          ..._getUniqueSubjectsFromEnrollments(
                            (_studentDetails!['enrollments'] as List)
                                .where(
                                  (e) =>
                                      selectedClassId == null ||
                                      e['class']['id'] == selectedClassId,
                                )
                                .toList(),
                          ).map(
                            (subject) => Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                                vertical: 8.0,
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.book,
                                  color: Color(0xFF2953A5),
                                ),
                                title: Text(subject['name']),
                                onTap: () => _showSubjectGradesDialog(subject),
                              ),
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Nenhuma disciplina cadastrada',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        const Divider(),
                        // Frequência
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 20.0,
                            right: 20.0,
                            top: 16.0,
                            bottom: 8.0,
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.check_circle_outline,
                                color: Color(0xFF2953A5),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Frequência',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2953A5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Filtro por matéria para frequência
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 8.0,
                          ),
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: selectedSubjectIdForAttendance,
                            decoration: InputDecoration(
                              labelText: 'Filtrar por matéria',
                              prefixIcon: const Icon(
                                Icons.filter_list,
                                color: Color(0xFF2953A5),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Todas as matérias'),
                              ),
                              if (_studentDetails != null &&
                                  _studentDetails!['enrollments'] != null)
                                ..._getUniqueSubjectsFromEnrollments(
                                  (_studentDetails!['enrollments'] as List)
                                      .where(
                                        (e) =>
                                            selectedClassId == null ||
                                            e['class']['id'] == selectedClassId,
                                      )
                                      .toList(),
                                ).map(
                                  (subject) => DropdownMenuItem<String>(
                                    value:
                                        subject['groupedType'] ?? subject['id'],
                                    child: Text(subject['name']),
                                  ),
                                ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedSubjectIdForAttendance = value;
                                showAllAttendances = false; // Reset ao filtrar
                              });
                            },
                          ),
                        ),
                        if (_studentDetails != null &&
                            _studentDetails!['attendances'] != null &&
                            (_studentDetails!['attendances'] as List)
                                .isNotEmpty)
                          ..._getFilteredAttendances().map(
                            (attendance) => _buildAttendanceTile(attendance),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Nenhuma frequência registrada',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        // Botão "Ver mais" se houver mais frequências para mostrar
                        if (_studentDetails != null &&
                            _studentDetails!['attendances'] != null &&
                            _shouldShowMoreButton())
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 16.0,
                            ),
                            child: Center(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    showAllAttendances = !showAllAttendances;
                                  });
                                },
                                icon: Icon(
                                  showAllAttendances
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                ),
                                label: Text(
                                  showAllAttendances
                                      ? 'Ver menos'
                                      : 'Ver mais (${_getTotalFilteredAttendances() - maxAttendancesToShow} restantes)',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2953A5),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Seção de Notas
                    // Remover a seção de Notas da tela principal (não exibir mais as notas agrupadas)
                  ],
                ),
              ),
    );
  }

  Widget _buildHeader() {
    final photoUrl =
        widget.student.profilePicture != null &&
                widget.student.profilePicture!.isNotEmpty
            ? '${ApiConfig.baseUrl}${widget.student.profilePicture}'
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
                  widget.student.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.student.email,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                if (widget.student.registrationNumber != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Matrícula: ${widget.student.registrationNumber}',
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

  Widget _buildEnrollmentCard(Map<String, dynamic> enrollment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            enrollment['class']?['name'] ?? 'Turma não especificada',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Ano: ${enrollment['year'] ?? 'N/A'}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          if (enrollment['status'] != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Status: ${enrollment['status']}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectCard(String subject) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.book, color: const Color(0xFF2953A5)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subject,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTile(Map attendance) {
    final lesson =
        _lessonsById != null ? _lessonsById![attendance['lessonId']] : null;

    // Determinar status da frequência (novo sistema ou compatibilidade)
    String status =
        attendance['status'] ??
        (attendance['present'] == true ? 'PRESENT' : 'ABSENT');
    final justification = attendance['justification'];

    // Definir cores e ícones baseado no status
    Color statusColor;
    Color backgroundColor;
    Color borderColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'PRESENT':
        statusColor = Colors.green;
        backgroundColor = Colors.green.withAlpha(30);
        borderColor = Colors.green.withAlpha(80);
        statusIcon = Icons.check_circle;
        statusText = 'Presente';
        break;
      case 'JUSTIFIED_ABSENT':
        statusColor = Colors.orange;
        backgroundColor = Colors.orange.withAlpha(30);
        borderColor = Colors.orange.withAlpha(80);
        statusIcon = Icons.assignment_late;
        statusText = 'Falta Justificada';
        break;
      case 'ABSENT':
      default:
        statusColor = Colors.red;
        backgroundColor = Colors.red.withAlpha(30);
        borderColor = Colors.red.withAlpha(80);
        statusIcon = Icons.cancel;
        statusText = 'Ausente';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson != null && lesson['subject'] != null
                          ? lesson['subject']['name'] ?? 'Disciplina'
                          : 'Disciplina',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lesson != null && lesson['date'] != null
                              ? _formatDate(lesson['date'])
                              : 'Data',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    if (lesson != null && lesson['teacher'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            lesson['teacher']['name'] ?? 'Professor',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed:
                            () => _showEditAttendanceDialog(
                              Map<String, dynamic>.from(attendance),
                            ),
                        tooltip: 'Editar frequência',
                        color: Colors.blue,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: const EdgeInsets.all(4),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed:
                            () => _showDeleteAttendanceDialog(
                              Map<String, dynamic>.from(attendance),
                            ),
                        tooltip: 'Excluir frequência',
                        color: Colors.red,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Mostrar justificativa se houver
          if (justification != null && justification.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Justificativa:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    justification,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getRoleLabel(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'teacher':
        return 'Professor';
      case 'student':
        return 'Aluno';
      default:
        return 'Aluno';
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Tem certeza que deseja excluir o aluno "${widget.student.name}"?\n\n'
            'Esta ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteStudent();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: widget.student.name);
    final emailController = TextEditingController(text: widget.student.email);
    final matriculaController = TextEditingController(
      text: widget.student.registrationNumber ?? '',
    );
    final phoneController = TextEditingController(
      text: _studentDetails?['phone'] ?? '',
    );
    final addressController = TextEditingController(
      text: _studentDetails?['address'] ?? '',
    );
    DateTime? birthDate =
        _studentDetails?['birthDate'] != null
            ? DateTime.tryParse(_studentDetails!['birthDate'])
            : null;
    File? selectedImage;
    String? currentPhotoUrl = widget.student.profilePicture;

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Editar Aluno'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Seção de foto
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            backgroundImage:
                                selectedImage != null
                                    ? FileImage(selectedImage!)
                                    : (currentPhotoUrl != null
                                        ? NetworkImage(
                                              '${ApiConfig.baseUrl}$currentPhotoUrl',
                                            )
                                            as ImageProvider
                                        : null),
                            child:
                                selectedImage == null && currentPhotoUrl == null
                                    ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.grey,
                                    )
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    FilePickerResult? result = await FilePicker
                                        .platform
                                        .pickFiles(
                                          type: FileType.image,
                                          allowMultiple: false,
                                        );

                                    if (result != null) {
                                      setState(() {
                                        selectedImage = File(
                                          result.files.single.path!,
                                        );
                                      });
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      // ignore: use_build_context_synchronously
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Erro ao selecionar imagem: ${userErrorMessage(e)}',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.photo_camera),
                                label: const Text('Selecionar Foto'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2953A5),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              if (selectedImage != null) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      selectedImage = null;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Remover foto',
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Campos de texto
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nome'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: matriculaController,
                      decoration: const InputDecoration(labelText: 'Matrícula'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Telefone'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Endereço'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Data de Nascimento:'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: birthDate ?? DateTime(2000, 1, 1),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null && context.mounted) {
                                setState(() => birthDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                birthDate != null
                                    ? '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}'
                                    : 'Selecionar',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                  onPressed: () async {
                    try {
                      // Validação básica
                      if (nameController.text.trim().isEmpty) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nome é obrigatório'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }

                      if (emailController.text.trim().isEmpty) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Email é obrigatório'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }

                      final updatedData = {
                        'name': nameController.text.trim(),
                        'email': emailController.text.trim(),
                        'registrationNumber': matriculaController.text.trim(),
                        'phone': phoneController.text.trim(),
                        'address': addressController.text.trim(),
                        if (birthDate != null)
                          'birthDate': birthDate!.toIso8601String(),
                      };

                      // Se uma nova foto foi selecionada, fazer upload
                      if (selectedImage != null) {
                        try {
                          final photoUrl = await _uploadStudentPhoto(
                            widget.student.id,
                            selectedImage!,
                          );
                          updatedData['profilePicture'] = photoUrl;
                        } catch (e) {
                          if (mounted) {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Erro ao fazer upload da foto: ${userErrorMessage(e)}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }
                      }

                      // Implementar atualização do aluno
                      try {
                        final response = await http.put(
                          Uri.parse(
                            '${ApiConfig.baseUrl}/students/${widget.student.id}',
                          ),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode(updatedData),
                        );

                        if (response.statusCode == 200) {
                          final updatedStudent = jsonDecode(response.body);

                          // Atualizar dados locais da tela
                          setState(() {
                            // Atualizar os detalhes do aluno na tela
                            if (_studentDetails != null) {
                              _studentDetails = {
                                ..._studentDetails!,
                                'name':
                                    updatedStudent['name'] ??
                                    widget.student.name,
                                'email':
                                    updatedStudent['email'] ??
                                    widget.student.email,
                                'registrationNumber':
                                    updatedStudent['registrationNumber'] ??
                                    widget.student.registrationNumber,
                                if (updatedStudent['profilePicture'] != null)
                                  'profilePicture':
                                      updatedStudent['profilePicture'],
                              };
                            }
                          });

                          if (mounted) {
                            // ignore: use_build_context_synchronously
                            Navigator.of(context).pop();
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Aluno atualizado com sucesso!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          final error = jsonDecode(response.body);
                          throw Exception(
                            error['error'] ?? 'Erro ao atualizar aluno',
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Erro ao atualizar aluno: ${userErrorMessage(e)}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }
                    } catch (e) {
                      if (!mounted) return;
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pop();
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Erro ao atualizar aluno: ${userErrorMessage(e)}',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Salvar Alterações'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String> _uploadStudentPhoto(String studentId, File imageFile) async {
    try {
      // Determina o mimetype baseado na extensão do arquivo
      String getMimeType(String filePath) {
        final extension = filePath.split('.').last.toLowerCase();
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            return 'image/jpeg';
          case 'png':
            return 'image/png';
          case 'gif':
            return 'image/gif';
          default:
            return 'image/jpeg'; // fallback
        }
      }

      final mimeType = getMimeType(imageFile.path);

      // Cria uma requisição multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/students/$studentId/photo'),
      );

      // Adiciona o arquivo com mimetype correto
      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      // Envia a requisição
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['photoUrl'] ?? '';
      } else {
        final error = jsonDecode(responseBody);
        throw Exception(error['error'] ?? 'Erro ao fazer upload da foto');
      }
    } catch (e) {
      throw Exception(userErrorMessage(e));
    }
  }

  Future<void> _deleteStudent() async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/students/${widget.student.id}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aluno excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Volta para a tela anterior
      } else {
        throw Exception('Erro ao excluir aluno');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir aluno: ${userErrorMessage(e)}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showEditGradeDialog(Grade grade) async {
    final formKey = GlobalKey<FormState>();
    final valueController = TextEditingController(text: grade.value.toString());
    bool isLoading = false;
    String? error;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Editar Nota - ${getGradeTypeName(grade.gradeTypeId)}',
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: valueController,
                      decoration: const InputDecoration(
                        labelText: 'Nota (0-10)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Informe a nota';
                        final value = double.tryParse(v);
                        if (value == null) return 'Nota deve ser um número';
                        if (value < 0 || value > 10) {
                          return 'Nota deve estar entre 0 e 10';
                        }
                        return null;
                      },
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                            // Excluir nota
                            setState(() => isLoading = true);
                            try {
                              await GradeService.deleteGrade(grade.id);
                              if (context.mounted) {
                                Navigator.pop(context);
                                this.setState(
                                  () {},
                                ); // Atualiza a tela principal
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Nota excluída com sucesso!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              setState(() {
                                error = 'Erro ao excluir nota';
                                isLoading = false;
                              });
                            }
                          },
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text(
                            'Excluir',
                            style: TextStyle(color: Colors.red),
                          ),
                ),
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                            if (formKey.currentState!.validate()) {
                              setState(() {
                                isLoading = true;
                                error = null;
                              });

                              try {
                                final newValue = double.parse(
                                  valueController.text,
                                );
                                await GradeService.updateGrade(grade.id, {
                                  'value': newValue,
                                });
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  this.setState(
                                    () {},
                                  ); // Atualiza a tela principal
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Nota atualizada com sucesso!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setState(() {
                                  error = 'Erro ao atualizar nota';
                                  isLoading = false;
                                });
                              }
                            }
                          },
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
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
  }

  void _showAddGradeDialog({Map<String, dynamic>? subject}) async {
    final formKey = GlobalKey<FormState>();
    double? value;
    String? gradeTypeId;

    // Para disciplinas agrupadas, usar o primeiro ID relacionado
    String? subjectId;
    if (subject != null) {
      final relatedIds = subject['relatedSubjectIds'] as List<String>?;
      if (relatedIds != null && relatedIds.isNotEmpty) {
        subjectId = relatedIds.first;
      } else {
        subjectId = subject['id'] as String;
      }
    }
    // Aguarda carregar os períodos, se necessário
    if (periods.isEmpty) {
      await _fetchPeriods();
    }
    periodId = periods.isNotEmpty ? periods.first['id'] as String : null;
    // Buscar disciplinas das turmas do aluno
    List<Map<String, dynamic>> enrollments =
        _studentDetails?['enrollments']?.cast<Map<String, dynamic>>() ?? [];
    List<Map<String, dynamic>> allSubjects = [];
    for (var enrollment in enrollments) {
      if (enrollment['class']?['subjects'] != null) {
        allSubjects.addAll(
          List<Map<String, dynamic>>.from(enrollment['class']['subjects']),
        );
      }
    }
    // Remover duplicados por id
    final subjectIds = <String>{};
    List<Map<String, dynamic>> uniqueSubjects = [];
    for (var s in allSubjects) {
      if (s['id'] != null && !subjectIds.contains(s['id'])) {
        subjectIds.add(s['id']);
        uniqueSubjects.add(s);
      }
    }
    bool loadingTypes = true;
    List<Map<String, dynamic>> gradeTypes = [];
    await showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (loadingTypes) {
              GradeTypeService.getAllGradeTypes()
                  .then((types) {
                    setState(() {
                      gradeTypes = types;
                      loadingTypes = false;
                    });
                  })
                  .catchError((error) {
                    setState(() {
                      loadingTypes = false;
                      // Fallback para tipos padrão se a API falhar
                      gradeTypes = [
                        {'id': 'PROVA_1', 'name': 'Prova 1'},
                        {'id': 'PROVA_2', 'name': 'Prova 2'},
                      ];
                    });
                  });
              return const Center(child: CircularProgressIndicator());
            }
            // Garante que o Dropdown de período sempre tem valor inicial válido
            if (periodId == null && periods.isNotEmpty) {
              periodId = periods.first['id'] as String;
            }
            return AlertDialog(
              title: const Text('Adicionar Nota'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: subjectId,
                      items:
                          uniqueSubjects
                              .map<DropdownMenuItem<String>>(
                                (s) => DropdownMenuItem<String>(
                                  value: s['id'] as String,
                                  child: Text(s['name']),
                                ),
                              )
                              .toList(),
                      onChanged: subject != null ? null : (v) => subjectId = v,
                      decoration: const InputDecoration(
                        labelText: 'Disciplina',
                      ),
                      validator:
                          (v) => v == null ? 'Selecione a disciplina' : null,
                      disabledHint:
                          subject != null ? Text(subject['name']) : null,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: gradeTypeId,
                      items:
                          gradeTypes
                              .map<DropdownMenuItem<String>>(
                                (type) => DropdownMenuItem<String>(
                                  value: type['id'] as String,
                                  child: Text(type['name'] as String),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => gradeTypeId = v, // Sempre habilitado
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Nota',
                      ),
                      validator:
                          (v) => v == null ? 'Selecione o tipo de nota' : null,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Valor da Nota',
                      ),
                      keyboardType: TextInputType.number,
                      validator:
                          (v) =>
                              v == null || v.isEmpty ? 'Informe o valor' : null,
                      onChanged: (v) => value = double.tryParse(v),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: periodId,
                      items:
                          periods
                              .map<DropdownMenuItem<String>>(
                                (p) => DropdownMenuItem<String>(
                                  value: p['id'] as String,
                                  child: Text(p['name']),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => periodId = v),
                      decoration: const InputDecoration(
                        labelText: 'Período Avaliativo',
                      ),
                      validator:
                          (v) => v == null ? 'Selecione o período' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate() &&
                        value != null &&
                        gradeTypeId != null &&
                        subjectId != null &&
                        periodId != null) {
                      final dialogContext = context;

                      // Verificar se já existe uma nota do mesmo tipo no mesmo bimestre
                      // Para disciplinas agrupadas, verificar em todas as disciplinas relacionadas
                      List<String> subjectIdsToCheck = [subjectId!];
                      if (subject != null) {
                        final relatedIds =
                            subject['relatedSubjectIds'] as List<String>?;
                        if (relatedIds != null && relatedIds.isNotEmpty) {
                          subjectIdsToCheck = relatedIds;
                        }
                      }

                      final existingGrade =
                          await _checkExistingGradeInMultipleSubjects(
                            subjectIds: subjectIdsToCheck,
                            typeId: gradeTypeId!,
                            periodId: periodId!,
                          );

                      if (existingGrade != null) {
                        // Mostrar aviso ao usuário
                        if (dialogContext.mounted) {
                          final shouldReplace = await _showReplaceGradeDialog(
                            context: dialogContext,
                            existingGrade: existingGrade,
                            gradeTypeName: _getGradeTypeNameById(gradeTypeId!),
                            periodName: _getPeriodNameById(periodId!),
                          );

                          if (!shouldReplace) {
                            return; // Usuário cancelou
                          }
                        }
                      }

                      try {
                        await GradeService.createGrade({
                          'studentId': widget.student.id,
                          'subjectId': subjectId!,
                          'typeId': gradeTypeId!,
                          'periodId': periodId!,
                          'value': value!,
                        });
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        setState(() {}); // Atualiza a tela
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text('Nota lançada com sucesso!'),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('lançar nota: \${userErrorMessage(e)}');

                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Erro ao lançar nota: ${userErrorMessage(e)}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _getUniqueSubjectsFromEnrollments(
    List enrollments,
  ) {
    final subjectTypes = <String>{};
    List<Map<String, dynamic>> uniqueSubjects = [];

    for (var enrollment in enrollments) {
      if (enrollment['class']?['subjects'] != null) {
        for (var s in enrollment['class']['subjects']) {
          final subjectType = s['type'] ?? s['name'] ?? '';

          // Agrupar por tipo de disciplina ao invés de ID
          // Isso evita duplicatas quando há múltiplos professores para a mesma matéria
          if (subjectType.isNotEmpty && !subjectTypes.contains(subjectType)) {
            subjectTypes.add(subjectType);

            // Criar um objeto disciplina agrupado
            final groupedSubject = Map<String, dynamic>.from(s);
            groupedSubject['groupedType'] = subjectType;

            // Coletar todos os IDs das disciplinas do mesmo tipo para buscar notas
            List<String> relatedSubjectIds = [];
            for (var enrollment2 in enrollments) {
              if (enrollment2['class']?['subjects'] != null) {
                for (var s2 in enrollment2['class']['subjects']) {
                  if ((s2['type'] ?? s2['name'] ?? '') == subjectType) {
                    relatedSubjectIds.add(s2['id']);
                  }
                }
              }
            }
            groupedSubject['relatedSubjectIds'] = relatedSubjectIds;

            uniqueSubjects.add(groupedSubject);
          }
        }
      }
    }
    return uniqueSubjects;
  }

  void _showSubjectGradesDialog(Map<String, dynamic> subject) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Notas de ${subject['name']}'),
          content: FutureBuilder<List<Map<String, dynamic>>>(
            future: GradeService.getGradesByStudent(widget.student.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Text('Erro ao carregar notas');
              }
              // Usar todos os IDs relacionados para buscar notas de todas as disciplinas do mesmo tipo
              final relatedSubjectIds =
                  subject['relatedSubjectIds'] as List<String>? ??
                  [subject['id']];
              final grades =
                  (snapshot.data ?? [])
                      .where((g) => relatedSubjectIds.contains(g['subjectId']))
                      .toList();

              // Debug: verificar estrutura dos dados
              if (grades.isNotEmpty) {
              }
              if (grades.isEmpty) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Nenhuma nota cadastrada para esta disciplina.'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar Nota'),
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddGradeDialog(subject: subject);
                      },
                    ),
                  ],
                );
              }
              final gradesByPeriod = <String, List<Map<String, dynamic>>>{};
              for (final g in grades) {
                final periodId = g['periodId']?.toString() ?? 'sem-periodo';
                gradesByPeriod.putIfAbsent(periodId, () => []).add(g);
              }
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final periodId in gradesByPeriod.keys)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 4),
                            child: Text(
                              'Bimestre: ${periods.firstWhere((p) => p['id'] == periodId, orElse: () => {'name': periodId})['name'] ?? periodId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF2953A5),
                              ),
                            ),
                          ),
                          ...gradesByPeriod[periodId]!.map((g) {
                            return ListTile(
                              title: Text('Nota:  ${g['value'] ?? 'N/A'}'),
                              subtitle: Text(
                                'Tipo:  ${_getGradeTypeDisplayName(g)}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showEditGradeDialog(
                                    Grade(
                                      id: g['id'] ?? '',
                                      value: (g['value'] ?? 0.0).toDouble(),
                                      gradeTypeId:
                                          g['typeId'] ?? g['gradeTypeId'] ?? '',
                                      periodId: g['periodId'] ?? '',
                                      subjectId: g['subjectId'] ?? '',
                                      studentId: g['studentId'] ?? '',
                                      createdAt:
                                          g['createdAt'] != null
                                              ? DateTime.parse(g['createdAt'])
                                              : DateTime.now(),
                                      updatedAt:
                                          g['updatedAt'] != null
                                              ? DateTime.parse(g['updatedAt'])
                                              : DateTime.now(),
                                    ),
                                  );
                                },
                              ),
                            );
                          }),
                          const Divider(),
                        ],
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar Nota'),
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddGradeDialog(subject: subject);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  String _getGradeTypeDisplayName(Map<String, dynamic> grade) {
    // 1. Verificar se há o objeto 'type' populado
    if (grade['type'] != null && grade['type']['name'] != null) {
      return grade['type']['name'];
    }

    // 2. Verificar typeId específicos
    final typeId = grade['typeId'] ?? grade['gradeTypeId'];
    if (typeId != null && typeId.isNotEmpty) {
      return getGradeTypeName(typeId);
    }

    // 3. Fallback baseado na posição da nota (para notas antigas sem tipo)
    return 'Avaliação';
  }

  String getGradeTypeName(String? id) {
    // Se o ID está vazio ou nulo, tentar inferir um tipo padrão
    if (id == null || id.isEmpty) {
      return 'Avaliação';
    }

    switch (id) {
      case 'PROVA_1':
        return 'Prova 1';
      case 'PROVA_2':
        return 'Prova 2';
      // Possíveis IDs da API (caso sejam UUIDs)
      default:
        // Se for um UUID, tentar descobrir o tipo pela API ou usar um nome genérico
        if (id.length > 10) {
          return 'Avaliação';
        }
        return id;
    }
  }

  // Função para verificar se já existe uma nota do mesmo tipo no mesmo bimestre
  Future<Map<String, dynamic>?> _checkExistingGrade({
    required String subjectId,
    required String typeId,
    required String periodId,
  }) async {
    try {
      final grades = await GradeService.getGradesByStudent(widget.student.id);

      // Procurar por uma nota existente com os mesmos critérios
      for (final grade in grades) {
        if (grade['subjectId'] == subjectId &&
            (grade['typeId'] == typeId || grade['gradeTypeId'] == typeId) &&
            grade['periodId'] == periodId) {
          return grade;
        }
      }
      return null;
    } catch (e) {
      debugPrint('verificar nota existente: \${userErrorMessage(e)}');
      return null;
    }
  }

  // Função para verificar se já existe uma nota do mesmo tipo no mesmo bimestre em múltiplas disciplinas
  Future<Map<String, dynamic>?> _checkExistingGradeInMultipleSubjects({
    required List<String> subjectIds,
    required String typeId,
    required String periodId,
  }) async {
    try {
      final grades = await GradeService.getGradesByStudent(widget.student.id);

      // Procurar por uma nota existente com os mesmos critérios em qualquer das disciplinas relacionadas
      for (final grade in grades) {
        if (subjectIds.contains(grade['subjectId']) &&
            (grade['typeId'] == typeId || grade['gradeTypeId'] == typeId) &&
            grade['periodId'] == periodId) {
          return grade;
        }
      }
      return null;
    } catch (e) {
      debugPrint('verificar nota existente: \${userErrorMessage(e)}');
      return null;
    }
  }

  // Função para obter o nome do tipo de nota pelo ID
  String _getGradeTypeNameById(String typeId) {
    switch (typeId) {
      case 'PROVA_1':
        return 'Prova 1';
      case 'PROVA_2':
        return 'Prova 2';
      case 'TRABALHO':
        return 'Trabalho';
      default:
        return typeId;
    }
  }

  // Função para obter o nome do período pelo ID
  String _getPeriodNameById(String periodId) {
    final period = periods.firstWhere(
      (p) => p['id'] == periodId,
      orElse: () => {'name': 'Período'},
    );
    return period['name'] ?? 'Período';
  }

  // Dialog para confirmar substituição da nota existente
  Future<bool> _showReplaceGradeDialog({
    required BuildContext context,
    required Map<String, dynamic> existingGrade,
    required String gradeTypeName,
    required String periodName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Nota já existe'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Já existe uma nota do tipo "$gradeTypeName" no $periodName para esta disciplina.',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nota atual:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Valor: ${existingGrade['value'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Deseja substituir a nota existente pela nova nota?',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Substituir'),
              ),
            ],
          ),
    );

    return result ?? false;
  }

  String _formatClassLabel(Map classData) {
    final name = classData['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;

    final grade = classData['grade']?.toString() ?? '';
    final letter = classData['letter']?.toString() ?? '';
    final year =
        classData['academicYear']?.toString() ??
        classData['year']?.toString() ??
        '';
    final shift = classData['shift']?.toString() ?? '';

    final parts = <String>[
      if (grade.isNotEmpty && letter.isNotEmpty) '$gradeº Ano $letter',
      if (year.isNotEmpty) year,
      if (shift.isNotEmpty) shift,
    ];
    return parts.isEmpty ? 'Turma' : parts.join(' - ');
  }

  // Função para filtrar frequências por matéria e aplicar limitação
  List<Map<String, dynamic>> _getFilteredAttendances() {
    if (_studentDetails == null || _studentDetails!['attendances'] == null) {
      return [];
    }

    List<Map<String, dynamic>> attendances = List<Map<String, dynamic>>.from(
      _studentDetails!['attendances'],
    );

    // Filtrar por matéria selecionada
    if (selectedSubjectIdForAttendance != null) {
      // Obter IDs relacionados para a matéria selecionada
      final relatedSubjectIds = _getRelatedSubjectIds(
        selectedSubjectIdForAttendance!,
      );

      attendances =
          attendances.where((attendance) {
            final lesson = _lessonsById?[attendance['lessonId']];
            return lesson != null &&
                relatedSubjectIds.contains(lesson['subjectId']);
          }).toList();
    }

    // Ordenar por data (mais recente primeiro)
    attendances.sort((a, b) {
      final lessonA = _lessonsById?[a['lessonId']];
      final lessonB = _lessonsById?[b['lessonId']];

      if (lessonA?['date'] == null || lessonB?['date'] == null) {
        return 0;
      }

      final dateA = DateTime.parse(lessonA['date']);
      final dateB = DateTime.parse(lessonB['date']);
      return dateB.compareTo(dateA);
    });

    // Aplicar limitação de quantidade
    if (!showAllAttendances && attendances.length > maxAttendancesToShow) {
      return attendances.take(maxAttendancesToShow).toList();
    }

    return attendances;
  }

  // Função para verificar se deve mostrar o botão "Ver mais"
  bool _shouldShowMoreButton() {
    final totalAttendances = _getTotalFilteredAttendances();
    return !showAllAttendances && totalAttendances > maxAttendancesToShow;
  }

  // Função para obter o total de frequências filtradas
  int _getTotalFilteredAttendances() {
    if (_studentDetails == null || _studentDetails!['attendances'] == null) {
      return 0;
    }

    List<Map<String, dynamic>> attendances = List<Map<String, dynamic>>.from(
      _studentDetails!['attendances'],
    );

    // Aplicar filtro por matéria
    if (selectedSubjectIdForAttendance != null) {
      // Obter IDs relacionados para a matéria selecionada
      final relatedSubjectIds = _getRelatedSubjectIds(
        selectedSubjectIdForAttendance!,
      );

      attendances =
          attendances.where((attendance) {
            final lesson = _lessonsById?[attendance['lessonId']];
            return lesson != null &&
                relatedSubjectIds.contains(lesson['subjectId']);
          }).toList();
    }

    return attendances.length;
  }

  // Função para obter IDs relacionados de uma disciplina
  List<String> _getRelatedSubjectIds(String selectedValue) {
    if (_studentDetails == null || _studentDetails!['enrollments'] == null) {
      return [selectedValue];
    }

    // Buscar pela disciplina agrupada
    final uniqueSubjects = _getUniqueSubjectsFromEnrollments(
      (_studentDetails!['enrollments'] as List)
          .where(
            (e) =>
                selectedClassId == null || e['class']['id'] == selectedClassId,
          )
          .toList(),
    );

    for (final subject in uniqueSubjects) {
      if (subject['groupedType'] == selectedValue ||
          subject['id'] == selectedValue) {
        final relatedIds = subject['relatedSubjectIds'] as List<String>?;
        return relatedIds ?? [subject['id']];
      }
    }

    return [selectedValue];
  }

  // Função para mostrar dialog de edição de frequência
  void _showEditAttendanceDialog(Map<String, dynamic> attendance) {
    final lesson = _lessonsById?[attendance['lessonId']];
    String currentStatus =
        attendance['status'] ??
        (attendance['present'] == true ? 'PRESENT' : 'ABSENT');
    String currentJustification = attendance['justification'] ?? '';

    final formKey = GlobalKey<FormState>();
    final justificationController = TextEditingController(
      text: currentJustification,
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Frequência'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informações da aula
                    Text(
                      'Aula: ${lesson?['subject']?['name'] ?? 'Disciplina'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Data: ${lesson?['date'] != null ? _formatDate(lesson['date']) : 'N/A'}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),

                    // Dropdown para status
                    DropdownButtonFormField<String>(
                      initialValue: currentStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status da Frequência',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'PRESENT',
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text('Presente'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'ABSENT',
                          child: Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Ausente'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'JUSTIFIED_ABSENT',
                          child: Row(
                            children: [
                              Icon(
                                Icons.assignment_late,
                                color: Colors.orange,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text('Falta Justificada'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          currentStatus = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo de justificativa (habilitado apenas para falta justificada)
                    TextFormField(
                      controller: justificationController,
                      decoration: InputDecoration(
                        labelText: 'Justificativa',
                        hintText:
                            currentStatus == 'JUSTIFIED_ABSENT'
                                ? 'Descreva o motivo da falta...'
                                : 'Justificativa não necessária',
                        border: const OutlineInputBorder(),
                        enabled: currentStatus == 'JUSTIFIED_ABSENT',
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (currentStatus == 'JUSTIFIED_ABSENT' &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Justificativa é obrigatória para falta justificada';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      await _updateAttendance(
                        attendance['id'],
                        currentStatus,
                        currentStatus == 'JUSTIFIED_ABSENT'
                            ? justificationController.text.trim()
                            : null,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Função para mostrar dialog de confirmação de exclusão
  void _showDeleteAttendanceDialog(Map<String, dynamic> attendance) {
    final lesson = _lessonsById?[attendance['lessonId']];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir Frequência'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tem certeza que deseja excluir esta frequência?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Disciplina: ${lesson?['subject']?['name'] ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Data: ${lesson?['date'] != null ? _formatDate(lesson['date']) : 'N/A'}',
                    ),
                    Text(
                      'Status: ${_getStatusDisplayName(attendance['status'] ?? (attendance['present'] == true ? 'PRESENT' : 'ABSENT'))}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Esta ação não pode ser desfeita.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _deleteAttendance(attendance['id']);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  // Função para atualizar frequência
  Future<void> _updateAttendance(
    String attendanceId,
    String status,
    String? justification,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/attendances/$attendanceId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': status,
          'justification': justification,
          // Manter compatibilidade com campo antigo
          'present': status == 'PRESENT',
        }),
      );

      if (response.statusCode == 200) {
        // Recarregar dados do estudante
        await _fetchStudentDetails();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Frequência atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Erro ao atualizar frequência: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar frequência: \${userErrorMessage(e)}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Função para excluir frequência
  Future<void> _deleteAttendance(String attendanceId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/attendances/$attendanceId'),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Recarregar dados do estudante
        await _fetchStudentDetails();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Frequência excluída com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Erro ao excluir frequência');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir frequência: \${userErrorMessage(e)}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Função auxiliar para obter nome do status
  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'PRESENT':
        return 'Presente';
      case 'JUSTIFIED_ABSENT':
        return 'Falta Justificada';
      case 'ABSENT':
        return 'Ausente';
      default:
        return status;
    }
  }
}
