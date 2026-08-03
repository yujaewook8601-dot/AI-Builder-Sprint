// ============================================================
// 📦 사용자 컨디션 데이터 모델
// Map<String, dynamic> 대신 타입 안전한 모델 클래스 사용
// ============================================================

enum UserMood { good, neutral, bad }

class UserCondition {
  final int yesterdayCompletionRate; // 0~100
  final int fatigueLevel;            // 1~5
  final List<String> soreness;       // 근육통 부위
  final List<String> injury;         // 부상 부위
  final UserMood mood;
  final double? sleepHours;          // null 허용
  final int consecutiveDays;         // 연속 운동일

  const UserCondition({
    required this.yesterdayCompletionRate,
    required this.fatigueLevel,
    required this.soreness,
    required this.injury,
    required this.mood,
    this.sleepHours,
    required this.consecutiveDays,
  });

  // ✅ 유효성 검증 포함 팩토리 생성자
  factory UserCondition.fromMap(Map<String, dynamic> map) {
    return UserCondition(
      yesterdayCompletionRate: _clampInt(map['yesterday_completion_rate'], 0, 100, 100),
      fatigueLevel:            _clampInt(map['fatigue_level'], 1, 5, 3),
      soreness:  _parseStringList(map['soreness']),
      injury:    _parseStringList(map['injury']),
      mood:      _parseMood(map['mood']),
      sleepHours: map['sleep_hours'] != null
          ? (map['sleep_hours'] as num).toDouble()
          : null,
      consecutiveDays: _clampInt(map['consecutive_days'], 0, 9999, 0),
    );
  }

  Map<String, dynamic> toJson() => {
    'yesterday_completion_rate': yesterdayCompletionRate,
    'fatigue_level':             fatigueLevel,
    'soreness':                  soreness,
    'injury':                    injury,
    'mood':                      mood.name,
    'sleep_hours':               sleepHours,
    'consecutive_days':          consecutiveDays,
  };

  // ── 내부 파싱 헬퍼 ──────────────────────────────────────────
  static int _clampInt(dynamic v, int min, int max, int fallback) {
    if (v == null) return fallback;
    final n = v is int ? v : int.tryParse(v.toString()) ?? fallback;
    return n.clamp(min, max);
  }

  static List<String> _parseStringList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }

  static UserMood _parseMood(dynamic v) {
    switch (v?.toString()) {
      case 'good':    return UserMood.good;
      case 'bad':     return UserMood.bad;
      default:        return UserMood.neutral;
    }
  }
}
