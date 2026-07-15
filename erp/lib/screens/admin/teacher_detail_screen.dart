import 'package:flutter/material.dart';
import '../../utils/user_friendly_error.dart';
import '../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_provider.dart';
import '../../../widgets/data_refresh_widget.dart';
import 'class_detail_screen.dart';
// ignore: depend_on_referenced_packages
import 'package:http_parser/http_parser.dart';

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
  int _selectedYear = DateTime.now().year; // Ano atual como padrão

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
        Uri.parse('${ApiConfig.baseUrl}/teachers/${widget.teacher['id']}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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

  // Atualizar dados do professor após edição
  Future<void> _updateTeacherData(Map<String, dynamic> updatedData) async {
    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Atualizar dados do professor no DataProvider
      await dataProvider.updateTeacherData(widget.teacher['id'], updatedData);

      // Atualizar dados do usuário se necessário
      if (authProvider.user != null) {
        await authProvider.refreshUserData();
      }

      // Atualizar dados locais da tela
      setState(() {
        widget.teacher['name'] = updatedData['name'];
        widget.teacher['email'] = updatedData['email'];
        if (updatedData['photoUrl'] != null) {
          widget.teacher['photoUrl'] = updatedData['photoUrl'];
        }

        // Atualizar também os detalhes se existirem
        if (_teacherDetails != null) {
          _teacherDetails = {
            ..._teacherDetails!,
            'name': updatedData['name'],
            'email': updatedData['email'],
            if (updatedData['photoUrl'] != null)
              'photoUrl': updatedData['photoUrl'],
          };
        }
      });

      // Mostrar feedback de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Professor atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar professor: ${userErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DataRefreshWidget(
      onDataRefreshed: () {
        _fetchTeacherDetails();
      },
      child: Scaffold(
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
                _showEditTeacherDialog();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                final dataProvider = Provider.of<DataProvider>(
                  context,
                  listen: false,
                );
                await dataProvider.refreshCurrentTeacher(widget.teacher['id']);
                await _fetchTeacherDetails();
              },
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
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
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
                      // Turmas que leciona
                      _buildSection(
                        title: 'Turmas que Leciona',
                        icon: Icons.class_,
                        children: [
                          // Filtro por ano
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.filter_list,
                                  color: Color(0xFF2953A5),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Filtrar por ano:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2953A5),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2953A5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButton<int>(
                                    value: _selectedYear,
                                    dropdownColor: const Color(0xFF2953A5),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    underline: const SizedBox(),
                                    items:
                                        _getAvailableYears().map((year) {
                                          return DropdownMenuItem<int>(
                                            value: year,
                                            child: Text(year.toString()),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedYear = value;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          // Lista de disciplinas filtradas
                          if (_getFilteredSubjects().isNotEmpty)
                            ..._getGroupedSubjectsByClass().entries.map(
                              (entry) =>
                                  _buildClassCard(entry.key, entry.value),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Nenhuma turma atribuída para este ano',
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
      ),
    );
  }

  Widget _buildHeader() {
    final filteredSubjects = _getFilteredSubjects();
    final subjectsCount = filteredSubjects.length;
    final lessonsCount = _teacherDetails?['lessons']?.length ?? 0;
    final classesCount = _getGroupedSubjectsByClass().length;
    final photoUrl = widget.teacher['photoUrl'] ?? _teacherDetails?['photoUrl'];

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
            backgroundImage:
                photoUrl != null
                    ? NetworkImage('${ApiConfig.baseUrl}$photoUrl')
                    : null,
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
                  widget.teacher['name'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.teacher['email'] ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _statChip(
                      Icons.class_,
                      '$classesCount turmas ($_selectedYear)',
                    ),
                    _statChip(Icons.book, '$subjectsCount disciplinas'),
                    _statChip(Icons.schedule, '$lessonsCount aulas'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
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

  Widget _buildClassCard(
    String classInfo,
    List<Map<String, dynamic>> subjects,
  ) {
    // Extrai informações da turma para criar o classData
    final classData = _createClassDataFromSubjects(subjects, classInfo);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClassDetailScreen(classData: classData),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _getClassDescription(classInfo),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (subjects.isNotEmpty)
              ...subjects.map((subject) => _buildSubjectCard(subject))
            else
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Nenhuma disciplina atribuída para esta turma',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _createClassDataFromSubjects(
    List<Map<String, dynamic>> subjects,
    String classInfo,
  ) {
    if (subjects.isEmpty) {
      return {
        'name': _getClassDescription(classInfo),
        'academicYear': _selectedYear.toString(),
        'grade': '',
        'letter': '',
        'shift': '',
      };
    }

    // Pega a primeira disciplina para extrair informações da turma
    final firstSubject = subjects.first;
    final subjectName = firstSubject['name'] ?? '';

    // Extrai informações da turma do nome da disciplina
    final classParts = _extractClassInfo(subjectName).split(' - ');
    String grade = '';
    String letter = '';
    String shift = '';

    if (classParts.length >= 2) {
      final gradeInfo = classParts[0]; // "1º Ano A 2025"
      shift = classParts[1]; // "MATUTINO"

      // Extrai série e letra
      if (gradeInfo.contains('º')) {
        final gradeMatch = RegExp(
          r'(\d+)º\s*Ano\s*([A-Z])',
        ).firstMatch(gradeInfo);
        if (gradeMatch != null) {
          grade = '${gradeMatch.group(1)}º Ano';
          letter = gradeMatch.group(2) ?? '';
        }
      }
    }

    return {
      'id': firstSubject['classId'] ?? '',
      'name': _getClassDescription(classInfo),
      'academicYear': _selectedYear.toString(),
      'grade': grade,
      'letter': letter,
      'shift': shift,
    };
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.book, color: const Color(0xFF2953A5), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getSubjectTypeDisplay(subject['type'] ?? ''),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${subject['name'] ?? 'Disciplina não especificada'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _extractClassInfo(String subjectName) {
    // Extrai informações da turma do nome da disciplina
    // Exemplo: "Língua Inglesa - 1º Ano A 2025 - MATUTINO"
    if (subjectName.contains(' - ')) {
      final parts = subjectName.split(' - ');
      if (parts.length >= 2) {
        return parts[1]; // Retorna "1º Ano A 2025 - MATUTINO"
      }
    }
    return 'Turma não especificada';
  }

  String _getClassDescription(String classInfo) {
    // Extrai informações específicas da turma
    if (classInfo.contains(' - ')) {
      final parts = classInfo.split(' - ');
      if (parts.length >= 2) {
        final gradeInfo = parts[0]; // "1º Ano A 2025"
        final shift = parts[1]; // "MATUTINO"
        return '$gradeInfo - $shift';
      }
    }
    return classInfo;
  }

  String _getSubjectTypeDisplay(String type) {
    switch (type) {
      case 'LINGUA_INGLESA':
        return 'Língua Inglesa';
      case 'ARTE':
        return 'Arte';
      case 'EDUCACAO_FISICA':
        return 'Educação Física';
      case 'MATEMATICA':
        return 'Matemática';
      case 'CIENCIAS':
        return 'Ciências';
      case 'HISTORIA':
        return 'História';
      case 'GEOGRAFIA':
        return 'Geografia';
      case 'ENSINO_RELIGIOSO':
        return 'Ensino Religioso';
      case 'BIOLOGIA':
        return 'Biologia';
      case 'FISICA':
        return 'Física';
      case 'QUIMICA':
        return 'Química';
      case 'FILOSOFIA':
        return 'Filosofia';
      case 'SOCIOLOGIA':
        return 'Sociologia';
      case 'CONTEUDO_INTERDISCIPLINAR':
        return 'Conteúdo Interdisciplinar';
      default:
        return type;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  List<Map<String, dynamic>> _getFilteredSubjects() {
    if (_teacherDetails == null || _teacherDetails!['subjects'] == null) {
      return [];
    }

    final subjects = _teacherDetails!['subjects'] as List;
    return subjects
        .where((subject) {
          final subjectName = subject['name'] ?? '';
          return subjectName.contains(_selectedYear.toString());
        })
        .map((subject) => Map<String, dynamic>.from(subject))
        .toList();
  }

  List<int> _getAvailableYears() {
    if (_teacherDetails == null || _teacherDetails!['subjects'] == null) {
      return [DateTime.now().year];
    }

    final subjects = _teacherDetails!['subjects'] as List;
    final years = <int>{};

    for (final subject in subjects) {
      final subjectName = subject['name'] ?? '';
      // Extrai o ano do nome da disciplina (ex: "2025")
      final yearMatch = RegExp(r'(\d{4})').firstMatch(subjectName);
      if (yearMatch != null) {
        years.add(int.parse(yearMatch.group(1)!));
      }
    }

    return years.toList()..sort((a, b) => b.compareTo(a)); // Ordem decrescente
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
      // Obter token de autenticação
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.user?.token;

      if (token == null) {
        throw Exception('Token de autenticação não encontrado');
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/teachers/${widget.teacher['id']}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
          content: Text('Erro ao excluir professor: ${userErrorMessage(e)}'),
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

  void _showEditTeacherDialog() {
    final TextEditingController nameController = TextEditingController(
      text: widget.teacher['name'] ?? '',
    );
    final TextEditingController emailController = TextEditingController(
      text: widget.teacher['email'] ?? '',
    );
    File? selectedImage;
    String? currentPhotoUrl =
        widget.teacher['photoUrl'] ?? _teacherDetails?['photoUrl'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Professor'),
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

                                    if (result != null && mounted) {
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
                      };

                      // Se uma nova foto foi selecionada, fazer upload
                      if (selectedImage != null) {
                        try {
                          final photoUrl = await _uploadTeacherPhoto(
                            widget.teacher['id'],
                            selectedImage!,
                          );
                          updatedData['photoUrl'] = photoUrl;
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

                      await _updateTeacherData(updatedData);

                      if (mounted) {
                        // ignore: use_build_context_synchronously
                        Navigator.of(context).pop();
                      }
                    } catch (e) {
                      if (!mounted) return;
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pop();
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Erro ao atualizar professor: ${userErrorMessage(e)}',
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

  Future<String> _uploadTeacherPhoto(String teacherId, File imageFile) async {
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
        Uri.parse('${ApiConfig.baseUrl}/teachers/$teacherId/photo'),
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

  Map<String, List<Map<String, dynamic>>> _getGroupedSubjectsByClass() {
    if (_teacherDetails == null || _teacherDetails!['subjects'] == null) {
      return {};
    }

    final subjects = _teacherDetails!['subjects'] as List;
    final groupedSubjects = <String, List<Map<String, dynamic>>>{};

    for (final subject in subjects) {
      final subjectName = subject['name'] ?? '';
      if (subjectName.contains(_selectedYear.toString())) {
        final classInfo = _extractClassInfo(subjectName);
        if (!groupedSubjects.containsKey(classInfo)) {
          groupedSubjects[classInfo] = [];
        }
        groupedSubjects[classInfo]!.add(Map<String, dynamic>.from(subject));
      }
    }

    return groupedSubjects;
  }
}
