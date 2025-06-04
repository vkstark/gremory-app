import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ChatAPIService {
  final String baseUrl = "https://gremory-backend.onrender.com/api/v1/chat"; // Replace this

  Future<Message> sendMessage(String model, String userQuery) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "lm_name": model,
        "user_query": userQuery,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final String replyText = json["data"]["answer"];  // <-- FIX HERE
      return Message.assistant(replyText);
    } else {
      throw Exception(
        'Failed to get chat response: ${response.statusCode} ${response.body}');
    }
  }
}
