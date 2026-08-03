enum BodyPart {
  upperBody,
  lowerBody,
  core,
}

class AnalysisResult {
  final bool hasInjury;
  final List<BodyPart> affectedBodyParts;
  final Set<String> affectedExercises;
  final List<String> detectedKeywords;

  AnalysisResult({
    required this.hasInjury,
    required this.affectedBodyParts,
    required this.affectedExercises,
    required this.detectedKeywords,
  });
}

class FeedbackAnalyzerService {
  // 1. 통증 관련 감지 키워드
  static const List<String> painKeywords = [
    '아파', '아픔', '통증', '쑤셔', '쑤심', '삐끗', '관절', '무리', '부상', '다쳤'
  ];

  // 2. 신체 부위 감지 키워드 및 매핑
  static const Map<BodyPart, List<String>> bodyPartKeywords = {
    BodyPart.upperBody: ['어깨', '손목', '팔꿈치', '가슴', '팔', '상체'],
    BodyPart.lowerBody: ['무릎', '발목', '허벅지', '종아리', '하체', '골반'],
    BodyPart.core: ['허리', '코어', '복근', '등'],
  };

  // 3. 신체 부위별 영향받는 운동 종목
  static const Map<BodyPart, List<String>> exerciseImpactMap = {
    BodyPart.upperBody: ['pushups'],
    BodyPart.lowerBody: ['squats', 'running'],
    BodyPart.core: ['plank', 'squats'], // 허리 통증 시 스쿼트도 조심
  };

  static AnalysisResult analyzeFeedback(String text) {
    bool hasPain = false;
    for (var keyword in painKeywords) {
      if (text.contains(keyword)) {
        hasPain = true;
        break;
      }
    }

    List<BodyPart> affectedParts = [];
    Set<String> exercises = {};
    List<String> detected = [];

    // 통증 키워드가 감지된 경우에만 부위 판별을 수행할 수도 있지만,
    // 부위만 말해도 (예: "오늘 무릎이 좀...") 감지할 수 있도록 유연하게 구성
    for (var entry in bodyPartKeywords.entries) {
      for (var keyword in entry.value) {
        if (text.contains(keyword)) {
          if (!affectedParts.contains(entry.key)) {
            affectedParts.add(entry.key);
          }
          detected.add(keyword);
        }
      }
    }

    // 통증 키워드가 직접 감지되었거나, 특정 신체 부위가 언급되었을 때만 발동
    bool hasInjury = hasPain || affectedParts.isNotEmpty;

    if (hasInjury) {
      for (var part in affectedParts) {
        var impacted = exerciseImpactMap[part];
        if (impacted != null) {
          exercises.addAll(impacted);
        }
      }
    }

    return AnalysisResult(
      hasInjury: hasInjury,
      affectedBodyParts: affectedParts,
      affectedExercises: exercises,
      detectedKeywords: detected,
    );
  }

  /// [체력 측정 단계 검증] Pushup, Squat, Running 단계: 숫자가 반드시 포함되어야 함
  static bool validateAssessmentInput(String text) {
    return RegExp(r'\d+').hasMatch(text);
  }

  /// [컨디션 입력 단계 검증] waitCondition 단계: 자유로운 자연어 허용, 의미 없는 특수기호나 빈값만 필터링
  static bool validateConditionInput(String text) {
    // 한글, 영문, 숫자 중 최소 1글자 이상 포함되어 있으면 정상 자연어로 간주하고 LLM에게 파싱 위임
    return RegExp(r'[가-힣a-zA-Z0-9]').hasMatch(text);
  }
}
