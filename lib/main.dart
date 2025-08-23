import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/signin_screen.dart';
// import 'screens/signin_screen.dart'; // We will create this file next

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // استبدل هذه البيانات ببيانات مشروعك في Supabase
  await Supabase.initialize(
    url: 'https://cojyysahbrvpqtydwscz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvanl5c2FoYnJ2cHF0eWR3c2N6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU3Njk3NDYsImV4cCI6MjA3MTM0NTc0Nn0.lHn2ZKH_C281H6wQXc-v3IndA9SK9r3rryglddnbHbk',
  );

  runApp(const MyApp());
}

// This is a placeholder for the Supabase client
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Safe App',
      theme: ThemeData.dark(),
      // The first screen the user will see
       home: SignInScreen()
    );
  }
}
