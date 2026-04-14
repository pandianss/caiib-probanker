import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final mobile = _mobileController.text.trim();
    final password = _passwordController.text.trim();
    
    if (mobile.isNotEmpty && password.isNotEmpty) {
      ref.read(authProvider.notifier).login(mobile, password);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter credentials')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 60.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.account_balance_rounded, size: 80, color: Color(0xFF6366F1)),
              const SizedBox(height: 32),
              Text(
                "Welcome to ProBanker",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Accelerate your banking career with micro-learning.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8B949E), fontSize: 16),
              ),
              const SizedBox(height: 60),
              TextField(
                controller: _mobileController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                onSubmitted: (_) => _handleLogin(),
              ),
              const SizedBox(height: 48),
              if (authState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    authState.errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleLogin,
                  child: authState.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SIGN IN"),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {},
                child: const Text("First time? Create account", style: TextStyle(color: Color(0xFF8B949E))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
