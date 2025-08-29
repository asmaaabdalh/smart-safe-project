import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotService {
  // -->> هنا قائد التكامل سيضع رابط سيرفر Flask الخاص به بعد رفعه على Azure <<--
  final String _apiUrl = 'https://smart-safe-project-production.up.railway.app/ask';

  /// Sends a question to the Flask API and returns the bot's answer.
  Future<String> askQuestion(String question) async {
    // للทดสอบ: إذا لم يتم تعيين الرابط، قم بإرجاع رد وهمي
    if (_apiUrl == 'YOUR_FLASK_API_URL_HERE') {
      await Future.delayed(const Duration(seconds: 1));
      return "The Flask API URL has not been set up yet.";
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'question': question}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['answer'] ?? 'Sorry, I could not get an answer.';
      } else {
        // التعامل مع أخطاء الخادم
        return 'Error: Failed to connect to the server (Status code: ${response.statusCode})';
      }
    } catch (e) {
      // التعامل مع أخطاء الشبكة
      return 'An error occurred while connecting. Please check your internet connection.';
    }
  }
}
