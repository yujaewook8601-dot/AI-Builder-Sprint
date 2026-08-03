import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import 'home_screen.dart';

class EndingScreen extends StatefulWidget {
  const EndingScreen({super.key});

  @override
  State<EndingScreen> createState() => _EndingScreenState();
}

class _EndingScreenState extends State<EndingScreen> {
  int _currentStep = 0;
  bool _isWhiteBg = false;
  bool _showEncouragement = false;
  bool _showStage2Button = false;
  
  final List<String> _lines = [
    "정령은 떠나지 않았습니다",
    "당신의 일부가 되었을 뿐",
    "이 순간을 잊지 말고, 당신의 길을 걸어가세요",
    "THE END"
  ];

  @override
  void initState() {
    super.initState();
    _startEndingSequence();
  }

  void _startEndingSequence() async {
    // 1. Text lines fade in step by step
    for (int i = 0; i < _lines.length; i++) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() {
        _currentStep++;
      });
    }

    // Hold THE END for 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // 2. Transition background from Black to White
    setState(() {
      _isWhiteBg = true;
    });

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // 3. Fade in encouragement text
    setState(() {
      _showEncouragement = true;
    });

    // 4. Wait 1 second and fade in Stage 2 button
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    setState(() {
      _showStage2Button = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 2),
        color: _isWhiteBg ? Colors.white : Colors.black,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(seconds: 1),
            child: !_isWhiteBg
                ? Column(
                    key: const ValueKey("black_lines"),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < _lines.length; i++)
                        AnimatedOpacity(
                          duration: const Duration(seconds: 2),
                          opacity: _currentStep > i ? 1.0 : 0.0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: Text(
                              _lines[i],
                              style: TextStyle(
                                color: i == _lines.length - 1 ? const Color(0xFFFBC531) : Colors.white,
                                fontSize: i == _lines.length - 1 ? 32 : 20,
                                fontWeight: i == _lines.length - 1 ? FontWeight.bold : FontWeight.normal,
                                letterSpacing: i == _lines.length - 1 ? 4.0 : 1.0,
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : Column(
                    key: const ValueKey("white_encouragement"),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(seconds: 2),
                        opacity: _showEncouragement ? 1.0 : 0.0,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            "앞으로의 여정을 응원합니다.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF2C3E50),
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                      AnimatedOpacity(
                        duration: const Duration(seconds: 1),
                        opacity: _showStage2Button ? 1.0 : 0.0,
                        child: ElevatedButton(
                          onPressed: _showStage2Button
                              ? () {
                                  final state = context.read<GameState>();
                                  state.resetToStage(2);
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D6A38),
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                          ),
                          child: const Text(
                            "2스테이지로 가기",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
