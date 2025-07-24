import 'package:flutter/material.dart';
import '../../services/assignment_service.dart';
import '../../services/teacher_service.dart';
import '../../services/attendance_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'task_submissions_screen.dart';

class TeacherClassDetailScreen extends StatefulWidget {
  final Map<String, dynamic> classData;
  const TeacherClassDetailScreen({super.key, required this.classData});

  @override
  State<TeacherClassDetailScreen> createState() =>
      _TeacherClassDetailScreenState();
}

class _TeacherClassDetailScreenState extends State<TeacherClassDetailScreen> {
  List<Map<String, dynamic>> _students = [];
  bool _loadingStudents = false;
  String? _errorStudents;
  int _selectedTabIndex = 0;

  // Nova implementação da aba de atividades
  List<Map<String, dynamic>> _assignments = [];
  bool _loadingAssignments = false;
  String? _errorAssignments;

  @override
  void initState() {
    super.initState();
    _fetchAssignments();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _loadingStudents = true;
      _errorStudents = null;
    });
    try {
      final students = await TeacherService.getClassStudents(
        widget.classData['id'],
      );
      setState(() {
        _students = students;
      });
    } catch (e) {
      setState(() {
        _errorStudents = e.toString();
      });
    } finally {
      setState(() {
        _loadingStudents = false;
      });
    }
  }

  Future<void> _fetchAssignments() async {
    setState(() {
      _loadingAssignments = true;
      _errorAssignments = null;
    });
    try {
      final assignments = await AssignmentService.getAssignmentsByClass(
        widget.classData['id'],
      );
      setState(() {
        _assignments = assignments;
      });
    } catch (e) {
      setState(() {
        _errorAssignments = e.toString();
      });
    } finally {
      setState(() {
        _loadingAssignments = false;
      });
    }
  }

  Future<void> _deleteAssignment(String assignmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Excluir Atividade'),
            content: const Text(
              'Tem certeza que deseja excluir esta atividade?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      setState(() => _loadingAssignments = true);
      try {
        await AssignmentService.deleteAssignment(assignmentId);
        await _fetchAssignments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Atividade excluída com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Erro ao excluir assignment: ' + e.toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _loadingAssignments = false);
      }
    }
  }

  void _showAttendanceDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Registrar Presença'),
            content: const Text(
              'Deseja registrar a presença de todos os alunos para hoje?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _registerAllAttendance();
                },
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );
  }

  void _markAttendance(String studentId, bool present) async {
    final dialogContext = context;
    try {
      await AttendanceService.markAttendance(
        studentId: studentId,
        classId: widget.classData['id'],
        present: present,
        date: DateTime.now(),
      );
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(
              present
                  ? 'Aluno marcado como presente'
                  : 'Aluno marcado como ausente',
            ),
            backgroundColor: present ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar presença: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _registerAllAttendance() async {
    final dialogContext = context;
    try {
      final studentIds = _students.map((s) => s['id'] as String).toList();
      await AttendanceService.markAllAttendance(
        classId: widget.classData['id'],
        studentIds: studentIds,
        present: true,
        date: DateTime.now(),
      );
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(
            content: Text('Presença registrada para todos os alunos'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar presença: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddAssignmentDialog() async {
    final result = await showDialog(
      context: context,
      builder:
          (context) => AddAssignmentDialog(classId: widget.classData['id']),
    );
    if (result == true) {
      _fetchAssignments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Turma - ${widget.classData['name'] ?? ''}'),
        backgroundColor: const Color(0xFF2953A5),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Tabs
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color:
                              _selectedTabIndex == 0
                                  ? const Color(0xFF2953A5)
                                  : Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Atividades',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                _selectedTabIndex == 0
                                    ? Colors.white
                                    : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color:
                              _selectedTabIndex == 1
                                  ? const Color(0xFF2953A5)
                                  : Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Chamada',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                _selectedTabIndex == 1
                                    ? Colors.white
                                    : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Conteúdo das tabs
            Expanded(
              child:
                  _selectedTabIndex == 0
                      ? _buildAssignmentsTab()
                      : _buildAttendanceTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return _loadingStudents
        ? const Center(child: CircularProgressIndicator())
        : _errorStudents != null
        ? Center(
          child: Text(
            _errorStudents!,
            style: const TextStyle(color: Colors.red),
          ),
        )
        : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chamada - Hoje',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _showAttendanceDialog,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Registrar Presença'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child:
                  _students.isEmpty
                      ? const Center(child: Text('Nenhum aluno encontrado.'))
                      : ListView.separated(
                        itemCount: _students.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF2953A5),
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(student['name'] ?? ''),
                              subtitle: Text(
                                student['registrationNumber'] ?? '',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    onPressed:
                                        () => _markAttendance(
                                          student['id'],
                                          true,
                                        ),
                                    tooltip: 'Presente',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                    ),
                                    onPressed:
                                        () => _markAttendance(
                                          student['id'],
                                          false,
                                        ),
                                    tooltip: 'Ausente',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        );
  }

  Widget _buildAssignmentsTab() {
    return Stack(
      children: [
        _loadingAssignments
            ? const Center(child: CircularProgressIndicator())
            : _errorAssignments != null
            ? Center(
              child: Text(
                _errorAssignments!,
                style: const TextStyle(color: Colors.red),
              ),
            )
            : _assignments.isEmpty
            ? const Center(child: Text('Nenhuma atividade cadastrada.'))
            : ListView.separated(
              itemCount: _assignments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final assignment = _assignments[index];
                final desc = assignment['description'] ?? '';
                final parts = desc.split('\n');
                final nome =
                    parts.isNotEmpty && parts[0].trim().isNotEmpty
                        ? parts[0]
                        : 'Sem nome';
                final descricao =
                    parts.length > 1 ? parts.sublist(1).join('\n') : '';
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: ListTile(
                    title: Text(nome),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (descricao.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(descricao),
                          ),
                        if (assignment['dueDate'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Entrega até: ${assignment['dueDate'] != null ? assignment['dueDate'].toString().split('T').first : ''}',
                            ),
                          ),
                        if (assignment['fileUrl'] != null &&
                            assignment['fileUrl'].toString().isNotEmpty)
                          TextButton.icon(
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Baixar Anexo'),
                            onPressed: () async {
                              final url = assignment['fileUrl'];
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Excluir atividade',
                      onPressed: () => _deleteAssignment(assignment['id']),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => TaskSubmissionsScreen(
                                assignment: assignment,
                                students: _students,
                              ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            backgroundColor: Colors.orange,
            onPressed: _showAddAssignmentDialog,
            child: const Icon(Icons.add, size: 32, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// Nova implementação do diálogo de adicionar atividade
class AddAssignmentDialog extends StatefulWidget {
  final String classId;
  const AddAssignmentDialog({super.key, required this.classId});

  @override
  State<AddAssignmentDialog> createState() => _AddAssignmentDialogState();
}

class _AddAssignmentDialogState extends State<AddAssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _dueDate;
  bool _loading = false;
  String? _error;
  String? _fileName;
  Uint8List? _fileBytes;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _fileName = result.files.single.name;
          _fileBytes = result.files.single.bytes;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao selecionar arquivo: $e';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _dueDate == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final dialogContext = context;
    try {
      String? fileUrl;
      if (_fileBytes != null && _fileName != null) {
        // Enviar arquivo para o backend (implemente o endpoint se necessário)
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${AssignmentService.baseUrl}/assignments/upload'),
        );
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _fileBytes!,
            filename: _fileName!,
          ),
        );
        final streamed = await request.send();
        final resp = await http.Response.fromStream(streamed);
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          fileUrl = data['url'] ?? data['fileUrl'];
        } else {
          setState(() {
            _error = 'Erro ao enviar arquivo: ${resp.body}';
          });
          return;
        }
      }
      await AssignmentService.createAssignment(
        classId: widget.classId,
        description: _nameController.text + '\n' + _descController.text,
        dueDate: _dueDate!,
        fileUrl: fileUrl,
      );
      if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
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
    return AlertDialog(
      title: const Text('Nova Atividade'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome da Atividade'),
              validator:
                  (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Descrição'),
              validator:
                  (v) => v == null || v.isEmpty ? 'Informe a descrição' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Data de Entrega:'),
                const SizedBox(width: 8),
                Text(
                  _dueDate == null
                      ? 'Selecione'
                      : _dueDate!.toString().split(' ')[0],
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _dueDate = picked);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Anexar Arquivo'),
                ),
                const SizedBox(width: 8),
                if (_fileName != null)
                  Flexible(
                    child: Text(
                      _fileName!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Colors.green),
                    ),
                  ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child:
              _loading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Salvar'),
        ),
      ],
    );
  }
}
