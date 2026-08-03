import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../controllers/focus_workout_controller.dart';
import '../widgets/focus_workout_widget.dart';
import '../services/llm/exercise_tips.dart';

class QuestsScreen extends StatelessWidget {
  const QuestsScreen({super.key});

  void _startWorkoutFocusMode(BuildContext context, Quest quest) {
    String tip = ExerciseTips.getRandom(quest.id);

    // 💡 1단계: 팁 오버레이 2초 표시 후 집중모드 진입
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future.delayed(const Duration(seconds: 2), () {
          if (dialogContext.mounted) {
            Navigator.pop(dialogContext); // 팁 다이얼로그 닫기
            _enterFocusModeScreen(context, quest);
          }
        });

        return Dialog(
          backgroundColor: const Color(0xFF162521),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFF2D6A38), width: 3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "💡 오늘의 운동 팁",
                  style: TextStyle(
                    color: Color(0xFFFBC531),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  tip.isNotEmpty ? tip : "${quest.title} 훈련에 집중하세요!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Color(0xFFA8E6CF),
                    strokeWidth: 2.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "잠시 후 집중 모드로 전환됩니다...",
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _enterFocusModeScreen(BuildContext context, Quest quest) {
    final focusController = context.read<FocusWorkoutController>();
    focusController.startWorkout(quest);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FocusWorkoutWidget(
          onCompleted: () {
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("🎉 [${quest.title}] 퀘스트 완료! 골드와 경험치를 획득했습니다!"),
                  backgroundColor: const Color(0xFF2D6A38),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("퀘스트 창", style: TextStyle(color: Color(0xFFA8E6CF), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A3622),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFA8E6CF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          const Text("🌟 오늘의 퀘스트", style: TextStyle(color: Color(0xFFFBC531), fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.grey),
          ...state.dailyQuests.map((q) => _buildQuestCard(context, q)),
        ],
      ),
    );
  }

  Widget _buildQuestCard(BuildContext context, Quest q) {
    double percent = q.target > 0 ? (q.current / q.target).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: const Color(0xFF2D6A38), width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 85,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
            color: const Color(0xFF1A3622),
            alignment: Alignment.center,
            child: Text(
              q.completed ? "완료됨" : "진행중",
              style: TextStyle(
                color: q.completed ? Colors.grey : const Color(0xFFA8E6CF),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${q.isRecovery ? '[회복] ' : ''}${q.title} (${q.target}${q.unit} x ${q.sets}세트)",
                    style: TextStyle(
                      color: q.isRecovery ? const Color(0xFFFBC531) : Colors.white, 
                      fontSize: 16, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: percent,
                    backgroundColor: Colors.black,
                    color: const Color(0xFF44BD32),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 6),
                  Text("${q.current} / ${q.target}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: q.completed ? Colors.grey.shade800 : const Color(0xFF2D6A38),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                side: const BorderSide(color: Colors.black, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: q.completed ? null : () => _startWorkoutFocusMode(context, q),
              child: Text(
                q.completed ? "완료" : "운동 시작",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
