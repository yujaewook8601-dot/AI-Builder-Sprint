import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'llm_fitness_config.dart';

class LlmTimeoutException implements Exception {
  final String message;
  LlmTimeoutException(this.message);
  @override
  String toString() => message;
}

class LlmNetworkException implements Exception {
  final String message;
  LlmNetworkException(this.message);
  @override
  String toString() => message;
}

class SolarApiService {
  static Future<String?> sendChatCompletion(
    List<Map<String, String>> messages, {
    double temperature = 0.35,
    double topP = 0.9,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(LlmFitnessConfig.apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${LlmFitnessConfig.apiKey}"
        },
        body: jsonEncode({
          "model": LlmFitnessConfig.modelName,
          "temperature": temperature,
          "top_p": topP,
          "messages": messages
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        throw LlmNetworkException('API Error: ${response.statusCode}');
      }
    } on TimeoutException {
      throw LlmTimeoutException('API Request Timed Out (15s)');
    } catch (e) {
      if (e is LlmNetworkException || e is LlmTimeoutException) rethrow;
      throw LlmNetworkException('Network Error: $e');
    }
  }
}
