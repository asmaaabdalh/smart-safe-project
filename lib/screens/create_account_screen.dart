import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'home_screen.dart';

class CreateAccountScreen extends StatefulWidget {
 const CreateAccountScreen({super.key});

 @override
 State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
 final _emailController = TextEditingController();
 final _passwordController = TextEditingController();
 final _confirmPasswordController = TextEditingController();
 final _supabaseService = SupabaseService();
 bool _isLoading = false;

 @override
 void dispose() {
  _emailController.dispose();
  _passwordController.dispose();
  _confirmPasswordController.dispose();
  super.dispose();
 }

 Future<void> _createAccount() async {
  setState(() {
   _isLoading = true;
  });

  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();
  final confirmPassword = _confirmPasswordController.text.trim();

  if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
   _showSnackBar('Email and password cannot be empty.');
   setState(() {
    _isLoading = false;
   });
   return;
  }

  if (password != confirmPassword) {
   _showSnackBar('Passwords do not match.');
   setState(() {
    _isLoading = false;
   });
   return;
  }

  final errorMessage = await _supabaseService.signUp(
   email: email,
   password: password,
  );

  if (errorMessage != null) {
   _showSnackBar(errorMessage);
  } else {
   _showSnackBar('A confirmation link has been sent to your email!');
   // Navigate to home screen or a confirmation screen
   Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const HomePage()),
   );
  }

  setState(() {
   _isLoading = false;
  });
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
    title: const Text('Create Account'),
   ),
   body: SafeArea(
    child: Center(
     child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
       child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
         const Text(
          'Get Started',
          textAlign: TextAlign.center,
          style: TextStyle(
           fontSize: 32,
           fontWeight: FontWeight.bold,
          ),
         ),
         const SizedBox(height: 8),
         const Text(
          'Create your account to get started.',
          textAlign: TextAlign.center,
          style: TextStyle(
           fontSize: 16,
           color: Colors.white70,
          ),
         ),
         const SizedBox(height: 48),

         TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
           labelText: 'Email',
           border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
           ),
          ),
          keyboardType: TextInputType.emailAddress,
         ),
         const SizedBox(height: 16),
         
         TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
           labelText: 'Password',
           border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
           ),
          ),
          obscureText: true,
         ),
         const SizedBox(height: 16),
         
         TextFormField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
           labelText: 'Confirm Password',
           border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
           ),
          ),
          obscureText: true,
         ),
         const SizedBox(height: 24),

         ElevatedButton(
          onPressed: _isLoading ? null : _createAccount,
          style: ElevatedButton.styleFrom(
           padding: const EdgeInsets.symmetric(vertical: 16),
           shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
           ),
          ),
          child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
              'Create Account',
              style: TextStyle(fontSize: 18),
             ),
         ),
        ],
       ),
      ),
     ),
    ),
   ),
  );
 }
}
