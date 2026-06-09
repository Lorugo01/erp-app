import 'package:flutter/material.dart';
import '../../utils/user_friendly_error.dart';
import '../../config/api_config.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../../models/user.dart';
import '../../services/user_service.dart';

class UserDetailScreen extends StatefulWidget {
  final User user;
  const UserDetailScreen({required this.user, super.key});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text('Detalhes do Usuário: ${widget.user.displayName}'),
        backgroundColor: const Color(0xFF2953A5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditUserDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card principal do usuário
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar e informações básicas
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF2953A5),
                        backgroundImage:
                            widget.user.photoUrl != null
                                ? NetworkImage(
                                  '${ApiConfig.baseUrl}${widget.user.photoUrl}',
                                )
                                : null,
                        child:
                            widget.user.photoUrl == null
                                ? Text(
                                  widget.user.displayName.isNotEmpty
                                      ? widget.user.displayName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                                : null,
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.displayName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.user.email,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor(widget.user.role),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getRoleText(widget.user.role),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Informações detalhadas
                  _buildInfoRow('ID do Usuário', widget.user.id),
                  _buildInfoRow('E-mail', widget.user.email),
                  _buildInfoRow(
                    'Tipo de Conta',
                    _getRoleText(widget.user.role),
                  ),
                  _buildInfoRow(
                    'Data de Criação',
                    _formatDate(widget.user.createdAt),
                  ),

                  // Informações específicas baseadas no papel
                  if (widget.user.student != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Informações do Aluno',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Nome', widget.user.student!.name),
                    if (widget.user.student!.registrationNumber != null)
                      _buildInfoRow(
                        'Matrícula',
                        widget.user.student!.registrationNumber!,
                      ),
                    if (widget.user.student!.profilePicture != null)
                      _buildInfoRow('Foto de Perfil', 'Sim'),
                  ],

                  if (widget.user.teacher != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Informações do Professor',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Nome', widget.user.teacher!.name),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditUserDialog(),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar Usuário'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2953A5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeleteConfirmation(),
                    icon: const Icon(Icons.delete),
                    label: const Text('Excluir Usuário'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Color _getRoleColor(Role role) {
    switch (role) {
      case Role.developer:
        return Colors.purple;
      case Role.admin:
        return Colors.red;
      case Role.teacher:
        return Colors.orange;
      case Role.student:
        return Colors.green;
    }
  }

  String _getRoleText(Role role) {
    switch (role) {
      case Role.developer:
        return 'Desenvolvedor';
      case Role.admin:
        return 'Administrador';
      case Role.teacher:
        return 'Professor';
      case Role.student:
        return 'Aluno';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Tem certeza que deseja excluir o usuário "${widget.user.displayName}"?\n\n'
            'Esta ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteUser();
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

  void _showEditUserDialog() {
    final TextEditingController nameController = TextEditingController(
      text: widget.user.displayName,
    );
    final TextEditingController emailController = TextEditingController(
      text: widget.user.email,
    );
    File? selectedImage;
    String? currentPhotoUrl = widget.user.photoUrl;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Usuário'),
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
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Erro ao selecionar imagem: ${userErrorMessage(e)}',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
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
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(),
                        hintText: 'Digite o nome completo',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        hintText: 'Digite o email',
                      ),
                      keyboardType: TextInputType.emailAddress,
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nome é obrigatório'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (emailController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email é obrigatório'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final updatedData = {
                        'name': nameController.text.trim(),
                        'email': emailController.text.trim(),
                      };

                      // Se uma nova foto foi selecionada, fazer upload
                      if (selectedImage != null) {
                        try {
                          final photoUrl = await _uploadUserPhoto(
                            widget.user.id,
                            selectedImage!,
                          );
                          updatedData['photoUrl'] = photoUrl;
                        } catch (e) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Erro ao fazer upload da foto: ${userErrorMessage(e)}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                      }

                      // Implementar atualização do usuário
                      try {
                        final response = await http.put(
                          Uri.parse(
                            '${ApiConfig.baseUrl}/users/${widget.user.id}',
                          ),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode(updatedData),
                        );

                        if (response.statusCode == 200) {
                          jsonDecode(response.body);

                          // Atualizar dados locais da tela
                          setState(() {
                            // Atualizar os dados do usuário na tela
                            // Como widget.user é final, vamos atualizar apenas os dados exibidos
                            // Os dados serão atualizados quando a tela for recarregada
                          });

                          // ignore: use_build_context_synchronously
                          Navigator.of(context).pop();
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Usuário atualizado com sucesso!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          final error = jsonDecode(response.body);
                          throw Exception(
                            error['error'] ?? 'Erro ao atualizar usuário',
                          );
                        }
                      } catch (e) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Erro ao atualizar usuário: ${userErrorMessage(e)}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
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
                            'Erro ao atualizar usuário: ${userErrorMessage(e)}',
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

  Future<String> _uploadUserPhoto(String userId, File imageFile) async {
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
        Uri.parse('${ApiConfig.baseUrl}/users/$userId/photo'),
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

  Future<void> _deleteUser() async {
    try {
      await UserService.deleteUser(widget.user.id);

      if (!mounted) return;

      Navigator.of(context).pop(); // Volta para a tela anterior
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário excluído com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir usuário: ${userErrorMessage(e)}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {}
  }
}
