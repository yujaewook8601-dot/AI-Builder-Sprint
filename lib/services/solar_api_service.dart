import 'dart:convert';
import 'package:http/http.dart' as http;
import 'llm_fitness_config.dart';

class SolarApiService {
  static Future<String?> sendChatCompletion(List<Map<String, String>> messages) async {
    try {
      final response = await http.post(
        Uri.parse(LlmFitnessConfig.apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${LlmFitnessConfig.apiKey}"
        },
        body: jsonEncode({
          "model": LlmFitnessConfig.modelName,
          "messages": messages
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }
}
