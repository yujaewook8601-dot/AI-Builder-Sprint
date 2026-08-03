// ============================================================
// 📦 CoachResponse 모델 (최종)
// ============================================================

class CoachResponse {
  final String coachMessage;

  const CoachResponse({required this.coachMessage});

  factory CoachResponse.fromJson(Map<String, dynamic> json) {
    return CoachResponse(
      coachMessage: json['coach_message']?.toString() ?? '오늘도 함께 힘내서 달려봐요! 화이팅! 😊',
    );
  }

  Map<String, dynamic> toJson() => {
    'coach_message': coachMessage,
  };
}
