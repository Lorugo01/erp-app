import 'package:flutter/material.dart';

class AdminAppBarMenu extends StatelessWidget {
  final VoidCallback? onConfig;
  final VoidCallback? onLogout;
  const AdminAppBarMenu({super.key, this.onConfig, this.onLogout});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Color(0xFF2953A5)),
      onSelected: (value) {
        if (value == 'config' && onConfig != null) {
          onConfig!();
        } else if (value == 'logout' && onLogout != null) {
          onLogout!();
        }
      },
      itemBuilder:
          (context) => [
            const PopupMenuItem<String>(
              value: 'config',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Configurações'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: ListTile(leading: Icon(Icons.logout), title: Text('Sair')),
            ),
          ],
    );
  }
}
