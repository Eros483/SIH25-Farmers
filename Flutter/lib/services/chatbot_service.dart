import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatBotService {
  static const String _baseUrl = 'https://sih25-farmers.onrender.com/chat';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  static Future<String> sendMessage(String message) async {
    try {
      final url = Uri.parse(_baseUrl);

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "message": message,
          "user_id": "flutter_user", // can be any string
          "response_language": "english"
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? "No response from chatbot.";
      } else {
        throw Exception('API call failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static String getWelcomeMessage() {
    return "Namaste! I am Krishi AI Sahayak, your helpful agricultural expert. How can I assist you with your farming queries today?";
  }

  static String getErrorMessage() {
    return "Sorry, the chatbot service is currently unavailable.";
  }
}
