import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../widgets/sprite_widget.dart';
import '../dialogues/dialogues.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final List<String> introDialogues = Dialogues.introDialogues;
  final List<String> tutorialDialogues = Dialogues.tutorialDialogues;

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
          if (!state.isOnboardingDone) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final bool isIntro = !state.isIntroDone;

    String fullLine = isIntro ? introDialogues[currentIdx] : tutorialDialogues[currentIdx];
    String speaker = "";
    String displayText = fullLine;

    if (fullLine.startsWith("정령: ")) {
      speaker = "정령";
      displayText = fullLine.substring(4);
    } else if (fullLine.startsWith("주인공: ")) {
      speaker = "주인공";
      displayText = fullLine.substring(5);
    } else if (fullLine.startsWith("몬스터: ")) {
      speaker = "몬스터";
      displayText = fullLine.substring(5);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: nextDialogue,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Characters Layout (Slime, Hero, Spirit)
              SizedBox(
                height: 250,
                width: MediaQuery.of(context).size.width * 0.9,
                child: Stack(
                  children: [
                    // Slime / Monster (Top Center)
                    Align(
                      alignment: Alignment.topCenter,
                      child: _buildCutsceneCharacter(
                        imagePath: 'assets/images/Walk3.png',
                        frameCount: 8,
                        spriteWidth: 50,
                        spriteHeight: 50,
                        opacity: speaker == "몬스터" ? 1.0 : (speaker.isEmpty ? 1.0 : 0.4),
                        scale: speaker == "몬스터" ? 1.05 : 1.0,
                        baseScale: 3.0,
                        loop: true,
                      ),
                    ),
                    // Hero (Bottom Left)
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: _buildCutsceneCharacter(
                          imagePath: 'assets/images/Dude_Monster_Idle_4.png',
                          frameCount: 4,
                          spriteWidth: 32,
                          spriteHeight: 32,
                          opacity: speaker == "주인공" ? 1.0 : (speaker.isEmpty ? 1.0 : 0.4),
                          scale: speaker == "주인공" ? 1.05 : 1.0,
                          baseScale: 5.5,
                          loop: true,
                        ),
                      ),
                    ),
                    // Spirit (Bottom Right)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: _buildCutsceneCharacter(
                          imagePath: 'assets/images/Pink_Monster_Idle_4.png',
                          frameCount: 4,
                          spriteWidth: 32,
                          spriteHeight: 32,
                          opacity: speaker == "정령" ? 1.0 : (speaker.isEmpty ? 1.0 : 0.4),
                          scale: speaker == "정령" ? 1.05 : 1.0,
                          baseScale: 5.5,
                          loop: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Dialogue Box
              Container(
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
                        if (speaker.isNotEmpty) ...[
                          Text(
                            speaker,
                            style: const TextStyle(
                              color: Color(0xFFFBC531),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        Text(
                          displayText,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCutsceneCharacter({
    required String imagePath,
    required int frameCount,
    required int spriteWidth,
    required int spriteHeight,
    required double opacity,
    required double scale,
    required double baseScale,
    required bool loop,
  }) {
    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 300),
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 300),
        child: SpriteWidget(
          imagePath: imagePath,
          frameCount: frameCount,
          spriteWidth: spriteWidth,
          spriteHeight: spriteHeight,
          scale: baseScale,
          loop: loop,
        ),
      ),
    );
  }
}
