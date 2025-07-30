import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/teacher_service.dart';
import '../../services/student_service.dart' as student_service;
import '../../services/class_service.dart';
import '../../services/user_service.dart';
import '../../models/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'class_detail_screen.dart';
import 'student_detail_screen.dart';
import 'teacher_detail_screen.dart';
import 'user_detail_screen.dart';
import 'grade_management_screen.dart';
import '../../widgets/admin_responsive_navigation.dart';
import '../../widgets/admin_app_bar_menu.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;

  List<Map<String, dynamic>> _teachers = [];
  bool _loadingTeachers = false;
  String? _errorTeachers;

  List<student_service.Student> _students = [];
  bool _loadingStudents = false;
  String? _errorStudents;

  List<Map<String, dynamic>> _classes = [];
  bool _loadingClasses = false;
  String? _errorClasses;

  List<User> _users = [];
  bool _loadingUsers = false;
  String? _errorUsers;

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
    _fetchStudents();
    _fetchClasses();
    _fetchUsers();
  }

  Future<void> _fetchTeachers([String? name]) async {
    setState(() {
      _loadingTeachers = true;
      _errorTeachers = null;
    });
    try {
      final teachers = await TeacherService.getAllTeachers();
      setState(() {
        _teachers = teachers;
      });
    } catch (e) {
      setState(() {
        _errorTeachers = e.toString();
      });
    } finally {
      setState(() {
        _loadingTeachers = false;
      });
    }
  }

  Future<void> _deleteTeacher(Map<String, dynamic> teacher) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:3000/teachers/${teacher['id']}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _teachers.removeWhere((t) => t['id'] == teacher['id']);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Professor excluído com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Erro ao excluir professor');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir professor: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredTeachers {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _teachers;
    return _teachers
        .where(
          (teacher) =>
              (teacher['name'] ?? '').toLowerCase().contains(query) ||
              (teacher['email'] ?? '').toLowerCase().contains(query),
        )
        .toList();
  }

  Future<void> _fetchStudents([String? name]) async {
    setState(() {
      _loadingStudents = true;
      _errorStudents = null;
    });
    try {
      final students = await student_service.StudentService.getAllStudents();
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

  Future<void> _deleteStudent(student_service.Student student) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:3000/students/${student.id}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _students.removeWhere((s) => s.id == student.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aluno excluído com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Erro ao excluir aluno');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir aluno: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<student_service.Student> get _filteredStudents {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _students;
    return _students
        .where(
          (student) =>
              (student.name).toLowerCase().contains(query) ||
              (student.email).toLowerCase().contains(query),
        )
        .toList();
  }

  Future<void> _fetchClasses() async {
    setState(() {
      _loadingClasses = true;
      _errorClasses = null;
    });
    try {
      final classes = await ClassService.getAllClasses();
      setState(() {
        _classes = classes;
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

  Future<void> _deleteClass(Map<String, dynamic> turma) async {
    try {
      await ClassService.deleteClass(turma['id']);
      setState(() {
        _classes.removeWhere((c) => c['id'] == turma['id']);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Turma excluída com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir turma: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _loadingUsers = true;
      _errorUsers = null;
    });
    try {
      final users = await UserService.getAllUsers();
      setState(() {
        _users = users;
      });
    } catch (e) {
      setState(() {
        _errorUsers = e.toString();
      });
    } finally {
      setState(() {
        _loadingUsers = false;
      });
    }
  }

  Future<void> _deleteUser(User user) async {
    try {
      await UserService.deleteUser(user.id);
      setState(() {
        _users.removeWhere((u) => u.id == user.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir usuário: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<User> get _filteredUsers {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _users;
    return _users
        .where(
          (user) =>
              user.displayName.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query) ||
              user.role
                  .toString()
                  .split('.')
                  .last
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
  }

  List<Map<String, dynamic>> get _filteredClasses {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _classes;
    return _classes
        .where(
          (c) =>
              (c['name'] ?? '').toLowerCase().contains(query) ||
              (c['letter'] ?? '').toLowerCase().contains(query) ||
              (c['shift'] ?? '').toLowerCase().contains(query) ||
              (c['academicYear']?.toString() ?? '').contains(query),
        )
        .toList();
  }

  void _showAddTeacherDialog() {
    showDialog(
      context: context,
      builder:
          (context) => _AddTeacherDialog(
            onAdd: (name, email, password) async {
              setState(() {
                _loadingTeachers = true;
                _errorTeachers = null;
              });
              try {
                final response = await http.post(
                  Uri.parse('http://localhost:3000/teachers'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'name': name,
                    'email': email,
                    'password': password,
                  }),
                );
                if (!context.mounted) return;
                if (response.statusCode == 201 || response.statusCode == 200) {
                  final newTeacher = jsonDecode(response.body);
                  setState(() {
                    _teachers.add(newTeacher);
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Professor cadastrado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  throw Exception('Erro ao cadastrar professor');
                }
              } catch (e) {
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Erro ao cadastrar professor: ${e.toString()}',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                setState(() {
                  _loadingTeachers = false;
                });
              }
            },
          ),
    );
  }

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder:
          (context) => _AddStudentDialog(
            onAdd: (name, email, registrationNumber, password) async {
              setState(() {
                _loadingStudents = true;
                _errorStudents = null;
              });
              try {
                final response = await http.post(
                  Uri.parse('http://localhost:3000/students'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'name': name,
                    'email': email,
                    'registrationNumber': registrationNumber,
                    'password': password,
                  }),
                );
                if (!context.mounted) return;
                if (response.statusCode == 201 || response.statusCode == 200) {
                  final newStudent = jsonDecode(response.body);
                  setState(() {
                    _students.add(
                      student_service.Student(
                        id: newStudent['id'] ?? '',
                        name: newStudent['name'] ?? name,
                        email: newStudent['email'] ?? email,
                        registrationNumber:
                            newStudent['registrationNumber'] ??
                            registrationNumber,
                        subjects: [],
                        createdAt: null,
                        role: null,
                      ),
                    );
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Aluno cadastrado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  throw Exception('Erro ao cadastrar aluno');
                }
              } catch (e) {
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao cadastrar aluno: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                setState(() {
                  _loadingStudents = false;
                });
              }
            },
          ),
    );
  }

  void _showAddClassDialog() {
    showDialog(
      context: context,
      builder:
          (context) => _AddClassDialog(
            onAdd: (grade, letter, academicYear, shift, evaluationModel) async {
              setState(() {
                _loadingClasses = true;
                _errorClasses = null;
              });
              try {
                final response = await http.post(
                  Uri.parse('http://localhost:3000/classes'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'grade': grade,
                    'letter': letter,
                    'academicYear': academicYear,
                    'shift': shift,
                    'evaluationModel': evaluationModel,
                  }),
                );
                if (!context.mounted) return;
                if (response.statusCode == 201 || response.statusCode == 200) {
                  final newClass = jsonDecode(response.body);
                  setState(() {
                    _classes.add(newClass);
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Turma cadastrada com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  throw Exception('Erro ao cadastrar turma');
                }
              } catch (e) {
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao cadastrar turma: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                setState(() {
                  _loadingClasses = false;
                });
              }
            },
          ),
    );
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder:
          (context) => _AddUserDialog(
            onAdd: (name, email, password, role) async {
              setState(() {
                _loadingUsers = true;
                _errorUsers = null;
              });
              try {
                final user = await UserService.createUser(
                  name: name,
                  email: email,
                  password: password,
                  role: role,
                );
                setState(() {
                  _users.add(user);
                });
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usuário cadastrado com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao cadastrar usuário: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                setState(() {
                  _loadingUsers = false;
                });
              }
            },
          ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedIndex) {
      case 0:
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isSmall = screenWidth < 600;

            // Calcular número de colunas baseado no tamanho da tela
            int crossAxisCount;
            if (screenWidth > 1200) {
              crossAxisCount = 4;
            } else if (screenWidth > 800) {
              crossAxisCount = 3;
            } else if (screenWidth > 600) {
              crossAxisCount = 2;
            } else {
              crossAxisCount = 1;
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Painel Geral',
                    style: TextStyle(
                      fontSize: isSmall ? 20 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isSmall ? 16 : 24),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: isSmall ? 12 : 16,
                    mainAxisSpacing: isSmall ? 12 : 16,
                    childAspectRatio: isSmall ? 1.2 : 1.4,
                    children: [
                      _DashboardInfoCard(
                        title: 'Usuários',
                        value: _users.length,
                        icon: Icons.people,
                        color: Colors.blue,
                        isSmall: isSmall,
                      ),
                      _DashboardInfoCard(
                        title: 'Professores',
                        value: _teachers.length,
                        icon: Icons.school,
                        color: Colors.orange,
                        isSmall: isSmall,
                      ),
                      _DashboardInfoCard(
                        title: 'Alunos',
                        value: _students.length,
                        icon: Icons.person,
                        color: Colors.green,
                        isSmall: isSmall,
                      ),
                      _DashboardInfoCard(
                        title: 'Turmas',
                        value: _classes.length,
                        icon: Icons.class_,
                        color: Colors.purple,
                        isSmall: isSmall,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar usuário...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchUsers,
                  tooltip: 'Atualizar',
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_loadingUsers)
              const Center(child: CircularProgressIndicator())
            else if (_errorUsers != null)
              Center(
                child: Text(
                  _errorUsers!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else
              Expanded(
                child:
                    _filteredUsers.isEmpty
                        ? const Center(
                          child: Text('Nenhum usuário encontrado.'),
                        )
                        : GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: getCrossAxisCount(context),
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                                childAspectRatio: 0.85,
                              ),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return _UserCardGrid(
                              user: user,
                              onDelete: () => _deleteUser(user),
                            );
                          },
                        ),
              ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar professor...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchTeachers,
                  tooltip: 'Atualizar',
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_loadingTeachers)
              const Center(child: CircularProgressIndicator())
            else if (_errorTeachers != null)
              Center(
                child: Text(
                  _errorTeachers!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else
              Expanded(
                child:
                    _filteredTeachers.isEmpty
                        ? const Center(
                          child: Text('Nenhum professor encontrado.'),
                        )
                        : GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: getCrossAxisCount(context),
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                                childAspectRatio: 0.85,
                              ),
                          itemCount: _filteredTeachers.length,
                          itemBuilder: (context, index) {
                            final teacher = _filteredTeachers[index];
                            return _TeacherCardGrid(
                              teacher: teacher,
                              onDelete: () => _deleteTeacher(teacher),
                            );
                          },
                        ),
              ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar aluno...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchStudents,
                  tooltip: 'Atualizar',
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_loadingStudents)
              const Center(child: CircularProgressIndicator())
            else if (_errorStudents != null)
              Center(
                child: Text(
                  _errorStudents!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else
              Expanded(
                child:
                    _filteredStudents.isEmpty
                        ? const Center(child: Text('Nenhum aluno encontrado.'))
                        : GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: getCrossAxisCount(context),
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                                childAspectRatio: 0.85,
                              ),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            return _StudentCardGrid(
                              student: student,
                              onDelete: () => _deleteStudent(student),
                            );
                          },
                        ),
              ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar turma...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchClasses,
                  tooltip: 'Atualizar',
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_loadingClasses)
              const Center(child: CircularProgressIndicator())
            else if (_errorClasses != null)
              Center(
                child: Text(
                  _errorClasses!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else
              Expanded(
                child:
                    _filteredClasses.isEmpty
                        ? const Center(child: Text('Nenhuma turma encontrada.'))
                        : GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: getCrossAxisCount(context),
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                                childAspectRatio: 0.85,
                              ),
                          itemCount: _filteredClasses.length,
                          itemBuilder: (context, index) {
                            final turma = _filteredClasses[index];
                            return _ClassCardGrid(
                              classData: turma,
                              onDelete: () => _deleteClass(turma),
                            );
                          },
                        ),
              ),
          ],
        );
      case 5:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.computer, size: 80, color: Color(0xFF2953A5)),
              SizedBox(height: 24),
              Text(
                'Gestão de Equipamentos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2953A5),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Funcionalidade em desenvolvimento',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Aqui você poderá gerenciar:\n• Inventário de equipamentos\n• Manutenções\n• Empréstimos\n• Relatórios de uso',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      case 6:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Relatórios do Sistema',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _ReportSection(
                title: 'Relatórios Acadêmicos',
                icon: Icons.school,
                reports: [
                  _ReportCard(
                    title: 'Boletim por Turma',
                    description: 'Média geral e desempenho por turma',
                    icon: Icons.assessment,
                    color: Colors.blue,
                    onTap:
                        () => _showReportDialog(context, 'Boletim por Turma'),
                  ),
                  _ReportCard(
                    title: 'Ranking de Alunos',
                    description: 'Melhores e piores desempenhos',
                    icon: Icons.leaderboard,
                    color: Colors.green,
                    onTap:
                        () => _showReportDialog(context, 'Ranking de Alunos'),
                  ),
                  _ReportCard(
                    title: 'Frequência Escolar',
                    description: 'Percentual de presença por aluno',
                    icon: Icons.calendar_today,
                    color: Colors.orange,
                    onTap:
                        () => _showReportDialog(context, 'Frequência Escolar'),
                  ),
                  _ReportCard(
                    title: 'Análise por Disciplina',
                    description: 'Desempenho por matéria',
                    icon: Icons.subject,
                    color: Colors.purple,
                    onTap:
                        () => _showReportDialog(
                          context,
                          'Análise por Disciplina',
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ReportSection(
                title: 'Relatórios Administrativos',
                icon: Icons.admin_panel_settings,
                reports: [
                  _ReportCard(
                    title: 'Matrículas por Período',
                    description: 'Evolução de matrículas ao longo do ano',
                    icon: Icons.person_add,
                    color: Colors.teal,
                    onTap:
                        () => _showReportDialog(
                          context,
                          'Matrículas por Período',
                        ),
                  ),
                  _ReportCard(
                    title: 'Carga Horária dos Professores',
                    description: 'Distribuição de aulas por professor',
                    icon: Icons.schedule,
                    color: Colors.indigo,
                    onTap:
                        () => _showReportDialog(
                          context,
                          'Carga Horária dos Professores',
                        ),
                  ),
                  _ReportCard(
                    title: 'Capacidade das Turmas',
                    description: 'Ocupação vs. capacidade máxima',
                    icon: Icons.group,
                    color: Colors.amber,
                    onTap:
                        () =>
                            _showReportDialog(context, 'Capacidade das Turmas'),
                  ),
                  _ReportCard(
                    title: 'Taxa de Evasão',
                    description: 'Alunos que saíram durante o ano',
                    icon: Icons.trending_down,
                    color: Colors.red,
                    onTap: () => _showReportDialog(context, 'Taxa de Evasão'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ReportSection(
                title: 'Relatórios Estratégicos',
                icon: Icons.trending_up,
                reports: [
                  _ReportCard(
                    title: 'Crescimento da Escola',
                    description: 'Evolução do número de alunos',
                    icon: Icons.show_chart,
                    color: Colors.green,
                    onTap:
                        () =>
                            _showReportDialog(context, 'Crescimento da Escola'),
                  ),
                  _ReportCard(
                    title: 'Distribuição por Turno',
                    description: 'Quantos alunos em cada turno',
                    icon: Icons.access_time,
                    color: Colors.blue,
                    onTap:
                        () => _showReportDialog(
                          context,
                          'Distribuição por Turno',
                        ),
                  ),
                  _ReportCard(
                    title: 'Performance por Turma',
                    description: 'Comparativo entre turmas',
                    icon: Icons.compare_arrows,
                    color: Colors.purple,
                    onTap:
                        () =>
                            _showReportDialog(context, 'Performance por Turma'),
                  ),
                ],
              ),
            ],
          ),
        );
      case 7:
        return const GradeManagementScreen();
      case 8:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configurações do Sistema',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _ConfigurationSection(
                title: 'Configurações Gerais',
                icon: Icons.settings,
                children: [
                  _ConfigItem(
                    label: 'Ano Letivo Atual',
                    value: '2024',
                    onTap: () => _showYearDialog(context),
                  ),
                  _ConfigItem(
                    label: 'Período de Matrículas',
                    value: '01/12/2024 - 31/01/2025',
                    onTap: () => _showEnrollmentPeriodDialog(context),
                  ),
                  _ConfigItem(
                    label: 'Horário de Funcionamento',
                    value: '07:00 - 18:00',
                    onTap: () => _showWorkingHoursDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ConfigurationSection(
                title: 'Sistema de Notas',
                icon: Icons.grade,
                children: [
                  _ConfigItem(
                    label: 'Tipo de Avaliação',
                    value: 'Numérico (0-10)',
                    onTap: () => _showGradeSystemDialog(context),
                  ),
                  _ConfigItem(
                    label: 'Média para Aprovação',
                    value: '7.0',
                    onTap: () => _showApprovalGradeDialog(context),
                  ),
                  _ConfigItem(
                    label: 'Períodos de Avaliação',
                    value: '4 Bimestres',
                    onTap: () => _showEvaluationPeriodsDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ConfigurationSection(
                title: 'Configurações de Turmas',
                icon: Icons.class_,
                children: [
                  _ConfigItem(
                    label: 'Capacidade Máxima',
                    value: '35 alunos',
                    onTap: () => _showClassCapacityDialog(context),
                  ),
                  _ConfigItem(
                    label: 'Carga Horária Semanal',
                    value: '25 horas',
                    onTap: () => _showWeeklyHoursDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ConfigurationSection(
                title: 'Configurações de Usuários',
                icon: Icons.people,
                children: [
                  _ConfigItem(
                    label: 'Tamanho Mínimo de Senha',
                    value: '6 caracteres',
                    onTap: () => _showPasswordPolicyDialog(context),
                  ),
                  _ConfigItem(
                    label: 'Tempo de Sessão',
                    value: '8 horas',
                    onTap: () => _showSessionTimeoutDialog(context),
                  ),
                ],
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar:
          isWide
              ? null
              : AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                title: const Text(
                  'Painel Administrativo',
                  style: TextStyle(
                    color: Color(0xFF2953A5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  AdminAppBarMenu(
                    onConfig: () => setState(() => _selectedIndex = 8),
                    onLogout: () => authProvider.logout(),
                  ),
                ],
                iconTheme: const IconThemeData(color: Color(0xFF2953A5)),
              ),
      body:
          isWide
              ? Row(
                children: [
                  AdminResponsiveNavigation(
                    selectedIndex: _selectedIndex,
                    onSelect: (index) {
                      if (index == 8) {
                        authProvider.logout();
                      } else {
                        setState(() => _selectedIndex = index);
                      }
                    },
                    onLogout: () => authProvider.logout(),
                    isWide: true,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: _buildTabContent(),
                    ),
                  ),
                ],
              )
              : Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildTabContent(),
                    ),
                  ),
                ],
              ),
      bottomNavigationBar:
          isWide
              ? null
              : AdminResponsiveNavigation(
                selectedIndex: _selectedIndex,
                onSelect: (index) {
                  setState(() => _selectedIndex = index);
                },
                onLogout: () => authProvider.logout(),
                isWide: false,
              ),
      floatingActionButton:
          (_selectedIndex == 1 ||
                  _selectedIndex == 2 ||
                  _selectedIndex == 3 ||
                  _selectedIndex == 4 ||
                  _selectedIndex == 5)
              ? Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.width < 600 ? 80 : 24,
                  right: 24,
                ),
                child: FloatingActionButton(
                  backgroundColor: Colors.yellow[700],
                  onPressed: () {
                    if (_selectedIndex == 1) {
                      _showAddUserDialog();
                    } else if (_selectedIndex == 2) {
                      _showAddTeacherDialog();
                    } else if (_selectedIndex == 3) {
                      _showAddStudentDialog();
                    } else if (_selectedIndex == 4) {
                      _showAddClassDialog();
                    } else if (_selectedIndex == 5) {
                      // Funcionalidade de equipamentos em desenvolvimento
                    }
                  },
                  child: const Icon(Icons.add, size: 36, color: Colors.white),
                ),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2953A5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 40, color: Color(0xFF2953A5)),
          ),
          const SizedBox(height: 16),
          Text(
            user['name'] ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user['id'] ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            user['role'] ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            user['email'] ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AddTeacherDialog extends StatefulWidget {
  final void Function(String name, String email, String password) onAdd;
  const _AddTeacherDialog({required this.onAdd});

  @override
  State<_AddTeacherDialog> createState() => _AddTeacherDialogState();
}

class _AddTeacherDialogState extends State<_AddTeacherDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Cadastrar Professor'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nome'),
              validator:
                  (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
              onSaved: (v) => _name = (v ?? '').trim(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator:
                  (v) => v == null || v.isEmpty ? 'Informe o email' : null,
              onSaved: (v) => _email = (v ?? '').trim(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Senha',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed:
                      () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
              validator:
                  (v) =>
                      v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
              onSaved: (v) => _password = v ?? '',
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              if (_name.isNotEmpty &&
                  _email.isNotEmpty &&
                  _password.isNotEmpty) {
                widget.onAdd(_name, _email, _password);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preencha todos os campos corretamente!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Cadastrar'),
        ),
      ],
    );
  }
}

class _AddStudentDialog extends StatefulWidget {
  final void Function(
    String name,
    String email,
    String registrationNumber,
    String password,
  )
  onAdd;
  const _AddStudentDialog({required this.onAdd});

  @override
  State<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _registrationNumber = '';
  String _password = '';
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Cadastrar Aluno'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nome'),
              validator:
                  (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
              onSaved: (v) => _name = (v ?? '').trim(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator:
                  (v) => v == null || v.isEmpty ? 'Informe o email' : null,
              onSaved: (v) => _email = (v ?? '').trim(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Matrícula'),
              validator:
                  (v) => v == null || v.isEmpty ? 'Informe a matrícula' : null,
              onSaved: (v) => _registrationNumber = (v ?? '').trim(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Senha',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed:
                      () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
              validator:
                  (v) =>
                      v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
              onSaved: (v) => _password = v ?? '',
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              if (_name.isNotEmpty &&
                  _email.isNotEmpty &&
                  _registrationNumber.isNotEmpty &&
                  _password.isNotEmpty) {
                widget.onAdd(_name, _email, _registrationNumber, _password);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preencha todos os campos corretamente!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Cadastrar'),
        ),
      ],
    );
  }
}

class _TeacherCardGrid extends StatelessWidget {
  final Map<String, dynamic> teacher;
  final VoidCallback? onDelete;

  const _TeacherCardGrid({required this.teacher, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TeacherDetailScreen(teacher: teacher),
          ),
        );
      },
      onLongPress: () => _showOptionsMenu(context),
      child: Container(
        constraints: BoxConstraints(
          minHeight: isSmall ? 150 : 200,
          maxHeight: isSmall ? 220 : 300,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF2953A5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(isSmall ? 12 : 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(child: SizedBox()),
                CircleAvatar(
                  radius: isSmall ? 24 : 32,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      teacher['photoUrl'] != null
                          ? NetworkImage(
                            'http://localhost:3000${teacher['photoUrl']}',
                          )
                          : null,
                  child:
                      teacher['photoUrl'] == null
                          ? Icon(
                            Icons.person,
                            size: isSmall ? 28 : 40,
                            color: const Color(0xFF2953A5),
                          )
                          : null,
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteConfirmation(context);
                        }
                      },
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Excluir'),
                                ],
                              ),
                            ),
                          ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmall ? 8 : 16),
            Text(
              teacher['name'] ?? '',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isSmall ? 15 : 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              teacher['email'] ?? '',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmall ? 12 : 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: const Text('Ver Detalhes'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TeacherDetailScreen(teacher: teacher),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Excluir Professor'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Tem certeza que deseja excluir o professor "${teacher['name']}"?\n\n'
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
                onDelete?.call();
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
}

class _StudentCardGrid extends StatelessWidget {
  final student_service.Student student;
  final VoidCallback? onDelete;

  const _StudentCardGrid({required this.student, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StudentDetailScreen(student: student),
          ),
        );
      },
      onLongPress: () => _showOptionsMenu(context),
      child: Container(
        constraints: BoxConstraints(
          minHeight: isSmall ? 150 : 200,
          maxHeight: isSmall ? 220 : 300,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF2953A5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(isSmall ? 12 : 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(child: SizedBox()),
                CircleAvatar(
                  radius: isSmall ? 24 : 32,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      student.profilePicture != null
                          ? NetworkImage(
                            'http://localhost:3000${student.profilePicture}',
                          )
                          : null,
                  child:
                      student.profilePicture == null
                          ? Icon(
                            Icons.person,
                            size: isSmall ? 28 : 40,
                            color: const Color(0xFF2953A5),
                          )
                          : null,
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteConfirmation(context);
                        }
                      },
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Excluir'),
                                ],
                              ),
                            ),
                          ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmall ? 8 : 16),
            Text(
              student.name,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isSmall ? 15 : 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              student.email,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmall ? 12 : 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (student.registrationNumber != null)
              Text(
                'Matrícula: ${student.registrationNumber}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmall ? 10 : 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: const Text('Ver Detalhes'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StudentDetailScreen(student: student),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Excluir Aluno'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Tem certeza que deseja excluir o aluno "${student.name}"?\n\n'
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
                onDelete?.call();
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
}

class _UserCardGrid extends StatelessWidget {
  final User user;
  final VoidCallback? onDelete;

  const _UserCardGrid({required this.user, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;
    final isVerySmall = MediaQuery.of(context).size.width < 400;
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => UserDetailScreen(user: user)));
      },
      onLongPress: () => _showOptionsMenu(context),
      child: Container(
        constraints: BoxConstraints(
          minHeight:
              isVerySmall
                  ? 120
                  : isSmall
                  ? 140
                  : 180,
          maxHeight:
              isVerySmall
                  ? 150
                  : isSmall
                  ? 180
                  : 240,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF2953A5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(
          isVerySmall
              ? 6
              : isSmall
              ? 8
              : 16,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(child: SizedBox()),
                CircleAvatar(
                  radius:
                      isVerySmall
                          ? 16
                          : isSmall
                          ? 18
                          : 24,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      user.photoUrl != null
                          ? NetworkImage(
                            user.photoUrl!.startsWith('http')
                                ? user.photoUrl!
                                : 'http://localhost:3000${user.photoUrl}',
                          )
                          : null,
                  child:
                      user.photoUrl == null
                          ? Icon(
                            Icons.person,
                            size:
                                isVerySmall
                                    ? 16
                                    : isSmall
                                    ? 18
                                    : 24,
                            color: const Color(0xFF2953A5),
                          )
                          : null,
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteConfirmation(context);
                        }
                      },
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Excluir'),
                                ],
                              ),
                            ),
                          ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height:
                  isVerySmall
                      ? 6
                      : isSmall
                      ? 8
                      : 16,
            ),
            Text(
              user.displayName,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize:
                    isVerySmall
                        ? 10
                        : isSmall
                        ? 12
                        : 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: TextStyle(
                color: Colors.white,
                fontSize:
                    isVerySmall
                        ? 9
                        : isSmall
                        ? 10
                        : 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getRoleText(user.role),
                style: TextStyle(
                  color: Colors.white,
                  fontSize:
                      isVerySmall
                          ? 8
                          : isSmall
                          ? 9
                          : 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(Role role) {
    switch (role) {
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
      case Role.admin:
        return 'ADMIN';
      case Role.teacher:
        return 'PROFESSOR';
      case Role.student:
        return 'ALUNO';
    }
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Excluir Usuário'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Tem certeza que deseja excluir o usuário "${user.displayName}"?\n\n'
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
                onDelete?.call();
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
}

class _ClassCardGrid extends StatelessWidget {
  final Map<String, dynamic> classData;
  final VoidCallback? onDelete;
  const _ClassCardGrid({required this.classData, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClassDetailScreen(classData: classData),
          ),
        );
      },
      child: Container(
        constraints: BoxConstraints(
          minHeight: isSmall ? 150 : 200,
          maxHeight: isSmall ? 220 : 300,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF2953A5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(isSmall ? 12 : 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: isSmall ? 24 : 32,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.class_,
                    size: isSmall ? 28 : 40,
                    color: const Color(0xFF2953A5),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmation(context);
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Excluir'),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
            SizedBox(height: isSmall ? 8 : 16),
            Text(
              classData['name'] ?? '',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isSmall ? 15 : 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Ano: ${classData['academicYear'] ?? ''}',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmall ? 12 : 14,
              ),
            ),
            Text(
              'Série: ${classData['grade'] ?? ''}${classData['letter'] ?? ''}',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmall ? 12 : 14,
              ),
            ),
            Text(
              'Turno: ${classData['shift'] ?? ''}',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmall ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Tem certeza que deseja excluir a turma "${classData['name']}"?\n\n'
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
                onDelete?.call();
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
}

class _AddClassDialog extends StatefulWidget {
  final void Function(
    int grade,
    String letter,
    int academicYear,
    String shift,
    String evaluationModel,
  )
  onAdd;
  const _AddClassDialog({required this.onAdd});

  @override
  State<_AddClassDialog> createState() => _AddClassDialogState();
}

class _AddClassDialogState extends State<_AddClassDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _grade;
  String _letter = '';
  int? _academicYear;
  String? _shift;
  String? _evaluationModel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Cadastrar Turma'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Série (número)'),
              keyboardType: TextInputType.number,
              validator:
                  (v) => v == null || v.isEmpty ? 'Informe a série' : null,
              onSaved: (v) => _grade = int.tryParse(v ?? '') ?? 0,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Letra'),
              validator:
                  (v) => v == null || v.isEmpty ? 'Informe a letra' : null,
              onSaved: (v) => _letter = (v ?? '').trim().toUpperCase(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Ano letivo'),
              keyboardType: TextInputType.number,
              validator:
                  (v) => v == null || v.isEmpty ? 'Informe o ano letivo' : null,
              onSaved: (v) => _academicYear = int.tryParse(v ?? '') ?? 0,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Turno'),
              items: const [
                DropdownMenuItem(value: 'MATUTINO', child: Text('Matutino')),
                DropdownMenuItem(
                  value: 'VESPERTINO',
                  child: Text('Vespertino'),
                ),
                DropdownMenuItem(value: 'NOTURNO', child: Text('Noturno')),
                DropdownMenuItem(value: 'INTEGRAL', child: Text('Integral')),
              ],
              validator:
                  (v) => v == null || v.isEmpty ? 'Selecione o turno' : null,
              onChanged: (v) => setState(() => _shift = v),
              onSaved: (v) => _shift = v ?? 'MATUTINO',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Metodologia do Boletim',
              ),
              value: _evaluationModel,
              items: const [
                DropdownMenuItem(value: 'NUMERIC', child: Text('Numérica')),
                DropdownMenuItem(value: 'CONCEPT', child: Text('Conceito')),
                DropdownMenuItem(value: 'HYBRID', child: Text('Híbrido')),
              ],
              validator: (v) => v == null ? 'Selecione a metodologia' : null,
              onChanged: (v) => setState(() => _evaluationModel = v),
              onSaved: (v) => _evaluationModel = v,
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              // Verificar se todos os campos estão preenchidos antes de chamar onAdd
              if (_grade != null &&
                  _letter.isNotEmpty &&
                  _academicYear != null &&
                  _shift != null &&
                  _evaluationModel != null) {
                widget.onAdd(
                  _grade!,
                  _letter,
                  _academicYear!,
                  _shift!,
                  _evaluationModel!,
                );
              } else {
                // Mostrar erro para o usuário
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preencha todos os campos corretamente!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Cadastrar'),
        ),
      ],
    );
  }
}

int getCrossAxisCount(BuildContext context) {
  double width = MediaQuery.of(context).size.width;
  if (width > 1400) return 5;
  if (width > 1100) return 4;
  if (width > 800) return 3;
  return 2; // Nunca retorna 1, sempre pelo menos 2 colunas
}

class _DashboardInfoCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final bool isSmall;

  const _DashboardInfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFF7F7FB),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isSmall ? 12 : 16,
          horizontal: isSmall ? 8 : 12,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: isSmall ? 28 : 36),
            SizedBox(height: isSmall ? 6 : 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: isSmall ? 22 : 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: isSmall ? 6 : 8),
            Text(
              title,
              style: TextStyle(
                fontSize: isSmall ? 14 : 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigurationSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ConfigurationSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ConfigItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ConfigItem({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.edit, size: 20, color: Color(0xFF2953A5)),
          ],
        ),
      ),
    );
  }
}

// Métodos para os diálogos de configuração
void _showYearDialog(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Ano Letivo'),
          content: const Text('Funcionalidade em desenvolvimento...'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
  );
}

void _showEnrollmentPeriodDialog(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Período de Matrículas'),
          content: const Text('Funcionalidade em desenvolvimento...'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
  );
}

void _showWorkingHoursDialog(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Horário de Funcionamento'),
          content: const Text('Funcionalidade em desenvolvimento...'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
  );
}

void _showGradeSystemDialog(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Sistema de Notas'),
          content: const Text('Funcionalidade em desenvolvimento...'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
  );
}

void _showApprovalGradeDialog(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Média para Aprovação'),
          content: const Text('Funcionalidade em desenvolvimento...'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
  );
}

void _showEvaluationPeriodsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Períodos de Avaliação'),
          content: const Text('Funcionalidade em desenvolvimento...'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
  );
}

void _showClassCapacityDialog(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Capacidade Máxima'),
          content: const Text('Funcionalidade em desenvolvimento...'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
  );
}

void _showWeeklyHoursDialog(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Carga Horária Semanal'),
          content: const Text('Funcionalidade em desenvolvimento...'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
  );
}

void _showPasswordPolicyDialog(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Política de Senhas'),
          content: const Text('Funcionalidade em desenvolvimento...'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
  );
}

void _showSessionTimeoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Tempo de Sessão'),
          content: const Text('Funcionalidade em desenvolvimento...'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
  );
}

class _ReportSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> reports;

  const _ReportSection({
    required this.title,
    required this.icon,
    required this.reports,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            const SizedBox(height: 16),
            Wrap(spacing: 12, runSpacing: 12, children: reports),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ReportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

void _showReportDialog(BuildContext context, String reportTitle) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(reportTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filtros disponíveis:'),
              const SizedBox(height: 8),
              const Text('• Período (mês/ano)'),
              const Text('• Turma específica'),
              const Text('• Professor'),
              const Text('• Disciplina'),
              const SizedBox(height: 16),
              const Text('Formatos de exportação:'),
              const SizedBox(height: 8),
              const Text('• PDF'),
              const Text('• Excel'),
              const Text('• CSV'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Relatório "$reportTitle" será gerado...'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Gerar Relatório'),
            ),
          ],
        ),
  );
}

class _AddUserDialog extends StatefulWidget {
  final void Function(String name, String email, String password, Role role)
  onAdd;
  const _AddUserDialog({required this.onAdd});

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  Role _selectedRole = Role.student;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Cadastrar Usuário'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nome'),
              validator:
                  (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
              onSaved: (v) => _name = (v ?? '').trim(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator:
                  (v) => v == null || v.isEmpty ? 'Informe o email' : null,
              onSaved: (v) => _email = (v ?? '').trim(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Senha',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed:
                      () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
              validator:
                  (v) =>
                      v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
              onSaved: (v) => _password = v ?? '',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Role>(
              decoration: const InputDecoration(labelText: 'Tipo de Usuário'),
              value: _selectedRole,
              items:
                  Role.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(_getRoleDisplayName(role)),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRole = value);
                }
              },
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              if (_name.isNotEmpty &&
                  _email.isNotEmpty &&
                  _password.isNotEmpty) {
                widget.onAdd(_name, _email, _password, _selectedRole);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preencha todos os campos corretamente!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Cadastrar'),
        ),
      ],
    );
  }

  String _getRoleDisplayName(Role role) {
    switch (role) {
      case Role.admin:
        return 'Administrador';
      case Role.teacher:
        return 'Professor';
      case Role.student:
        return 'Aluno';
    }
  }
}
