import 'package:flutter/material.dart';
import 'package:erp/providers/auth_provider.dart'; // Added import for AuthProvider
import 'package:provider/provider.dart'; // Added import for Provider

class NavigationBarWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool isWide;

  const NavigationBarWidget({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return _BlueSidebar(selectedIndex: selectedIndex, onSelect: onSelect);
    } else {
      return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF2953A5), // azul
        selectedItemColor: Colors.white, // ícones selecionados brancos
        unselectedItemColor:
            Colors.white70, // ícones não selecionados levemente acinzentados
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Disciplinas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendário',
          ),
        ],
        currentIndex: selectedIndex,
        onTap: onSelect,
      );
    }
  }
}

class _BlueSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _BlueSidebar({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: const Color(0xFF2953A5),
      child: Column(
        children: [
          // Logo/Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Color(0xFF2953A5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ERP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _NavigationItem(
                  icon: Icons.home,
                  label: 'Início',
                  isSelected: selectedIndex == 0,
                  onTap: () => onSelect(0),
                ),
                _NavigationItem(
                  icon: Icons.menu_book,
                  label: 'Disciplinas',
                  isSelected: selectedIndex == 1,
                  onTap: () => onSelect(1),
                ),
                _NavigationItem(
                  icon: Icons.calendar_today,
                  label: 'Calendário',
                  isSelected: selectedIndex == 2,
                  onTap: () => onSelect(2),
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.white24, height: 1),
                // Botão de logout
                _NavigationItem(
                  icon: Icons.logout,
                  label: 'Sair',
                  isSelected: false,
                  onTap: () {
                    // Logout usando Provider
                    final provider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    provider.logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color:
                  isSelected ? Colors.white.withAlpha(30) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
