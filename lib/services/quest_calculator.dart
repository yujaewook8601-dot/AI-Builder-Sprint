import 'dart:math';
import '../models/quest.dart';
import '../models/fitness_profile.dart';
import '../models/recovery_condition.dart';

// ============================================================
// 🧮 QuestCalculator (결정론적 퀘스트 수량 계산기)
// LLM의 개입 없이 오직 Flutter에서만 퀘스트 수량을 결정합니다.
// Pure Function으로 구성되어 상태를 변경하지 않습니다.
// ============================================================

class QuestCalculator {
  // --- 1. 상수 테이블 ---
  
  static const Map<int, double> _ratioTable = {
    1: 0.60,
    2: 0.65,
    3: 0.70,
    4: 0.75,
  };

  static const Map<int, double> _fatigueMultiplier = {
    1: 1.05,
    2: 1.00,
    3: 0.95,
    4: 0.90,
    5: 0.80,
  };

  static const Map<String, int> _minLimits = {
    'pushup': 5,
    'squat': 8,
    'running': 5,
  };

  static const Map<String, int> _maxLimits = {
    'pushup': 50,
    'squat': 80,
    'running': 40,
  };

  static const Map<String, int> _setsTable = {
    'pushup': 2,
    'squat': 2,
    'running': 1,
  };

  static const Map<SorenessSeverity, double> _sorenessMultiplier = {
    SorenessSeverity.none: 1.0,
    SorenessSeverity.mild: 0.90,
    SorenessSeverity.moderate: 0.70,
    SorenessSeverity.severe: 0.0, // Recovery Quest 변환용
  };

  static const double recoveryQuestXpMultiplier = 0.6;
  static const double normalQuestXpMultiplier = 1.0;

  // --- 2. Pure Function: calculate ---
  
  static List<Quest> calculate({
    required FitnessProfile profile,
    required RecoveryCondition condition,
    required double yesterdayCompletionRate, // 0.0 ~ 1.0
  }) {
    // 1) 완료율 배수 계산
    double completionMultiplier = 1.0;
    if (yesterdayCompletionRate >= 0.90) {
      completionMultiplier = 1.0;
    } else if (yesterdayCompletionRate >= 0.70) {
      completionMultiplier = 1.0;
    } else if (yesterdayCompletionRate >= 0.40) {
      completionMultiplier = 0.95;
    } else {
      completionMultiplier = 0.90;
    }

    // 2) 기본 배수 수집
    double baseRatio = _ratioTable[profile.fitnessLevel] ?? 0.60;
    double fatigueMult = _fatigueMultiplier[condition.fatigueLevel] ?? 1.00;
    double recoveryMult = condition.recoveryMode ? 0.80 : 1.00;

    double globalMultiplier = baseRatio * fatigueMult * recoveryMult * completionMultiplier;

    // 3) 부위별 근육통 파악
    SorenessSeverity upperSeverity = SorenessSeverity.none;
    SorenessSeverity lowerSeverity = SorenessSeverity.none;

    for (var sore in condition.soreness) {
      if (sore.area == BodyArea.upperBody) {
        if (sore.severity.index > upperSeverity.index) upperSeverity = sore.severity;
      } else if (sore.area == BodyArea.lowerBody) {
        if (sore.severity.index > lowerSeverity.index) lowerSeverity = sore.severity;
      }
    }

    // 4) 퀘스트 개별 생성
    List<Quest> quests = [];

    // [Pushup] - UpperBody
    quests.add(_buildQuest(
      id: 'pushup',
      baseTitle: '팔굽혀펴기',
      stat: 'str',
      maxCap: profile.pushupMax,
      globalMult: globalMultiplier,
      severity: upperSeverity,
      recoveryTitle: '어깨·가슴 스트레칭',
      recoveryTarget: 5,
      recoveryUnit: '분',
    ));

    // [Squat] - LowerBody
    quests.add(_buildQuest(
      id: 'squat',
      baseTitle: '스쿼트',
      stat: 'end',
      maxCap: profile.squatMax,
      globalMult: globalMultiplier,
      severity: lowerSeverity,
      recoveryTitle: '하체 스트레칭',
      recoveryTarget: 5,
      recoveryUnit: '분',
    ));

    // [Running] - LowerBody
    quests.add(_buildQuest(
      id: 'running',
      baseTitle: '달리기',
      stat: 'agi',
      maxCap: profile.runningMaxMinutes,
      globalMult: globalMultiplier,
      severity: lowerSeverity,
      recoveryTitle: '가벼운 걷기',
      recoveryTarget: 10,
      recoveryUnit: '분',
    ));

    return quests;
  }

  static Quest _buildQuest({
    required String id,
    required String baseTitle,
    required String stat,
    required int maxCap,
    required double globalMult,
    required SorenessSeverity severity,
    required String recoveryTitle,
    required int recoveryTarget,
    required String recoveryUnit,
  }) {
    if (severity == SorenessSeverity.severe) {
      return Quest(
        id: id,
        title: recoveryTitle,
        target: recoveryTarget,
        sets: 1,
        unit: recoveryUnit,
        stat: stat,
        isRecovery: true,
        expReward: (10 * recoveryQuestXpMultiplier).round(),
      );
    }

    double soreMult = _sorenessMultiplier[severity] ?? 1.0;
    int calculated = (maxCap * globalMult * soreMult).floor();
    
    int minLimit = _minLimits[id] ?? 5;
    int maxLimit = _maxLimits[id] ?? 50;

    int finalTarget = calculated.clamp(minLimit, maxLimit);
    int sets = _setsTable[id] ?? 1;
    String unit = (id == 'running') ? '분' : '회';

    return Quest(
      id: id,
      title: baseTitle,
      target: finalTarget,
      sets: sets,
      unit: unit,
      stat: stat,
      isRecovery: false,
      expReward: (10 * normalQuestXpMultiplier).round(),
    );
  }
}
