// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add this line
import '../services/mqtt_service.dart';
import '../services/supabase_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // استخدم Consumer للاستماع للتغييرات في MqttService
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
                  // TODO: أضف هنا الانتقال إلى شاشة الدخول
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // -- كارت عرض حالة الخزنة --
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Safe Status',
                          style: TextStyle(fontSize: 18, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mqttService.safeStatus, // القيمة تأتي من الـ Service
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: mqttService.safeStatus == 'Locked' ? Colors.redAccent : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // -- حقل إدخال كلمة المرور لفتح الخزنة --
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

                // -- زر فتح الخزنة --
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