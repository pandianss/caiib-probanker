import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
}

class ProgressProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? candidateData;
  Map<String, dynamic>? tracingData;
  bool isLoading = true;

  Future<void> fetchDashboardData() async {
    isLoading = true;
    notifyListeners();
    candidateData = await _apiService.getProgress();
    tracingData = await _apiService.getKnowledgeTracing();
    isLoading = false;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CAIIB ProBanker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Using our modern dark theme
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
