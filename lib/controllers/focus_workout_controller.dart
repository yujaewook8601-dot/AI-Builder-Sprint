import 'dart:async';
import 'package:flutter/material.dart';
import '../models/quest.dart';
import '../providers/game_state.dart';

/// ============================================================
/// 🏃 FocusWorkoutController
/// 운동 집중 모드(Focus Mode) 비즈니스 로직 및 타이머 상태 관리 컨트롤러
/// ============================================================
class FocusWorkoutController extends ChangeNotifier {
  // ----------------------------------------------------------
  // 운동 종류별 최소 포커스 유지 시간(초) 설정 상수
  // (현재 3개 운동: pushup / squat / running)
  // ----------------------------------------------------------
  static const Map<String, int> minFocusSecondsPerExercise = {
    'pushup': 10,
    'pushups': 10,
    'squat': 15,
    'squats': 15,
    'running': 60,
  };

  static const int defaultMinFocusSeconds = 10;

  Quest? _activeQuest;
  bool _isFocusMode = false;
  int _remainingSeconds = 0;
  int _totalDurationSeconds = 0;
  Timer? _timer;

  // Getters
  Quest? get activeQuest => _activeQuest;
  bool get isFocusMode => _isFocusMode;
  int get remainingSeconds => _remainingSeconds;
  int get totalDurationSeconds => _totalDurationSeconds;
  bool get canComplete => _remainingSeconds <= 0;

  /// 진행률 (0.0 ~ 1.0)
  double get progress {
    if (_totalDurationSeconds <= 0) return 1.0;
    return (1.0 - (_remainingSeconds / _totalDurationSeconds)).clamp(0.0, 1.0);
  }

  /// 타이머 표시용 MM:SS 텍스트 (예: 00:10, 00:09)
  String get formattedRemainingTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    String minStr = minutes.toString().padLeft(2, '0');
    String secStr = seconds.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }

  /// 운동 ID별 최소 포커스 시간 반환 (확장성 고려)
  int getMinFocusSeconds(String questId) {
    return minFocusSecondsPerExercise[questId.toLowerCase()] ?? defaultMinFocusSeconds;
  }

  /// 1. Focus Mode 진입 & 타이머 시작
  void startWorkout(Quest quest) {
    _activeQuest = quest;
    _isFocusMode = true;

    int duration = getMinFocusSeconds(quest.id);
    _totalDurationSeconds = duration;
    _remainingSeconds = duration;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _timer?.cancel();
        notifyListeners();
      }
    });

    notifyListeners();
  }

  /// 2. 운동 완료 처리 (최소 시간 지난 후 가능)
  void completeWorkout(GameState gameState) {
    if (!canComplete || _activeQuest == null) return;

    _timer?.cancel();
    gameState.completeQuestDirectly(_activeQuest!.id);

    _isFocusMode = false;
    _activeQuest = null;
    _remainingSeconds = 0;
    _totalDurationSeconds = 0;
    notifyListeners();
  }

  /// Focus Mode 강제 취소 (필요시)
  void cancelWorkout() {
    _timer?.cancel();
    _isFocusMode = false;
    _activeQuest = null;
    _remainingSeconds = 0;
    _totalDurationSeconds = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
