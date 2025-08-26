import 'package:flutter/material.dart';

class AdminResponsiveNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onLogout;
  final bool isWide;

  const AdminResponsiveNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.onLogout,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return _AdminSidebar(
        selectedIndex: selectedIndex,
        onSelect: onSelect,
        onLogout: onLogout,
      );
    } else {
      return _AdminBottomNavBar(
        selectedIndex: selectedIndex,
        onSelect: onSelect,
        onLogout: onLogout,
      );
    }
  }
}

class _AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onLogout;

  const _AdminSidebar({
    required this.selectedIndex,
    required this.onSelect,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: const Color(0xFF2953A5),
      child: Column(
        children: [
          // Cabeçalho fixo
          Container(
            padding: const EdgeInsets.all(24),
            child: const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 60, color: Color(0xFF2953A5)),
            ),
          ),

          // Lista scrollável de botões
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _SidebarButton(
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    selected: selectedIndex == 0,
                    onTap: () => onSelect(0),
                  ),
                  _SidebarButton(
                    icon: Icons.people,
                    label: 'Usuários',
                    selected: selectedIndex == 1,
                    onTap: () => onSelect(1),
                  ),
                  _SidebarButton(
                    icon: Icons.school,
                    label: 'Professores',
                    selected: selectedIndex == 2,
                    onTap: () => onSelect(2),
                  ),
                  _SidebarButton(
                    icon: Icons.groups,
                    label: 'Alunos',
                    selected: selectedIndex == 3,
                    onTap: () => onSelect(3),
                  ),
                  _SidebarButton(
                    icon: Icons.class_,
                    label: 'Turmas',
                    selected: selectedIndex == 4,
                    onTap: () => onSelect(4),
                  ),
                  _SidebarButton(
                    icon: Icons.computer,
                    label: 'Armários',
                    selected: selectedIndex == 5,
                    onTap: () => onSelect(5),
                  ),
                  _SidebarButton(
                    icon: Icons.bar_chart,
                    label: 'Relatórios',
                    selected: selectedIndex == 6,
                    onTap: () => onSelect(6),
                  ),
                  _SidebarButton(
                    icon: Icons.grade,
                    label: 'Gestão de Notas',
                    selected: selectedIndex == 7,
                    onTap: () => onSelect(7),
                  ),
                  _SidebarButton(
                    icon: Icons.book,
                    label: 'Gerenciar\nMatérias',
                    selected: selectedIndex == 8,
                    onTap: () => onSelect(8),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Rodapé fixo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const Divider(color: Colors.white54, indent: 16, endIndent: 16),
                _SidebarButton(
                  icon: Icons.settings,
                  label: 'Configurações',
                  selected: selectedIndex == 9,
                  onTap: () => onSelect(9),
                ),
                _SidebarButton(
                  icon: Icons.logout,
                  label: 'Sair',
                  selected: false,
                  onTap: onLogout,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onLogout;

  const _AdminBottomNavBar({
    required this.selectedIndex,
    required this.onSelect,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    // Mapear índices para as abas principais
    int getBottomNavIndex() {
      if (selectedIndex <= 4) return selectedIndex;
      if (selectedIndex == 5) return 4; // Armários
      if (selectedIndex == 6) return 4; // Relatórios
      if (selectedIndex == 7) return 4; // Gestão de Notas
      if (selectedIndex == 8) return 4; // Gerenciar Matérias
      if (selectedIndex == 9) return 4; // Configurações
      return 0;
    }

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF2953A5),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      currentIndex: getBottomNavIndex(),
      onTap: (index) {
        onSelect(index);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Usuários'),
        BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Professores'),
        BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Alunos'),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'Mais'),
      ],
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
    return Material(
      color: selected ? Colors.white.withAlpha(30) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withAlpha(selected ? 255 : 180),
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para o menu "Mais" no mobile
class AdminMoreMenu extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onLogout;

  const AdminMoreMenu({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2953A5),
        title: const Text('Mais Opções', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MoreMenuItem(
            icon: Icons.class_,
            title: 'Turmas',
            subtitle: 'Gerenciar turmas e séries',
            selected: selectedIndex == 4,
            onTap: () {
              Navigator.pop(context);
              onSelect(4);
            },
          ),
          _MoreMenuItem(
            icon: Icons.computer,
            title: 'Armários',
            subtitle: 'Controle de equipamentos',
            selected: selectedIndex == 5,
            onTap: () {
              Navigator.pop(context);
              onSelect(5);
            },
          ),
          _MoreMenuItem(
            icon: Icons.bar_chart,
            title: 'Relatórios',
            subtitle: 'Relatórios e estatísticas',
            selected: selectedIndex == 6,
            onTap: () {
              Navigator.pop(context);
              onSelect(6);
            },
          ),
          _MoreMenuItem(
            icon: Icons.grade,
            title: 'Gestão de Notas',
            subtitle: 'Sistema de avaliações',
            selected: selectedIndex == 7,
            onTap: () {
              Navigator.pop(context);
              onSelect(7);
            },
          ),
          _MoreMenuItem(
            icon: Icons.book,
            title: 'Gerenciar Matérias',
            subtitle: 'Disciplinas e conteúdos',
            selected: selectedIndex == 8,
            onTap: () {
              Navigator.pop(context);
              onSelect(8);
            },
          ),
          _MoreMenuItem(
            icon: Icons.settings,
            title: 'Configurações',
            subtitle: 'Configurações do sistema',
            selected: selectedIndex == 9,
            onTap: () {
              Navigator.pop(context);
              onSelect(9);
            },
          ),
          const Divider(height: 32),
          _MoreMenuItem(
            icon: Icons.logout,
            title: 'Sair',
            subtitle: 'Fazer logout do sistema',
            selected: false,
            onTap: () {
              Navigator.pop(context);
              onLogout?.call();
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}

class _MoreMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _MoreMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.selected = false,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: selected ? 4 : 1,
      color: selected ? const Color(0xFF2953A5).withAlpha(20) : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isDestructive
                  ? Colors.red.withAlpha(30)
                  : selected
                  ? const Color(0xFF2953A5).withAlpha(30)
                  : Colors.grey.withAlpha(30),
          child: Icon(
            icon,
            color:
                isDestructive
                    ? Colors.red
                    : selected
                    ? const Color(0xFF2953A5)
                    : Colors.grey[600],
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: isDestructive ? Colors.red : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDestructive ? Colors.red.withAlpha(180) : Colors.grey[600],
          ),
        ),
        trailing:
            selected
                ? const Icon(Icons.check_circle, color: Color(0xFF2953A5))
                : const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
        onTap: onTap,
      ),
    );
  }
}
