import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/focus_workout_controller.dart';
import '../providers/game_state.dart';
import '../services/llm/exercise_tips.dart';
import '../widgets/sprite_widget.dart';

/// ============================================================
/// 🏃 FocusWorkoutWidget
/// 집중 모드(Focus Mode) 전용 UI 위젯
/// - 뒤로가기 gesture / 버튼 비활성화 (PopScope)
/// - 운동별 랜덤 팁 카드 표시
/// - 카운트다운 타이머 및 활성/비활성 "운동 완료" 버튼
/// ============================================================
class FocusWorkoutWidget extends StatefulWidget {
  final VoidCallback onCompleted;

  const FocusWorkoutWidget({
    super.key,
    required this.onCompleted,
  });

  @override
  State<FocusWorkoutWidget> createState() => _FocusWorkoutWidgetState();
}

class _FocusWorkoutWidgetState extends State<FocusWorkoutWidget> {
  String _exerciseTip = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<FocusWorkoutController>();
      if (controller.activeQuest != null) {
        setState(() {
          _exerciseTip = ExerciseTips.getRandom(controller.activeQuest!.id);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FocusWorkoutController>();
    final gameState = context.read<GameState>();
    final quest = controller.activeQuest;

    if (quest == null) return const SizedBox.shrink();

    return PopScope(
      canPop: false, // 🔒 뒤로가기 완전히 비활성화
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1B1E),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Header Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3622),
                    border: Border.all(color: const Color(0xFF2D6A38), width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "🏃 운동 중",
                        style: TextStyle(
                          color: Color(0xFFA8E6CF),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Center Content (Sprite + Title + Tip + Timer + Progress)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pixel Character Sprite
                    const SizedBox(
                      height: 80,
                      child: SpriteWidget(
                        imagePath: 'assets/images/Dude_Monster_Walk_6.png',
                        frameCount: 6,
                        spriteWidth: 56,
                        spriteHeight: 56,
                        scale: 1.6,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Exercise Title & Goal
                    Text(
                      "${quest.title} (${quest.target})",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      "운동에 집중하세요.",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Exercise Tip Box
                    if (_exerciseTip.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3622).withValues(alpha: 0.7),
                          border: Border.all(color: const Color(0xFF2D6A38), width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "💡 팁: $_exerciseTip",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFA8E6CF),
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ),

                    const SizedBox(height: 25),

                    // Countdown Timer Display (MM:SS)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF162521),
                        border: Border.all(color: const Color(0xFF2D6A38), width: 2),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Color(0x75000000), blurRadius: 8, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Text(
                        controller.formattedRemainingTime,
                        style: const TextStyle(
                          color: Color(0xFFA8E6CF),
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Progress Indicator Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: controller.progress,
                        minHeight: 10,
                        backgroundColor: Color(0x75000000),
                        color: const Color(0xFF44BD32),
                      ),
                    ),
                  ],
                ),

                // Bottom Complete Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: controller.canComplete
                          ? const Color(0xFF2D6A38)
                          : const Color(0xFF222222),
                      foregroundColor: controller.canComplete
                          ? Colors.white
                          : Colors.grey,
                      elevation: controller.canComplete ? 6 : 0,
                      side: BorderSide(
                        color: controller.canComplete
                            ? const Color(0xFFA8E6CF)
                            : Colors.grey.shade800,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: controller.canComplete
                        ? () {
                            controller.completeWorkout(gameState);
                            widget.onCompleted();
                          }
                        : null,
                    child: Text(
                      controller.canComplete
                          ? "운동 완료"
                          : "운동 완료 (${controller.formattedRemainingTime})",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: controller.canComplete ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
