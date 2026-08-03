// ============================================================
// 💡 앱 내 운동별 팁 데이터 (ExerciseTips)
// ============================================================

class ExerciseTips {
  static const List<String> pushup = [
    "복부에 힘을 유지해 몸이 일직선이 되도록 하세요.",
    "내려갈 때 2초, 올라올 때 1초 속도를 지켜보세요.",
    "손목을 10초 돌려 관절을 풀고 시작하세요.",
    "팔꿈치가 몸통 바깥으로 너무 벌어지지 않게 하세요.",
    "시선은 바닥을 향해 목이 꺾이지 않도록 하세요.",
  ];

  static const List<String> squat = [
    "무릎이 발끝을 넘지 않도록 의식하세요.",
    "발뒤꿈치가 바닥에서 떨어지지 않게 하세요.",
    "내려갈 때 허벅지가 바닥과 평행이 될 때까지 내려가세요.",
    "올라올 때 엉덩이를 먼저 조이며 일어서세요.",
    "시선은 정면을 유지해 척추가 굽지 않도록 하세요.",
  ];

  static const List<String> running = [
    "처음 3분은 천천히 걸으며 몸을 풀어주세요.",
    "발 앞꿈치보다 발 중간으로 착지하면 무릎 부담이 줄어요.",
    "호흡은 2걸음 들이쉬고 2걸음 내쉬는 리듬을 유지하세요.",
    "팔은 90도로 구부려 앞뒤로 자연스럽게 흔들어주세요.",
    "페이스를 일정하게 유지하는 것이 기록보다 중요해요.",
  ];

  // Shuffle Bag 상태 저장소
  static final Map<String, List<String>> _bags = {};

  /// 셔플 백 기반 팁 선택 (중복 방지)
  static String getRandom(String exerciseId) {
    final key = exerciseId.toLowerCase();
    
    List<String> originalTips;
    if (key == 'pushup' || key == 'pushups' || key == 'q1') {
      originalTips = pushup;
    } else if (key == 'squat' || key == 'squats' || key == 'q2') {
      originalTips = squat;
    } else if (key == 'running' || key == 'q3') {
      originalTips = running;
    } else {
      originalTips = [];
    }

    if (originalTips.isEmpty) return '';

    // 백이 비어있거나 초기화되지 않았다면 다시 채우고 섞음
    if (!_bags.containsKey(key) || _bags[key]!.isEmpty) {
      _bags[key] = List<String>.from(originalTips)..shuffle();
    }

    // 백에서 하나를 꺼냄
    return _bags[key]!.removeLast();
  }

  /// 오늘 퀘스트 전체에서 중복 없이 팁 선택
  static List<String> getTipsForQuests(List<String> questIds) {
    return questIds
        .map((id) => getRandom(id))
        .where((tip) => tip.isNotEmpty)
        .toList();
  }
}
