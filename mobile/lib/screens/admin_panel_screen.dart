import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _secretController = TextEditingController();
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  String _paperCode = 'BRBL';
  bool _isSubmitting = false;

  Future<void> _pushUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8001/api/admin/push/'),
        headers: {
          'Content-Type': 'application/json',
          'X-Admin-Secret': _secretController.text,
        },
        body: json.encode({
          "type": "flashcard",
          "payload": {
            "paper_code": _paperCode,
            "front": _frontController.text,
            "back": _backController.text,
          }
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Regulatory update pushed successfully!')));
        _frontController.clear();
        _backController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to push update. Check secret key.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Regulatory Control', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Push RBI/SEBI Update', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('New content will be flagged as "High Priority" for all candidates results.', style: GoogleFonts.outfit(color: Colors.grey)),
              const SizedBox(height: 32),
              TextFormField(
                controller: _secretController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Admin Secret Key', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _paperCode,
                decoration: const InputDecoration(labelText: 'Target Paper', border: OutlineInputBorder()),
                items: ['ABM', 'BFM', 'ABFM', 'BRBL'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _paperCode = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _frontController,
                decoration: const InputDecoration(labelText: 'Regulation / Front', border: OutlineInputBorder()),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _backController,
                decoration: const InputDecoration(labelText: 'Detail / Back', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                  onPressed: _isSubmitting ? null : _pushUpdate,
                  child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('PUSH DYNAMIC UPDATE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
