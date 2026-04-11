import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // Added
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  String? _selectedElective;
  final ApiService _apiService = ApiService();
  bool isRegistering = false;
  String errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // Added
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_selectedElective == null) {
      setState(() => errorMessage = 'Please select an elective subject.');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      isRegistering = true;
      errorMessage = '';
    });
    
    final result = await _apiService.register(
      _nameController.text,
      _passwordController.text,
      _emailController.text,
      _mobileController.text,
      _selectedElective!
    );

    setState(() {
      isRegistering = false;
    });

    if (result['success'] == true) {
      if (mounted) {
        Navigator.pop(context); // Go back to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful. Please log in.')),
        );
      }
    } else {
      setState(() {
        errorMessage = result['error'] ?? 'Registration failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Join CAIIB Bitsize',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Start your CAIIB journey today',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone_android),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Elective',
                  prefixIcon: Icon(Icons.subject),
                ),
                value: _selectedElective,
                items: const [
                  DropdownMenuItem(value: 'RURAL', child: Text('Rural Banking')),
                  DropdownMenuItem(value: 'HRM', child: Text('Human Resources Management')),
                  DropdownMenuItem(value: 'IT_DB', child: Text('Information Tech & Digital')),
                  DropdownMenuItem(value: 'RISK', child: Text('Risk Management')),
                  DropdownMenuItem(value: 'CENTRAL', child: Text('Central Banking')),
                ],
                onChanged: (val) {
                  setState(() { _selectedElective = val; });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_reset),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  'Must be at least 8 characters, not entirely numeric, and not easily guessable.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(errorMessage, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              
              ElevatedButton(
                onPressed: isRegistering ? null : _handleRegister,
                child: isRegistering 
                   ? const SizedBox(
                       height: 20, 
                       width: 20, 
                       child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                     )
                   : const Text('CREATE ACCOUNT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
