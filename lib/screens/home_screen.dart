import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import '../services/supabase_service.dart';
import 'signin_screen.dart';
import 'access_log_screen.dart';
import 'chatbot_screen.dart';

// هذه هي النسخة النهائية والكاملة للشاشة الرئيسية
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // تعريف كل المتغيرات اللازمة للشاشة
  final _passwordController = TextEditingController();
  final MqttService _mqttService = MqttService();
  final SupabaseService _supabaseService = SupabaseService();

  bool _isLoading = false; // لتتبع حالة التحميل
  bool _isPasswordVisible = false; // لتتبع رؤية كلمة المرور

  // متغيرات وهمية لعرضها في الواجهة (سيتم ربطها لاحقًا بالبيانات الحية من MQTT)
  String _safeStatus = 'Locked';

  @override
  void dispose() {
    // من المهم التخلص من الـ controllers لتحرير الموارد
    _passwordController.dispose();
    super.dispose();
  }

  // دالة إرسال أمر فتح الخزنة
  // The function is now void, not Future<void>
  void _unlockSafe() {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a password.')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // بدء التحميل وإظهار الدائرة
    });

    try {
      // THE FIX: The 'await' keyword has been removed from the line below
      _mqttService.publishPassword(_passwordController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unlock command sent successfully!')),
        );
      }
      _passwordController.clear();
    } catch (e) {
      // في حالة حدوث خطأ، إظهار رسالة للمستخدم
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send command: $e')),
        );
      }
    }

    // Use a small delay to simulate network time and keep the spinner visible
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false; // إيقاف التحميل وإخفاء الدائرة
        });
      }
    });
  }
  
  // دالة تسجيل الخروج
  Future<void> _signOut() async {
    await _supabaseService.signOut();
    if (mounted) {
      // إرجاع المستخدم إلى شاشة تسجيل الدخول ومنع العودة للخلف
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Safe Control'),
        automaticallyImplyLeading: false, // لمنع زر الرجوع التلقائي
        actions: [
          // زر سجلات الدخول
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Access Logs',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccessLogScreen()),
              );
            },
          ),
          // زر تسجيل الخروج
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card لعرض حالة الخزنة
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _safeStatus == 'Locked' ? Colors.redAccent : Colors.green),
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
              ),
              const SizedBox(height: 48),

              // حقل إدخال كلمة المرور مع أيقونة العين
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
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // زر فتح الخزنة مع مؤشر التحميل
              ElevatedButton(
                onPressed: _isLoading ? null : _unlockSafe,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.green,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'Unlock Safe',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
      // زر الشات بوت العائم
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatbotScreen()),
          );
        },
        backgroundColor: Colors.deepPurple,
        tooltip: 'Chat with Assistant',
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }
}

