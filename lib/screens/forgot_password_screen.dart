
import 'package:flutter/material.dart';
import '../services/supabase_service.dart'; // تأكدي من استيراد الخدمة

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final SupabaseService _authService = SupabaseService();
  bool _isLoading = false;

  Future<void> _sendResetLink() async {
    if (_emailController.text.isEmpty) {
      _showSnackBar('Please enter your email.');
      return;
    }

    setState(() { _isLoading = true; });

    final errorMessage = await _authService.resetPasswordForEmail(_emailController.text.trim());

    if (errorMessage == null) {
      _showSnackBar('Password reset link has been sent to your email.');
    } else {
      _showSnackBar(errorMessage);
    }

    setState(() { _isLoading = false; });
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter the email address associated with your account, and we will send you a link to reset your password.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendResetLink,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send Reset Link'),
            ),
          ],
        ),
      ),
    );
  }
}
