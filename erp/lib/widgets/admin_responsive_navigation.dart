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
      width: 220,
      color: const Color(0xFF2953A5),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 60, color: Color(0xFF2953A5)),
          ),
          const SizedBox(height: 24),
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
            label: 'Equipamentos',
            selected: selectedIndex == 5,
            onTap: () => onSelect(5),
          ),
          _SidebarButton(
            icon: Icons.bar_chart,
            label: 'Relatórios',
            selected: selectedIndex == 6,
            onTap: () => onSelect(6),
          ),
          const Spacer(),
          const Divider(color: Colors.white54, indent: 16, endIndent: 16),
          _SidebarButton(
            icon: Icons.settings,
            label: 'Configurações',
            selected: selectedIndex == 7,
            onTap: () => onSelect(7),
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
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF2953A5),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      currentIndex: selectedIndex > 5 ? 0 : selectedIndex,
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
        BottomNavigationBarItem(icon: Icon(Icons.class_), label: 'Turmas'),
        BottomNavigationBarItem(
          icon: Icon(Icons.computer),
          label: 'Equipamentos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Relatórios',
        ),
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withAlpha(selected ? 255 : 180),
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
