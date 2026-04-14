import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _initFields();
  }

  void _initFields() {
    final subState = ref.read(subscriptionProvider);
    // Profile info would ideally be in a better location, but leveraging existing data
    // In a production app, we'd have a UserProvider
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
      ref.read(subscriptionProvider.notifier).refresh();
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
              const SizedBox(height: 110),
              
              ElevatedButton(
                onPressed: isSaving ? null : _handleSave,
                child: isSaving 
                   ? const CircularProgressIndicator(color: Colors.white)
                   : const Text('SAVE CHANGES'),
              ),

              const SizedBox(height: 16),
              
              OutlinedButton(
                onPressed: () {
                   ref.read(authProvider.notifier).logout();
                },
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
                child: const Text('LOGOUT', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
