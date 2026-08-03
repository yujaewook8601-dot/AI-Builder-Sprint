import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../services/llm_fitness_config.dart';
import '../services/solar_api_service.dart';
import '../services/quest_calculator.dart';
import '../models/quest.dart';
import '../models/fitness_profile.dart';
import '../models/recovery_condition.dart';
import '../dialogues/dialogues.dart';
import '../services/feedback_analyzer_service.dart';
import '../services/widget_service.dart';

export '../models/quest.dart';

enum CutsceneType {
  none,
  bossIntro,
  ending,
}

enum AssessmentStep {
  idle,
  waitPushup,
  waitSquat,
  waitRunning,
}

class UserStat {
  String name;
  int lv;
  int exp;
  UserStat({required this.name, this.lv = 1, this.exp = 0});

  Map<String, dynamic> toJson() => {'name': name, 'lv': lv, 'exp': exp};
  factory UserStat.fromJson(Map<String, dynamic> json) => 
      UserStat(name: json['name'], lv: json['lv'] ?? 1, exp: json['exp'] ?? 0);
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

  Map<String, dynamic> toJson() => {
    'id': id, 'stat': stat, 'amount': amount, 'expiresAt': expiresAt.toIso8601String()
  };
  factory Buff.fromJson(Map<String, dynamic> json) => Buff(
    id: json['id'], stat: json['stat'], amount: json['amount'], expiresAt: DateTime.parse(json['expiresAt'])
  );
}

class ChatMessage {
  final String speaker;
  final String text;
  final bool isUser;

  ChatMessage({required this.speaker, required this.text, required this.isUser});

  Map<String, dynamic> toJson() => {'speaker': speaker, 'text': text, 'isUser': isUser};
  factory ChatMessage.fromJson(Map<String, dynamic> json) => 
      ChatMessage(speaker: json['speaker'], text: json['text'], isUser: json['isUser']);
}

class GameState extends ChangeNotifier with WidgetsBindingObserver {
  // Configs
  static const int reqExpPerLevel = 100;
  static const Map<String, int> statRewards = {'str': 20, 'agi': 20, 'end': 20};

  // ----------------------------------------------------
  // 🛡️ 런타임 방어 및 Race Condition 차단 변수
  // ----------------------------------------------------
  bool _isDisposed = false;
  bool isLoaded = false; // 🚀 초기 데이터 로딩 완료 여부
  int _chatRequestId = 0; // Request Token
  String _lastSavedDateStr = "";
  static const int _maxChatHistory = 50;

  Timer? _thirstTimer;
  bool _hasNotifiedWater20 = false;
  String? waterNotificationMessage;

  GameState() {
    WidgetsBinding.instance.addObserver(this);
    _initStorage();
    _startThirstTimer();
  }

  void _startThirstTimer() {
    _thirstTimer?.cancel();
    _thirstTimer = Timer.periodic(const Duration(minutes: 7, seconds: 30), (_) {
      decreaseThirstOverTime(10);
    });
  }

  Future<void> _initStorage() async {
    await loadState();
    _checkDailyReset();
  }

  @override
  void dispose() {
    _thirstTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true;
    super.dispose();
  }

