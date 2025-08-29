// lib/screens/update_password_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'home_screen.dart';
// استيراد مكتبة dart:html للتعامل مع URL في تطبيقات الويب
import 'dart:html' as html show window;


class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  // أضفنا متغير جديد للتحكم في حالة عرض كلمة المرور
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // استدعاء الدالة الخاصة بالويب
    _handlePasswordReset();
  }

  // دالة خاصة بالويب للتعامل مع التوكن
  void _handlePasswordReset() async {
    // استخراج التوكن من URL
    final uri = Uri.parse(html.window.location.href);
    final fragment = uri.fragment;

    // Supabase يستخدم التوكن في "fragment" وليس "query parameters"
    final token = fragment.contains('access_token')
        ? fragment.split('access_token=')[1].split('&')[0]
        : null;

    if (token != null) {
      // استخدام التوكن لاستعادة الجلسة
      try {
        await supabase.auth.setSession(token);
        _showSnackBar('تم تسجيل الدخول بنجاح! يمكنك الآن تحديث كلمة المرور.');
      } catch (e) {
        print('Error recovering session: $e');
        _showSnackBar('حدث خطأ أثناء استعادة الجلسة.');
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    setState(() {
      _isLoading = true;
    });

    final newPassword = _passwordController.text.trim();
    if (newPassword.isEmpty) {
      _showSnackBar('Please enter a new password.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      _showSnackBar('Password updated successfully!');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (Route<dynamic> route) => false,
      );
    } on AuthException catch (e) {
      _showSnackBar(e.message ?? 'An error occurred.');
    } catch (e) {
      _showSnackBar('An unexpected error occurred.');
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
        title: const Text('Update Password'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Please enter your new password:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              // استخدام المتغير الجديد للتحكم في إخفاء النص
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: const OutlineInputBorder(),
                // إضافة زرار إظهار/إخفاء الباسورد
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _updatePassword,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }
}
