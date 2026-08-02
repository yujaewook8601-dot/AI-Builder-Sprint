import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../widgets/sprite_widget.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final List<String> introDialogues = [
    "그날도\n평소와 다르지 않은 하루였습니다.",
    "늦은 밤,\n당신은 깊은 잠에 빠져들었습니다.",
    "...",
    "정체를 알 수 없는 존재가 나타나\n당신에게서\n무언가를 빼앗아 갔습니다.",
    "그리고…\n보이지 않던 것들이 보이기 시작했습니다."
  ];
  
  final List<String> tutorialDialogues = [
    "정령: 드디어\n깨어났네.",
    "주인공: ...?",
    "주인공: 너는...\n누구야?",
    "정령: 나는\n건강의 정령.",
    "정령: 먼저\n미안하다는 말부터 할게.",
    "정령: 네 건강을\n지키지 못했어.",
    "주인공: 내 건강...?",
    "정령: 꿈속에서\n무언가를 빼앗겼던 거\n기억나?",
    "정령: 그게\n바로 너의 건강이야.",
    "정령: 건강을 잃은 순간부터\n현실에는 보이지 않던 존재들이\n모습을 드러내기 시작했어.",
    "주인공: 그럼...\n저 몬스터들은?",
    "정령: 게으름.\n미루는 습관.\n운동하지 않는 하루.",
    "정령: 그런 것들이\n몬스터가 된 모습이야.",
    "정령: 하지만\n걱정하지 마.",
    "정령: 건강은\n되찾을 수 있어.",
    "정령: 다만...\n이 세계에는 한 가지 규칙이 있어.",
    "정령: 이곳에서는\n싸우는 것만으로는 강해질 수 없어.",
    "정령: 네가 현실에서 움직여야만\n이곳의 너도 함께 강해질 수 있어.",
    "정령: 앞으로\n내가 퀘스트를 줄게.",
    "정령: 현실에서 퀘스트를 완료하면\n스탯이 오르고\n몬스터를 이길 힘도 얻게 될 거야.",
    "정령: 그리고 조금씩...\n잃어버린 건강도 되찾을 수 있어.",
    "정령: 준비됐어?"
  ];

  int currentIdx = 0;

  void nextDialogue() {
    final state = context.read<GameState>();
    setState(() {
      if (!state.isIntroDone) {
        if (currentIdx < introDialogues.length - 1) {
          currentIdx++;
        } else {
          state.completeIntro();
          currentIdx = 0;
        }
      } else if (!state.isTutorialDone) {
        if (currentIdx < tutorialDialogues.length - 1) {
          currentIdx++;
        } else {
          state.completeTutorial();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final bool isIntro = !state.isIntroDone;

    String currentText = isIntro ? introDialogues[currentIdx] : tutorialDialogues[currentIdx];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: nextDialogue,
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            constraints: const BoxConstraints(minHeight: 160),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3622),
              border: Border.all(color: const Color(0xFF2D6A38), width: 4),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!isIntro)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 15),
                        child: SpriteWidget(
                          imagePath: 'assets/images/Pink_Monster_Idle_4.png',
                          frameCount: 4,
                          spriteWidth: 56,
                          spriteHeight: 56,
                          scale: 1.5,
                        ),
                      ),
                    Text(
                      currentText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
                const Positioned(
                  bottom: 0,
                  right: 0,
                  child: Icon(Icons.arrow_drop_down, color: Color(0xFFA8E6CF), size: 30),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
