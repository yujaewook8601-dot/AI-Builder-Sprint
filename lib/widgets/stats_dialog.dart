import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';

class StatsDialog extends StatelessWidget {
  const StatsDialog({super.key});

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
        "${state.userName}의 능력",
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFA8E6CF), fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.isHydrationDebuffActive)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(8),
                color: const Color(0xFF3D251C),
                child: const Text("⚠️ 갈증 경고: 지구력 -20% 하락 중!", style: TextStyle(color: Color(0xFFFFD29B), fontSize: 12)),
              ),
            if (state.outdoorDebuffActive)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(8),
                color: const Color(0xFF3D251C),
                child: const Text("⚠️ 외출 미완료: 근성 -20% 하락 중!", style: TextStyle(color: Color(0xFFFFD29B), fontSize: 12)),
              ),
            ...state.stats.entries.map((entry) {
              final statKey = entry.key;
              final stat = entry.value;
              final effLv = state.getEffectiveStatLevel(statKey);
              final buffAmount = state.getStatBuffAmount(statKey);
              double percent = (stat.exp / GameState.reqExpPerLevel).clamp(0.0, 1.0);

              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${stat.name} ${buffAmount > 0 ? '(+버프 ${buffAmount}Lv)' : ''}",
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Text("Lv. $effLv (${stat.exp}/${GameState.reqExpPerLevel})", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(width: 5),
                            InkWell(
                              onTap: () => context.read<GameState>().devLevelUpStat(statKey),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text("+1 (Dev)", style: TextStyle(color: Colors.white, fontSize: 10)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: percent,
                      backgroundColor: Colors.black,
                      color: const Color(0xFF9B59B6),
                      minHeight: 10,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("닫기", style: TextStyle(color: Color(0xFFA8E6CF), fontWeight: FontWeight.bold)),
        )
      ],
    );
  }
}
