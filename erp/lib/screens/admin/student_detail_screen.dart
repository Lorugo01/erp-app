import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../../services/student_service.dart' as student_service;
import '../../services/grade_service.dart';
import '../../services/grade_type_service.dart';
import '../../models/grade.dart';

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
      final response = await http.get(
        Uri.parse('http://192.168.18.15:3000/students/${widget.student.id}'),
        headers: {'Content-Type': 'application/json'},
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
        _error = 'Erro de conexão:  [${e.toString()}';
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
    Map<String, dynamic> lessonsMap = {};
    for (final lessonId in lessonIds) {
      if (lessonId == null) continue;
      final response = await http.get(
        Uri.parse('http://192.168.18.15:3000/lessons/$lessonId'),
        headers: {'Content-Type': 'application/json'},
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
    final response = await http.get(
      Uri.parse('http://192.168.18.15:3000/grade-periods'),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: SizedBox(
                            width: 400,
                            child: DropdownButtonFormField<String>(
                              value:
                                  selectedClassId ??
                                  ((_studentDetails!['enrollments'] as List)
                                          .isNotEmpty
                                      ? (_studentDetails!['enrollments']
                                          as List)[0]['class']['id']
                                      : null),
                              hint: const Text('Selecione a turma'),
                              items:
                                  (_studentDetails!['enrollments'] as List).map<
                                    DropdownMenuItem<String>
                                  >((enrollment) {
                                    final classData = enrollment['class'];
                                    return DropdownMenuItem<String>(
                                      value: classData['id'],
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.class_,
                                            size: 16,
                                            color: Colors.blue[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              _formatClassLabel(classData),
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedClassId = newValue;
                                });
                              },
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
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
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                prefixIcon: Icon(
                                  Icons.school,
                                  color: Colors.blue[600],
                                ),
                                suffixIcon: Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey[600],
                                ),
                              ),
                              icon: const SizedBox.shrink(),
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
                        if (_studentDetails != null &&
                            _studentDetails!['attendances'] != null &&
                            (_studentDetails!['attendances'] as List)
                                .isNotEmpty)
                          ...(_studentDetails!['attendances'] as List).map(
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
            ? 'http://192.168.18.15:3000${widget.student.profilePicture}'
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
    final presente = attendance['present'] == true;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: presente ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              presente ? Colors.green.withAlpha(80) : Colors.red.withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          Icon(
            presente ? Icons.check_circle : Icons.cancel,
            color: presente ? Colors.green : Colors.red,
          ),
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
          Text(
            presente ? 'Presente' : 'Ausente',
            style: TextStyle(
              color: presente ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
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
                                              'http://192.168.18.15:3000$currentPhotoUrl',
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
                                            'Erro ao selecionar imagem: ${e.toString()}',
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
                                  'Erro ao fazer upload da foto: ${e.toString()}',
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
                            'http://192.168.18.15:3000/students/${widget.student.id}',
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
                                'Erro ao atualizar aluno: ${e.toString()}',
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
                            'Erro ao atualizar aluno: ${e.toString()}',
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
        Uri.parse('http://192.168.18.15:3000/students/$studentId/photo'),
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
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<void> _deleteStudent() async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await http.delete(
        Uri.parse('http://192.168.18.15:3000/students/${widget.student.id}'),
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
          content: Text('Erro ao excluir aluno: ${e.toString()}'),
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
    double? newValue = grade.value;
    String? newGradeTypeId = grade.gradeTypeId;
    newPeriodId =
        grade.periodId ??
        (periods.isNotEmpty ? periods.first['id'] as String : null);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Nota'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: grade.value.toString(),
                  decoration: const InputDecoration(labelText: 'Valor da Nota'),
                  keyboardType: TextInputType.number,
                  validator:
                      (v) => v == null || v.isEmpty ? 'Informe o valor' : null,
                  onChanged: (v) => newValue = double.tryParse(v),
                ),
                DropdownButtonFormField<String>(
                  value: newGradeTypeId,
                  items: [
                    DropdownMenuItem(value: 'PROVA_1', child: Text('Prova 1')),
                    DropdownMenuItem(value: 'PROVA_2', child: Text('Prova 2')),
                    DropdownMenuItem(
                      value: 'RECUPERACAO',
                      child: Text('Recuperação'),
                    ),
                    DropdownMenuItem(
                      value: 'RECUPERACAO_FINAL',
                      child: Text('Recuperação Final'),
                    ),
                  ],
                  onChanged: (v) => newGradeTypeId = v,
                  decoration: const InputDecoration(labelText: 'Tipo de Nota'),
                  validator:
                      (v) => v == null ? 'Selecione o tipo de nota' : null,
                ),
                DropdownButtonFormField<String>(
                  value: newPeriodId,
                  items:
                      periods
                          .map<DropdownMenuItem<String>>(
                            (p) => DropdownMenuItem<String>(
                              value: p['id'] as String,
                              child: Text(p['name']),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => newPeriodId = v,
                  decoration: const InputDecoration(
                    labelText: 'Período Avaliativo',
                  ),
                  validator: (v) => v == null ? 'Selecione o período' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Excluir nota
                final dialogContext = context;
                try {
                  await GradeService.deleteGrade(grade.id);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  setState(() {});
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Nota excluída com sucesso!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Erro ao excluir nota')),
                    );
                  }
                }
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate() &&
                    newValue != null &&
                    newPeriodId != null &&
                    newGradeTypeId != null) {
                  final dialogContext = context;
                  try {
                    await GradeService.updateGrade(
                      gradeId: grade.id,
                      value: newValue,
                      typeId: newGradeTypeId,
                      periodId: newPeriodId,
                    );
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                    setState(() {}); // Atualiza a tela
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Nota atualizada com sucesso!'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Erro ao atualizar nota')),
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
  }

  void _showAddGradeDialog({Map<String, dynamic>? subject}) async {
    final formKey = GlobalKey<FormState>();
    double? value;
    String? gradeTypeId;
    String? subjectId = subject != null ? subject['id'] as String : null;
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
    await showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (loadingTypes) {
              GradeTypeService.getAllGradeTypes().then((types) {
                setState(() {
                  loadingTypes = false;
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
                      value: subjectId,
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
                      value: gradeTypeId,
                      items: [
                        DropdownMenuItem(
                          value: 'PROVA_1',
                          child: Text('Prova 1'),
                        ),
                        DropdownMenuItem(
                          value: 'PROVA_2',
                          child: Text('Prova 2'),
                        ),
                        DropdownMenuItem(
                          value: 'RECUPERACAO',
                          child: Text('Recuperação'),
                        ),
                        DropdownMenuItem(
                          value: 'RECUPERACAO_FINAL',
                          child: Text('Recuperação Final'),
                        ),
                      ],
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
                      value: periodId,
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
                      try {
                        await GradeService.createGrade(
                          studentId: widget.student.id,
                          subjectId: subjectId!,
                          typeId: gradeTypeId!,
                          periodId: periodId!,
                          value: value!,
                        );
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
                        if (e is http.Response) {
                          debugPrint(
                            'Erro ao lançar nota: statusCode=${e.statusCode}, body=${e.body}',
                          );
                        } else {
                          debugPrint('Erro ao lançar nota: $e');
                        }
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text('Erro ao lançar nota'),
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
    final subjectIds = <String>{};
    List<Map<String, dynamic>> uniqueSubjects = [];
    for (var enrollment in enrollments) {
      if (enrollment['class']?['subjects'] != null) {
        for (var s in enrollment['class']['subjects']) {
          if (s['id'] != null && !subjectIds.contains(s['id'])) {
            subjectIds.add(s['id']);
            uniqueSubjects.add(s);
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
              final grades =
                  (snapshot.data ?? [])
                      .where((g) => g['subjectId'] == subject['id'])
                      .toList();
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
                final periodId = g['periodId'] ?? '-';
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
                              'Bimestre: ${periods.firstWhere((p) => p['id'] == periodId, orElse: () => <String, dynamic>{})['name'] ?? periodId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF2953A5),
                              ),
                            ),
                          ),
                          ...gradesByPeriod[periodId]!.map((g) {
                            return ListTile(
                              title: Text('Nota:  ${g['value']}'),
                              subtitle: Text(
                                'Tipo:  ${getGradeTypeName(g['gradeTypeId'])}',
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
                                      id: g['id'],
                                      value: g['value'].toDouble(),
                                      gradeTypeId: g['gradeTypeId'],
                                      periodId: g['periodId'],
                                      subjectId: g['subjectId'],
                                      studentId: g['studentId'],
                                      createdAt: DateTime.parse(g['createdAt']),
                                      updatedAt: DateTime.parse(g['updatedAt']),
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

  String getGradeTypeName(String id) {
    switch (id) {
      case 'PROVA_1':
        return 'Prova 1';
      case 'PROVA_2':
        return 'Prova 2';
      case 'RECUPERACAO':
        return 'Recuperação';
      case 'RECUPERACAO_FINAL':
        return 'Recuperação Final';
      default:
        return id;
    }
  }

  String _formatClassLabel(Map classData) {
    final name = classData['name'] ?? '';
    final year = classData['year']?.toString() ?? '';
    final shift = classData['shift'] ?? '';
    // Monta só com os campos que existem e não são nulos/vazios
    return [name, year, shift]
        .where((e) => e != null && e.toString().isNotEmpty && e != 'null')
        .join(' - ');
  }
}
