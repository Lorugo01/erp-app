import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/data_refresh_widget.dart';

class TeacherProfileScreen extends StatefulWidget {
  final String teacherId;

  const TeacherProfileScreen({super.key, required this.teacherId});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen>
    with DataRefreshMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    setState(() => _isLoading = true);

    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      await dataProvider.refreshCurrentTeacher(widget.teacherId);

      final teacher = dataProvider.currentTeacher;
      if (teacher != null) {
        _nameController.text = teacher['name'] ?? '';
        _emailController.text = teacher['email'] ?? '';
      }
    } catch (e) {
      showErrorSnackBar('Erro ao carregar dados: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTeacherData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Atualizar dados do professor
      await dataProvider.updateTeacherData(widget.teacherId, {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
      });

      // Atualizar dados do usuário se necessário
      if (authProvider.user != null) {
        await authProvider.refreshUserData();
      }

      setState(() => _isEditing = false);
      showRefreshSnackBar('Dados atualizados com sucesso!');
    } catch (e) {
      showErrorSnackBar('Erro ao atualizar dados: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTeacherPhoto() async {
    // Implementar upload de foto
    showRefreshSnackBar('Funcionalidade de upload de foto será implementada');
  }

  @override
  Widget build(BuildContext context) {
    return DataRefreshWidget(
      onDataRefreshed: () {
        _loadTeacherData();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Perfil do Professor'),
          actions: [
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed:
                  _isEditing
                      ? _updateTeacherData
                      : () {
                        setState(() => _isEditing = true);
                      },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await refreshTeacherData(widget.teacherId);
                await _loadTeacherData();
              },
            ),
          ],
        ),
        body: Consumer<DataProvider>(
          builder: (context, dataProvider, child) {
            final teacher = dataProvider.currentTeacher;

            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (teacher == null) {
              return const Center(child: Text('Professor não encontrado'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto do perfil
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage:
                              teacher['photoUrl'] != null
                                  ? NetworkImage(
                                    '${ApiConfig.baseUrl}${teacher['photoUrl']}',
                                  )
                                  : null,
                          child:
                              teacher['photoUrl'] == null
                                  ? const Icon(Icons.person, size: 60)
                                  : null,
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                ),
                                onPressed: _updateTeacherPhoto,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Formulário de dados
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          enabled: _isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Nome',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nome é obrigatório';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          enabled: _isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email é obrigatório';
                            }
                            if (!value.contains('@')) {
                              return 'Email inválido';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Informações adicionais
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informações do Professor',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const Icon(Icons.school),
                            title: const Text('ID do Professor'),
                            subtitle: Text(teacher['id'] ?? 'N/A'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: const Text('Data de Criação'),
                            subtitle: Text(
                              teacher['createdAt'] != null
                                  ? DateTime.parse(
                                    teacher['createdAt'],
                                  ).toString().split(' ')[0]
                                  : 'N/A',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botões de ação
                  if (_isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _updateTeacherData,
                            child: const Text('Salvar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() => _isEditing = false);
                              _loadTeacherData(); // Recarregar dados originais
                            },
                            child: const Text('Cancelar'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
