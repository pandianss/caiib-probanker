import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shell/main_shell.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  await authProvider.checkToken();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool isAuthenticated = false;
  bool isAttemptingLogin = false;
  String errorMessage = '';

  Future<void> checkToken() async {
    final token = await _apiService.getToken();
    if (token != null) {
      isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    isAttemptingLogin = true;
    errorMessage = '';
    notifyListeners();

    final success = await _apiService.login(username, password);
    if (success) {
      isAuthenticated = true;
    } else {
      errorMessage = 'Invalid credentials or network error';
    }
    isAttemptingLogin = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    await _apiService.clearSession();
    isAuthenticated = false;
    notifyListeners();
  }
}

class ProgressProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? candidateData;
  Map<String, dynamic>? statsData;
  bool isLoading = true;
  int dueCount = 0;

  Future<void> fetchDashboardData() async {
    isLoading = true;
    notifyListeners();
    
    final results = await Future.wait([
      _apiService.getProgress(),
      _apiService.getStats(),
      _apiService.getDueBites(),
    ]);

    candidateData = results[0] as Map<String, dynamic>?;
    statsData = results[1] as Map<String, dynamic>?;
    final dueData = results[2] as Map<String, dynamic>?;
    dueCount = dueData?['due_count'] ?? 0;

    isLoading = false;
    notifyListeners();
  }

  Future<bool> updateElective(String elective) async {
    final success = await _apiService.updateElective(elective);
    if (success) {
      await fetchDashboardData(); // Refresh all state
    }
    return success;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CAIIB Bitsize',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            return const MainShell();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
