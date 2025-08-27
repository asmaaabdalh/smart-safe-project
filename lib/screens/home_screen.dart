// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mqtt_service.dart';
import '../services/supabase_service.dart';
import 'signin_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MqttService>(
      builder: (context, mqttService, child) {
        final _passwordController = TextEditingController();

        void _unlockSafe() {
          if (_passwordController.text.isNotEmpty) {
            mqttService.publishPassword(_passwordController.text);
            _passwordController.clear();
          }
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Smart Safe Control'),
            automaticallyImplyLeading: false, 
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  final supabaseService = SupabaseService();
                  supabaseService.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInScreen()),
                  );
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: mqttService.isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: mqttService.isConnected ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Safe Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mqttService.safeStatus,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: mqttService.safeStatus == 'Locked' ? Colors.redAccent : Colors.green,
                        ),
                      ),
                      // Display wrong attempts count if the status is ALARM
                      if (mqttService.safeStatus == 'ALARM')
                        Text(
                          'Wrong Attempts: ${mqttService.wrongAttempts}/3',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Enter Password to Unlock',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _unlockSafe,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'Unlock Safe',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
