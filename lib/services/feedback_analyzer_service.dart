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

  /// [신규 추가] 딴소리 차단: 사용자의 입력이 운동/퀘스트와 관련이 있는지 확인
  static bool isFitnessRelated(String text, {bool isAssessment = false}) {
    // 띄어쓰기 제거 및 소문자 변환으로 검색 정확도 향상
    String normalizedText = text.replaceAll(' ', '').toLowerCase();

    // 체력 측정 단계일 때만 숫자가 포함된 입력을 유효한 답변으로 처리
    if (isAssessment && RegExp(r'\d+').hasMatch(normalizedText)) {
      return true;
    }

    // 허용 키워드 리스트
    final List<String> keywords = [
      // 운동 종목
      '푸시업', '팔굽혀펴기', '스쿼트', '달리기', '런닝', '러닝', '플랭크', '운동', '훈련', '퀘스트',
      // 신체 부위
      '어깨', '무릎', '코어', '팔', '다리', '허리', '가슴', '등', '근육', '몸',
      // 상태/컨디션
      '아파', '힘들어', '피곤', '좋아', '거뜬', '괜찮', '아프', '힘듦', '쉬웠', '어려',
      '별로', '이상해', '이상하', '못잤', '잠을', '기분', '뻐근', '쑤셔', '결려', '컨디션', '상태',
      // 단위
      '개', '번', '회', '세트', '분', 'km', '킬로미터'
    ];

    // 키워드가 하나라도 포함되어 있으면 true 반환
    for (var keyword in keywords) {
      if (normalizedText.contains(keyword)) {
        return true;
      }
    }
    
    // 관련 키워드가 전혀 없으면 false (딴소리)
    return false;
  }
}
