import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/teacher/teacher_dashboard_screen.dart';
import 'screens/student/student_dashboard_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: MaterialApp(
        title: 'ByLAB ERP',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2953A5)),
          useMaterial3: true,
        ),
        home: const AuthFlow(),
      ),
    );
  }
}

class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  bool showLogin = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.isAuthenticated) {
      // Redireciona para dashboard conforme o tipo de usuário
      if (authProvider.user!.isTeacher) {
        return TeacherDashboardScreen();
      }
      if (authProvider.user!.isStudent) {
        return StudentDashboardScreen();
      }
      if (authProvider.user!.isAdmin) {
        return const AdminDashboardScreen();
      }
      return const HomeScreen();
    }
    return showLogin
        ? LoginScreen(
          key: const ValueKey('login'),
          onRegisterTap: () => setState(() => showLogin = false),
        )
        : RegisterScreen(
          key: const ValueKey('register'),
          onLoginTap: () => setState(() => showLogin = true),
        );
  }

  @override
  void initState() {
    super.initState();
    Provider.of<AuthProvider>(context, listen: false).loadUserFromStorage();
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bem-vindo ao ByLAB ERP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Olá, ${authProvider.user?.displayName ?? 'usuário'}!\nSeu papel: ${authProvider.user?.role.toString().split('.').last ?? ''}',
          style: const TextStyle(fontSize: 22),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
