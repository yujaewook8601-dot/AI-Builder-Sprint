// ============================================================
// 📦 RecoveryCondition 모델 및 관련 Enum
// 매일 분석된 사용자의 컨디션(피로도, 회복 중심 여부, 통증)을 담는 모델
// ============================================================

enum BodyArea {
  upperBody,
  lowerBody
}

enum SorenessSeverity {
  none,
  mild,
  moderate,
  severe
}

class SorenessInfo {
  final BodyArea area;
  final SorenessSeverity severity;

  const SorenessInfo({
    required this.area,
    required this.severity,
  });

  factory SorenessInfo.fromJson(Map<String, dynamic> json) {
    return SorenessInfo(
      area: _parseBodyArea(json['area']?.toString()),
      severity: _parseSeverity(json['severity']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'area': area.name,
    'severity': severity.name,
  };

  static BodyArea _parseBodyArea(String? val) {
    if (val == 'upperBody') return BodyArea.upperBody;
    if (val == 'lowerBody') return BodyArea.lowerBody;
    return BodyArea.upperBody; // 기본값
  }

  static SorenessSeverity _parseSeverity(String? val) {
    if (val == 'mild') return SorenessSeverity.mild;
    if (val == 'moderate') return SorenessSeverity.moderate;
    if (val == 'severe') return SorenessSeverity.severe;
    return SorenessSeverity.none; // 기본값
  }
}

class RecoveryCondition {
  final int fatigueLevel; // 1~5
  final bool recoveryMode;
  final String mood; // 'good', 'neutral', 'bad'
  final List<SorenessInfo> soreness;

  const RecoveryCondition({
    required this.fatigueLevel,
    required this.recoveryMode,
    required this.mood,
    required this.soreness,
  });

  factory RecoveryCondition.fromJson(Map<String, dynamic> json) {
    List<SorenessInfo> parsedSoreness = [];
    if (json['soreness'] is List) {
      parsedSoreness = (json['soreness'] as List)
          .map((e) => SorenessInfo.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return RecoveryCondition(
      fatigueLevel: json['fatigue_level'] as int? ?? 2,
      recoveryMode: json['recovery_mode'] as bool? ?? false,
      mood: json['mood']?.toString() ?? 'neutral',
      soreness: parsedSoreness,
    );
  }

  /// LLM 파싱 실패 시 사용할 기본 Fallback 값
  factory RecoveryCondition.fallback() {
    return const RecoveryCondition(
      fatigueLevel: 2,
      recoveryMode: false,
      mood: 'neutral',
      soreness: [],
    );
  }

  Map<String, dynamic> toJson() => {
    'fatigue_level': fatigueLevel,
    'recovery_mode': recoveryMode,
    'mood': mood,
    'soreness': soreness.map((s) => s.toJson()).toList(),
  };
}
