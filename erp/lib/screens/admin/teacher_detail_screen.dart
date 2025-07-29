import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TeacherDetailScreen extends StatefulWidget {
  final Map<String, dynamic> teacher;

  const TeacherDetailScreen({super.key, required this.teacher});

  @override
  State<TeacherDetailScreen> createState() => _TeacherDetailScreenState();
}

class _TeacherDetailScreenState extends State<TeacherDetailScreen> {
  bool _loading = false;
  Map<String, dynamic>? _teacherDetails;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTeacherDetails();
  }

  Future<void> _fetchTeacherDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/teachers/${widget.teacher['id']}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _teacherDetails = data;
        });
      } else {
        setState(() {
          _error = 'Erro ao carregar detalhes do professor';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro de conexão: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text('Ficha do Professor: ${widget.teacher['name']}'),
        backgroundColor: const Color(0xFF2953A5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implementar edição do professor
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidade de edição em desenvolvimento'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
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
                      onPressed: _fetchTeacherDetails,
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
                        _buildInfoRow('Nome', widget.teacher['name'] ?? ''),
                        _buildInfoRow('Email', widget.teacher['email'] ?? ''),
                        if (_teacherDetails != null) ...[
                          if (_teacherDetails!['phone'] != null)
                            _buildInfoRow(
                              'Telefone',
                              _teacherDetails!['phone'],
                            ),
                          if (_teacherDetails!['address'] != null)
                            _buildInfoRow(
                              'Endereço',
                              _teacherDetails!['address'],
                            ),
                          if (_teacherDetails!['birthDate'] != null)
                            _buildInfoRow(
                              'Data de Nascimento',
                              _formatDate(_teacherDetails!['birthDate']),
                            ),
                          if (_teacherDetails!['specialization'] != null)
                            _buildInfoRow(
                              'Especialização',
                              _teacherDetails!['specialization'],
                            ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Informações profissionais
                    _buildSection(
                      title: 'Informações Profissionais',
                      icon: Icons.work,
                      children: [
                        if (_teacherDetails != null) ...[
                          if (_teacherDetails!['hireDate'] != null)
                            _buildInfoRow(
                              'Data de Contratação',
                              _formatDate(_teacherDetails!['hireDate']),
                            ),
                          if (_teacherDetails!['status'] != null)
                            _buildInfoRow('Status', _teacherDetails!['status']),
                          if (_teacherDetails!['department'] != null)
                            _buildInfoRow(
                              'Departamento',
                              _teacherDetails!['department'],
                            ),
                          if (_teacherDetails!['qualification'] != null)
                            _buildInfoRow(
                              'Qualificação',
                              _teacherDetails!['qualification'],
                            ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Turmas que leciona
                    _buildSection(
                      title: 'Turmas que Leciona',
                      icon: Icons.class_,
                      children: [
                        if (_teacherDetails != null &&
                            _teacherDetails!['classes'] != null)
                          ...(_teacherDetails!['classes'] as List).map(
                            (classData) => _buildClassCard(classData),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Nenhuma turma atribuída',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Disciplinas que leciona
                    _buildSection(
                      title: 'Disciplinas que Leciona',
                      icon: Icons.book,
                      children: [
                        if (_teacherDetails != null &&
                            _teacherDetails!['subjects'] != null)
                          ...(_teacherDetails!['subjects'] as List).map(
                            (subject) => _buildSubjectCard(subject),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Nenhuma disciplina atribuída',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Informações do sistema
                    _buildSection(
                      title: 'Informações do Sistema',
                      icon: Icons.info,
                      children: [
                        _buildInfoRow('ID', widget.teacher['id'] ?? ''),
                        if (widget.teacher['createdAt'] != null)
                          _buildInfoRow(
                            'Data de Criação',
                            _formatDate(widget.teacher['createdAt']),
                          ),
                        _buildInfoRow('Tipo de Usuário', 'Professor'),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildHeader() {
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
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 50, color: Color(0xFF2953A5)),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.teacher['name'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.teacher['email'] ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                if (_teacherDetails != null &&
                    _teacherDetails!['specialization'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Especialização: ${_teacherDetails!['specialization']}',
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

  Widget _buildClassCard(Map<String, dynamic> classData) {
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
            classData['name'] ?? 'Turma não especificada',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.grade, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Série: ${classData['grade'] ?? ''}${classData['letter'] ?? ''}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Ano: ${classData['academicYear'] ?? 'N/A'}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          if (classData['shift'] != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Turno: ${classData['shift']}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject['name'] ?? 'Disciplina não especificada',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (subject['description'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subject['description'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
                if (subject['workload'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Carga horária: ${subject['workload']} horas',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ],
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

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Tem certeza que deseja excluir o professor "${widget.teacher['name']}"?\n\n'
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
                _deleteTeacher();
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

  Future<void> _deleteTeacher() async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await http.delete(
        Uri.parse('http://localhost:3000/teachers/${widget.teacher['id']}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Professor excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Volta para a tela anterior
      } else {
        throw Exception('Erro ao excluir professor');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir professor: ${e.toString()}'),
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
}
