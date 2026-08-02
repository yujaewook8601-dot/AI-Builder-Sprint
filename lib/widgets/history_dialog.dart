import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';

class HistoryDialog extends StatefulWidget {
  const HistoryDialog({super.key});

  @override
  State<HistoryDialog> createState() => _HistoryDialogState();
}

class _HistoryDialogState extends State<HistoryDialog> {
  int? selectedDay;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();

    return AlertDialog(
      backgroundColor: const Color(0xFF121212),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFF2D6A38), width: 4),
        borderRadius: BorderRadius.circular(8),
      ),
      title: Text(
        selectedDay == null ? "과거 퀘스트 기록" : "$selectedDay일차 상세 기록",
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFA8E6CF), fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: selectedDay == null
              ? _buildCalendarGrid(state)
              : _buildDayDetail(state, selectedDay!),
        ),
      ),
      actions: [
        if (selectedDay != null)
          TextButton(
            onPressed: () => setState(() => selectedDay = null),
            child: const Text("⬅️ 달력으로 돌아가기", style: TextStyle(color: Color(0xFFFBC531))),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("닫기", style: TextStyle(color: Color(0xFFA8E6CF), fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildCalendarGrid(GameState state) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: state.day,
      itemBuilder: (context, index) {
        int dayNum = index + 1;
        bool isCurrentDay = dayNum == state.day;

        return GestureDetector(
          onTap: () => setState(() => selectedDay = dayNum),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A3622),
              border: Border.all(
                color: isCurrentDay ? const Color(0xFFFBC531) : const Color(0xFF2D6A38),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$dayNum일차",
                  style: const TextStyle(color: Color(0xFFA8E6CF), fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  isCurrentDay ? "☀️ 오늘" : "📜 기록",
                  style: const TextStyle(fontSize: 16),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayDetail(GameState state, int dayNum) {
    bool isCurrentDay = dayNum == state.day;

    if (isCurrentDay) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: state.dailyQuests.map((q) {
          return Card(
            color: const Color(0xFF1A1A1A),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(q.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text("${q.current} / ${q.target}", style: const TextStyle(color: Colors.grey)),
              trailing: Text(
                q.completed ? "✅ 완료" : "⏳ 진행중",
                style: TextStyle(color: q.completed ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),
      );
    }

    // Past Days Sample Quests
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          color: const Color(0xFF1A1A1A),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text("팔굽혀펴기 ${(dayNum - 1) * 5 + 20}개", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            trailing: const Text("✅ 완료", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ),
        Card(
          color: const Color(0xFF1A1A1A),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text("스쿼트 ${(dayNum - 1) * 5 + 30}개", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            trailing: const Text("✅ 완료", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ),
        Card(
          color: const Color(0xFF1A1A1A),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text("야외활동 퀘스트", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            trailing: const Text("✅ 완료", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
