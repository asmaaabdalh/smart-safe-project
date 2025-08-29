import 'package:flutter/material.dart';
import '../services/chatbot_service.dart';

// نموذج بسيط لرسالة الشات
class ChatMessage {
  final String text;
  final bool isUser; // صحيح إذا كانت الرسالة من المستخدم، خطأ إذا كانت من البوت
  ChatMessage({required this.text, required this.isUser});
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _textController = TextEditingController();
  final ChatbotService _chatbotService = ChatbotService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // إضافة رسالة ترحيب أولية من البوت
    _messages.add(ChatMessage(
      text: "Hello! I am your safe assistant. How can I help you today? \n(e.g., 'What is the safe status?')",
      isUser: false,
    ));
  }

  // دالة لإرسال الرسالة والحصول على الرد
  Future<void> _sendMessage() async {
    if (_textController.text.isEmpty) return;

    final userMessage = ChatMessage(text: _textController.text, isUser: true);
    setState(() {
      _messages.add(userMessage);
      _isLoading = true; // إظهار مؤشر التحميل
    });

    final question = _textController.text;
    _textController.clear(); // مسح حقل الإدخال

    // الحصول على الرد من الخدمة
    final botResponse = await _chatbotService.askQuestion(question);
    final botMessage = ChatMessage(text: botResponse, isUser: false);

    setState(() {
      _messages.add(botMessage);
      _isLoading = false; // إخفاء مؤشر التحميل
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Safe Assistant'),
        backgroundColor: Colors.deepPurple, // -->> تعديل: تغيير لون شريط العنوان
      ),
      body: Column(
        children: [
          // منطقة عرض الرسائل
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      // -->> تعديل: تغيير لون رسائل المستخدم للموف
                      color: message.isUser ? Colors.deepPurple : Colors.grey[800],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          // إظهار مؤشر التحميل عند انتظار الرد
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: CircularProgressIndicator(),
            ),
          // منطقة إدخال النص
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Ask a question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey[850],
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  style: IconButton.styleFrom(
                    // -->> تعديل: تغيير لون زر الإرسال للموف
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

