import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import '../services/supabase_service.dart';
import 'signin_screen.dart';
import 'access_log_screen.dart';

// 1. We convert the screen to a StatefulWidget to manage its state locally.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 2. We define the controllers and services here, once.
  final _passwordController = TextEditingController();
  final MqttService _mqttService = MqttService();
  final SupabaseService _supabaseService = SupabaseService();

  // A variable to hold the current status (can be updated later)
  final String _safeStatus = 'Locked'; 
  final bool _isConnected = true; // Dummy data for UI, can be updated from MQTT
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  // 3. The unlock function now lives inside the State class.
  void _unlockSafe() {
    if (_passwordController.text.isNotEmpty) {
      // We call the publishPassword function from our service instance
      _mqttService.publishPassword(_passwordController.text.trim());
      _passwordController.clear();
      // You can add a SnackBar here for user feedback if you like
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unlock command sent!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Safe Control'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccessLogScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async { // Made async for proper signout
              await _supabaseService.signOut();
              if(mounted){
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                );
              }
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
            // 4. The UI is the same, but uses our local state variables.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isConnected ? Colors.green : Colors.red,
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
                    _safeStatus,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _safeStatus == 'Locked' ? Colors.redAccent : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible, 
              decoration: InputDecoration(
                labelText: 'Enter Password to Unlock',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  
                  
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    // -->> (Step 3) Toggle the state when the icon is pressed <<--
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                ),
              ),
            
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _unlockSafe, // The button now calls our local function
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
  }
}