  // ----------------------------------------------------
  // 📱 앱 생명주기 관리 (자동 저장 및 자정 갱신)
  // ----------------------------------------------------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDailyReset();
      _safeNotifyListeners(); // 날짜가 바뀌었을 수 있으므로 UI 갱신
    } else if (state == AppLifecycleState.paused || 
               state == AppLifecycleState.inactive || 
               state == AppLifecycleState.detached) {
      saveState();
    }
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
      WidgetService.updateQuestWidget(dailyQuests);
    }
  }

  void _addChatMessage(ChatMessage message) {
    chatHistory.add(message);
    if (chatHistory.length > _maxChatHistory) chatHistory.removeAt(0);
  }

  // ----------------------------------------------------
  // ⏳ 자정(Midnight) 자동 감지 및 초기화
  // ----------------------------------------------------
  void _checkDailyReset() {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    
    if (_lastSavedDateStr.isNotEmpty && _lastSavedDateStr != todayStr) {
      if (!outdoorCompletedToday) outdoorDebuffActive = true;
      
      yesterdayCompletionRate = dailyQuests.isNotEmpty 
          ? dailyQuests.where((q) => q.completed).length / dailyQuests.length 
          : 0.0;
      
      day++;
      thirst = (thirst - 10).clamp(0, 100);
      outdoorCompletedToday = false;
      dailyQuests.clear(); // 자정 지났으므로 어제 퀘스트 폐기
      todayCondition = null;
      lastQuestGeneratedDate = null; 
      lastChatDate = null;
    }
    _lastSavedDateStr = todayStr;
  }

  // ----------------------------------------------------
  // 💾 완전한 Persistence (저장 로직 통일)
  // ----------------------------------------------------
  Future<void> saveState() async {
    if (_isDisposed) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 스칼라 데이터
      await prefs.setInt('gold', gold);
      await prefs.setInt('level', level);
      await prefs.setInt('exp', exp);
      await prefs.setInt('day', day);
      await prefs.setDouble('distance', distance);
      await prefs.setInt('thirst', thirst);
      await prefs.setString('lastSavedDateStr', _lastSavedDateStr);
      if (lastQuestGeneratedDate != null) {
        await prefs.setInt('lastQuestGeneratedDate', lastQuestGeneratedDate!);
      }
      await prefs.setDouble('yesterdayCompletionRate', yesterdayCompletionRate);
      await prefs.setBool('outdoorCompletedToday', outdoorCompletedToday);
      await prefs.setBool('outdoorDebuffActive', outdoorDebuffActive);

      // 앱 실행 상태 및 유저 정보
      await prefs.setBool('isIntroDone', isIntroDone);
      await prefs.setBool('isTutorialDone', isTutorialDone);
      await prefs.setBool('isOnboardingDone', isOnboardingDone);
      await prefs.setBool('hasAutoOpenedSpiritRoom', hasAutoOpenedSpiritRoom);
      await prefs.setString('userName', userName);
      await prefs.setInt('userAge', userAge);
      await prefs.setDouble('userHeight', userHeight);
      await prefs.setDouble('userWeight', userWeight);
      await prefs.setString('userGoal', userGoal);
      
      // 누락 방지: 복합 객체 직렬화
      await prefs.setString('fitnessProfile', jsonEncode(fitnessProfile?.toJson() ?? {}));
      await prefs.setString('todayCondition', jsonEncode(todayCondition?.toJson() ?? {}));
      await prefs.setString('dailyQuests', jsonEncode(dailyQuests.map((q) => q.toJson()).toList()));
      await prefs.setString('stats', jsonEncode(stats.map((k, v) => MapEntry(k, v.toJson()))));
      
    } catch (e) {
      debugPrint("Save error: $e");
    }
  }

  Future<void> loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      gold = prefs.getInt('gold') ?? 0;
      level = prefs.getInt('level') ?? 1;
      exp = prefs.getInt('exp') ?? 0;
      day = prefs.getInt('day') ?? 1;
      distance = prefs.getDouble('distance') ?? 300.0;
      thirst = prefs.getInt('thirst') ?? 100;
      _lastSavedDateStr = prefs.getString('lastSavedDateStr') ?? DateTime.now().toIso8601String().substring(0, 10);
      lastQuestGeneratedDate = prefs.getInt('lastQuestGeneratedDate');
      yesterdayCompletionRate = prefs.getDouble('yesterdayCompletionRate') ?? 1.0;
      outdoorCompletedToday = prefs.getBool('outdoorCompletedToday') ?? false;
      outdoorDebuffActive = prefs.getBool('outdoorDebuffActive') ?? false;

      isIntroDone = prefs.getBool('isIntroDone') ?? false;
      isTutorialDone = prefs.getBool('isTutorialDone') ?? false;
      isOnboardingDone = prefs.getBool('isOnboardingDone') ?? false;
      hasAutoOpenedSpiritRoom = prefs.getBool('hasAutoOpenedSpiritRoom') ?? false;
      
      userName = prefs.getString('userName') ?? "용사";
      userAge = prefs.getInt('userAge') ?? 25;
      userHeight = prefs.getDouble('userHeight') ?? 175.0;
      userWeight = prefs.getDouble('userWeight') ?? 70.0;
      userGoal = prefs.getString('userGoal') ?? "근력 강화";

      final fpStr = prefs.getString('fitnessProfile');
      if (fpStr != null && fpStr != "{}") {
        fitnessProfile = FitnessProfile.fromJson(jsonDecode(fpStr));
      }
      final condStr = prefs.getString('todayCondition');
      if (condStr != null && condStr != "{}") {
        todayCondition = RecoveryCondition.fromJson(jsonDecode(condStr));
      }
      final questsStr = prefs.getString('dailyQuests');
      if (questsStr != null) {
        final List<dynamic> qList = jsonDecode(questsStr);
        dailyQuests = qList.map((q) => Quest.fromJson(q)).toList();
      }
      final statsStr = prefs.getString('stats');
      if (statsStr != null) {
        final Map<String, dynamic> sMap = jsonDecode(statsStr);
        stats = sMap.map((k, v) => MapEntry(k, UserStat.fromJson(v)));
      }

      isLoaded = true; // 🚀 로딩 완료 플래그 활성화
      _safeNotifyListeners();
    } catch (e) {
      debugPrint("Load error: $e");
      isLoaded = true; // 에러가 나더라도 로딩은 끝난 것으로 처리
      _safeNotifyListeners();
    }
  }
  
  // App State
  bool isIntroDone = false;
  bool isTutorialDone = false;
  bool isOnboardingDone = false;
  bool hasAutoOpenedSpiritRoom = false;

  bool get isDailyQuestsCompleted => dailyQuests.isNotEmpty && dailyQuests.every((q) => q.completed);

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

  // RPG State
  int day = 1;
  int gold = 0;
  int level = 1;
  int exp = 0;
  double distance = 300.0;
  int thirst = 100;
  bool hasPet = false;
  String activePet = "";

  // ----------------------------------------------------
  // 리팩토링 아키텍처 상태 필드
  // ----------------------------------------------------
  FitnessProfile? fitnessProfile;
  RecoveryCondition? todayCondition;
  
  AssessmentStep assessmentStep = AssessmentStep.idle;
  
  int? pushupValue;
  int? squatValue;
  int? runningValue;

  int? lastQuestGeneratedDate; 
  int? lastChatDate;
  double yesterdayCompletionRate = 1.0; 

  bool get isAssessmentComplete => fitnessProfile != null;
  bool get isDailyConversationDone => isAssessmentComplete && lastQuestGeneratedDate == day;

  int get fitnessLevel => fitnessProfile?.fitnessLevel ?? 1;
  String get fitnessLevelName {
    switch (fitnessLevel) {
      case 1: return "초급";
      case 2: return "중급";
      case 3: return "고급";
      case 4: return "엘리트";
      default: return "초급";
    }
  }

  Map<String, UserStat> stats = {
    'str': UserStat(name: '💪 근력'),
    'agi': UserStat(name: '⚡ 민첩'),
    'end': UserStat(name: '🛡️ 지구력'),
  };

  List<Quest> dailyQuests = [];
  bool outdoorCompletedToday = false;
  bool outdoorDebuffActive = false;
  List<Buff> activeBuffs = [];

  List<ChatMessage> chatHistory = [];
  bool isChatLoading = false;

  void buyPet(String petType) {
    hasPet = true;
    activePet = petType;
    notifyListeners();
  }

  void decreaseDistance([double amount = 0.1]) {
    if (distance > 0) {
      distance = double.parse((distance - amount).toStringAsFixed(1));
      if (distance <= 0) distance = 0.0;
      notifyListeners();
    }
  }

  void initSpiritGreeting() {
    if (lastChatDate != day) {
      chatHistory.clear();
      lastChatDate = day;
    }

    if (!isAssessmentComplete) {
      if (chatHistory.isEmpty) {
        assessmentStep = AssessmentStep.waitPushup;
        _addChatMessage(
          ChatMessage(
            speaker: "정령",
            text: "안녕하세요, $userName 님! 함께 운동하게 되어 정말 기뻐요 😊\n딱 맞는 맞춤형 퀘스트를 드리기 위해 체력을 먼저 확인해볼게요.\n가장 먼저, 푸시업은 최대 몇 번 하실 수 있나요?",
            isUser: false,
          ),
        );
        _safeNotifyListeners();
      }
    } else {
      if (chatHistory.isEmpty || (chatHistory.isNotEmpty && chatHistory.last.isUser)) {
        String greeting;
        if (day > 1 && yesterdayCompletionRate < 1.0) {
          greeting = "이런, $userName 님! 어제는 퀘스트를 다 끝내지 못하셨군요 😢\n오늘은 어제 몫까지 더 열심히 해볼까요? 오늘 컨디션은 좀 어떠신가요? (예: 허벅지가 아파요, 피곤해요 등)";
        } else {
          greeting = "안녕하세요, $userName 님! 다시 오셨군요 😊\n몸이 뻐근하거나 아픈 곳은 없는지, 오늘 컨디션은 어떤지 편하게 이야기해 주세요!";
        }
        
        _addChatMessage(
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
    fitnessProfile = null;
    assessmentStep = AssessmentStep.waitPushup;
    pushupValue = null;
    squatValue = null;
    runningValue = null;
    
    _addChatMessage(
      ChatMessage(
        speaker: "정령",
        text: "좋아요, $userName 님! 체력 수준을 다시 꼼꼼하게 체크해볼게요.\n가장 먼저, 푸시업은 최대 몇 번 하실 수 있나요?",
        isUser: false,
      ),
    );
    _safeNotifyListeners();
  }

  void cancelAssessment() {
    assessmentStep = AssessmentStep.idle;
    pushupValue = null;
    squatValue = null;
    runningValue = null;
    chatHistory.clear();
    _chatRequestId++; // 진행 중인 LLM 응답 무효화
    _safeNotifyListeners();
  }

  void completeIntro() {
    isIntroDone = true;
    unawaited(saveState());
    _safeNotifyListeners();
  }

  void completeTutorial() {
    isTutorialDone = true;
    unawaited(saveState());
    _safeNotifyListeners();
  }

  void completeOnboarding(String name, int age, double height, double weight, String levelDesc, String goal) {
    userName = name;
    userAge = age;
    userHeight = height;
    userWeight = weight;
    userGoal = goal;
    isOnboardingDone = true;
    unawaited(saveState());
    _safeNotifyListeners();
  }

  void markSpiritRoomOpened() {
    hasAutoOpenedSpiritRoom = true;
    unawaited(saveState());
    _safeNotifyListeners();
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

  double calculateHeroDamage() {
    return 20.0 + getEffectiveStatLevel('str') + (getEffectiveStatLevel('end') * 0.5);
  }

  int calculateHeroAttackIntervalMs() {
    double speedMultiplier = 1.0 + (getEffectiveStatLevel('agi') * 0.02) + (getEffectiveStatLevel('end') * 0.01);
    int intervalMs = (1500 / speedMultiplier).round();
    return intervalMs < 500 ? 500 : intervalMs; 
  }

  void decreaseThirstOverTime([int amount = 10]) {
    if (_isDisposed) return;
    int oldThirst = thirst;
    thirst = (thirst - amount).clamp(0, 100);

    if (thirst <= 20 && thirst > 0 && (oldThirst > 20 || !_hasNotifiedWater20)) {
      _hasNotifiedWater20 = true;
      waterNotificationMessage = "💧 물 마실 시간입니다!";
    } else if (thirst == 0 && (oldThirst > 0 || !_hasNotifiedWater20)) {
      _hasNotifiedWater20 = true;
      waterNotificationMessage = "💧 물 마실 시간입니다! (갈증 0% - 능력치 게이지 감소 중)";
    }

    if (thirst == 0) {
      decreaseAllStatsExp(1);
    }

    _safeNotifyListeners();
  }

  void drinkWater() {
    if (thirst < 100) {
      thirst = (thirst + 20).clamp(0, 100);
      if (thirst > 20) {
        _hasNotifiedWater20 = false;
      }
      waterNotificationMessage = null;
      notifyListeners();
    }
  }

  void gainGlobalExp([int? amount]) {
    exp += (amount ?? 1);
    while (exp >= 5) {
      level++;
      exp -= 5;
    }
    notifyListeners();
  }



  void completeQuestDirectly(String questId) {
    _checkDailyReset(); 
    final idx = dailyQuests.indexWhere((q) => q.id == questId);
    if (idx != -1) {
      var q = dailyQuests[idx];
      q.current = q.target;
      if (!q.completed) {
        q.completed = true;
        gold += 10;
        gainGlobalExp(1);
        gainStatExp(q.stat, q.expReward);
        saveState(); 
      }
      _safeNotifyListeners();
    }
  }

  void completeOutdoorQuest() {
    if (!outdoorCompletedToday) {
      outdoorCompletedToday = true;
      outdoorDebuffActive = false;
      gold += 20;
      gainGlobalExp(1);
      notifyListeners();
    }
  }

  void nextDay() {
    if (!outdoorCompletedToday) {
      outdoorDebuffActive = true;
    }
    if (dailyQuests.isNotEmpty) {
      int completedCount = dailyQuests.where((q) => q.completed).length;
      yesterdayCompletionRate = completedCount / dailyQuests.length;
    } else {
      yesterdayCompletionRate = 0.0;
    }
    
    day++;
    thirst = (thirst - 10).clamp(0, 100);
    outdoorCompletedToday = false;
    dailyQuests.clear(); // 퀘스트는 정령과 대화 후 발급
    todayCondition = null;
    notifyListeners();
  }

  void gainStatExp(String statKey, [int? amount]) {
    if (!stats.containsKey(statKey)) return;
    int expAmount = amount ?? statRewards[statKey] ?? 20;
    final stat = stats[statKey]!;

    stat.exp += expAmount;
    while (stat.exp >= reqExpPerLevel) {
      stat.lv += 1;
      stat.exp -= reqExpPerLevel;
      level += 1;
    }
    notifyListeners();
  }

  void decreaseAllStatsExp(int amount) {
    for (var stat in stats.values) {
      if (stat.exp >= amount) {
        stat.exp -= amount;
      } else {
        if (stat.lv > 1) {
          stat.lv -= 1;
          stat.exp = reqExpPerLevel - (amount - stat.exp);
        } else {
          stat.exp = 0;
        }
      }
    }
  }

  void buyItem(int price, Function onBuy) {
    _checkDailyReset();
    if (gold >= price) {
      gold -= price;
      onBuy();
      notifyListeners();
    }
  }

  void addGold(int amount) {
    gold += amount;
    notifyListeners();
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

  // ----------------------------------------------------
  // 채팅 및 정령의 방 대화 관리
  // ----------------------------------------------------
  Future<void> sendChatMessage(String message) async {
    if (message.trim().isEmpty) return;
    if (isChatLoading) return; // Race Condition 및 중복 입력 차단 (SSOT)

    _checkDailyReset(); 

    _addChatMessage(ChatMessage(speaker: userName, text: message, isUser: true));
    _safeNotifyListeners();

    if (isAssessmentComplete && lastQuestGeneratedDate == day) {
      // 퀘스트가 이미 발급되어 정령이 사라진 상태라면 Companion Chat 실행
    }

    isChatLoading = true;
    final int currentRequestId = ++_chatRequestId; // 🚀 토큰 발급
    _safeNotifyListeners();

    try {
      if (!isAssessmentComplete) {
        await _handleFitnessAssessment(message, currentRequestId);
      } else if (lastQuestGeneratedDate == day) {
        await _handleCompanionChat(message, currentRequestId);
      } else {
        await _handleConditionAnalysis(message);
      }
    } catch (e) {
      if (_isDisposed || currentRequestId != _chatRequestId) return; 
      
      _addChatMessage(ChatMessage(
        speaker: "정령", 
        text: SpiritErrorMessages.getMessage(e), 
        isUser: false
      ));
    } finally {
      if (!_isDisposed && currentRequestId == _chatRequestId) {
        isChatLoading = false;
        unawaited(saveState()); // 🚀 Fire and Forget 비동기 저장 명시
        _safeNotifyListeners();
      }
    }
  }

  // ----------------------------------------------------
  // 채팅 및 퀘스트 발급 플로우 (LLM 판단 -> Flutter 계산)
  // ----------------------------------------------------
  Future<void> _handleFitnessAssessment(String message, int requestId) async {
    if (!FeedbackAnalyzerService.isFitnessRelated(message, isAssessment: true)) {
      String replyText = "지금은 체력 측정 중입니다.";
      if (assessmentStep == AssessmentStep.waitPushup) {
        replyText = "지금은 푸시업 최대 횟수만 알려주세요.";
      } else if (assessmentStep == AssessmentStep.waitSquat) {
        replyText = "지금은 스쿼트 최대 횟수만 알려주세요.";
      } else if (assessmentStep == AssessmentStep.waitRunning) {
        replyText = "지금은 달리기 가능한 시간을 알려주세요.";
      }
      _addChatMessage(ChatMessage(speaker: "정령", text: replyText, isUser: false));
      return; // 상태 변경 없이 현재 WAIT 상태 유지
    }

    int? extractedValue;

    try {
      final prompt = LlmFitnessConfig.fitnessAssessmentPrompt;
      final reply = await SolarApiService.sendChatCompletion([
        {"role": "system", "content": prompt},
        {"role": "user", "content": message}
      ], temperature: 0.1, topP: 0.85).timeout(const Duration(seconds: 10));

      if (_isDisposed || requestId != _chatRequestId) return;

      if (reply != null) {
        final jsonStr = _extractJson(reply);
        if (jsonStr != null) {
          final data = jsonDecode(jsonStr);
          if (data['value'] != null && data['value'] is int) {
            extractedValue = data['value'] as int;
          }
        }
      }
    } catch (e) {
      if (_isDisposed || requestId != _chatRequestId) return;
      _addChatMessage(ChatMessage(speaker: "정령", text: "응답이 너무 늦어지고 있어요. 숫자를 한 번만 다시 입력해 주시겠어요?", isUser: false));
      return; // 상태 변경 없이 현재 WAIT 상태 유지
    }

    if (extractedValue == null) {
      _addChatMessage(ChatMessage(
        speaker: "정령",
        text: "정확한 숫자를 찾지 못했어요. 푸시업, 스쿼트, 달리기 중 현재 질문에 해당하는 숫자만 다시 입력해 주시겠어요?",
        isUser: false,
      ));
      return; // 상태 변경 없이 현재 WAIT 상태 유지
    }

    if (assessmentStep == AssessmentStep.waitPushup) {
      if (extractedValue < 1 || extractedValue > 200) {
        _addChatMessage(ChatMessage(speaker: "정령", text: "푸시업 개수가 범위를 벗어난 것 같아요 (1~200). 다시 한 번 말씀해 주시겠어요?", isUser: false));
        return;
      }
      pushupValue = extractedValue;
      assessmentStep = AssessmentStep.waitSquat;
      _addChatMessage(ChatMessage(speaker: "정령", text: "푸시업 ${extractedValue}번! 기록했어요. 다음으로 스쿼트는 최대 몇 번 하실 수 있나요?", isUser: false));
      
    } else if (assessmentStep == AssessmentStep.waitSquat) {
      if (extractedValue < 1 || extractedValue > 300) {
        _addChatMessage(ChatMessage(speaker: "정령", text: "스쿼트 개수가 범위를 벗어난 것 같아요 (1~300). 다시 한 번 말씀해 주시겠어요?", isUser: false));
        return;
      }
      squatValue = extractedValue;
      assessmentStep = AssessmentStep.waitRunning;
      _addChatMessage(ChatMessage(speaker: "정령", text: "스쿼트 ${extractedValue}번! 좋습니다. 마지막으로 달리기는 쉬지 않고 몇 분 정도 가능하신가요?", isUser: false));
      
    } else if (assessmentStep == AssessmentStep.waitRunning) {
      if (extractedValue < 1 || extractedValue > 60) {
        _addChatMessage(ChatMessage(speaker: "정령", text: "달리기 시간이 범위를 벗어난 것 같아요 (1~60분). 다시 한 번 말씀해 주시겠어요?", isUser: false));
        return;
      }
      runningValue = extractedValue;
      
      if (pushupValue != null && squatValue != null && runningValue != null) {
        int calculatedLevel = FitnessProfile.calculateLevel(pushupValue!, squatValue!, runningValue!);

        fitnessProfile = FitnessProfile(
          pushupMax: pushupValue!,
          squatMax: squatValue!,
          runningMaxMinutes: runningValue!,
          fitnessLevel: calculatedLevel,
        );
        
        assessmentStep = AssessmentStep.idle; // 🚀 완료 직후 IDLE로 복귀하여 깔끔한 상태 유지
        
        _addChatMessage(ChatMessage(
          speaker: "정령",
          text: "달리기 ${extractedValue}분까지 모두 확인했어요! 현재 체력을 바탕으로 오늘의 퀘스트를 준비해 볼게요. 이제 오늘 컨디션은 어떠신지 편하게 말씀해 주세요.",
          isUser: false,
        ));
      } else {
        _addChatMessage(ChatMessage(speaker: "정령", text: "입력 정보가 누락되었어요. 안전을 위해 처음부터 다시 진행할게요.", isUser: false));
        resetAssessment();
      }
    }
  }

  Future<void> _handleConditionAnalysis(String message) async {
    if (!FeedbackAnalyzerService.isFitnessRelated(message, isAssessment: false)) {
      _addChatMessage(ChatMessage(
        speaker: "정령",
        text: "오늘 운동과 관련된 이야기나 현재 상태를 알려주세요.",
        isUser: false,
      ));
      return;
    }

    // 1. 컨디션 분석 (LLM #2)
    final prompt = LlmFitnessConfig.conditionAnalyzerPrompt;
    double completionRate = yesterdayCompletionRate;
    
    final conditionReply = await SolarApiService.sendChatCompletion([
      {"role": "system", "content": prompt},
      {"role": "user", "content": "[Yesterday Completion Rate: ${(completionRate * 100).toInt()}%] User says: $message"}
    ], temperature: 0.2, topP: 0.9);

    RecoveryCondition condition = RecoveryCondition.fallback();
    if (conditionReply != null) {
      final jsonStr = _extractJson(conditionReply);
      if (jsonStr != null) {
        try {
          condition = RecoveryCondition.fromJson(jsonDecode(jsonStr));
        } catch (e) {
          debugPrint("Condition JSON parse error, using fallback. Error: $e");
        }
      }
    }

    todayCondition = condition;

    // 2. Flutter 퀘스트 수량 계산기 실행
    final calculatedQuests = QuestCalculator.calculate(
      profile: fitnessProfile!,
      condition: condition,
      yesterdayCompletionRate: completionRate,
    );

    // 3. 퀘스트 RPG 장식 (LLM #3)
    final questsJsonData = calculatedQuests.map((q) => {
      'id': q.id,
      'target': q.target,
      'sets': q.sets,
      'unit': q.unit,
      'isRecovery': q.isRecovery
    }).toList();

    final contextJsonData = {
      "condition": {
        "fatigue_level": condition.fatigueLevel,
        "recovery_mode": condition.recoveryMode,
        "mood": condition.mood
      },
      "quests": questsJsonData
    };

    final decoratorPrompt = LlmFitnessConfig.getQuestDecoratorPrompt(jsonEncode(contextJsonData));
    final decoratorReply = await SolarApiService.sendChatCompletion([
      {"role": "system", "content": decoratorPrompt},
      {"role": "user", "content": "오늘의 컨디션과 퀘스트 목표를 바탕으로, 아직 운동을 시작하지 않은 사용자에게 부담 없이 시작할 수 있도록 응원하고 첫걸음에 의미를 부여하는 따뜻한 격려 메시지를 작성해주세요. (절대 과거형으로 완료를 칭찬하지 마세요.)"}
    ], temperature: 0.6, topP: 0.95);

    String encouragement = "오늘도 무리하지 말고 시작해 볼까요?";
    if (decoratorReply != null) {
      final jsonStr = _extractJson(decoratorReply);
      if (jsonStr != null) {
        try {
          final data = jsonDecode(jsonStr);
          encouragement = data['encouragement'] ?? encouragement;
          
          final closing = data['closing_message'];
          if (closing != null && closing is String && closing.trim().isNotEmpty) {
            encouragement += "\n\n$closing";
          }
        } catch (_) {}
      }
    }

    dailyQuests = calculatedQuests;
    lastQuestGeneratedDate = day;

    chatHistory.add(ChatMessage(
      speaker: "정령",
      text: encouragement,
      isUser: false,
    ));
  }

  Future<void> _handleCompanionChat(String message, int requestId) async {
    final prompt = LlmFitnessConfig.companionChatPrompt;
    final reply = await SolarApiService.sendChatCompletion([
      {"role": "system", "content": prompt},
      {"role": "user", "content": message}
    ], temperature: 0.7, topP: 0.9);

    if (_isDisposed || requestId != _chatRequestId) return;

    if (reply != null) {
      _addChatMessage(ChatMessage(
        speaker: "AI 가이드",
        text: reply,
        isUser: false,
      ));
    }
  }

  String? _extractJson(String text) {
    // 1순위: Markdown JSON 코드블록
    final mdMatch = RegExp(
      r'```(?:json)?\s*(\{[\s\S]*?\})\s*```',
    ).firstMatch(text);

    if (mdMatch != null) {
      return mdMatch.group(1)?.trim();
    }

    // 2순위: 텍스트 내부 JSON 객체
    final jsonMatch = RegExp(
      r'\{[\s\S]*\}',
    ).firstMatch(text);

    return jsonMatch?.group(0)?.trim();
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

  void resetToStage(int stageNum) {
    if (stageNum == 2) {
      distance = 200.0;
    } else if (stageNum == 1) {
      distance = 300.0;
    } else if (stageNum == 3) {
      distance = 100.0;
    }
    _safeNotifyListeners();
    saveState();
  }

  void devResetAllToOpening() async {
    isIntroDone = false;
    isTutorialDone = false;
    isOnboardingDone = false;
    hasAutoOpenedSpiritRoom = false;
    distance = 300.0;
    gold = 0;
    level = 1;
    exp = 0;
    thirst = 100;
    day = 1;
    
    // Reset all stats & EXP
    stats = {
      'str': UserStat(name: '💪 근력', lv: 1, exp: 0),
      'agi': UserStat(name: '⚡ 민첩', lv: 1, exp: 0),
      'end': UserStat(name: '🛡️ 지구력', lv: 1, exp: 0),
    };
    
    // Reset quests, condition, assessment, chat, pets
    dailyQuests = [];
    fitnessProfile = null;
    todayCondition = null;
    assessmentStep = AssessmentStep.idle;
    pushupValue = null;
    squatValue = null;
    runningValue = null;
    chatHistory.clear();
    lastChatDate = null;
    lastQuestGeneratedDate = null;
    hasPet = false;
    activePet = "";
    outdoorCompletedToday = false;
    outdoorDebuffActive = false;

    await saveState();
    _safeNotifyListeners();
  }

  void devLevelUpStat(String statKey) {
    if (stats.containsKey(statKey)) {
      stats[statKey]!.lv++;
      _safeNotifyListeners();
    }
  }

  void devCompleteAllQuests() {
    if (dailyQuests.isNotEmpty) {
      for (var q in dailyQuests) {
        q.completed = true;
        q.current = q.target; // Set progress to max
      }
      _safeNotifyListeners();
    }
  }
}

class SpiritErrorMessages {
  static final _random = Random();

  static const List<String> timeoutMessages = Dialogues.timeoutMessages;
  static const List<String> networkMessages = Dialogues.networkMessages;
  static const List<String> parseMessages = Dialogues.parseMessages;
  static const List<String> unknownMessages = Dialogues.unknownMessages;

  static String getMessage(Object error) {
    if (error is LlmTimeoutException) {
      return timeoutMessages[_random.nextInt(timeoutMessages.length)];
    } else if (error is LlmNetworkException) {
      return networkMessages[_random.nextInt(networkMessages.length)];
    }

    String errorString = error.toString().toLowerCase();
    if (errorString.contains('json') || errorString.contains('parse') || errorString.contains('format')) {
      return parseMessages[_random.nextInt(parseMessages.length)];
    } else {
      return unknownMessages[_random.nextInt(unknownMessages.length)];
    }
  }
}
