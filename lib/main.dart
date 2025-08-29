// lib/main.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'screens/signin_screen.dart';
import 'screens/home_screen.dart';
import 'screens/update_password_screen.dart';
import 'services/mqtt_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://cojyysahbrvpqtydwscz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvanl5c2FoYnJ2cHF0eWR3c2N6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU3Njk3NDYsImV4cCI6MjA3MTM0NTc0Nn0.lHn2ZKH_C281H6wQXc-v3IndA9SK9r3rryglddnbHbk',
  );
  
  runApp(
    ChangeNotifierProvider(
      create: (context) {
        final mqttService = MqttService();
        mqttService.connect();
        return mqttService;
      },
      child: const MyApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        // Since we are handling the URL redirect for web, we just let the router handle it
      } else if (event == AuthChangeEvent.signedIn) {
        if (supabase.auth.currentUser != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Safe App',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false, 
      initialRoute: '/',
      routes: {
        '/': (context) => supabase.auth.currentUser == null
            ? const SignInScreen()
            : const HomePage(),
        '/update-password': (context) => const UpdatePasswordScreen(),
      },
    );
  }
}