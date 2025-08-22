import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/data_refresh_widget.dart';
import '../../services/teacher_service.dart';
import '../../services/tecaai_service.dart';
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import 'teacher_class_detail_screen.dart';
import 'teacher_student_detail_screen.dart';
import 'teacher_calendar_screen.dart';

// Classe utilitária para logging estruturado
class TeacherDashboardLogger {
  static const String _prefix = '🏫 [TeacherDashboard]';

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

  static void armario(String message, [Map<String, dynamic>? data]) {
    debugPrint('$_prefix 🗄️ [Armário] $message');
    if (data != null) {
      debugPrint('$_prefix 📊 Dados do armário: $data');
    }
  }
}

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen>
    with SingleTickerProviderStateMixin, DataRefreshMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _classesSearchController =
      TextEditingController();

  List<Map<String, dynamic>> _teacherClasses = [];
  List<Map<String, dynamic>> _filteredClasses = [];
  List<Map<String, dynamic>> _allStudents = [];
  bool _loadingClasses = false;
  bool _loadingStudents = false;
  String? _errorClasses;
  String? _errorStudents;
  Timer? _debounce;

  // Variáveis para controle dos armários
  bool _isLoadingArmarios = false;
  bool _isConnected = false;
  List<TecaAIItem> _armarioItems = [];
  List<TecaAIItem> _filteredArmarioItems = [];
  String? _selectedArmario;
  final TextEditingController _armarioSearchController =
      TextEditingController();

  // Variáveis para filtragem de armários
  String? _selectedArmarioFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Debug inicial
    TeacherDashboardLogger.info('Inicializando dashboard do professor');
    TeacherDashboardLogger.debug('Estado inicial', {
      'selectedArmario': _selectedArmario,
      'tabControllerLength': _tabController.length,
    });

    // Garantir que comece como null
    _selectedArmario = null;
    TeacherDashboardLogger.debug('Estado após reset', {
      'selectedArmario': _selectedArmario,
    });

    _loadInitialData();
    _loadArmarioData();
  }

  // Método para mostrar diálogo de confirmação antes de sair
  Future<void> _showLogoutConfirmation() async {
    TeacherDashboardLogger.info('Mostrando diálogo de confirmação de logout');

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.orange),
              SizedBox(width: 8),
              Text('Confirmar Saída'),
            ],
          ),
          content: const Text(
            'Tem certeza que deseja sair da sua conta?\n\n'
            'Você será redirecionado para a tela de login.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                TeacherDashboardLogger.info('Logout cancelado pelo usuário');
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                TeacherDashboardLogger.info('Logout confirmado pelo usuário');
                Navigator.of(context).pop();
                // Executar logout após confirmação
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                authProvider.logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadInitialData() async {
    await _loadTeacherClasses();
    await _loadAllStudents();
  }

  Future<void> _loadArmarioData() async {
    await _checkArmarioConnection();
    await _loadArmarioItems();
  }

  Future<void> _checkArmarioConnection() async {
    try {
      final connected = await TecaAIService.checkConnection();
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
        });
      }
    }
  }

  Future<void> _loadArmarioItems() async {
    if (mounted) {
      setState(() => _isLoadingArmarios = true);
    }
    try {
      final items = await TecaAIService.getAllItems();
      if (mounted) {
        setState(() {
          _armarioItems = items;
          _filteredArmarioItems = items;

          // Debug dos itens carregados
          TeacherDashboardLogger.info('Itens carregados');
          TeacherDashboardLogger.debug('Total de itens', {
            'total': items.length,
          });
          TeacherDashboardLogger.debug('selectedArmario', {
            'selectedArmario': _selectedArmario,
          });

          if (items.isNotEmpty) {
            TeacherDashboardLogger.debug('Primeiro item', {
              'nome': items.first.nome,
              'posicao': items.first.posicao,
              'espIp': items.first.espIp,
              'espIpOriginal': items.first.espIpOriginal,
            });

            if (items.length > 1) {
              TeacherDashboardLogger.debug('Segundo item', {
                'nome': items[1].nome,
                'posicao': items[1].posicao,
                'espIp': items[1].espIp,
                'espIpOriginal': items[1].espIpOriginal,
              });
            }
          }
          TeacherDashboardLogger.info('========================');
        });

        // Aplicar filtros após carregar os itens
        _applyFilters();
      }
    } catch (e) {
      TeacherDashboardLogger.error('Erro ao carregar itens', e);
    } finally {
      if (mounted) {
        setState(() => _isLoadingArmarios = false);
      }
    }
  }

  void _filterArmarioItems(String query) {
    TeacherDashboardLogger.info('Filtrando itens');
    TeacherDashboardLogger.debug('Query', {'query': query});
    TeacherDashboardLogger.debug('Filtro de armário', {
      'selectedArmarioFilter': _selectedArmarioFilter,
    });
    TeacherDashboardLogger.debug('selectedArmario', {
      'selectedArmario': _selectedArmario,
    });

    setState(() {
      // Primeiro aplicar filtro de armário
      List<TecaAIItem> armarioFiltered;
      if (_selectedArmarioFilter == null) {
        armarioFiltered = _armarioItems;
      } else {
        armarioFiltered =
            _armarioItems.where((item) {
              // Usar o campo esp_ip que já vem traduzido da API
              return item.espIp == _selectedArmarioFilter;
            }).toList();
      }

      // Depois aplicar filtro de texto
      if (query.isEmpty) {
        _filteredArmarioItems = armarioFiltered;
      } else {
        _filteredArmarioItems =
            armarioFiltered.where((item) {
              return item.nome.toLowerCase().contains(query.toLowerCase()) ||
                  item.posicao.toLowerCase().contains(query.toLowerCase());
            }).toList();
      }
    });

    TeacherDashboardLogger.info('Itens filtrados');
    TeacherDashboardLogger.debug('Total de itens filtrados', {
      'total': _filteredArmarioItems.length,
    });
    TeacherDashboardLogger.info('========================');
  }

  void _filterArmarioItemsByArmario(String? armario) {
    setState(() {
      _selectedArmario = armario;
      if (armario == null) {
        _filteredArmarioItems = _armarioItems;
      } else {
        _filteredArmarioItems =
            _armarioItems.where((item) {
              return item.posicao.startsWith(armario);
            }).toList();
      }
    });
  }

  void _filterClasses(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredClasses = _teacherClasses;
      } else {
        _filteredClasses =
            _teacherClasses.where((classData) {
              final className =
                  classData['name']?.toString().toLowerCase() ?? '';
              final letter =
                  classData['letter']?.toString().toLowerCase() ?? '';
              final shift = classData['shift']?.toString().toLowerCase() ?? '';
              return className.contains(query.toLowerCase()) ||
                  letter.contains(query.toLowerCase()) ||
                  shift.contains(query.toLowerCase());
            }).toList();
      }
    });
  }

  Future<void> _loadTeacherClasses() async {
    setState(() {
      _loadingClasses = true;
      _errorClasses = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user?.teacher != null) {
        final classes = await TeacherService.getTeacherClasses(
          authProvider.user!.teacher!.id,
          token: authProvider.user?.token,
        );
        setState(() {
          _teacherClasses = classes;
          _filteredClasses = classes;
          _loadingClasses = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorClasses = e.toString();
        _loadingClasses = false;
      });
    }
  }

  Future<void> _loadAllStudents() async {
    setState(() {
      _loadingStudents = true;
      _errorStudents = null;
    });

    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      await dataProvider.refreshStudents();
      setState(() {
        _allStudents = dataProvider.students;
        _loadingStudents = false;
      });
    } catch (e) {
      setState(() {
        _errorStudents = e.toString();
        _loadingStudents = false;
      });
    }
  }

  // Atualizar dados do professor atual
  Future<void> _refreshTeacherData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    if (authProvider.user?.teacher != null) {
      await dataProvider.refreshCurrentTeacher(authProvider.user!.teacher!.id);
      showRefreshSnackBar('Dados do professor atualizados!');
    }
  }

  // Atualizar todos os dados
  Future<void> _refreshAllData() async {
    await refreshAllData();
    await _loadTeacherClasses();
    await _loadAllStudents();
    showRefreshSnackBar('Todos os dados foram atualizados!');
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Ajuda'),
            content: const SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Como usar o dashboard:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Visualize suas turmas e alunos'),
                  Text('• Clique em uma turma para ver detalhes'),
                  Text('• Clique em um aluno para ver seu desempenho'),
                  Text('• Use a barra de pesquisa para encontrar alunos'),
                  Text('• Puxe para baixo para atualizar os dados'),
                  SizedBox(height: 16),
                  Text('Dicas:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('• Mantenha as informações dos alunos atualizadas'),
                  Text('• Registre a frequência regularmente'),
                  Text('• Acompanhe o desempenho dos alunos'),
                  Text(
                    '• Use a atualização automática para dados em tempo real',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendi'),
              ),
            ],
          ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.settings, color: Color(0xFF2953A5)),
                SizedBox(width: 8),
                Text('Configurações'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Perfil:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2953A5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.person, color: Color(0xFF2953A5)),
                    title: const Text('Editar Perfil'),
                    subtitle: const Text(
                      'Atualizar dados pessoais e profissionais',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showEditProfileDialog();
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Preferências:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2953A5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const ListTile(
                    leading: Icon(Icons.notifications, color: Colors.orange),
                    title: Text('Notificações'),
                    subtitle: Text('Ativado'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.color_lens, color: Colors.purple),
                    title: Text('Tema'),
                    subtitle: Text('Claro'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.language, color: Colors.green),
                    title: Text('Idioma'),
                    subtitle: Text('Português'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.refresh, color: Colors.blue),
                    title: Text('Atualização Automática'),
                    subtitle: Text('Ativado'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }

  void _showEditProfileDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final teacher = user?.teacher;

    if (user == null || teacher == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Dados do professor não encontrados'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final nameController = TextEditingController(text: teacher.name);
    final emailController = TextEditingController(text: user.email);
    bool isLoading = false;
    File? selectedImage;
    String? currentPhotoUrl = user.photoUrl;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.person, color: Color(0xFF2953A5)),
                      SizedBox(width: 8),
                      Text('Editar Perfil'),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Seção de Foto
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withAlpha(60),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Avatar/Foto
                                GestureDetector(
                                  onTap:
                                      isLoading
                                          ? null
                                          : () async {
                                            try {
                                              final result = await FilePicker
                                                  .platform
                                                  .pickFiles(
                                                    type: FileType.image,
                                                    allowMultiple: false,
                                                  );

                                              if (result != null &&
                                                  result.files.isNotEmpty) {
                                                final file = File(
                                                  result.files.first.path!,
                                                );
                                                setState(() {
                                                  selectedImage = file;
                                                });
                                              }
                                            } catch (e) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Erro ao selecionar imagem: $e',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 50,
                                        backgroundColor: Colors.grey[300],
                                        backgroundImage:
                                            selectedImage != null
                                                ? FileImage(selectedImage!)
                                                : (currentPhotoUrl != null &&
                                                    currentPhotoUrl.isNotEmpty)
                                                ? NetworkImage(
                                                  '${ApiConfig.baseUrl}$currentPhotoUrl',
                                                )
                                                : null,
                                        child:
                                            (selectedImage == null &&
                                                    (currentPhotoUrl == null ||
                                                        currentPhotoUrl
                                                            .isEmpty))
                                                ? Icon(
                                                  Icons.person,
                                                  size: 50,
                                                  color: Colors.grey[600],
                                                )
                                                : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF2953A5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  selectedImage != null
                                      ? 'Nova foto selecionada'
                                      : 'Toque para alterar a foto',
                                  style: TextStyle(
                                    color:
                                        selectedImage != null
                                            ? Colors.green
                                            : Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Campo Nome
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nome Completo',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 16),

                          // Campo Email (somente leitura por enquanto)
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                              helperText: 'Email não pode ser alterado',
                            ),
                            enabled:
                                false, // Email não pode ser alterado por enquanto
                          ),
                          const SizedBox(height: 16),

                          // Info sobre campos futuros
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.withAlpha(60),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Campos adicionais como telefone e disciplinas serão disponibilizados em futuras atualizações.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                setState(() {
                                  isLoading = true;
                                });

                                try {
                                  // Validação básica
                                  final name = nameController.text.trim();
                                  final email = emailController.text.trim();

                                  if (name.isEmpty || email.isEmpty) {
                                    throw Exception(
                                      'Nome e email são obrigatórios',
                                    );
                                  }

                                  // Atualizar foto se uma nova foi selecionada
                                  if (selectedImage != null) {
                                    await _uploadTeacherPhoto(
                                      teacher.id,
                                      selectedImage!,
                                    );
                                  }

                                  // Preparar dados para atualização
                                  final updateData = {'name': name};

                                  // Atualizar dados do professor via API
                                  await TeacherService.updateTeacher(
                                    teacher.id,
                                    updateData,
                                  );

                                  // Recarregar dados do usuário
                                  await _refreshTeacherData();

                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Perfil atualizado com sucesso!',
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Erro ao atualizar perfil: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2953A5),
                        foregroundColor: Colors.white,
                      ),
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Salvar'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _uploadTeacherPhoto(String teacherId, File imageFile) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/teachers/$teacherId/photo');
      final request = http.MultipartRequest('POST', uri);

      // Adicionar o arquivo
      final multipartFile = await http.MultipartFile.fromPath(
        'photo',
        imageFile.path,
        filename: 'teacher_photo.jpg',
      );
      request.files.add(multipartFile);

      // Enviar a requisição
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Erro ao fazer upload da foto');
      }

      TeacherDashboardLogger.info('Foto do professor atualizada com sucesso');
    } catch (e) {
      TeacherDashboardLogger.error('Erro no upload da foto', e);
      throw Exception('Erro ao atualizar foto: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _classesSearchController.dispose();
    _armarioSearchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {});
    });
  }

  Future<void> _fetchTeacherClasses() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final teacherId = authProvider.user?.teacher?.id;

    if (teacherId == null) {
      if (!mounted) return;
      setState(() {
        _errorClasses =
            'Professor não encontrado. Verifique se você está logado como professor.';
      });
      return;
    }

    TeacherDashboardLogger.api('/teachers/$teacherId/classes', 'GET');
    try {
      final classes = await TeacherService.getTeacherClasses(
        teacherId,
        token: authProvider.user?.token,
      );
      TeacherDashboardLogger.debug('Classes encontradas', {
        'total': classes.length,
      });
      if (!mounted) return;
      setState(() {
        _teacherClasses = classes;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorClasses = e.toString();
      });
    }

    if (mounted) {
      setState(() {
        _loadingClasses = false;
      });
    }
  }

  Future<void> _fetchStudentsFromClasses() async {
    if (!mounted) return;
    setState(() {
      _loadingStudents = true;
      _errorStudents = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      List<Map<String, dynamic>> allStudents = [];

      for (final classData in _teacherClasses) {
        final classId = classData['id'];
        final students = await TeacherService.getClassStudents(
          classId,
          token: authProvider.user?.token,
        );
        allStudents.addAll(students);
      }

      // Remove duplicatas baseado no ID do aluno
      final uniqueStudents = <String, Map<String, dynamic>>{};
      for (final student in allStudents) {
        uniqueStudents[student['id']] = student;
      }

      if (!mounted) return;
      setState(() {
        _allStudents = uniqueStudents.values.toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorStudents = e.toString();
      });
    }

    if (mounted) {
      setState(() {
        _loadingStudents = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredStudents {
    final searchText = _searchController.text.toLowerCase();
    if (searchText.isEmpty) {
      return _allStudents;
    }
    return _allStudents.where((student) {
      final name = student['name']?.toString().toLowerCase() ?? '';
      final email = student['email']?.toString().toLowerCase() ?? '';
      final registration =
          student['registrationNumber']?.toString().toLowerCase() ?? '';

      return name.contains(searchText) ||
          email.contains(searchText) ||
          registration.contains(searchText);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar:
          isWide
              ? null
              : AppBar(
                backgroundColor: const Color(0xFF2953A5),
                elevation: 0,
                title: Text(
                  _getTabTitle(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: Colors.white),
                    onPressed: _showHelpDialog,
                    tooltip: 'Ajuda',
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: _showSettingsDialog,
                    tooltip: 'Configurações',
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: _showLogoutConfirmation,
                    tooltip: 'Sair',
                  ),
                ],
              ),
      body:
          isWide
              ? _buildWideLayout(authProvider)
              : _buildMobileLayout(authProvider),
      bottomNavigationBar: isWide ? null : _buildBottomNavigation(),
    );
  }

  Widget _buildWideLayout(AuthProvider authProvider) {
    return Row(
      children: [
        // Menu lateral azul
        Container(
          width: 220,
          color: const Color(0xFF2953A5),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Menu
              _SidebarButton(
                icon: Icons.class_,
                label: 'Minhas Turmas',
                selected: _tabController.index == 0,
                onTap: () => setState(() => _tabController.animateTo(0)),
              ),
              _SidebarButton(
                icon: Icons.groups,
                label: 'Meus Alunos',
                selected: _tabController.index == 1,
                onTap: () => setState(() => _tabController.animateTo(1)),
              ),
              _SidebarButton(
                icon: Icons.inventory_2,
                label: 'Armários',
                selected: _tabController.index == 2,
                onTap: () => setState(() => _tabController.animateTo(2)),
              ),
              _SidebarButton(
                icon: Icons.calendar_today,
                label: 'Agenda',
                selected: _tabController.index == 3,
                onTap: () => setState(() => _tabController.animateTo(3)),
              ),
              const Spacer(),
              const Divider(color: Colors.white54, indent: 16, endIndent: 16),
              _SidebarButton(
                icon: Icons.help_outline,
                label: 'Ajuda',
                selected: false,
                onTap: () {
                  _showHelpDialog();
                },
              ),
              _SidebarButton(
                icon: Icons.settings,
                label: 'Configurações',
                selected: false,
                onTap: () {
                  _showSettingsDialog();
                },
              ),
              _SidebarButton(
                icon: Icons.logout,
                label: 'Sair',
                selected: false,
                onTap: () => _showLogoutConfirmation(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        // Área principal
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildMainContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Header com busca
        Row(
          children: [
            if (_tabController.index == 0)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        child: TextField(
                          controller: _classesSearchController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Buscar turma...',
                          ),
                          onChanged: _filterClasses,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.grey),
                        onPressed: () => setState(() {}),
                        tooltip: 'Buscar',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: Color(0xFF2953A5),
                        ),
                        onPressed: _fetchTeacherClasses,
                        tooltip: 'Atualizar Turmas',
                      ),
                    ],
                  ),
                ),
              ),
            if (_tabController.index == 1)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Buscar aluno...',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.grey),
                        onPressed: () => setState(() {}),
                        tooltip: 'Buscar',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: Color(0xFF2953A5),
                        ),
                        onPressed: _fetchStudentsFromClasses,
                        tooltip: 'Atualizar Alunos',
                      ),
                    ],
                  ),
                ),
              ),
            if (_tabController.index == 2)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        child: TextField(
                          controller: _armarioSearchController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Buscar item...',
                          ),
                          onChanged: _filterArmarioItems,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.grey),
                        onPressed: () => setState(() {}),
                        tooltip: 'Buscar',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: Color(0xFF2953A5),
                        ),
                        onPressed: _loadArmarioItems,
                        tooltip: 'Atualizar Itens',
                      ),
                    ],
                  ),
                ),
              ),
            if (_tabController.index == 3)
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF2953A5)),
                onPressed: () {
                  // Para a agenda, vamos recarregar os dados do calendário
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Agenda atualizada automaticamente'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: 'Atualizar Agenda',
              ),
          ],
        ),
        const SizedBox(height: 24),
        // Conteúdo das abas
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildClassesTab(),
              _buildStudentsTab(),
              _buildArmariosTab(),
              _buildAgendaTab(),
            ],
          ),
        ),
      ],
    );
  }

  String _getTabTitle() {
    switch (_tabController.index) {
      case 0:
        return 'Minhas Turmas';
      case 1:
        return 'Meus Alunos';
      case 2:
        return 'Controle dos Armários';
      case 3:
        return 'Minha Agenda';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2953A5),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                icon: Icons.class_,
                label: 'Turmas',
                isSelected: _tabController.index == 0,
                onTap: () => setState(() => _tabController.animateTo(0)),
              ),
              _BottomNavItem(
                icon: Icons.groups,
                label: 'Alunos',
                isSelected: _tabController.index == 1,
                onTap: () => setState(() => _tabController.animateTo(1)),
              ),
              _BottomNavItem(
                icon: Icons.inventory_2,
                label: 'Armários',
                isSelected: _tabController.index == 2,
                onTap: () => setState(() => _tabController.animateTo(2)),
              ),
              _BottomNavItem(
                icon: Icons.calendar_today,
                label: 'Agenda',
                isSelected: _tabController.index == 3,
                onTap: () => setState(() => _tabController.animateTo(3)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassesTab() {
    if (_loadingClasses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorClasses != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar turmas',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorClasses!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchTeacherClasses,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_teacherClasses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma turma encontrada',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Você ainda não foi adicionado a nenhuma turma.\n\nPara ser adicionado a uma turma, entre em contato com o administrador.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_filteredClasses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma turma encontrada',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Nenhuma turma corresponde aos critérios de busca.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        int crossAxisCount;
        double childAspectRatio;

        if (screenWidth > 1200) {
          crossAxisCount = 4;
          childAspectRatio = 1.4;
        } else if (screenWidth > 800) {
          crossAxisCount = 3;
          childAspectRatio = 1.2;
        } else if (screenWidth > 600) {
          crossAxisCount = 2;
          childAspectRatio = 1.1;
        } else {
          crossAxisCount = 1;
          childAspectRatio = 1.0;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: screenWidth > 600 ? 24 : 16,
            mainAxisSpacing: screenWidth > 600 ? 24 : 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: _filteredClasses.length,
          itemBuilder: (context, index) {
            final classData = _filteredClasses[index];
            return _ClassCard(classData: classData);
          },
        );
      },
    );
  }

  Widget _buildStudentsTab() {
    if (_loadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorStudents != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar alunos',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorStudents!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchStudentsFromClasses,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_allStudents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum aluno encontrado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Você ainda não tem alunos em suas turmas.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_filteredStudents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum aluno encontrado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Tente ajustar os termos de busca.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        int crossAxisCount;
        double childAspectRatio;

        if (screenWidth > 1200) {
          crossAxisCount = 5;
          childAspectRatio = 0.9;
        } else if (screenWidth > 800) {
          crossAxisCount = 4;
          childAspectRatio = 0.85;
        } else if (screenWidth > 600) {
          crossAxisCount = 3;
          childAspectRatio = 0.8;
        } else if (screenWidth > 400) {
          crossAxisCount = 2;
          childAspectRatio = 0.75;
        } else {
          crossAxisCount = 1;
          childAspectRatio = 0.7;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: screenWidth > 600 ? 24 : 16,
            mainAxisSpacing: screenWidth > 600 ? 24 : 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: _filteredStudents.length,
          itemBuilder: (context, index) {
            final student = _filteredStudents[index];
            return _StudentCard(student: student);
          },
        );
      },
    );
  }

  Widget _buildArmariosTab() {
    // Debug inicial
    TeacherDashboardLogger.armario('Construindo aba de armários');
    TeacherDashboardLogger.debug('selectedArmario', {
      'selectedArmario': _selectedArmario,
    });
    TeacherDashboardLogger.debug('armarioItems.length', {
      'total': _armarioItems.length,
    });
    TeacherDashboardLogger.debug('filteredArmarioItems.length', {
      'total': _filteredArmarioItems.length,
    });
    TeacherDashboardLogger.info('========================');

    if (_isLoadingArmarios) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.signal_wifi_off, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Não foi possível conectar ao armário.',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Verifique sua conexão com a internet e tente novamente.',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadArmarioData,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da seção
          Row(
            children: [
              Icon(Icons.computer, size: 32, color: Color(0xFF2953A5)),
              SizedBox(width: 12),
              Text(
                'Controle dos Armários - TecaAI',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2953A5),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Status de conexão
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _isConnected ? Icons.check_circle : Icons.error,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isConnected ? 'TecaAI Conectado' : 'TecaAI Desconectado',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(_isConnected ? Icons.wifi : Icons.wifi_off),
                    onPressed: _checkArmarioConnection,
                    tooltip: _isConnected ? 'Conectado' : 'Desconectado',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Seção: Localizar Item
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Localizar Item',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed:
                            _isLoadingArmarios ? null : _loadArmarioItems,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Recarregar Itens',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecione um item para localizá-lo no laboratório',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // Campo de busca
                  TextFormField(
                    controller: _armarioSearchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome ou posição...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: _filterArmarioItems,
                  ),

                  const SizedBox(height: 16),

                  // Filtro por Armário
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Filtrar por Armário',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.inventory),
                          ),
                          value: _selectedArmarioFilter,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Todos os Armários'),
                            ),
                            ..._getAvailableArmarios().map((armario) {
                              return DropdownMenuItem<String>(
                                value: armario,
                                child: Row(
                                  children: [
                                    Icon(Icons.inventory, size: 16),
                                    const SizedBox(width: 8),
                                    Text('Armário $armario'),
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (String? value) {
                            setState(() {
                              _selectedArmarioFilter = value;
                              _applyFilters();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear),
                        label: const Text('Limpar Filtros'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Lista de itens
                  if (_filteredArmarioItems.isEmpty)
                    const Center(child: Text('Nenhum item encontrado'))
                  else
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: _filteredArmarioItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredArmarioItems[index];

                          // Criar um identificador único para cada item
                          final itemId = '${item.nome}_${item.posicao}';

                          // Debug simplificado
                          TeacherDashboardLogger.debug('Item', {
                            'index': index,
                            'nome': item.nome,
                            'ID': itemId,
                            'selectedArmario': _selectedArmario,
                          });

                          // Comparação usando o ID único do item
                          final isSelected = _selectedArmario == itemId;

                          TeacherDashboardLogger.debug('isSelected', {
                            'isSelected': isSelected,
                          });

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Colors.blue
                                        : Colors.grey.shade700,
                                width: isSelected ? 2.0 : 1.5,
                              ),
                              borderRadius: BorderRadius.circular(50),
                              color:
                                  isSelected
                                      ? Colors.blue.withAlpha(30)
                                      : Colors.transparent,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(50),
                                onTap: () {
                                  TeacherDashboardLogger.info('Clique no item');
                                  TeacherDashboardLogger.debug('Item clicado', {
                                    'nome': item.nome,
                                    'ID': itemId,
                                  });
                                  TeacherDashboardLogger.debug(
                                    'selectedArmario atual',
                                    {'selectedArmario': _selectedArmario},
                                  );

                                  setState(() {
                                    if (_selectedArmario == itemId) {
                                      // Se já está selecionado, deseleciona
                                      _selectedArmario = null;
                                      TeacherDashboardLogger.info(
                                        'Item DESELECIONADO',
                                      );
                                    } else {
                                      // Seleciona o novo item
                                      _selectedArmario = itemId;
                                      TeacherDashboardLogger.info(
                                        'Item SELECIONADO',
                                      );
                                    }
                                  });
                                },
                                child: ListTile(
                                  title: Text(
                                    item.nome,
                                    style: TextStyle(
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${item.posicao} - Armário ${item.espIp}',
                                  ),
                                  selected:
                                      false, // Sempre false para evitar conflitos
                                  selectedTileColor: Colors.transparent,
                                  trailing:
                                      isSelected
                                          ? Icon(
                                            Icons.check_circle,
                                            color: Colors.blue,
                                            size: 20,
                                          )
                                          : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Item Selecionado
                  if (_selectedArmario != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Item Selecionado:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Builder(
                            builder: (context) {
                              final selectedItem = _filteredArmarioItems
                                  .firstWhere(
                                    (item) =>
                                        '${item.nome}_${item.posicao}' ==
                                        _selectedArmario,
                                    orElse:
                                        () => _armarioItems.firstWhere(
                                          (item) =>
                                              '${item.nome}_${item.posicao}' ==
                                              _selectedArmario,
                                          orElse:
                                              () => TecaAIItem(
                                                id: null,
                                                nome: 'Item não encontrado',
                                                posicao: '',
                                                posicaoOriginal: '',
                                                espIp: '',
                                                espIpOriginal: '',
                                              ),
                                        ),
                                  );

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nome: ${selectedItem.nome}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Posição: ${selectedItem.posicao}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Armário: ${selectedItem.espIp}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Botão de localizar (se houver item selecionado)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isLoadingArmarios
                                ? null
                                : () => _locateSelectedItem(),
                        icon: const Icon(Icons.search),
                        label: const Text('Localizar Item Selecionado'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Comandos Pré-definidos
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Comandos de Controle',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Controle as funcionalidades dos armários',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed:
                            _isLoadingArmarios
                                ? null
                                : () => _executePredefinedCommand('ligar_luz'),
                        icon: const Icon(Icons.lightbulb),
                        label: const Text('Ligar Luz'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            _isLoadingArmarios
                                ? null
                                : () =>
                                    _executePredefinedCommand('desligar_luz'),
                        icon: const Icon(Icons.lightbulb_outline),
                        label: const Text('Desligar Luz'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            _isLoadingArmarios
                                ? null
                                : () =>
                                    _executePredefinedCommand('modo_festa_on'),
                        icon: const Icon(Icons.celebration),
                        label: const Text('Modo Festa ON'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            _isLoadingArmarios
                                ? null
                                : () =>
                                    _executePredefinedCommand('modo_festa_off'),
                        icon: const Icon(Icons.celebration_outlined),
                        label: const Text('Modo Festa OFF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Informações do Sistema
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informações do Sistema',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          title: 'Total de Itens',
                          value: _armarioItems.length.toString(),
                          icon: Icons.inventory_2,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _InfoCard(
                          title: 'Itens Filtrados',
                          value: _filteredArmarioItems.length.toString(),
                          icon: Icons.filter_list,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Status: ${_isConnected ? "Sistema Operacional" : "Sistema Offline"}',
                    style: TextStyle(
                      color: _isConnected ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaTab() {
    return const TeacherCalendarScreen();
  }

  Future<void> _executePredefinedCommand(String commandKey) async {
    if (mounted) {
      setState(() {
        _isLoadingArmarios = true;
      });
    }

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user!;
      final response = await TecaAIService.executePredefinedCommand(
        commandKey: commandKey,
        user: user,
      );

      if (mounted) {
        setState(() {
          _isLoadingArmarios = false;
        });
      }

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comando executado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${response.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingArmarios = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao executar comando: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _locateSelectedItem() async {
    if (_selectedArmario == null) return;

    // Extrair o nome do item do ID único
    final itemName = _selectedArmario!.split('_')[0];

    final selectedItem = _filteredArmarioItems.firstWhere(
      (item) => '${item.nome}_${item.posicao}' == _selectedArmario,
      orElse:
          () => _armarioItems.firstWhere(
            (item) => '${item.nome}_${item.posicao}' == _selectedArmario,
            orElse:
                () => TecaAIItem(
                  id: null,
                  nome: itemName,
                  posicao: '',
                  posicaoOriginal: '',
                  espIp: '',
                  espIpOriginal: '',
                ),
          ),
    );

    TeacherDashboardLogger.info(
      'Item selecionado para localização: ${selectedItem.nome}',
    );
    TeacherDashboardLogger.debug('ID único', {
      'selectedArmario': _selectedArmario,
    });

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user!;
      final response = await TecaAIService.locateItem(
        item: selectedItem.nome,
        user: user,
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item localizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao localizar item: ${response.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao localizar item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<String> _getAvailableArmarios() {
    final uniqueArmarios = <String>{};
    for (final item in _armarioItems) {
      // Usar o campo esp_ip que já vem traduzido da API (ex: "A", "B", "C")
      if (item.espIp.isNotEmpty) {
        uniqueArmarios.add(item.espIp);
      }
    }

    TeacherDashboardLogger.info('Armários disponíveis');
    TeacherDashboardLogger.debug('Armários encontrados', {
      'armarios': uniqueArmarios.toList(),
    });
    TeacherDashboardLogger.info('========================');

    return uniqueArmarios.toList()..sort();
  }

  void _applyFilters() {
    setState(() {
      if (_selectedArmarioFilter == null) {
        _filteredArmarioItems = _armarioItems;
      } else {
        _filteredArmarioItems =
            _armarioItems.where((item) {
              // Usar o campo esp_ip que já vem traduzido da API
              return item.espIp == _selectedArmarioFilter;
            }).toList();
      }
    });

    TeacherDashboardLogger.info('Filtros aplicados');
    TeacherDashboardLogger.debug('Filtro de armário', {
      'selectedArmarioFilter': _selectedArmarioFilter,
    });
    TeacherDashboardLogger.debug('Itens filtrados', {
      'total': _filteredArmarioItems.length,
    });
    TeacherDashboardLogger.info('========================');
  }

  void _clearFilters() {
    setState(() {
      _selectedArmarioFilter = null;
      _armarioSearchController.clear();
      _filteredArmarioItems = _armarioItems;
    });

    TeacherDashboardLogger.info('Filtros limpos');
    TeacherDashboardLogger.info('Filtros resetados para valores padrão');
    TeacherDashboardLogger.debug('Itens filtrados', {
      'total': _filteredArmarioItems.length,
    });
    TeacherDashboardLogger.info('========================');
  }
}

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _SidebarButton({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration:
          selected
              ? BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(8),
              )
              : null,
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white54,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final Map<String, dynamic> classData;

  const _ClassCard({required this.classData});

  String _getShiftText(String? shift) {
    switch (shift) {
      case 'MATUTINO':
        return 'Matutino';
      case 'VESPERTINO':
        return 'Vespertino';
      case 'NOTURNO':
        return 'Noturno';
      default:
        return shift ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;
    final isVerySmall = MediaQuery.of(context).size.width < 400;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TeacherClassDetailScreen(classData: classData),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(
            isVerySmall
                ? 8.0
                : isSmall
                ? 12.0
                : 16.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius:
                    isVerySmall
                        ? 20
                        : isSmall
                        ? 24
                        : 32,
                backgroundColor: const Color(0xFF2953A5),
                child: Icon(
                  Icons.class_,
                  size:
                      isVerySmall
                          ? 24
                          : isSmall
                          ? 28
                          : 40,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                height:
                    isVerySmall
                        ? 8
                        : isSmall
                        ? 12
                        : 16,
              ),
              Text(
                classData['name'] ?? 'Turma',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize:
                      isVerySmall
                          ? 12
                          : isSmall
                          ? 14
                          : 16,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(
                height:
                    isVerySmall
                        ? 4
                        : isSmall
                        ? 6
                        : 8,
              ),
              Text(
                'Ano: ${classData['year'] ?? ''}',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize:
                      isVerySmall
                          ? 10
                          : isSmall
                          ? 12
                          : 14,
                ),
              ),
              SizedBox(
                height:
                    isVerySmall
                        ? 2
                        : isSmall
                        ? 3
                        : 4,
              ),
              Text(
                _getShiftText(classData['shift']),
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize:
                      isVerySmall
                          ? 9
                          : isSmall
                          ? 11
                          : 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentCard extends StatefulWidget {
  final Map<String, dynamic> student;

  const _StudentCard({required this.student});

  @override
  State<_StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<_StudentCard> {
  Future<void> _onStudentCardTap(String teacherId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final classes = await TeacherService.getTeacherClasses(
        teacherId,
        token: authProvider.user?.token,
      );
      if (!mounted) return;

      // Debug: verificar turmas retornadas
      TeacherDashboardLogger.debug('Turmas retornadas', {'turmas': classes});

      // Filtrar as turmas que contêm este aluno
      final studentClasses =
          classes.where((classData) {
            final enrollments = classData['enrollments'] as List? ?? [];
            return enrollments.any(
              (e) => e['studentId'] == widget.student['id'],
            );
          }).toList();

      // Debug: verificar turmas filtradas
      TeacherDashboardLogger.debug('Turmas do aluno', {
        'turmas': studentClasses,
      });

      if (!mounted) return;

      // Se não houver turmas
      if (studentClasses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhuma turma encontrada para este aluno'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Se houver apenas uma turma
      if (studentClasses.length == 1) {
        final classData = studentClasses.first;
        final subjects = classData['subjects'] as List? ?? [];

        // Debug: verificar disciplinas da turma
        TeacherDashboardLogger.debug('Disciplinas da turma', {
          'disciplinas': subjects,
        });

        // Se não houver disciplinas
        if (subjects.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nenhuma disciplina encontrada para esta turma'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Filtrar apenas as disciplinas que o professor leciona
        final teacherSubjects =
            subjects.where((s) => s['teacherId'] == teacherId).toList();

        if (teacherSubjects.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Você não leciona nenhuma disciplina nesta turma'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Se houver apenas uma disciplina
        if (teacherSubjects.length == 1) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (_) => TeacherStudentDetailScreen(
                    student: widget.student,
                    classData: classData,
                    subjectId: teacherSubjects.first['id'],
                    teacherId: teacherId,
                  ),
            ),
          );
        } else {
          // Se houver múltiplas disciplinas
          await _showSubjectSelectionDialog(
            teacherSubjects,
            widget.student,
            classData,
            teacherId,
          );
        }
      } else {
        // Se houver múltiplas turmas
        await _showClassSelectionDialog(
          studentClasses,
          widget.student,
          teacherId,
        );
      }
    } catch (error) {
      if (!mounted) return;
      TeacherDashboardLogger.error('Erro ao carregar turmas', error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar turmas: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showClassSelectionDialog(
    List<Map<String, dynamic>> classes,
    Map<String, dynamic> student,
    String teacherId,
  ) async {
    if (!mounted) return;

    final selectedClass = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Selecionar Turma'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    classes.map((classData) {
                      return ListTile(
                        title: Text(classData['name'] ?? ''),
                        onTap: () => Navigator.of(context).pop(classData),
                      );
                    }).toList(),
              ),
            ),
          ),
    );

    if (!mounted) return;

    if (selectedClass != null) {
      final subjects = selectedClass['subjects'] as List<dynamic>;
      final teacherSubjects =
          subjects.where((s) => s['teacherId'] == teacherId).toList();

      if (teacherSubjects.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Você não leciona nenhuma disciplina nesta turma.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (teacherSubjects.length == 1) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (_) => TeacherStudentDetailScreen(
                  student: student,
                  classData: selectedClass,
                  subjectId: teacherSubjects[0]['id'],
                  teacherId: teacherId,
                ),
          ),
        );
      } else {
        if (!mounted) return;
        await _showSubjectSelectionDialog(
          teacherSubjects,
          student,
          selectedClass,
          teacherId,
        );
      }
    }
  }

  Future<void> _showSubjectSelectionDialog(
    List<dynamic> subjects,
    Map<String, dynamic> student,
    Map<String, dynamic> classData,
    String teacherId,
  ) async {
    if (!mounted) return;

    final selectedSubject = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Selecionar Disciplina'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    subjects.map((subject) {
                      return ListTile(
                        title: Text(subject['name'] ?? ''),
                        onTap: () => Navigator.of(context).pop(subject),
                      );
                    }).toList(),
              ),
            ),
          ),
    );

    if (!mounted) return;

    if (selectedSubject != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => TeacherStudentDetailScreen(
                student: student,
                classData: classData,
                subjectId: selectedSubject['id'],
                teacherId: teacherId,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;
    final isVerySmall = MediaQuery.of(context).size.width < 400;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final teacherId = authProvider.user?.teacher?.id;

        if (teacherId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro: Professor não encontrado'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Debug: verificar dados do professor
        TeacherDashboardLogger.debug('ID do Professor', {'id': teacherId});
        TeacherDashboardLogger.debug('Dados do aluno', {
          'aluno': widget.student,
        });

        _onStudentCardTap(teacherId);
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(
            isVerySmall
                ? 8.0
                : isSmall
                ? 12.0
                : 16.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius:
                    isVerySmall
                        ? 20
                        : isSmall
                        ? 24
                        : 32,
                backgroundColor: const Color(0xFF2953A5),
                child: Icon(
                  Icons.person,
                  size:
                      isVerySmall
                          ? 24
                          : isSmall
                          ? 28
                          : 40,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                height:
                    isVerySmall
                        ? 8
                        : isSmall
                        ? 12
                        : 16,
              ),
              Text(
                widget.student['name'] ?? 'Aluno',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize:
                      isVerySmall
                          ? 12
                          : isSmall
                          ? 14
                          : 16,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(
                height:
                    isVerySmall
                        ? 4
                        : isSmall
                        ? 6
                        : 8,
              ),
              Text(
                widget.student['registrationNumber'] ?? '',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize:
                      isVerySmall
                          ? 10
                          : isSmall
                          ? 12
                          : 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(
                height:
                    isVerySmall
                        ? 4
                        : isSmall
                        ? 6
                        : 8,
              ),
              Text(
                widget.student['email'] ?? '',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize:
                      isVerySmall
                          ? 9
                          : isSmall
                          ? 11
                          : 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
