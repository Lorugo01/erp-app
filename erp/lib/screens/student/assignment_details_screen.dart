import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../config/api_config.dart';
import '../../services/file_link_service.dart';
import '../../providers/auth_provider.dart';
import '../../services/alexandria_service.dart';
import '../../utils/user_friendly_error.dart';
import '../../widgets/alexandria_book_picker.dart';
import 'package:provider/provider.dart';

class AssignmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> assignment;

  const AssignmentDetailsScreen({super.key, required this.assignment});

  @override
  State<AssignmentDetailsScreen> createState() =>
      _AssignmentDetailsScreenState();
}

class _AssignmentDetailsScreenState extends State<AssignmentDetailsScreen> {
  bool _loading = false;
  String? _selectedFilePath;
  String? _selectedFileName;
  final _descriptionController = TextEditingController();

  // Entrega já feita pelo aluno (null enquanto não entregou)
  Map<String, dynamic>? _mySubmission;
  bool _loadingMine = true;
  bool _canEdit = false;
  DateTime? _deadline;
  bool _editing = false;
  bool _removeExistingFile = false;

  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  bool get _hasExistingFile =>
      _editing &&
      !_removeExistingFile &&
      (_mySubmission?['fileUrl']?.toString().isNotEmpty ?? false);

  /// A entrega precisa de um texto (ex.: resumo da leitura) ou de um arquivo.
  bool get _canSubmit =>
      !_loading &&
      (_selectedFilePath != null ||
          _descriptionController.text.trim().isNotEmpty ||
          _hasExistingFile);

