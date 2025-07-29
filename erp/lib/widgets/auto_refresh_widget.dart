import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';

/// Widget que automaticamente atualiza dados quando a tela é aberta
class AutoRefreshWidget extends StatefulWidget {
  final Widget child;
  final String? teacherId;
  final String? studentId;
  final String? userId;
  final VoidCallback? onDataRefreshed;
  final bool autoRefresh;

  const AutoRefreshWidget({
    super.key,
    required this.child,
    this.teacherId,
    this.studentId,
    this.userId,
    this.onDataRefreshed,
    this.autoRefresh = true,
  });

  @override
  State<AutoRefreshWidget> createState() => _AutoRefreshWidgetState();
}

class _AutoRefreshWidgetState extends State<AutoRefreshWidget> {
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

    try {
      // Atualizar dados do usuário se especificado
      if (widget.userId != null) {
        await authProvider.refreshUserData();
      }

      // Atualizar dados específicos
      if (widget.teacherId != null) {
        await dataProvider.refreshCurrentTeacher(widget.teacherId!);
      }

      if (widget.studentId != null) {
        await dataProvider.refreshCurrentStudent(widget.studentId!);
      }

      // Atualizar listas gerais
      await dataProvider.refreshTeachers();
      await dataProvider.refreshStudents();

      widget.onDataRefreshed?.call();
    } catch (e) {
      // Silenciosamente ignora erros de atualização automática
      debugPrint('Erro na atualização automática: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Mixin para facilitar atualizações em StatefulWidgets
mixin AutoRefreshMixin<T extends StatefulWidget> on State<T> {
  Future<void> refreshTeacherData(String teacherId) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await dataProvider.refreshCurrentTeacher(teacherId);
  }

  Future<void> refreshStudentData(String studentId) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await dataProvider.refreshCurrentStudent(studentId);
  }

  Future<void> refreshUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshUserData();
  }

  Future<void> refreshAllData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    await authProvider.refreshUserData();
    await dataProvider.refreshTeachers();
    await dataProvider.refreshStudents();
  }

  void showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Widget para mostrar loading durante atualizações
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withAlpha(50),
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(message!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget para mostrar dados com atualização automática
class AutoRefreshDataWidget<T> extends StatelessWidget {
  final Future<T> Function() dataLoader;
  final Widget Function(T data) builder;
  final Widget Function(String error)? errorBuilder;
  final Widget? loadingWidget;
  final Duration refreshInterval;

  const AutoRefreshDataWidget({
    super.key,
    required this.dataLoader,
    required this.builder,
    this.errorBuilder,
    this.loadingWidget,
    this.refreshInterval = const Duration(seconds: 30),
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: dataLoader(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return errorBuilder?.call(snapshot.error.toString()) ??
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao carregar dados: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Recarregar dados
                        (context as Element).markNeedsBuild();
                      },
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              );
        }

        if (snapshot.hasData) {
          return builder(snapshot.data as T);
        }

        return const Center(child: Text('Nenhum dado encontrado'));
      },
    );
  }
}
