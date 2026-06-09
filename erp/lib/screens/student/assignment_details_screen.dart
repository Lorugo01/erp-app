import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
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
  String? _description;

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
                              onPressed: () async {
                                final url = '${ApiConfig.baseUrl}$fileUrl';
                                final uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Não foi possível abrir o arquivo',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Seção de entrega
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Entrega',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campo de descrição
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Descrição da entrega (opcional)',
                        border: OutlineInputBorder(),
                        hintText: 'Descreva sua entrega...',
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        setState(() {
                          _description = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Seleção de arquivo
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.attach_file),
                            label: Text(
                              _selectedFileName ?? 'Selecionar Arquivo',
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

                    // Botão de enviar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _selectedFilePath != null
                                ? _submitAssignment
                                : null,
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text(
                                  'Enviar Entrega',
                                  style: TextStyle(fontSize: 16),
                                ),
                      ),
                    ),
                  ],
                ),
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
          content: Text('Erro ao selecionar arquivo: \${userErrorMessage(e)}'),
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
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um arquivo para enviar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // Buscar ID do aluno
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      final token = user?.token;
      String? studentId;

      if (user?.student?.id != null) {
        studentId = user!.student!.id;
      } else if (user?.id != null) {
        final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
        final studentResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/students/user/${user!.id}'),
          headers: headers,
        );

        if (studentResponse.statusCode == 200) {
          final studentData = jsonDecode(studentResponse.body);
          studentId = studentData['id']?.toString();
        }
      }

      if (studentId == null) {
        throw Exception('ID do aluno não encontrado');
      }

      // Criar request multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '${ApiConfig.baseUrl}/assignments/${widget.assignment['id']}/submissions',
        ),
      );

      // Adicionar headers
      final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      request.headers.addAll(headers);

      // Adicionar campos
      request.fields['studentId'] = studentId;
      if (_description != null && _description!.isNotEmpty) {
        request.fields['description'] = _description!;
      }

      // Adicionar arquivo
      final file = File(_selectedFilePath!);
      final stream = http.ByteStream(file.openRead());
      final length = await file.length();
      final multipartFile = http.MultipartFile(
        'file',
        stream,
        length,
        filename: _selectedFileName,
      );
      request.files.add(multipartFile);

      // Enviar request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrega enviada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retorna true para indicar sucesso
      } else {
        throw Exception(
          'Erro ao enviar entrega: ${response.statusCode} - $responseBody',
        );
      }
    } catch (e) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar entrega: \${userErrorMessage(e)}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
}
