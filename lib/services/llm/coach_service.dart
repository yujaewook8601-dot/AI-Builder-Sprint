import 'dart:convert';
import 'package:http/http.dart' as http;
import 'llm_coach_config.dart';
import 'coach_response.dart';
import 'user_condition.dart';
import '../../models/quest.dart';

// ============================================================
// 🌐 LLM API 통신 서비스 (일일 퀘스트 코치)
// ============================================================
class CoachService {

  // ----------------------------------------------------------
  // 메인 호출 메서드 (Coach Prompt — 항상 JSON 반환)
  // ----------------------------------------------------------
  Future<CoachResponse> fetchCoachMessage({
    required String userName,
    required int fitnessLevel,
    required String levelName,
    required bool recoveryMode,
    required List<Quest> todayQuests,
    required UserCondition condition,
  }) async {
    // 1. User Message 조립
    final userMessage = LlmCoachConfig.buildUserMessage(
      userName:      userName,
      fitnessLevel:  fitnessLevel,
      levelName:     levelName,
      recoveryMode:  recoveryMode,
      todayQuests:   todayQuests,
      condition:     condition,
    );

    // 2. API 요청 Body 구성 (solar-pro2, temp 0.35, top_p 0.9, json_object)
    final requestBody = jsonEncode({
      'model': LlmCoachConfig.modelName,
      'messages': [
        {
          'role':    'system',
          'content': LlmCoachConfig.systemPrompt,
        },
        {
          'role':    'user',
          'content': userMessage,
        },
      ],
      'temperature': 0.35,
      'top_p': 0.9,
      'response_format': {'type': 'json_object'},
      'max_tokens': 600,
    });

    // 3. HTTP POST
    final response = await http.post(
      Uri.parse(LlmCoachConfig.apiUrl),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer ${LlmCoachConfig.apiKey}',
      },
      body: requestBody,
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('⏱️ LLM 응답 시간 초과'),
    );

    // 4. 응답 처리
    return _parseResponse(response);
  }

  // ----------------------------------------------------------
  // 응답 파싱 (다단계 방어 로직)
  // ----------------------------------------------------------
  CoachResponse _parseResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception(
        '🚨 API 오류 [${response.statusCode}]: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rawContent = decoded['choices']?[0]?['message']?['content'];

    if (rawContent == null || rawContent.toString().isEmpty) {
      throw Exception('🚨 LLM 응답이 비어있습니다.');
    }

    final cleanJson = _extractJson(rawContent.toString());

    try {
      final jsonMap = jsonDecode(cleanJson) as Map<String, dynamic>;
      return CoachResponse.fromJson(jsonMap);
    } catch (e) {
      throw Exception('🚨 CoachResponse 파싱 실패: $e\n원본: $cleanJson');
    }
  }

  // ----------------------------------------------------------
  // JSON 추출 헬퍼
  // ----------------------------------------------------------
  String _extractJson(String raw) {
    final codeBlockRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final match = codeBlockRegex.firstMatch(raw);
    if (match != null) return match.group(1)!.trim();

    final start = raw.indexOf('{');
    final end   = raw.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return raw.substring(start, end + 1);
    }

    return raw.trim();
  }
}
