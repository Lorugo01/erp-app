import 'package:flutter/material.dart';
import 'widgets/bylab_safe_area.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/teacher/teacher_dashboard_screen.dart';
import 'screens/student/student_dashboard_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/developer/developer_dashboard_screen.dart';
import 'config/environment.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar dados de localização para formatação de datas em PT-BR
  await initializeDateFormatting('pt_BR', null);
  Intl.defaultLocale = 'pt_BR';

  // Carregar variáveis do arquivo .env
  await EnvironmentConfig.load();

  // Imprimir configurações atuais para debug
  AppConfig.printCurrentConfig();

  // Validar configurações
  final configErrors = AppConfig.validateConfig();
  if (configErrors.isNotEmpty) {
    debugPrint('❌ ERROS DE CONFIGURAÇÃO:');
    for (final error in configErrors) {
      debugPrint('   - $error');
    }
  }

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
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
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
      if (authProvider.user!.isDeveloper) {
        return const DeveloperDashboardScreen();
      }
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
      body: BylabSafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => authProvider.logout(),
                tooltip: 'Sair',
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Olá, ${authProvider.user?.displayName ?? 'usuário'}!\nSeu papel: ${authProvider.user?.role.toString().split('.').last ?? ''}',
                  style: const TextStyle(fontSize: 22),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
