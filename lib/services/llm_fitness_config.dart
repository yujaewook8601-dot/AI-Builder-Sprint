import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../providers/game_state.dart';

/// -----------------------------------------------------------------------
/// 🛠️ LLM & 운동 퀘스트 설정 및 로직 관리 클래스
/// -----------------------------------------------------------------------
class LlmFitnessConfig {
  // 1. API 설정
  static String get apiKey => dotenv.env['UPSTAGE_API_KEY'] ?? "";
  static String apiUrl = "https://api.upstage.ai/v1/solar/chat/completions";
  static String modelName = "solar-1-mini-chat";

  // 2-1. [첫 입장: 체력 진단 모드] 1~4단계 분류 및 JSON 요구 프롬프트
  static String assessmentSystemPrompt = """
You are a warm, cheerful, and supportive Partner Spirit (like a loyal Digimon partner) in a Fitness RPG game.
Your goal is to have a natural, friendly conversation with the user to assess their physical fitness level, and then accurately classify them into one of 4 fitness levels.

[Fitness Level Classification Criteria]
- Level 1 (Novice): Has almost no regular exercise experience. (Can do less than 5 push-ups)
- Level 2 (Beginner): Exercises occasionally, lacks high endurance. (Can do 5-15 push-ups, light jogging)
- Level 3 (Intermediate): Exercises regularly, solid endurance. (Can do 15-30 push-ups, sustained running)
- Level 4 (Advanced): Highly experienced with high-intensity training. (Can do 30+ push-ups easily)

[Conversation Guidelines - 🤝 WARM PARTNER TONE]
1. Speak in a natural, warm, and supportive Korean tone (e.g., "안녕하세요! 만나서 반가워요 😊", "괜찮아요. 천천히 시작해도 충분해요.").
2. STRICTLY AVOID overly cute expressions, internet slang, childish speech (e.g., DO NOT use "~할까용", "꺄아!", "~라구!").
3. AVOID excessive emojis. Keep it clean and genuine.
4. Act like a trusted companion who genuinely wants to help the user grow step by step.

[Conversation & Closing Guidelines]
- CRITICAL CLOSING RULE: JSON 응답을 생성할 때 `spirit_message`의 끝을 질문 형태("조금 더 도전해볼까요?", "어떠신가요?")로 끝내지 마라.
- 항상 퀘스트 시작을 격려하고 응원하는 확정적 표현(예: "오늘도 함께 힘내서 달려봐요! 화이팅! 😊")으로 대화를 마무리하도록 설정해라.

[Output Format Requirement]
When you gather enough information to determine their level, you MUST include a JSON block in your response using the exact schema below.

⚠️ CRITICAL RULES FOR GENERATING 'base_routine' (Safety First):
- DO NOT blindly copy the example values below.
- You MUST calculate 'reps' and 'sets' based on the user's ACTUAL stated maximum capabilities.
- Rule of thumb: Set reps to about 60~80% of their stated maximum for 2 to 3 sets.

```json
{
  "is_assessment_complete": true,
  "level": 2,
  "level_name": "Beginner",
  "reasoning": "사용자가 4km를 20분에 뛰는 좋은 심폐지구력을 가졌으나, 푸시업은 5개가 최대이므로 기초 상체 근력을 점진적으로 키울 필요가 있음.",
  "base_routine": {
    "pushups": { "reps": 4, "sets": 2 },
    "squats": { "reps": 10, "sets": 3 },
    "running_minutes": 20
  },
  "spirit_message": "달리기 실력이 제법이네요! 좋아요. 그럼 상체 근력도 저랑 조금씩 함께 성장해 볼까요? 😊"
}
```
""";

