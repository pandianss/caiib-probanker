import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.account_balance, size: 50, color: Theme.of(context).primaryColor),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Welcome to ProBanker',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to sync your CAIIB progress',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                onSubmitted: (_) => context.read<AuthProvider>().login(
                  _usernameController.text, 
                  _passwordController.text
                ),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 32),
              
              if (auth.errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(auth.errorMessage, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              
              ElevatedButton(
                onPressed: auth.isAttemptingLogin ? null : () {
                   context.read<AuthProvider>().login(
                     _usernameController.text, 
                     _passwordController.text
                   );
                },
                child: auth.isAttemptingLogin 
                   ? const CircularProgressIndicator(color: Colors.white)
                   : const Text('SIGN IN'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?", style: Theme.of(context).textTheme.bodyMedium),
                  TextButton(
                    onPressed: () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(builder: (context) => const RegisterScreen()),
                       );
                    },
                    child: Text('Register', style: TextStyle(color: Theme.of(context).primaryColor)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
