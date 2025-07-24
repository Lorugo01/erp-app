import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/teacher_service.dart';
import 'dart:async';
import 'teacher_class_detail_screen.dart';
import 'teacher_attendance_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _teacherClasses = [];
  List<Map<String, dynamic>> _allStudents = [];
  bool _loadingClasses = false;
  bool _loadingStudents = false;
  String? _errorClasses;
  String? _errorStudents;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchTeacherClasses();
    _searchController.addListener(_onSearchChanged);
    _tabController.addListener(() {
      if (_tabController.index == 1 &&
          _allStudents.isEmpty &&
          _teacherClasses.isNotEmpty) {
        _fetchStudentsFromClasses();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
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
    setState(() {
      _loadingClasses = true;
      _errorClasses = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final teacherId = authProvider.user?.teacher?.id;

      // Debug: verificar dados do usuário
      debugPrint('User ID: ${authProvider.user?.id}');
      debugPrint('Teacher ID: $teacherId');
      debugPrint('User Role: ${authProvider.user?.role}');
      debugPrint('Teacher Data: ${authProvider.user?.teacher?.toJson()}');
      debugPrint('Is Teacher: ${authProvider.user?.isTeacher}');

      if (teacherId == null) {
        throw Exception(
          'Professor não encontrado. Verifique se você está logado como professor.',
        );
      }

      debugPrint(
        'Fazendo requisição para: http://localhost:3000/teachers/$teacherId/classes',
      );
      final classes = await TeacherService.getTeacherClasses(teacherId);
      debugPrint('Classes encontradas: ${classes.length}');
      setState(() {
        _teacherClasses = classes;
      });
    } catch (e) {
      setState(() {
        _errorClasses = e.toString();
      });
    } finally {
      setState(() {
        _loadingClasses = false;
      });
    }
  }

  Future<void> _fetchStudentsFromClasses() async {
    setState(() {
      _loadingStudents = true;
      _errorStudents = null;
    });

    try {
      List<Map<String, dynamic>> allStudents = [];

      for (final classData in _teacherClasses) {
        final classId = classData['id'];
        final students = await TeacherService.getClassStudents(classId);
        allStudents.addAll(students);
      }

      // Remove duplicatas baseado no ID do aluno
      final uniqueStudents = <String, Map<String, dynamic>>{};
      for (final student in allStudents) {
        uniqueStudents[student['id']] = student;
      }

      setState(() {
        _allStudents = uniqueStudents.values.toList();
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

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Row(
        children: [
          // Menu lateral azul
          Container(
            width: 220,
            color: const Color(0xFF2953A5),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Avatar
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 60, color: Color(0xFF2953A5)),
                ),
                const SizedBox(height: 24),
                // Nome do professor
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    authProvider.user?.displayName ?? 'Professor',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  authProvider.user?.email ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
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
                  icon: Icons.how_to_reg,
                  label: 'Chamadas',
                  selected: _tabController.index == 2,
                  onTap: () => setState(() => _tabController.animateTo(2)),
                ),
                const Spacer(),
                const Divider(color: Colors.white54, indent: 16, endIndent: 16),
                _SidebarButton(
                  icon: Icons.help_outline,
                  label: 'Ajuda',
                  selected: false,
                  onTap: () {
                    // TODO: Implementar ajuda
                  },
                ),
                _SidebarButton(
                  icon: Icons.settings,
                  label: 'Configurações',
                  selected: false,
                  onTap: () {
                    // TODO: Implementar configurações
                  },
                ),
                _SidebarButton(
                  icon: Icons.logout,
                  label: 'Sair',
                  selected: false,
                  onTap: () => authProvider.logout(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Área principal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header com título e busca
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _tabController.index == 0
                              ? 'Minhas Turmas'
                              : _tabController.index == 1
                              ? 'Meus Alunos'
                              : 'Chamadas',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2953A5),
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
                                  icon: const Icon(
                                    Icons.search,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => setState(() {}),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          if (_tabController.index == 0) {
                            _fetchTeacherClasses();
                          } else {
                            _fetchStudentsFromClasses();
                          }
                        },
                        tooltip: 'Atualizar',
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
                        const TeacherAttendanceScreen(),
                      ],
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

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.2,
      ),
      itemCount: _teacherClasses.length,
      itemBuilder: (context, index) {
        final classData = _teacherClasses[index];
        return _ClassCard(classData: classData);
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

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 0.85,
      ),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        return _StudentCard(student: student);
      },
    );
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFF2953A5),
                child: Icon(Icons.class_, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                classData['name'] ?? 'Turma',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Ano: ${classData['year'] ?? ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                _getShiftText(classData['shift']),
                style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;

  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFF2953A5),
                      child: Icon(Icons.person, size: 32, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        student['name'] ?? 'Aluno',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (student['registrationNumber'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Matrícula: ${student['registrationNumber']}',
                        ),
                      ),
                    Text('Email: ${student['email'] ?? ''}'),
                    if (student['createdAt'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Criado em: ${DateTime.parse(student['createdAt']).toLocal().toString().split(" ")[0]}',
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFF2953A5),
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                student['name'] ?? 'Aluno',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                student['registrationNumber'] ?? '',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                student['email'] ?? '',
                style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
