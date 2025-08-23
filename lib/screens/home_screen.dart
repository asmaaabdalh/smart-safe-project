import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Safe Control'),
        // بنلغي زر الرجوع التلقائي عشان المستخدم ميقدرش يرجع لصفحة الدخول
        automaticallyImplyLeading: false, 
        actions: [
          // زر تسجيل الخروج
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // هنا هنكتب كود تسجيل الخروج الفعلي بعدين
              // وهنرجع المستخدم لشاشة تسجيل الدخول
              print('Log out button pressed!');
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
                    SizedBox(height: 8),
                    // دي بيانات وهمية مؤقتًا
                    Text(
                      'Locked',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 48),

            // -- حقل إدخال كلمة المرور لفتح الخزنة --
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Enter Password to Unlock',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              obscureText: true,
            ),
            SizedBox(height: 24),

            // -- زر فتح الخزنة --
            ElevatedButton(
              onPressed: () {
                // هنا هنبعت الباسورد للخزنة عن طريق MQTT
                print('Unlock button pressed!');
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.green, // لون مختلف للتمييز
              ),
              child: Text(
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
