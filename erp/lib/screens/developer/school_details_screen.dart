import 'package:flutter/material.dart';
import '../../models/school.dart';
import '../../models/user.dart';
import '../../services/school_service.dart';
import '../../services/auth_service.dart';

class SchoolDetailsScreen extends StatefulWidget {
  final School school;

  const SchoolDetailsScreen({super.key, required this.school});

  @override
  State<SchoolDetailsScreen> createState() => _SchoolDetailsScreenState();
}

class _SchoolDetailsScreenState extends State<SchoolDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? schoolStats;
  bool isLoadingStats = false;
  late School _currentSchool;

  @override
  void initState() {
    super.initState();
    _currentSchool = widget.school;
    _tabController = TabController(length: 4, vsync: this);
    _loadSchoolStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSchoolStats() async {
    setState(() {
      isLoadingStats = true;
    });

    try {
      final stats = await SchoolService.getSchoolStats(_currentSchool.id);
      setState(() {
        schoolStats = stats;
        isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        isLoadingStats = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar estatísticas: \${userErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentSchool.name} - Detalhes'),
        backgroundColor: const Color(0xFF2953A5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showCreateUserDialog(context),
            tooltip: 'Criar Usuário',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditSchoolDialog(context),
            tooltip: 'Editar Escola',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSchoolStats,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header da escola
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2953A5).withAlpha(50),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF2953A5),
                  child: Text(
                    _currentSchool.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _currentSchool.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_currentSchool.address != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _currentSchool.address!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (_currentSchool.phone != null)
                      _buildContactInfo(
                        Icons.phone,
                        'Telefone',
                        _currentSchool.phone!,
                      ),
                    if (_currentSchool.email != null)
                      _buildContactInfo(
                        Icons.email,
                        'Email',
                        _currentSchool.email!,
                      ),
                    if (_currentSchool.website != null)
                      _buildContactInfo(
                        Icons.language,
                        'Website',
                        _currentSchool.website!,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Tabs de navegação
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              indicator: BoxDecoration(
                color: const Color(0xFF2953A5),
                borderRadius: BorderRadius.circular(10),
              ),
              tabs: const [
                Tab(text: 'Visão Geral'),
                Tab(text: 'Usuários'),
                Tab(text: 'Turmas'),
                Tab(text: 'Atividades'),
              ],
            ),
          ),

          // Conteúdo das tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildClassesTab(),
                _buildActivitiesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2953A5), size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    if (isLoadingStats) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2953A5)),
      );
    }

    if (schoolStats == null) {
      return const Center(child: Text('Erro ao carregar estatísticas'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Informações da Escola',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2953A5),
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showCreateUserDialog(context),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Criar Usuário'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showEditSchoolDialog(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar Escola'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2953A5),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildOverviewSection('Informações da Escola', [
            _buildInfoRow('Nome', _currentSchool.name),
            if (_currentSchool.address != null)
              _buildInfoRow('Endereço', _currentSchool.address!),
            if (_currentSchool.phone != null)
              _buildInfoRow('Telefone', _currentSchool.phone!),
            if (_currentSchool.email != null)
              _buildInfoRow('Email', _currentSchool.email!),
            if (_currentSchool.website != null)
              _buildInfoRow('Website', _currentSchool.website!),
            _buildInfoRow('Criada em', _formatDate(_currentSchool.createdAt)),
            _buildInfoRow(
              'Última atualização',
              _formatDate(_currentSchool.updatedAt),
            ),
            _buildInfoRow(
              'Status',
              _currentSchool.isActive ? 'Ativa' : 'Inativa',
            ),
          ]),
          const SizedBox(height: 20),
          _buildOverviewSection('Estatísticas do Sistema', [
            _buildInfoRow(
              'Total de Usuários',
              '${schoolStats!['totalUsers'] ?? 0}',
            ),
            _buildInfoRow('Alunos', '${schoolStats!['totalStudents'] ?? 0}'),
            _buildInfoRow(
              'Professores',
              '${schoolStats!['totalTeachers'] ?? 0}',
            ),
            _buildInfoRow(
              'Administradores',
              '${schoolStats!['totalAdmins'] ?? 0}',
            ),
            _buildInfoRow('Turmas', '${schoolStats!['totalClasses'] ?? 0}'),
            _buildInfoRow(
              'Disciplinas',
              '${schoolStats!['totalSubjects'] ?? 0}',
            ),
            _buildInfoRow('Eventos', '${schoolStats!['totalEvents'] ?? 0}'),
            _buildInfoRow('Chats Ativos', '${schoolStats!['totalChats'] ?? 0}'),
          ]),
          const SizedBox(height: 20),
          _buildOverviewSection('Configurações do Sistema', [
            _buildInfoRow(
              'Períodos de Notas',
              '${schoolStats!['totalGradePeriods'] ?? 0}',
            ),
            _buildInfoRow(
              'Tipos de Notas',
              '${schoolStats!['totalGradeTypes'] ?? 0}',
            ),
            _buildInfoRow(
              'Configurações',
              '${schoolStats!['totalConfigs'] ?? 0}',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    if (isLoadingStats) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2953A5)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('Distribuição de Usuários por Tipo'),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showCreateUserDialog(context),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Criar Usuário'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showEditSchoolDialog(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar Escola'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2953A5),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildUserTypeCard(
            'Alunos',
            schoolStats?['totalStudents'] ?? 0,
            Icons.school,
            Colors.green,
            'Estudantes matriculados na escola',
          ),
          const SizedBox(height: 15),
          _buildUserTypeCard(
            'Professores',
            schoolStats?['totalTeachers'] ?? 0,
            Icons.person,
            Colors.orange,
            'Docentes responsáveis pelas disciplinas',
          ),
          const SizedBox(height: 15),
          _buildUserTypeCard(
            'Administradores',
            schoolStats?['totalAdmins'] ?? 0,
            Icons.admin_panel_settings,
            Colors.blue,
            'Usuários com acesso administrativo',
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Informações Adicionais'),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(50),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withAlpha(100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Dados dos Usuários',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Todos os usuários estão associados a esta escola e têm acesso apenas aos dados e funcionalidades específicos da instituição.',
                  style: TextStyle(color: Colors.blue[700], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesTab() {
    if (isLoadingStats) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2953A5)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('Estrutura Acadêmica'),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showCreateUserDialog(context),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Criar Usuário'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showEditSchoolDialog(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar Escola'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2953A5),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildAcademicCard(
            'Turmas',
            schoolStats?['totalClasses'] ?? 0,
            Icons.class_,
            Colors.purple,
            'Grupos de alunos organizados por série/turma',
          ),
          const SizedBox(height: 15),
          _buildAcademicCard(
            'Disciplinas',
            schoolStats?['totalSubjects'] ?? 0,
            Icons.book,
            Colors.teal,
            'Matérias oferecidas pela escola',
          ),
          const SizedBox(height: 15),
          _buildAcademicCard(
            'Períodos de Notas',
            schoolStats?['totalGradePeriods'] ?? 0,
            Icons.calendar_today,
            Colors.indigo,
            'Divisões do ano letivo para avaliações',
          ),
          const SizedBox(height: 15),
          _buildAcademicCard(
            'Tipos de Notas',
            schoolStats?['totalGradeTypes'] ?? 0,
            Icons.grade,
            Colors.amber,
            'Categorias de avaliação disponíveis',
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Organização'),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(50),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withAlpha(100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_tree, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Sistema Organizacional',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'A escola possui uma estrutura organizada com turmas, disciplinas e sistema de avaliação configurado para acompanhar o progresso dos alunos.',
                  style: TextStyle(color: Colors.green[700], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesTab() {
    if (isLoadingStats) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2953A5)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('Atividades e Eventos'),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showCreateUserDialog(context),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Criar Usuário'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showEditSchoolDialog(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar Escola'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2953A5),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildActivityCard(
            'Eventos',
            schoolStats?['totalEvents'] ?? 0,
            Icons.event,
            Colors.red,
            'Eventos programados pela escola',
          ),
          const SizedBox(height: 15),
          _buildActivityCard(
            'Chats Ativos',
            schoolStats?['totalChats'] ?? 0,
            Icons.chat,
            Colors.blue,
            'Conversas ativas entre usuários',
          ),
          const SizedBox(height: 15),
          _buildActivityCard(
            'Configurações',
            schoolStats?['totalConfigs'] ?? 0,
            Icons.settings,
            Colors.grey,
            'Configurações personalizadas da escola',
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Sistema de Comunicação'),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(50),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withAlpha(100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Ferramentas de Comunicação',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'A escola dispõe de sistema de chat e eventos para facilitar a comunicação entre alunos, professores e administradores.',
                  style: TextStyle(color: Colors.orange[700], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(100),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2953A5),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2953A5),
      ),
    );
  }

  Widget _buildUserTypeCard(
    String title,
    int count,
    IconData icon,
    Color color,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(100),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(50),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicCard(
    String title,
    int count,
    IconData icon,
    Color color,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(100),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(50),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    String title,
    int count,
    IconData icon,
    Color color,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(100),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(50),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showEditSchoolDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController(
      text: widget.school.name,
    );
    final TextEditingController addressController = TextEditingController(
      text: widget.school.address ?? '',
    );
    final TextEditingController phoneController = TextEditingController(
      text: widget.school.phone ?? '',
    );
    final TextEditingController emailController = TextEditingController(
      text: widget.school.email ?? '',
    );
    final TextEditingController websiteController = TextEditingController(
      text: widget.school.website ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Editar ${_currentSchool.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Escola *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Endereço',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: websiteController,
                    decoration: const InputDecoration(
                      labelText: 'Website',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nome da escola é obrigatório'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    final updatedSchool = await SchoolService.updateSchool(
                      id: _currentSchool.id,
                      name: nameController.text.trim(),
                      address:
                          addressController.text.trim().isEmpty
                              ? null
                              : addressController.text.trim(),
                      phone:
                          phoneController.text.trim().isEmpty
                              ? null
                              : phoneController.text.trim(),
                      email:
                          emailController.text.trim().isEmpty
                              ? null
                              : emailController.text.trim(),
                      website:
                          websiteController.text.trim().isEmpty
                              ? null
                              : websiteController.text.trim(),
                    );

                    Navigator.pop(context);

                    // Atualizar os dados da escola na tela
                    setState(() {
                      _currentSchool = updatedSchool;
                    });

                    // Recarregar estatísticas
                    _loadSchoolStats();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Escola "${updatedSchool.name}" atualizada com sucesso!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao criar usuário: \${userErrorMessage(e)}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
    );
  }

  void _showCreateUserDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    Role selectedRole = Role.student;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Criar Usuário em ${_currentSchool.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome Completo *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Senha *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Role>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Usuário *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: Role.student,
                        child: Row(
                          children: [
                            Icon(Icons.school, color: Colors.green),
                            const SizedBox(width: 8),
                            const Text('Aluno'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: Role.teacher,
                        child: Row(
                          children: [
                            Icon(Icons.person, color: Colors.orange),
                            const SizedBox(width: 8),
                            const Text('Professor'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: Role.admin,
                        child: Row(
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            const Text('Administrador'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (Role? value) {
                      if (value != null) {
                        selectedRole = value;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(50),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withAlpha(100)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'O usuário será automaticamente associado à escola "${_currentSchool.name}"',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty ||
                      emailController.text.trim().isEmpty ||
                      passwordController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Todos os campos são obrigatórios'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    // Criar o usuário usando o AuthService
                    await AuthService.register(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                      name: nameController.text.trim(),
                      role: selectedRole,
                      schoolId: _currentSchool.id,
                    );

                    Navigator.pop(context);

                    // Recarregar estatísticas para mostrar o novo usuário
                    _loadSchoolStats();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Usuário "${nameController.text.trim()}" criado com sucesso em ${_currentSchool.name}!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao criar usuário: \${userErrorMessage(e)}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2953A5),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Criar Usuário'),
              ),
            ],
          ),
    );
  }
}
