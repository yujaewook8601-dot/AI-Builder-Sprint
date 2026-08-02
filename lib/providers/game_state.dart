import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/llm_fitness_config.dart';
import '../services/feedback_analyzer_service.dart';
import '../services/solar_api_service.dart';

class UserStat {
  String name;
  int lv;
  int exp;
  UserStat({required this.name, this.lv = 1, this.exp = 0});
}

class Quest {
  String id;
  String title;
  int current;
  int target;
  bool completed;
  bool isPast;
  String stat;

  Quest({
    required this.id,
    required this.title,
    this.current = 0,
    required this.target,
    this.completed = false,
    this.isPast = false,
    required this.stat,
  });
}

class Buff {
  String id;
  String stat;
  int amount;
  DateTime expiresAt;

  Buff({
    required this.id,
    required this.stat,
    required this.amount,
    required this.expiresAt,
  });
}

class ChatMessage {
  final String speaker;
  final String text;
  final bool isUser;

  ChatMessage({required this.speaker, required this.text, required this.isUser});
}

class GameState extends ChangeNotifier {
  // Configs
  static const int reqExpPerLevel = 100;
  static const Map<String, int> statRewards = {'str': 20, 'agi': 20, 'end': 20};
  
  // App State
  bool isIntroDone = false;
  bool isTutorialDone = false;
  bool isOnboardingDone = false;

  // User Info
  String userName = "용사";
  int userAge = 25;
  double userHeight = 175.0;
  double userWeight = 70.0;
  String userGoal = "근력 강화";

  double get userBmi {
    if (userHeight == 0) return 0;
    return userWeight / ((userHeight / 100) * (userHeight / 100));
  }

  // [신규 추가] 날짜 추적 변수
  int? lastQuestGeneratedDate; 
  int? lastChatDate;
  bool wasYesterdayQuestCompleted = true; // 어제 퀘스트 완료 여부 (첫날은 잔소리 방지 위해 true)

  // 오늘 퀘스트 발급이 완료되어 하루 치 필요 대화가 끝났는지 여부
  bool get isDailyConversationDone {
    return isAssessmentComplete && lastQuestGeneratedDate == day;
  }

  // 4-Stage Fitness Level
  int fitnessLevel = 1; // 1: Novice, 2: Beginner, 3: Intermediate, 4: Advanced
  String fitnessLevelName = "Novice";
  bool isAssessmentComplete = false;

  // Game State
  int day = 1;
  int gold = 0;
  int level = 1;
  int exp = 0;
  double distance = 300.0; // 마왕성까지 남은 거리
  int thirst = 100;
  bool hasPet = false;
  String activePet = "";

  void buyPet(String petType) {
    hasPet = true;
    activePet = petType;
    notifyListeners();
  }

  void decreaseDistance() {
    if (distance > 0) {
      distance -= 1.0;
      if (distance < 0) distance = 0;
      notifyListeners();
    }
  }

  // Stats
  Map<String, UserStat> stats = {
    'str': UserStat(name: '💪 근력'),
    'agi': UserStat(name: '⚡ 민첩'),
    'end': UserStat(name: '🛡️ 지구력'),
  };

  // Quests
  List<Quest> dailyQuests = [];
  bool outdoorCompletedToday = false;
  bool outdoorDebuffActive = false;

  // Buffs
  List<Buff> activeBuffs = [];

  // Chat & LLM
  List<ChatMessage> chatHistory = [];
  bool isChatLoading = false;
  Map<String, dynamic>? pendingAssessedRoutine;

  GameState() {
    _initQuests();
  }

