import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProgressProvider>();
    final candidateData = provider.candidateData;
    if (candidateData != null) {
      final String firstName = candidateData['first_name'] ?? '';
      final String lastName = candidateData['last_name'] ?? '';
      _nameController.text = lastName.isEmpty ? firstName : '$firstName $lastName'.trim();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() { isSaving = true; });
    final success = await _apiService.updateProfile(_nameController.text);
    setState(() { isSaving = false; });
    
    if (success && mounted) {
      context.read<ProgressProvider>().fetchDashboardData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();
    final data = provider.candidateData;
    final email = data?['email'] ?? 'No email';
    final mobile = data?['mobile_number'] ?? 'No mobile number';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
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
              Center(
                child: Hero(
                  tag: 'profile_avatar',
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person, size: 64, color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 24),
              
              TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email Address (Locked)',
                  hintText: email,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 24),

              TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Mobile Number (Locked)',
                  hintText: mobile,
                  prefixIcon: const Icon(Icons.phone_android),
                ),
              ),
              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: isSaving ? null : _handleSave,
                child: isSaving 
                   ? const CircularProgressIndicator(color: Colors.white)
                   : const Text('SAVE CHANGES'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
