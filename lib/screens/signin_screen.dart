import 'package:flutter/material.dart';
import 'create_account_screen.dart';
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold هو الهيكل الأساسي لأي شاشة في فلاتر
    return Scaffold(
      // SafeArea بتضمن إن محتوى الشاشة ميتداخلش مع أجزاء النظام زي شريط الإشعارات
      body: SafeArea(
        // Center بيخلي كل حاجة جواه في نص الشاشة
        child: Center(
          // Padding بيدي مساحة فاضية حوالين المحتوى عشان ميبقاش لازق في حواف الشاشة
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            // Column بيرص كل حاجة جواه بشكل عمودي (فوق بعض)
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // خلي المحتوى في نص الشاشة بالطول
              crossAxisAlignment: CrossAxisAlignment.stretch, // خلي المحتوى ياخد عرض الشاشة كله
              children: [
                // -- عنوان الشاشة --
                Text(
                  'Sign In',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8), // مسافة فاضية صغيرة
                Text(
                  'Welcome back! Please sign in to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(height: 48), // مسافة فاضية كبيرة

                // -- حقل إدخال البريد الإلكتروني --
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16), // مسافة فاضية متوسطة

                // -- حقل إدخال كلمة المرور --
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true, // لإخفاء كلمة المرور
                ),
                SizedBox(height: 24),

                // -- زر تسجيل الدخول --
                ElevatedButton(
                  onPressed: () {
                    // هنا هنكتب الكود اللي بينادي على شغل الباك إند بعدين
                    print('Sign In button pressed!');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Sign In',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                SizedBox(height: 16),

                // -- زر إنشاء حساب جديد --
                TextButton(
                  onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CreateAccountScreen()),
                      );
                    },
                  child: Text("Don't have an account? Create one"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
