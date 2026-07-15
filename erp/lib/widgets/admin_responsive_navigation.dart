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
    }
    return _AdminBottomNavBar(
      selectedIndex: selectedIndex,
      onSelect: onSelect,
      onLogout: onLogout,
    );
  }
}

class _NavItem {
  final int index;
  final IconData icon;
  final String label;

  const _NavItem(this.index, this.icon, this.label);
}

const _primaryNavItems = <_NavItem>[
  _NavItem(0, Icons.dashboard, 'Início'),
  _NavItem(4, Icons.class_, 'Turmas'),
  _NavItem(3, Icons.groups, 'Alunos'),
  _NavItem(2, Icons.school, 'Profs'),
];

const _moreNavItems = <_NavItem>[
  _NavItem(1, Icons.people, 'Usuários'),
  _NavItem(5, Icons.computer, 'Armários'),
  _NavItem(6, Icons.bar_chart, 'Relatórios'),
  _NavItem(7, Icons.grade, 'Gestão de Notas'),
  _NavItem(8, Icons.book, 'Gerenciar Matérias'),
  _NavItem(9, Icons.settings, 'Configurações'),
];

const _sidebarNavItems = <_NavItem>[
  _NavItem(0, Icons.dashboard, 'Dashboard'),
  _NavItem(1, Icons.people, 'Usuários'),
  _NavItem(2, Icons.school, 'Professores'),
  _NavItem(3, Icons.groups, 'Alunos'),
  _NavItem(4, Icons.class_, 'Turmas'),
  _NavItem(5, Icons.computer, 'Armários'),
  _NavItem(6, Icons.bar_chart, 'Relatórios'),
  _NavItem(7, Icons.grade, 'Gestão de Notas'),
  _NavItem(8, Icons.book, 'Gerenciar Matérias'),
  _NavItem(9, Icons.settings, 'Configurações'),
];

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
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Color(0xFF2953A5)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final item in _sidebarNavItems)
                    _SidebarButton(
                      icon: item.icon,
                      label: item.label,
                      selected: selectedIndex == item.index,
                      onTap: () => onSelect(item.index),
                    ),
                  const Divider(
                    color: Colors.white54,
                    indent: 16,
                    endIndent: 16,
                  ),
                  _SidebarButton(
                    icon: Icons.logout,
                    label: 'Sair',
                    selected: false,
                    onTap: onLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
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

  bool get _isMoreSelected =>
      _moreNavItems.any((item) => item.index == selectedIndex);

  int get _currentPrimaryIndex {
    final idx = _primaryNavItems.indexWhere((i) => i.index == selectedIndex);
    return idx >= 0 ? idx : 0;
  }

  Future<void> _openMoreSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Mais opções',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              for (final item in _moreNavItems)
                ListTile(
                  leading: Icon(
                    item.icon,
                    color:
                        selectedIndex == item.index
                            ? const Color(0xFF2953A5)
                            : null,
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight:
                          selectedIndex == item.index
                              ? FontWeight.bold
                              : FontWeight.normal,
                      color:
                          selectedIndex == item.index
                              ? const Color(0xFF2953A5)
                              : null,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onSelect(item.index);
                  },
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.orange),
                title: const Text('Sair'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onLogout?.call();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;

    return Theme(
      data: Theme.of(context).copyWith(
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF2953A5),
          indicatorColor: Colors.white.withAlpha(40),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              color: selected ? Colors.white : Colors.white70,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? Colors.white : Colors.white70,
            );
          }),
        ),
      ),
      child: NavigationBar(
        height: isLandscape ? 56 : 68,
        labelBehavior:
            isLandscape
                ? NavigationDestinationLabelBehavior.alwaysHide
                : NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: _isMoreSelected ? 4 : _currentPrimaryIndex,
        onDestinationSelected: (index) {
          if (index == 4) {
            _openMoreSheet(context);
            return;
          }
          onSelect(_primaryNavItems[index].index);
        },
        destinations: [
          for (final item in _primaryNavItems)
            NavigationDestination(icon: Icon(item.icon), label: item.label),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz),
            label: 'Mais',
          ),
        ],
      ),
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
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
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