  Map<String, String> get _authHeaders {
    final token = ApiConfig.sessionToken;
    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  String get _mineUrl =>
      '${ApiConfig.baseUrl}/assignments/${widget.assignment['id']}/submissions/mine';

  @override
  void initState() {
    super.initState();
    _loadMySubmission();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadMySubmission() async {
    try {
      final response = await http.get(
        Uri.parse(_mineUrl),
        headers: _authHeaders,
      );
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _mySubmission = data['submission'] as Map<String, dynamic>?;
          _canEdit = data['canEdit'] == true;
          _deadline = DateTime.tryParse('${data['deadline']}')?.toLocal();
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar a entrega do aluno: $e');
    } finally {
      if (mounted) setState(() => _loadingMine = false);
    }
  }

  void _startEditing() {
    setState(() {
      _editing = true;
      _removeExistingFile = false;
      _selectedFilePath = null;
      _selectedFileName = null;
      _descriptionController.text =
          _mySubmission?['description']?.toString() ?? '';
    });
  }

  void _cancelEditing() {
    setState(() {
      _editing = false;
      _selectedFilePath = null;
      _selectedFileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;
    final description = assignment['description'] ?? 'Sem descrição';
    final dueDate = assignment['dueDate'] ?? '';
    final subject =
        assignment['subject']?['name'] ?? 'Disciplina não informada';
    final fileUrl = assignment['fileUrl'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Atividade'),
        backgroundColor: const Color(0xFF2953A5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card com informações da atividade
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.assignment,
                          color: Color(0xFF2953A5),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Atividade',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(description, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    _buildInfoRow('Disciplina', subject),
                    if (dueDate.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow('Data de Entrega', _formatDate(dueDate)),
                    ],
                    if (fileUrl != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.attach_file,
                            color: Color(0xFF2953A5),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Arquivo da Atividade:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.download, size: 18),
                              label: const Text('Baixar Anexo'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF2953A5),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onPressed:
                                  () => FileLinkService.open(
                                    context,
                                    fileUrl?.toString(),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (assignment['bookId'] != null) ...[
              const SizedBox(height: 16),
              _buildBookCard(assignment),
            ],
            const SizedBox(height: 24),

            // Seção de entrega
            _buildDeliveryCard(assignment),
          ],
        ),
      ),
    );
  }

  /// Livro do Alexandria compartilhado pelo professor.
  Widget _buildBookCard(Map<String, dynamic> assignment) {
    final bookId = '${assignment['bookId']}';
    final title = '${assignment['bookTitle'] ?? 'Livro'}';
    final coverUrl = assignment['bookCoverUrl'] as String?;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AlexandriaBookCover(url: coverUrl, width: 56, height: 80),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Livro para ler',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.menu_book, size: 18),
                    label: const Text('Abrir no Alexandria'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2953A5),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final opened = await AlexandriaService.openBook(bookId);
                      if (!opened && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Não foi possível abrir o Alexandria. '
                              'Verifique se o app está instalado.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
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

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar arquivo: ${userErrorMessage(e)}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearFile() {
    setState(() {
      _selectedFilePath = null;
      _selectedFileName = null;
    });
  }

  Future<void> _submitAssignment() async {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escreva sua entrega ou anexe um arquivo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      if (_editing) {
        await _sendSubmission('PUT', Uri.parse(_mineUrl), {
          'description': _descriptionController.text.trim(),
          if (_removeExistingFile && _selectedFilePath == null)
            'removeFile': 'true',
        }, expectedStatus: 200);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrega atualizada!'),
            backgroundColor: Colors.green,
          ),
        );
        _cancelEditing();
        await _loadMySubmission();
        return;
      }

      final studentId = await _findStudentId();
      if (studentId == null) {
        throw Exception('ID do aluno não encontrado');
      }
      final description = _descriptionController.text.trim();
      await _sendSubmission(
        'POST',
        Uri.parse(
          '${ApiConfig.baseUrl}/assignments/${widget.assignment['id']}/submissions',
        ),
        {
          'studentId': studentId,
          if (description.isNotEmpty) 'description': description,
        },
        expectedStatus: 201,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrega enviada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _selectedFilePath = null;
        _selectedFileName = null;
      });
      await _loadMySubmission();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar entrega: ${userErrorMessage(e)}'),
          backgroundColor: Colors.red,
        ),
      );
      // Ex.: já existia uma entrega (409); mostra a que está salva
      await _loadMySubmission();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<String?> _findStudentId() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user?.student?.id != null) return user!.student!.id;
    if (user?.id == null) return null;
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/students/user/${user!.id}'),
      headers: {...ApiConfig.defaultHeaders, ..._authHeaders},
    );
    if (response.statusCode != 200) return null;
    return jsonDecode(response.body)['id']?.toString();
  }

  Future<void> _sendSubmission(
    String method,
    Uri uri,
    Map<String, String> fields, {
    required int expectedStatus,
  }) async {
    final request =
        http.MultipartRequest(method, uri)
          ..headers.addAll(_authHeaders)
          ..fields.addAll(fields);
    if (_selectedFilePath != null) {
      final file = File(_selectedFilePath!);
      request.files.add(
        http.MultipartFile(
          'file',
          http.ByteStream(file.openRead()),
          await file.length(),
          filename: _selectedFileName,
        ),
      );
    }
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode != expectedStatus) {
      final message =
          body.trim().startsWith('{') ? jsonDecode(body)['error'] : null;
      throw Exception(message ?? 'Erro ${response.statusCode}');
    }
  }

  /// Entrega: formulário enquanto não entregou; depois, o que foi enviado,
  /// com edição liberada só dentro do prazo.
  Widget _buildDeliveryCard(Map<String, dynamic> assignment) {
    final showForm = _mySubmission == null || _editing;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _mySubmission == null ? 'Entrega' : 'Sua entrega',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_loadingMine)
              const Center(child: CircularProgressIndicator())
            else if (showForm)
              ..._buildSubmissionForm(assignment['bookId'] != null)
            else
              ..._buildSubmissionView(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSubmissionView() {
    final sub = _mySubmission!;
    final text = sub['description']?.toString() ?? '';
    final fileUrl = sub['fileUrl']?.toString() ?? '';
    final submittedAt = DateTime.tryParse('${sub['submittedAt']}')?.toLocal();
    final updatedAt = DateTime.tryParse('${sub['updatedAt']}')?.toLocal();
    final deadline =
        _deadline == null ? '' : _dateTimeFormat.format(_deadline!);
    return [
      if (submittedAt != null)
        Text(
          'Enviada em ${_dateTimeFormat.format(submittedAt)}'
          '${updatedAt == null ? '' : ' · editada em ${_dateTimeFormat.format(updatedAt)}'}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      if (text.isNotEmpty) ...[
        const SizedBox(height: 12),
        SelectableText(text, style: const TextStyle(fontSize: 15)),
      ],
      if (fileUrl.isNotEmpty) ...[
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(Icons.attach_file, size: 18),
          label: const Text('Ver arquivo enviado'),
          onPressed: () => FileLinkService.open(context, fileUrl),
        ),
      ],
      const SizedBox(height: 16),
      if (_canEdit) ...[
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _startEditing,
            icon: const Icon(Icons.edit),
            label: const Text('Editar entrega'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2953A5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (deadline.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Você pode editar até $deadline.',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ] else
        Text(
          deadline.isEmpty
              ? 'O prazo terminou. A entrega não pode mais ser editada.'
              : 'O prazo terminou em $deadline. A entrega não pode mais ser editada.',
          style: const TextStyle(color: Colors.orange),
        ),
    ];
  }

  List<Widget> _buildSubmissionForm(bool isBook) {
    final existingFile = _mySubmission?['fileUrl']?.toString() ?? '';
    return [
      TextField(
        controller: _descriptionController,
        decoration: InputDecoration(
          labelText: isBook ? 'Resumo da leitura' : 'Descrição da entrega',
          border: const OutlineInputBorder(),
          hintText:
              isBook
                  ? 'Escreva um resumo do que você leu...'
                  : 'Descreva sua entrega...',
        ),
        maxLines: isBook ? 6 : 3,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 16),
      if (_hasExistingFile && _selectedFilePath == null) ...[
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.attach_file, size: 18),
                label: const Text('Arquivo atual'),
                onPressed: () => FileLinkService.open(context, existingFile),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _removeExistingFile = true),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Remover arquivo atual',
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(
                _selectedFileName ??
                    (_hasExistingFile
                        ? 'Trocar arquivo (opcional)'
                        : 'Anexar arquivo (opcional)'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2953A5),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          if (_selectedFilePath != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: _clearFile,
              icon: const Icon(Icons.clear, color: Colors.red),
              tooltip: 'Remover arquivo',
            ),
          ],
        ],
      ),
      if (_selectedFileName != null) ...[
        const SizedBox(height: 8),
        Text(
          'Arquivo selecionado: $_selectedFileName',
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _canSubmit ? _submitAssignment : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2953A5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child:
              _loading
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Text(
                    _editing ? 'Salvar alterações' : 'Enviar Entrega',
                    style: const TextStyle(fontSize: 16),
                  ),
        ),
      ),
      if (_editing)
        Center(
          child: TextButton(
            onPressed: _loading ? null : _cancelEditing,
            child: const Text('Cancelar'),
          ),
        ),
    ];
  }
}