  void initSpiritGreeting() {
    // 마지막 대화일과 인게임 날짜가 다르면 채팅 초기화
    if (lastChatDate != day) {
      chatHistory.clear();
      lastChatDate = day;
    }

    if (!isAssessmentComplete) {
      if (chatHistory.isEmpty) {
        chatHistory.add(
          ChatMessage(
            speaker: "정령",
            text: "안녕하세요, $userName 님! 함께 운동하게 되어 정말 기뻐요 😊\n앞으로 딱 맞는 맞춤형 퀘스트를 드리기 위해 체력을 먼저 확인해볼게요.\n\n평소에 운동은 얼마나 자주 하시나요? 팔굽혀펴기(푸시업)나 스쿼트는 한 번에 몇 개 정도 하실 수 있는지 편하게 알려주세요!",
            isUser: false,
          ),
        );
        notifyListeners();
      }
    } else {
      if (chatHistory.isEmpty || (chatHistory.isNotEmpty && chatHistory.last.isUser)) {
        String greeting;
        if (day > 1 && !wasYesterdayQuestCompleted) {
          greeting = "이런, $userName 님! 어제는 퀘스트를 다 끝내지 못하셨군요 😢\n오늘은 어제 몫까지 더 열심히 해볼까요? 오늘 컨디션은 좀 어떠신가요?";
        } else {
          greeting = "안녕하세요, $userName 님! 다시 오셨군요 😊\n저번 운동은 어떠셨나요? 몸이 뻐근하거나 아픈 곳은 없는지, 오늘 컨디션은 어떤지 편하게 이야기해 주세요!";
        }
        
        chatHistory.add(
          ChatMessage(
            speaker: "정령",
            text: greeting,
            isUser: false,
          ),
        );
        notifyListeners();
      }
    }
  }

  void resetAssessment() {
    isAssessmentComplete = false;
    chatHistory.add(
      ChatMessage(
        speaker: "정령",
        text: "좋아요, $userName 님! 체력 수준을 다시 꼼꼼하게 체크해볼게요.\n최근 수행할 수 있는 최대 푸시업 개수나 운동량을 편하게 말씀해 주세요 😊",
        isUser: false,
      ),
    );
    notifyListeners();
  }

  void _initQuests([Map<String, dynamic>? baseRoutine]) {
    dailyQuests = LlmFitnessConfig.buildDailyQuests(
      fitnessLevel: fitnessLevel,
      day: day,
      baseRoutine: baseRoutine,
    );
    notifyListeners();
  }

  bool applyAssessedRoutineToQuests() {
    if (!isAssessmentComplete && pendingAssessedRoutine == null) {
      return false;
    }
    _initQuests(pendingAssessedRoutine);
    
    // [신규 추가] 발급 완료 후 인게임 날짜 기록
    lastQuestGeneratedDate = day;
    
    notifyListeners();
    return true;
  }

  void completeIntro() {
    isIntroDone = true;
    notifyListeners();
  }

  void completeTutorial() {
    isTutorialDone = true;
    notifyListeners();
  }

  void completeOnboarding(String name, int age, double height, double weight, String levelDesc, String goal) {
    userName = name;
    userAge = age;
    userHeight = height;
    userWeight = weight;
    userGoal = goal;
    isOnboardingDone = true;
    notifyListeners();
  }

  int getStatBuffAmount(String statKey) {
    activeBuffs.removeWhere((b) => b.expiresAt.isBefore(DateTime.now()));
    return activeBuffs.where((b) => b.stat == statKey).fold(0, (sum, b) => sum + b.amount);
  }

  bool get isHydrationDebuffActive => thirst <= 40;

  int getStatDebuffPercent(String statKey) {
    int debuff = 0;
    if (isHydrationDebuffActive && statKey == 'end') debuff += 20;
    if (outdoorDebuffActive && statKey == 'str') debuff += 20;
    return debuff;
  }

  int getEffectiveStatLevel(String statKey) {
    int baseLv = stats[statKey]!.lv + getStatBuffAmount(statKey);
    int debuffPct = getStatDebuffPercent(statKey);
    return ((baseLv * (100 - debuffPct)) / 100).floor().clamp(1, 9999);
  }

  // --- 전투(Combat) 연산 공식 ---
  
  /// 영웅의 기본 공격 데미지 계산
  /// [수정 가이드] 
  /// - 기본 데미지(20.0)를 바꾸거나, 적용되는 스탯(str, end) 계수를 조절하세요.
  double calculateHeroDamage() {
    return 20.0 + getEffectiveStatLevel('str') + (getEffectiveStatLevel('end') * 0.5);
  }

  /// 영웅의 공격 간격(주기) 계산 (밀리초)
  /// [수정 가이드]
  /// - 기본 쿨타임(1500)이나 민첩(agi)/지구력(end)에 따른 쿨타임 감소 배율을 조정하세요.
  /// - 반환값이 작을수록 공격 속도가 빠릅니다.
  int calculateHeroAttackIntervalMs() {
    double speedMultiplier = 1.0 + (getEffectiveStatLevel('agi') * 0.02) + (getEffectiveStatLevel('end') * 0.01);
    int intervalMs = (1500 / speedMultiplier).round();
    return intervalMs < 500 ? 500 : intervalMs; // 최소 공격 쿨타임 500ms 제한
  }

