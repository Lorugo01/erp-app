import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../widgets/navigation_bar_widget.dart';
import '../admin/subject_detail_screen.dart';
import 'student_calendar_screen.dart';
import '../../providers/auth_provider.dart';
import '../../services/student_service.dart';
import '../../services/attendance_service.dart';
import '../../services/user_service.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoadingSubjects = false;
  String? _subjectsError;

  // Estado para estatísticas de frequência
  Map<String, dynamic>? _attendanceStats;
  bool _isLoadingStats = false;
  String? _statsError;

  // Estado para dados do aluno
  String _studentName = '';
  String _registrationNumber = '';
  String? _profilePictureUrl;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
    _loadSubjects();
    _loadAttendanceStats();
  }

  Future<void> _loadStudentData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user?.student == null) {
      setState(() {
        _studentName = user?.email ?? 'Aluno';
        _registrationNumber = '-';
        _profilePictureUrl = null;
      });
      return;
    }

    setState(() {});

    try {
      // Usar dados do usuário atual diretamente
      final currentUser = authProvider.user;
      debugPrint('Usuário atual: ${currentUser?.toJson()}');

      if (currentUser?.student != null) {
        debugPrint('Dados do aluno: ${currentUser!.student!.toJson()}');

        setState(() {
          _studentName = currentUser.student!.name;
          _registrationNumber = currentUser.student!.registrationNumber ?? '-';
          _profilePictureUrl = currentUser.student!.profilePicture;
        });

        // Debug: verificar URL da imagem
        if (currentUser.student!.profilePicture != null &&
            currentUser.student!.profilePicture!.isNotEmpty) {
          debugPrint(
            'URL da imagem: http://localhost:3000${currentUser.student!.profilePicture}',
          );
        } else {
          debugPrint('Nenhuma imagem encontrada para o aluno');
        }
      } else {
        debugPrint('Dados do aluno não encontrados');
      }
    } catch (e) {
      setState(() {
        _studentName = user?.student?.name ?? user?.email ?? 'Aluno';
        _registrationNumber = user?.student?.registrationNumber ?? '-';
        _profilePictureUrl = user?.student?.profilePicture;
      });
    }
  }

  Future<void> _loadSubjects() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user?.student?.id == null) {
      setState(() {
        _subjectsError = 'ID do aluno não encontrado';
      });
      return;
    }

    setState(() {
      _isLoadingSubjects = true;
      _subjectsError = null;
    });

    try {
      final subjects = await StudentService.getStudentSubjects(
        user!.student!.id,
      );
      setState(() {
        _subjects = subjects;
        _isLoadingSubjects = false;
      });
    } catch (e) {
      setState(() {
        _subjectsError = 'Erro ao carregar disciplinas: $e';
        _isLoadingSubjects = false;
      });
    }
  }

  Future<void> _loadAttendanceStats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user?.student?.id == null) {
      setState(() {
        _statsError = 'ID do aluno não encontrado';
      });
      return;
    }

    setState(() {
      _isLoadingStats = true;
      _statsError = null;
    });

    try {
      final stats = await AttendanceService.getStudentAttendanceStats(
        user!.student!.id,
      );
      setState(() {
        _attendanceStats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _statsError = 'Erro ao carregar estatísticas: $e';
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FB),
          body: SafeArea(
            child: Row(
              children: [
                if (isWide)
                  NavigationBarWidget(
                    selectedIndex: _selectedIndex,
                    onSelect: (i) => setState(() => _selectedIndex = i),
                    isWide: isWide,
                  ),
                Expanded(child: _buildTabContent(_selectedIndex)),
              ],
            ),
          ),
          bottomNavigationBar:
              isWide
                  ? null
                  : NavigationBarWidget(
                    selectedIndex: _selectedIndex,
                    onSelect: (i) => setState(() => _selectedIndex = i),
                    isWide: isWide,
                  ),
        );
      },
    );
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildSubjectsTab();
      case 2:
        return StudentCalendarScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar com botão de edição sobreposto
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                      ? ClipOval(
                        child: Image.network(
                          'http://localhost:3000$_profilePictureUrl!',
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('Erro ao carregar imagem: $error');
                            return Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 56,
                                color: Colors.grey,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                        ),
                      )
                      : CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.grey[300],
                        child: const Icon(
                          Icons.person,
                          size: 56,
                          color: Colors.grey,
                        ),
                      ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => _EditProfileDialog(
                                  currentEmail:
                                      Provider.of<AuthProvider>(
                                        context,
                                        listen: false,
                                      ).user?.email ??
                                      '',
                                  onSave: _saveProfileChanges,
                                ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2953A5),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _studentName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Matrícula: $_registrationNumber',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Sininho
              IconButton(
                icon: const Icon(Icons.notifications_none, size: 32),
                onPressed: () {},
              ),
            ],
          ),
        ),
        // Cards
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              // Frequência detalhada
              _buildAttendanceStatsCard(),
              const SizedBox(height: 16),
              // Mensagens
              _InfoCard(
                icon: Icons.mail,
                iconColor: Colors.blue,
                label: 'Mensagens',
                value: '0 mensagens',
              ),
              const SizedBox(height: 16),
              // Agenda de hoje
              _InfoCard(
                icon: Icons.calendar_today,
                iconColor: Colors.deepPurple,
                label: 'Agenda de hoje',
                value: '0 aulas',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Disciplinas',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 28),
                onPressed: _loadSubjects,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: _buildSubjectsContent()),
        ],
      ),
    );
  }

  Widget _buildSubjectsContent() {
    if (_isLoadingSubjects) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_subjectsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _subjectsError!,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSubjects,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma disciplina encontrada',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _subjects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, i) {
        final subject = _subjects[i];
        final teacher = subject['teacher'] as Map<String, dynamic>?;
        final teacherName = teacher?['name'] ?? 'Professor não definido';
        final teacherPhoto = teacher?['photoUrl'] as String?;

        return _SubjectCard(
          data: _SubjectData(
            name: subject['name'] ?? 'Disciplina sem nome',
            teacher: teacherName,
            teacherPhoto: teacherPhoto,
            icon: _getSubjectIcon(subject['type'] ?? ''),
            color: _getSubjectColor(subject['name'] ?? ''),
            iconColor: _getSubjectIconColor(subject['name'] ?? ''),
          ),
        );
      },
    );
  }

  IconData _getSubjectIcon(String type) {
    switch (type) {
      case 'MATEMATICA':
        return Icons.calculate;
      case 'CIENCIAS':
      case 'BIOLOGIA':
      case 'FISICA':
      case 'QUIMICA':
        return Icons.science;
      case 'HISTORIA':
        return Icons.history;
      case 'GEOGRAFIA':
        return Icons.public;
      case 'LINGUA_INGLESA':
        return Icons.language;
      case 'ARTE':
        return Icons.palette;
      case 'EDUCACAO_FISICA':
        return Icons.sports_soccer;
      case 'ENSINO_RELIGIOSO':
        return Icons.church;
      case 'FILOSOFIA':
        return Icons.psychology;
      case 'SOCIOLOGIA':
        return Icons.people;
      case 'CONTEUDO_INTERDISCIPLINAR':
        return Icons.integration_instructions;
      default:
        return Icons.school;
    }
  }

  Color _getSubjectColor(String name) {
    final colors = [
      const Color(0xFFF6DFA7), // Amarelo
      const Color(0xFFE2D7FF), // Roxo
      const Color(0xFFFFD7D7), // Rosa
      const Color(0xFFD7E6FF), // Azul
      const Color(0xFFD7F7E2), // Verde
      const Color(0xFFFFE8D7), // Laranja
      const Color(0xFFE8F7FF), // Azul claro
      const Color(0xFFF7E8FF), // Roxo claro
    ];

    final index = name.hashCode % colors.length;
    return colors[index];
  }

  Color _getSubjectIconColor(String name) {
    final colors = [
      const Color(0xFFD1A13C), // Amarelo escuro
      const Color(0xFF6C4ED6), // Roxo escuro
      const Color(0xFFE05A5A), // Rosa escuro
      const Color(0xFF4E8ED6), // Azul escuro
      const Color(0xFF4ED67A), // Verde escuro
      const Color(0xFFD67A4E), // Laranja escuro
      const Color(0xFF4E8ED6), // Azul escuro
      const Color(0xFF8E4ED6), // Roxo escuro
    ];

    final index = name.hashCode % colors.length;
    return colors[index];
  }

  Widget _buildAttendanceStatsCard() {
    if (_isLoadingStats) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.check_circle, color: Colors.green, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                'Frequência',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
          ],
        ),
      );
    }

    if (_statsError != null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.check_circle, color: Colors.green, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequência',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Erro ao carregar',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh, size: 16, color: Colors.grey[600]),
              onPressed: _loadAttendanceStats,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    final total = _attendanceStats?['total'] as int? ?? 0;
    final present = _attendanceStats?['present'] as int? ?? 0;
    final percentage = _attendanceStats?['percentage'] as int? ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.check_circle, color: Colors.green, size: 28),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  'Frequência',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Total', total.toString(), Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Presente',
                  present.toString(),
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Faltas',
                  (_attendanceStats?['absent'] ?? 0).toString(),
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  // Função para salvar alterações do perfil
  Future<void> _saveProfileChanges(
    String newEmail,
    String? newImagePath,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Usuário não encontrado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Atualizar email se foi alterado
      if (newEmail != user.email) {
        final updatedUser = await UserService.updateUser(user.id, {
          'email': newEmail,
        });
        authProvider.updateUserData(updatedUser);
      }

      // Upload da nova imagem se foi selecionada
      if (newImagePath != null) {
        final photoUrl = await _uploadUserPhoto(user.id, File(newImagePath));

        // Atualizar dados do usuário com a nova foto
        final updatedUser = await UserService.updateUser(user.id, {
          'photoUrl': photoUrl,
        });
        authProvider.updateUserData(updatedUser);

        // Recarregar dados do aluno para atualizar a foto
        await _loadStudentData();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar perfil: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Função para fazer upload da foto do usuário
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
        Uri.parse('http://localhost:3000/users/$userId/photo'),
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
}

class _SubjectData {
  final String name;
  final String teacher;
  final String? teacherPhoto;
  final IconData icon;
  final Color color;
  final Color iconColor;
  _SubjectData({
    required this.name,
    required this.teacher,
    this.teacherPhoto,
    required this.icon,
    required this.color,
    required this.iconColor,
  });
}

class _SubjectCard extends StatelessWidget {
  final _SubjectData data;
  const _SubjectCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (_) => SubjectDetailScreen(
                  name: data.name,
                  teacher: data.teacher,
                  icon: data.icon,
                  color: data.color,
                  iconColor: data.iconColor,
                ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: data.color,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(data.icon, color: data.iconColor, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (data.teacherPhoto != null)
                        Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(right: 6),
                          child: ClipOval(
                            child: Image.network(
                              'http://localhost:3000${data.teacherPhoto!}',
                              width: 20,
                              height: 20,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.grey[600],
                                );
                              },
                            ),
                          ),
                        )
                      else
                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data.teacher,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: iconColor.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final String currentEmail;
  final void Function(String newEmail, String? newImage) onSave;
  const _EditProfileDialog({required this.currentEmail, required this.onSave});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late TextEditingController _emailController;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.currentEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImagePath = result.files.single.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Editar Perfil'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Campo de email
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 16),
          // Upload de imagem
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    _selectedImagePath != null
                        ? FileImage(File(_selectedImagePath!))
                        : null,
                child:
                    _selectedImagePath == null
                        ? const Icon(Icons.person, size: 32, color: Colors.grey)
                        : null,
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload),
                label: const Text('Alterar foto'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_emailController.text, _selectedImagePath);
            Navigator.of(context).pop();
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
