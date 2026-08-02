import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/scheduler.dart';
import '../providers/game_state.dart';
import '../widgets/sprite_widget.dart';
import 'quests_screen.dart';
import 'training_screen.dart';
import 'outdoor_screen.dart';
import 'shop_screen.dart';
import '../widgets/stats_dialog.dart';
import '../widgets/history_dialog.dart';
import '../widgets/scrolling_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  double _bgX = 0.0;
  double _monsterRight = -100.0;
  String _heroState = 'walk';
  String _monsterState = 'walk';
  double _monsterHp = 100.0;
  final double _monsterMaxHp = 100.0;
  bool _isEngaged = false;
  bool _isResetting = false;
  int _currentStage = 1;
  bool _showStagePopup = false;
  String _popupText = '';
  Duration _lastTime = Duration.zero;
  late Ticker _ticker;
  
  Timer? _attackTimer;
  Timer? _respawnTimer;
  final List<Map<String, dynamic>> _floatingDamages = [];
  final Map<int, double> _aspectRatios = {1: 987/292, 2: 1920/1080};

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_gameLoop)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheAndGetRatios();
      _spawnMonster();
    });
  }

  void _precacheAndGetRatios() {
    final s1 = const AssetImage('assets/images/stage1.png');
    final s2 = const AssetImage('assets/images/stage2.png');
    
    precacheImage(s1, context);
    precacheImage(s2, context);
    
    s1.resolve(const ImageConfiguration()).addListener(ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _aspectRatios[1] = info.image.width / info.image.height;
        });
      }
    }));
    s2.resolve(const ImageConfiguration()).addListener(ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _aspectRatios[2] = info.image.width / info.image.height;
        });
      }
    }));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _attackTimer?.cancel();
    _respawnTimer?.cancel();
    super.dispose();
  }

  void _gameLoop(Duration elapsed) {
    if (!mounted) return;
    
    double dt = (elapsed - _lastTime).inMilliseconds / 16.666;
    _lastTime = elapsed;
    if (dt > 10) dt = 1.0;
    
    if (!_isEngaged) {
      setState(() {
        _bgX -= 1.5 * dt;
      });
    }
  }

  void _spawnMonster() {
    if (!mounted) return;
    setState(() {
      _monsterHp = _monsterMaxHp;
      _monsterState = 'walk';
      _heroState = 'walk';
      _isEngaged = false;
      _isResetting = true;
      _monsterRight = -100.0; 
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() {
        _isResetting = false;
        _monsterRight = MediaQuery.of(context).size.width - 180.0;
      });
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _startCombat();
      });
    });
  }

  void _startCombat() {
    if (!mounted) return;
    setState(() {
      _isEngaged = true;
    });
    
    final state = context.read<GameState>();
    int intervalMs = state.calculateHeroAttackIntervalMs();

    _attackTimer?.cancel();
    _attackTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _executeAttack();
    });
  }

  void _executeAttack() {
    final state = context.read<GameState>();
    double damage = state.calculateHeroDamage();

    setState(() {
      _heroState = 'attack';
      _monsterHp -= damage;
      if (_monsterHp < 0) _monsterHp = 0;
      _monsterState = 'hurt';
      _showFloatingDamage(damage.toInt());
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          if (_monsterHp <= 0) {
            _monsterState = 'dead';
            _isEngaged = false;
          } else {
            _monsterState = 'walk';
          }
          _heroState = 'walk';
        });
      }
    });

    if (_monsterHp <= 0) {
      _attackTimer?.cancel();
      _respawnTimer?.cancel();
      
      state.decreaseDistance();
      _checkStageTransition(state.distance);
      
      _respawnTimer = Timer(const Duration(milliseconds: 1500), () {
        _spawnMonster();
      });
    }
  }

  void _checkStageTransition(double distance) {
    int newStage = 1;
    String stageName = '침대의 숲';
    if (distance <= 200) {
      newStage = 2;
      stageName = '알코올의 늪';
    }
    
    if (newStage != _currentStage) {
      setState(() {
        _currentStage = newStage;
        _showStagePopup = true;
        _popupText = '[Stage $newStage]\n$stageName';
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showStagePopup = false;
          });
        }
      });
    }
  }

  void _showFloatingDamage(int dmg) {
    final key = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _floatingDamages.add({'key': key, 'dmg': dmg});
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _floatingDamages.removeWhere((item) => item['key'] == key);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();

    String bgImage = 'assets/images/stage1.png';
    String mobName = '이불 슬라임';
    
    if (_currentStage == 2) {
      bgImage = 'assets/images/stage2.png';
      mobName = '숙취 슬라임';
    }

    double currentRatio = _aspectRatios[_currentStage] ?? (1920/1080);
    double charBottom = _currentStage == 1 ? 15.0 : 40.0;
    double petBottom = _currentStage == 1 ? 20.0 : 45.0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(10, 25, 15, 0.85),
                border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(context: context, builder: (_) => const HistoryDialog());
                    },
                    child: Text(
                      "☀️ ${state.day}일차",
                      style: const TextStyle(
                        color: Color(0xFFA8E6CF),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text("💰 ${state.gold} G", style: const TextStyle(color: Color(0xFFA8E6CF), fontSize: 13, fontWeight: FontWeight.bold)),
                  Text("🚩 ${state.distance}km", style: const TextStyle(color: Color(0xFFA8E6CF), fontSize: 13, fontWeight: FontWeight.bold)),
                  Text("💧 ${state.thirst}%", style: TextStyle(color: state.isHydrationDebuffActive ? Colors.red : const Color(0xFF00A8FF), fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            // Main Animation Area
            Expanded(
              child: Stack(
                children: [
                  // Background
                  Positioned.fill(
                    child: ScrollingBackground(
                      imagePath: bgImage,
                      bgX: _bgX,
                      aspectRatio: currentRatio,
                    ),
                  ),
                  
                  // HUD Left (Stats)
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(10, 25, 15, 0.85),
                        border: Border.all(color: const Color(0xFF2D6A38), width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("💪 Lv.${state.getEffectiveStatLevel('str')}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("⚡ Lv.${state.getEffectiveStatLevel('agi')}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("🛡️ Lv.${state.getEffectiveStatLevel('end')}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                  // HUD Right (Actions)
                  Positioned(
                    top: 10, right: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () => context.read<GameState>().drinkWater(),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4F72), minimumSize: const Size(80, 30)),
                          child: const Text("💧 물마시기", style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                        const SizedBox(height: 5),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const OutdoorScreen()));
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D6A38), minimumSize: const Size(80, 30)),
                          child: const Text("☀️ 야외활동", style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                        const SizedBox(height: 5),
                        ElevatedButton(
                          onPressed: () => context.read<GameState>().nextDay(),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE1B12C), minimumSize: const Size(80, 30)),
                          child: const Text("📅 다음날", style: TextStyle(color: Colors.black, fontSize: 11)),
                        ),
                        const SizedBox(height: 5),
                        ElevatedButton(
                          onPressed: () {
                            double newDist = state.distance <= 200 ? 100 : 200;
                            context.read<GameState>().devSetDistance(newDist);
                            _checkStageTransition(newDist);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(80, 25)),
                          child: const Text("⏭️ 다음 스테이지 (Dev)", style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                        const SizedBox(height: 5),
                        ElevatedButton(
                          onPressed: () => context.read<GameState>().devAddGold(1000),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, minimumSize: const Size(80, 25)),
                          child: const Text("💰 +1000 G (Dev)", style: TextStyle(color: Colors.black, fontSize: 10)),
                        ),
                      ],
                    ),
                  ),

                  // Characters
                  if (state.hasPet)
                    Positioned(
                      bottom: petBottom, left: 20,
                      child: SpriteWidget(
                        imagePath: state.activePet == 'pet2'
                            ? 'assets/images/Pet2_Walk.png'
                            : 'assets/images/Pet1_Walk.png',
                        frameCount: 6,
                        spriteWidth: 44,
                        spriteHeight: 44,
                        scale: 1.2,
                      ),
                    ),
                    
                  // Hero
                  Positioned(
                    bottom: charBottom, left: 60,
                    child: SpriteWidget(
                      imagePath: _heroState == 'attack' ? 'assets/images/Dude_Monster_Attack2_6.png' : 'assets/images/Dude_Monster_Walk_6.png',
                      frameCount: 6,
                      spriteWidth: 56,
                      spriteHeight: 56,
                      scale: 1.5,
                      loop: _heroState != 'attack',
                    ),
                  ),
                  
                  // Monster
                  AnimatedPositioned(
                    duration: Duration(seconds: _isEngaged || _isResetting ? 0 : 2),
                    bottom: charBottom,
                    right: _monsterRight,
                    child: Column(
                      children: [
                        Text(
                          mobName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1))],
                          ),
                        ),
                        const SizedBox(height: 3),
                        // HP Bar
                        SizedBox(
                          width: 40,
                          child: LinearProgressIndicator(
                            value: _monsterHp / _monsterMaxHp,
                            backgroundColor: Colors.black,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 5),
                        SpriteWidget(
                          imagePath: _monsterState == 'dead' ? 'assets/images/Dead3.png'
                                   : _monsterState == 'hurt' ? 'assets/images/Hurt3.png'
                                   : 'assets/images/Walk3.png',
                          frameCount: 8,
                          spriteWidth: 50,
                          spriteHeight: 50,
                          scale: 1.5,
                          loop: _monsterState != 'dead',
                        ),
                      ],
                    ),
                  ),

                // Floating Damages
                  ..._floatingDamages.map((fd) {
                    return Positioned(
                      bottom: 120,
                      right: _monsterRight + 10,
                      child: TweenAnimationBuilder(
                        key: ValueKey(fd['key']),
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, double val, child) {
                          return Opacity(
                            opacity: 1.0 - val,
                            child: Transform.translate(
                              offset: Offset(0, -50 * val),
                              child: Text(
                                "-${fd['dmg']}",
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1))
                                  ]
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                  
                  // Stage Popup Overlay
                  if (_showStagePopup)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        alignment: Alignment.center,
                        child: Text(
                          _popupText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 5, offset: Offset(2, 2)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Navigation
            Container(
              height: 70,
              color: const Color(0xFF0A0A0A),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _navBtn(context, "능력", () {
                    showDialog(context: context, builder: (_) => const StatsDialog());
                  }),
                  _navBtn(context, "퀘스트", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestsScreen()));
                  }),
                  _navBtn(context, "정령방", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TrainingScreen()));
                  }),
                  _navBtn(context, "상점", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()));
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navBtn(BuildContext context, String title, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A3622),
            foregroundColor: const Color(0xFFA8E6CF),
            side: const BorderSide(color: Colors.black, width: 3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            padding: EdgeInsets.zero,
          ),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }
}
