// ============================================================
// 📦 FitnessProfile 모델
// 최초 체력 측정 결과 데이터를 저장하는 모델
// ============================================================

class FitnessProfile {
  final int pushupMax;
  final int squatMax;
  final int runningMaxMinutes;
  final int fitnessLevel; // 1~4

  const FitnessProfile({
    required this.pushupMax,
    required this.squatMax,
    required this.runningMaxMinutes,
    required this.fitnessLevel,
  });

  factory FitnessProfile.fromJson(Map<String, dynamic> json) {
    return FitnessProfile(
      pushupMax: json['pushup_max'] as int? ?? 10,
      squatMax: json['squat_max'] as int? ?? 15,
      runningMaxMinutes: json['running_minutes'] as int? ?? 10,
      fitnessLevel: json['fitness_level'] as int? ?? 1,
    );
  }

  /// 규칙 기반 체력 레벨 판정 (결정론적)
  static int calculateLevel(int pushup, int squat, int running) {
    int pLevel = pushup < 10 ? 1 : (pushup < 20 ? 2 : (pushup < 35 ? 3 : 4));
    int sLevel = squat < 15 ? 1 : (squat < 25 ? 2 : (squat < 40 ? 3 : 4));
    int rLevel = running < 10 ? 1 : (running < 20 ? 2 : (running < 30 ? 3 : 4));

    List<int> levels = [pLevel, sLevel, rLevel];
    int minLevel = levels.reduce((a, b) => a < b ? a : b);
    
    // 가장 낮은 레벨이 1개뿐이라면 평균값으로 보정 (반올림)
    int minCount = levels.where((l) => l == minLevel).length;
    if (minCount == 1) {
      double average = (pLevel + sLevel + rLevel) / 3.0;
      return average.round().clamp(1, 4);
    }
    
    return minLevel;
  }

  Map<String, dynamic> toJson() => {
    'pushup_max': pushupMax,
    'squat_max': squatMax,
    'running_minutes': runningMaxMinutes,
    'fitness_level': fitnessLevel,
  };
}
