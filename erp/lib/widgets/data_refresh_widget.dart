import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';

class DataRefreshWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDataRefreshed;
  final bool autoRefresh;

  const DataRefreshWidget({
    super.key,
    required this.child,
    this.onDataRefreshed,
    this.autoRefresh = true,
  });

  @override
  State<DataRefreshWidget> createState() => _DataRefreshWidgetState();
}

class _DataRefreshWidgetState extends State<DataRefreshWidget> {
  @override
  void initState() {
    super.initState();
    if (widget.autoRefresh) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshData();
      });
    }
  }

  Future<void> _refreshData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    if (authProvider.isAuthenticated && authProvider.user != null) {
      // Atualizar dados do usuário atual
      await authProvider.refreshUserData();

      // Atualizar dados específicos baseado no tipo de usuário
      if (authProvider.user!.isTeacher && authProvider.user!.teacher != null) {
        await dataProvider.refreshCurrentTeacher(
          authProvider.user!.teacher!.id,
        );
      } else if (authProvider.user!.isStudent &&
          authProvider.user!.student != null) {
        await dataProvider.refreshCurrentStudent(
          authProvider.user!.student!.id,
        );
      }

      // Atualizar listas se necessário
      await dataProvider.refreshTeachers();
      await dataProvider.refreshStudents();

      widget.onDataRefreshed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: _refreshData, child: widget.child);
  }
}

// Widget para atualizar dados específicos
class SpecificDataRefreshWidget extends StatelessWidget {
  final Widget child;
  final String? teacherId;
  final String? studentId;
  final VoidCallback? onDataRefreshed;

  const SpecificDataRefreshWidget({
    super.key,
    required this.child,
    this.teacherId,
    this.studentId,
    this.onDataRefreshed,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final dataProvider = Provider.of<DataProvider>(context, listen: false);

        if (teacherId != null) {
          await dataProvider.refreshCurrentTeacher(teacherId!);
        }

        if (studentId != null) {
          await dataProvider.refreshCurrentStudent(studentId!);
        }

        onDataRefreshed?.call();
      },
      child: child,
    );
  }
}

// Mixin para facilitar atualização de dados em StatefulWidgets
mixin DataRefreshMixin<T extends StatefulWidget> on State<T> {
  Future<void> refreshUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshUserData();
  }

  Future<void> refreshTeacherData(String teacherId) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await dataProvider.refreshCurrentTeacher(teacherId);
  }

  Future<void> refreshStudentData(String studentId) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await dataProvider.refreshCurrentStudent(studentId);
  }

  Future<void> refreshAllData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    await authProvider.refreshUserData();
    await dataProvider.refreshTeachers();
    await dataProvider.refreshStudents();
  }

  void showRefreshSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
