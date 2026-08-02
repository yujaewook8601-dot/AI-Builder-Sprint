import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';

class QuestsScreen extends StatelessWidget {
  const QuestsScreen({super.key});

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
    
    return GestureDetector(
      onTap: () {
        if (!q.completed) {
          // simple tap to add +1 to quest for testing
          context.read<GameState>().updateQuest(q.id, 1);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border: Border.all(color: const Color(0xFF2D6A38), width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              padding: const EdgeInsets.all(10),
              color: const Color(0xFF1A3622),
              alignment: Alignment.center,
              child: Text(
                q.completed ? "완료됨" : "진행중",
                style: const TextStyle(color: Color(0xFFA8E6CF), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${q.title} ${q.target}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: percent,
                      backgroundColor: Colors.black,
                      color: const Color(0xFF44BD32),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 5),
                    Text("${q.current} / ${q.target} (탭하여 +1)", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