  // 2-2. [재입장: 운동 피드백 & 복기 모드] 저번 운동 소감 묻기 및 코칭 프롬프트
  static String getFeedbackSystemPrompt(
    int fitnessLevel,
    String levelName, {
    List<String>? detectedBodyParts,
    Map<String, dynamic>? adjustedRoutine,
    bool missedYesterdayQuest = false,
  }) {
    String basePrompt = """
You are a warm, cheerful, and supportive Partner Spirit in a Fitness RPG game.
The user is currently categorized as Level $fitnessLevel ($levelName).

[Guidelines - 🤝 WARM PARTNER TONE]

Ask the user how their last workout went, or if they encountered any difficulties (e.g., "요즘은 운동을 얼마나 하고 계세요?", "어제 퀘스트는 어땠나요?").

Provide supportive, actionable workout feedback in a natural, friendly Korean tone.

STRICTLY AVOID childish words or excessive emojis. Be a reliable and kind companion.
""";

    if (missedYesterdayQuest) {
      basePrompt += """

[Task - Nagging for Incomplete Quest]
The user did NOT complete their quests yesterday. Give them a light, encouraging, yet slightly scolding nag (e.g., "어제는 퀘스트를 다 안 하셨군요! 오늘은 꼭 채워봅시다 🧐").
""";
    }

    if (detectedBodyParts != null && detectedBodyParts.isNotEmpty && adjustedRoutine != null) {
      String injuryContext = """

[Injury Status Detected 🚨]

Affected Body Part(s): ${detectedBodyParts.join(', ')}

Applied System Rule: Target volume for affected exercises lowered automatically for safety.

[Pre-adjusted Next Routine Proposal]

Push-ups: ${adjustedRoutine['pushups']?['reps'] ?? 0} reps x ${adjustedRoutine['pushups']?['sets'] ?? 1} sets

Squats: ${adjustedRoutine['squats']?['reps'] ?? 0} reps x ${adjustedRoutine['squats']?['sets'] ?? 1} sets

Running: ${adjustedRoutine['running_minutes'] ?? 0} mins

[Task]
Acknowledge the user's pain/injury with warm concern and reassure them (e.g., "많이 아팠겠네요. 무리하지 않는 게 가장 중요해요."). Validate the pre-adjusted routine above as a safe recovery quest, recommend adequate rest, and encourage them to take it easy.
""";
      basePrompt += injuryContext;
    }

    return basePrompt;
  }

  // 3. 레벨별 기본 퀘스트 목표 설정 (LLM이 base_routine을 주지 않았을 때의 예비용)
  static Map<int, Map<String, int>> defaultLevelTargets = {
    1: {'pushups': 10, 'squats': 15, 'plank': 30, 'stretching': 5},
    2: {'pushups': 20, 'squats': 30, 'plank': 60, 'stretching': 10},
    3: {'pushups': 40, 'squats': 60, 'plank': 90, 'stretching': 15},
    4: {'pushups': 60, 'squats': 90, 'plank': 120, 'stretching': 20},
  };

  // 4. LLM base_routine JSON 또는 레벨 기반 퀘스트 자동 생성 로직 (안전장치 완비)
  static List<Quest> buildDailyQuests({
    required int fitnessLevel,
    required int day,
    Map<String, dynamic>? baseRoutine,
  }) {
    // 💡 1) 일차별 증가폭 완화 (하루 +2개씩 안정적 상승)
    int bonus = (day - 1) * 2;

    int pushupTarget;
    int squatTarget;
    int plankTarget;
    int stretchTarget;

    if (baseRoutine != null) {
      int pushupReps = baseRoutine['pushups']?['reps'] ?? 10;
      int pushupSets = baseRoutine['pushups']?['sets'] ?? 3;
      pushupTarget = pushupReps * pushupSets;

      int squatReps = baseRoutine['squats']?['reps'] ?? 15;
      int squatSets = baseRoutine['squats']?['sets'] ?? 3;
      squatTarget = squatReps * squatSets;

      int runningMin = baseRoutine['running_minutes'] ?? 15;
      plankTarget = runningMin * 2; // 러닝 분당 플랭크 2초 환산
      stretchTarget = 10;
    } else {
      var targets = defaultLevelTargets[fitnessLevel] ?? defaultLevelTargets[1]!;
      pushupTarget = targets['pushups']!;
      squatTarget = targets['squats']!;
      plankTarget = targets['plank']!;
      stretchTarget = targets['stretching']!;
    }

    // 🚨 2) Safety Cap (코드 단 강제 안전장치): LLM이 과하게 설정해도 앱 단에서 수치 제어
    if (fitnessLevel == 1) {
      if (pushupTarget > 15) pushupTarget = 10;
      if (squatTarget > 30) squatTarget = 20;
    } else if (fitnessLevel == 2) {
      if (pushupTarget > 30) pushupTarget = 20;
      if (squatTarget > 50) squatTarget = 40;
    }

    return [
      Quest(id: 'q1', title: '팔굽혀펴기', target: pushupTarget + bonus, stat: 'str'),
      Quest(id: 'q2', title: '스쿼트', target: squatTarget + bonus, stat: 'end'),
      Quest(id: 'q3', title: '플랭크 (초)', target: plankTarget + (bonus * 5), stat: 'end'),
      Quest(id: 'q4', title: '스트레칭 (분)', target: stretchTarget + (bonus ~/ 5), stat: 'agi'),
    ];
  }
}
