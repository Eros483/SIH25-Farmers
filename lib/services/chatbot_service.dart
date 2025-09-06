import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatBotService {
  static const String _baseUrl = 'YOUR_CHATBOT_API_ENDPOINT';

  // API headers
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    // Add your API keys or authorization headers here
    // 'Authorization': 'Bearer YOUR_API_KEY',
  };

  // Send a message to the chatbot
  static Future<String> sendMessage(String message) async {
    try {
      final url = Uri.parse(_baseUrl);

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'message': message,
          'context': 'agriculture',
          'language': 'english', // now using English
          // Add any other required parameters
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'I am having some difficulty understanding.';
      } else {
        throw Exception('API call failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Welcome message from chatbot
  static String getWelcomeMessage() {
    return "Hello! I am your agriculture assistant. You can ask me anything about farming, crops, soil, and weather.";
  }

  // Error message if service is unavailable
  static String getErrorMessage() {
    return "Sorry, the service is currently unavailable. Please try again later.";
  }
}
