import 'package:flutter/material.dart';
import '../services/supabase_service.dart'; // تأكدي من استيراد الخدمة

class AccessLogScreen extends StatefulWidget {
  const AccessLogScreen({super.key});

  @override
  State<AccessLogScreen> createState() => _AccessLogScreenState();
}

class _AccessLogScreenState extends State<AccessLogScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<Map<String, dynamic>>> _logsFuture;

  @override
  void initState() {
    super.initState();
    // استدعاء الدالة عند فتح الشاشة لأول مرة
    _logsFuture = _supabaseService.getAccessLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access History'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          // في حالة تحميل البيانات
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // في حالة حدوث خطأ
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          // في حالة عدم وجود بيانات
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No access logs found.'));
          }

          // إذا نجح كل شيء، اعرض البيانات
          final logs = snapshot.data!;
          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              // تنسيق التاريخ والوقت بشكل أفضل
              final timestamp = DateTime.parse(log['created_at']).toLocal();
              final formattedTime = "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}";
              final formattedDate = "${timestamp.day}/${timestamp.month}/${timestamp.year}";

              return ListTile(
                leading: Icon(
                  log['action'] == 'Opened Safe' ? Icons.lock_open : Icons.lock,
                  color: log['action'] == 'Opened Safe' ? Colors.green : Colors.red,
                ),
                title: Text(log['action']),
                subtitle: Text('At $formattedTime on $formattedDate'),
              );
            },
          );
        },
      ),
    );
  }
}