  void drinkWater() {
    if (thirst < 100) {
      thirst = (thirst + 20).clamp(0, 100);
      notifyListeners();
    }
  }

  void gainGlobalExp() {
    exp++;
    if (exp >= 5) {
      level++;
      exp = 0;
    }
    notifyListeners();
  }

  void gainStatExp(String statKey, [int? amount]) {
    final stat = stats[statKey]!;
    int expGain = amount ?? (statRewards[statKey] ?? 20);
    stat.exp += expGain;
    while (stat.exp >= reqExpPerLevel) {
      stat.lv++;
      stat.exp -= reqExpPerLevel;
    }
    notifyListeners();
  }

  void updateQuest(String questId, int amount) {
    final idx = dailyQuests.indexWhere((q) => q.id == questId);
    if (idx != -1) {
      var q = dailyQuests[idx];
      q.current = (q.current + amount).clamp(0, q.target);
      if (q.current >= q.target && !q.completed) {
        q.completed = true;
        gold += 10;
        gainGlobalExp();
        gainStatExp(q.stat);
      }
      notifyListeners();
    }
  }

  void completeOutdoorQuest() {
    if (!outdoorCompletedToday) {
      outdoorCompletedToday = true;
      outdoorDebuffActive = false;
      gold += 20;
      gainGlobalExp();
      notifyListeners();
    }
  }

  void nextDay() {
    if (!outdoorCompletedToday) {
      outdoorDebuffActive = true;
    }
    
    // 어제(이전 날) 퀘스트를 모두 완료했는지 체크
    if (dailyQuests.isNotEmpty) {
      wasYesterdayQuestCompleted = dailyQuests.every((q) => q.completed);
    }
    
    day++;
    thirst = (thirst - 10).clamp(0, 100);
    outdoorCompletedToday = false;
    _initQuests();
    notifyListeners();
  }

  void buyItem(int price, Function onBuy) {
    if (gold >= price) {
      gold -= price;
      onBuy();
      notifyListeners();
    }
  }

  void applyBuff(String id, String stat, int amount, int durationSeconds) {
    activeBuffs.add(Buff(
      id: id,
      stat: stat,
      amount: amount,
      expiresAt: DateTime.now().add(Duration(seconds: durationSeconds)),
    ));
    notifyListeners();
  }

