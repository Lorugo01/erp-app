import 'package:flutter/material.dart';
import '../../widgets/navigation_bar_widget.dart';
import '../admin/subject_detail_screen.dart';
import 'student_calendar_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  final String name;
  final String registrationNumber;
  final String? profilePictureUrl;
  final int absences;
  final int messages;
  final int todayClasses;

  const StudentDashboardScreen({
    super.key,
    required this.name,
    required this.registrationNumber,
    this.profilePictureUrl,
    this.absences = 0,
    this.messages = 0,
    this.todayClasses = 0,
  });

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _selectedIndex = 0;

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
                  CircleAvatar(
                    radius: 48,
                    backgroundImage:
                        widget.profilePictureUrl != null
                            ? NetworkImage(widget.profilePictureUrl!)
                            : null,
                    child:
                        widget.profilePictureUrl == null
                            ? const Icon(
                              Icons.person,
                              size: 56,
                              color: Colors.grey,
                            )
                            : null,
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
                                  currentEmail: '', // TODO: passar email real
                                  onSave: (newEmail, newImage) {
                                    // TODO: salvar alterações
                                  },
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
                      widget.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Matrícula: ${widget.registrationNumber}',
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
              // Faltas
              _InfoCard(
                icon: Icons.close,
                iconColor: Colors.red,
                label: 'Faltas',
                value: widget.absences.toString(),
              ),
              const SizedBox(height: 16),
              // Mensagens
              _InfoCard(
                icon: Icons.mail,
                iconColor: Colors.blue,
                label: 'Mensagens',
                value: '${widget.messages} mensagens',
              ),
              const SizedBox(height: 16),
              // Agenda de hoje
              _InfoCard(
                icon: Icons.calendar_today,
                iconColor: Colors.deepPurple,
                label: 'Agenda de hoje',
                value:
                    '${widget.todayClasses} aula${widget.todayClasses == 1 ? '' : 's'}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectsTab() {
    final subjects = [
      _SubjectData(
        name: 'Matemática',
        teacher: 'Prof. Ana Souza',
        icon: Icons.calculate,
        color: const Color(0xFFF6DFA7),
        iconColor: const Color(0xFFD1A13C),
      ),
      _SubjectData(
        name: 'Química',
        teacher: 'Prof. Carlos Pereira',
        icon: Icons.science,
        color: const Color(0xFFE2D7FF),
        iconColor: const Color(0xFF6C4ED6),
      ),
      _SubjectData(
        name: 'História',
        teacher: 'Prof. Mariana Ferreira',
        icon: Icons.science,
        color: const Color(0xFFFFD7D7),
        iconColor: const Color(0xFFE05A5A),
      ),
      _SubjectData(
        name: 'Física',
        teacher: 'Prof. Paulo Andrade',
        icon: Icons.bubble_chart,
        color: const Color(0xFFD7E6FF),
        iconColor: const Color(0xFF4E8ED6),
      ),
    ];

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
                icon: const Icon(Icons.notifications_none, size: 28),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: subjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 18),
              itemBuilder: (context, i) => _SubjectCard(data: subjects[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectData {
  final String name;
  final String teacher;
  final IconData icon;
  final Color color;
  final Color iconColor;
  _SubjectData({
    required this.name,
    required this.teacher,
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
            Column(
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
                Text(
                  data.teacher,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
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
  String? _selectedImage;

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
          // Simulação de upload de imagem
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.person, size: 32, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: implementar seleção de imagem
                },
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
            widget.onSave(_emailController.text, _selectedImage);
            Navigator.of(context).pop();
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
