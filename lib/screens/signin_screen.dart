import 'package:flutter/material.dart';
import '../services/supabase_service.dart'; // Import the Supabase service
import 'home_screen.dart'; // Import the home screen
import 'create_account_screen.dart'; // Import the create account screen

// Change the screen to be Stateful
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  // To control the text input fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // To define the loading state when buttons are pressed
  bool _isLoading = false;

  // Instance of the Supabase service
  final _supabaseService = SupabaseService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Sign In function
  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Check for empty fields
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Email and password cannot be empty.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final errorMessage = await _supabaseService.signInWithPassword(
      email: email,
      password: password,
    );

    // Show an error message if the operation fails
    if (errorMessage != null) {
      _showSnackBar(errorMessage);
    } else {
      _showSnackBar('Signed in successfully!');
      // Navigate the user to the home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// Function to show a message to the user
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
        title: const Text('Sign In / Sign Up'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Email field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              // Password field
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              // Sign In button
              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Sign In'),
              ),
              const SizedBox(height: 10),
              // Sign Up button
              TextButton(
                onPressed: _isLoading ? null : () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateAccountScreen()),
                  );
                },
                child: const Text('No account? Create a new one'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}