  Future<void> sendChatMessage(String message) async {
    if (message.trim().isEmpty) return;

    chatHistory.add(ChatMessage(speaker: userName, text: message, isUser: true));
    notifyListeners();

    // [로컬 차단 1] 중복 발급 방지
    if (isAssessmentComplete && lastQuestGeneratedDate == day) {
      chatHistory.add(ChatMessage(
        speaker: "정령",
        text: "오늘 퀘스트는 이미 받았어요! 남은 훈련을 완수하고 내일 다시 이야기해요 😊",
        isUser: false,
      ));
      notifyListeners();
      return;
    }

    // [로컬 차단 2] 딴소리 방지
    if (!FeedbackAnalyzerService.isFitnessRelated(message)) {
      chatHistory.add(ChatMessage(
        speaker: "정령",
        text: "모험가님! 지금은 훈련에 집중할 시간이에요. 딴청 피우지 말고 오늘의 컨디션이나 퀘스트에 대해 이야기해 볼까요? 🧐",
        isUser: false,
      ));
      notifyListeners();
      return;
    }

    isChatLoading = true;
    notifyListeners();

    try {
      String activePrompt;
      if (isAssessmentComplete) {
        var analysisResult = FeedbackAnalyzerService.analyzeFeedback(message);
        
        Map<String, dynamic>? adjustedRoutine;
        List<String>? detectedBodyParts;

        if (analysisResult.hasInjury) {
          detectedBodyParts = analysisResult.detectedKeywords;
          
          // 조절된 루틴 생성 (기존 pendingAssessedRoutine 또는 기본값에서 시작)
          Map<String, dynamic> base = pendingAssessedRoutine ?? {};
          adjustedRoutine = {
            'pushups': {'reps': base['pushups']?['reps'] ?? LlmFitnessConfig.defaultLevelTargets[fitnessLevel]!['pushups'], 'sets': base['pushups']?['sets'] ?? 1},
            'squats': {'reps': base['squats']?['reps'] ?? LlmFitnessConfig.defaultLevelTargets[fitnessLevel]!['squats'], 'sets': base['squats']?['sets'] ?? 1},
            'running_minutes': base['running_minutes'] ?? 15,
          };

          // 감지된 운동 난이도 40% 삭감
          if (analysisResult.affectedExercises.contains('pushups')) {
            adjustedRoutine['pushups']['reps'] = (adjustedRoutine['pushups']['reps'] * 0.6).ceil();
          }
          if (analysisResult.affectedExercises.contains('squats')) {
            adjustedRoutine['squats']['reps'] = (adjustedRoutine['squats']['reps'] * 0.6).ceil();
          }
          if (analysisResult.affectedExercises.contains('running')) {
            adjustedRoutine['running_minutes'] = (adjustedRoutine['running_minutes'] * 0.6).ceil();
          }

          // 앱 내부 상태(pendingAssessedRoutine)도 업데이트하여 퀘스트 받기 시 반영되도록 함
          pendingAssessedRoutine = adjustedRoutine;
        }

        activePrompt = LlmFitnessConfig.getFeedbackSystemPrompt(
          fitnessLevel, 
          fitnessLevelName,
          detectedBodyParts: detectedBodyParts,
          adjustedRoutine: adjustedRoutine,
          missedYesterdayQuest: day > 1 && !wasYesterdayQuestCompleted,
        );
      } else {
        activePrompt = LlmFitnessConfig.assessmentSystemPrompt;
      }

      List<Map<String, String>> messages = [
        {
          "role": "system",
          "content": "$activePrompt\n[User Profile Context: Name: $userName, Age: $userAge, Height: ${userHeight}cm, Weight: ${userWeight}kg, BMI: ${userBmi.toStringAsFixed(1)}, Goal: $userGoal]"
        }
      ];

      for (var chat in chatHistory) {
        messages.add({
          "role": chat.isUser ? "user" : "assistant",
          "content": chat.text
        });
      }

      final reply = await SolarApiService.sendChatCompletion(messages);
      
      if (reply != null) {
        String? spiritMessage = _processAssessmentJson(reply);
        if (spiritMessage != null) {
          chatHistory.add(ChatMessage(speaker: "정령", text: spiritMessage, isUser: false));
        }
      } else {
        chatHistory.add(ChatMessage(speaker: "시스템", text: "API 응답이 비어있습니다.", isUser: false));
      }
    } catch (e) {
      chatHistory.add(ChatMessage(speaker: "시스템", text: "오류 발생: $e", isUser: false));
    } finally {
      isChatLoading = false;
      notifyListeners();
    }
  }

  String? _processAssessmentJson(String reply) {
    try {
      final RegExp jsonRegExp = RegExp(r'\{[\s\S]*\}');
      final match = jsonRegExp.firstMatch(reply);
      
      if (match != null) {
        String jsonStr = match.group(0)!;
        Map<String, dynamic> data = jsonDecode(jsonStr);
        if (data['is_assessment_complete'] == true) {
          fitnessLevel = data['level'] ?? fitnessLevel;
          fitnessLevelName = data['level_name'] ?? fitnessLevelName;
          isAssessmentComplete = true;
          pendingAssessedRoutine = data['base_routine'];
          
          // JSON에 진단 완료 신호가 오면, 별도의 퀘스트 받기 버튼 없이 자동 적용
          applyAssessedRoutineToQuests();
        }
        return data['spirit_message'];
      } else {
        // [핵심 수정] JSON 블록이 없는 일반 대화 응답인 경우, 마크다운 태그를 제거한 rawText 반환
        return reply.replaceAll(RegExp(r'```json|```'), '').trim();
      }
    } catch (e) {
      debugPrint("Assessment JSON parsing error: $e");
      return "앗, 제가 말을 조금 더듬었네요. 다시 한 번 말씀해 주시겠어요? 😅";
    }
  }

  // --- DEV TOOLS ---
  void devAddGold(int amount) {
    gold += amount;
    notifyListeners();
  }

  void devSetDistance(double dist) {
    distance = dist;
    notifyListeners();
  }

  void devLevelUpStat(String statKey) {
    if (stats.containsKey(statKey)) {
      stats[statKey]!.lv += 1;
      notifyListeners();
    }
  }
}
