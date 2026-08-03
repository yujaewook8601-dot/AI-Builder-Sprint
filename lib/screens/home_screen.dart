import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
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
import '../models/boss.dart';
import '../dialogues/dialogues.dart';
import 'ending_screen.dart';
import 'intro_screen.dart';
import '../main.dart'; // For routeObserver

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin, RouteAware {
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
  final List<Map<String, dynamic>> _floatingGolds = [];
  final Map<int, double> _aspectRatios = {1: 987/292, 2: 1920/1080};

  // Cutscene State
  CutsceneType _cutsceneType = CutsceneType.none;
  int _cutsceneIndex = 0;
  Boss? _currentBoss;
  bool _isSpiritFading = false;
  bool _showCutsceneDialog = false;
  bool _heroAutoWalk = false;
  bool _screenFadeOut = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_gameLoop)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheAndGetRatios();
      
      final state = context.read<GameState>();
      if (state.distance <= 100) {
        _currentStage = 3;
      } else if (state.distance <= 200) {
        _currentStage = 2;
      } else {
        _currentStage = 1;
      }
      
      _triggerStagePopup(_currentStage);
      _spawnMonster();
      _checkAutoOpenSpiritRoom();
    });
  }

  void _checkAutoOpenSpiritRoom() {
    final state = context.read<GameState>();
    if (!state.isDailyQuestsCompleted) {
      if (!state.hasAutoOpenedSpiritRoom) {
        state.markSpiritRoomOpened();
      }
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrainingScreen()),
        );
      }
    }
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _ticker.dispose();
    _attackTimer?.cancel();
    _respawnTimer?.cancel();
    super.dispose();
  }

  @override
  void didPushNext() {
    // Other screen is pushed, pause combat
    _attackTimer?.cancel();
  }

  @override
  void didPopNext() {
    // Returned to this screen, resume combat
    if (_isEngaged && _monsterHp > 0) {
      _startCombat();
    }
  }

  void _gameLoop(Duration elapsed) {
    if (!mounted) return;
    // Freeze all game loop updates during cutscenes (unless auto walking at the end)
    if (_cutsceneType != CutsceneType.none && !_heroAutoWalk) return;
    
    double dt = (elapsed - _lastTime).inMilliseconds / 16.666;
    _lastTime = elapsed;
    if (dt > 10) dt = 1.0;
    
    // Stop scrolling if engaged in combat or in a cutscene, unless hero is auto walking
    if ((!_isEngaged && _cutsceneType == CutsceneType.none) || _heroAutoWalk) {
      setState(() {
        _bgX -= 1.5 * dt;
      });
    }
  }

  void prepareBoss() {
    print("Boss Spawn");
    _currentBoss = BossDatabase.getBossForStage(_currentStage);
    _monsterHp = _currentBoss?.maxHp ?? _monsterMaxHp;
    _monsterState = 'walk';
    _heroState = 'walk';
    _isEngaged = false;
    _isResetting = true;
    _monsterRight = MediaQuery.of(context).size.width - 430.0;
    
    // Instantly enter cutscene mode before any AI or game loops can update
    _cutsceneType = CutsceneType.bossIntro;
    _cutsceneIndex = 0;
    _showCutsceneDialog = false;
    print("Cutscene Start");
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _cutsceneType == CutsceneType.bossIntro) {
        setState(() => _showCutsceneDialog = true);
      }
    });
  }

  void startBossBattle() {
    print("Boss AI Update");
    setState(() {
      _cutsceneType = CutsceneType.none;
      _isResetting = false;
    });
    _startCombat();
  }

  void _spawnMonster() {
    if (!mounted) return;
    
    final boss = BossDatabase.getBossForStage(_currentStage);
    if (boss != null) {
      setState(() {
        prepareBoss();
      });
      return;
    }

    setState(() {
      _currentBoss = null;
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
        _startCombat();
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
            if (_currentBoss != null && _currentBoss!.isFinalBoss) {
              _monsterState = 'hurt'; // Keep alive for the cutscene background
            } else {
              _monsterState = 'dead';
            }
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
      
      if (_currentBoss != null && _currentBoss!.isFinalBoss) {
        // Trigger Ending Cutscene
        setState(() {
          _cutsceneType = CutsceneType.ending;
          _cutsceneIndex = 0;
          _isSpiritFading = false;
          _showCutsceneDialog = false;
        });
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) setState(() => _showCutsceneDialog = true);
        });
        return;
      }

      if (_currentStage == 1 || _currentStage == 2) {
        int goldEarned = Random().nextInt(3) + 1;
        _showFloatingGold(goldEarned);
        context.read<GameState>().addGold(goldEarned);
      }
      
      state.decreaseDistance();
      _checkStageTransition(state.distance);
      
      if (_currentStage == 3) {
        prepareBoss();
      } else {
        _respawnTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) _spawnMonster();
        });
      }
    }
  }

  void _nextCutsceneLine() {
    setState(() {
      final dialogues = _cutsceneType == CutsceneType.bossIntro 
          ? Dialogues.bossIntroDialogues 
          : Dialogues.endingDialogues;

      if (_cutsceneIndex < dialogues.length - 1) {
        _cutsceneIndex++;
        final currentEvent = dialogues[_cutsceneIndex].event;
        if (currentEvent == DialogueEvent.spiritFade) {
          _isSpiritFading = true;
        }
      } else {
        if (_cutsceneType == CutsceneType.ending) {
          setState(() {
            _showCutsceneDialog = false;
            _screenFadeOut = true;
          });
          
          // Wait for silence in black screen then transition smoothly to EndingScreen
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const EndingScreen()),
              );
            }
          });
        }
      }
    });
  }

  void _triggerStagePopup(int stage) {
    if (stage == 3) return; // 보스 스테이지(Stage 3)는 팝업을 띄우지 않음

    String stageName = '침대의 숲';
    if (stage == 2) stageName = '알코올의 늪';

    setState(() {
      _showStagePopup = true;
      _popupText = '[Stage $stage]\n$stageName';
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showStagePopup = false;
        });
      }
    });
  }

  void _checkStageTransition(double distance) {
    int newStage = 1;
    if (distance <= 200) {
      newStage = 2;
    }
    if (distance <= 100) {
      newStage = 3;
    }
    
    if (newStage != _currentStage) {
      _currentStage = newStage;
      _triggerStagePopup(newStage);
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

  void _showFloatingGold(int amount) {
    final key = DateTime.now().millisecondsSinceEpoch.toString() + "_gold";
    setState(() {
      _floatingGolds.add({'key': key, 'amount': amount});
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _floatingGolds.removeWhere((item) => item['key'] == key);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();

    // 00시 이후 (혹은 앱 재시작 시) 퀘스트 미완료 상태라면 자동 이동
    if (!state.isDailyQuestsCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          _checkAutoOpenSpiritRoom();
        }
      });
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    String bgImage = 'assets/images/stage1.png';
    String mobName = '이불 슬라임';
    
    if (_currentStage == 2) {
      bgImage = 'assets/images/stage2.png';
      mobName = '숙취 슬라임';
    } else if (_currentStage == 3) {
      bgImage = 'assets/images/stage3.png';
      mobName = '마왕 (게으름의 화신)';
    }

    double currentRatio = _aspectRatios[_currentStage] ?? (1920/1080);
    double charBottom = _currentStage == 1 ? 15.0 : 40.0;
    double petBottom = _currentStage == 1 ? 20.0 : 45.0;

    // Cutscene Visual Overrides
    bool isCutscene = _cutsceneType != CutsceneType.none && !_heroAutoWalk;
    String currentSpeaker = "";
    if (_cutsceneType != CutsceneType.none) {
      final dialogues = _cutsceneType == CutsceneType.bossIntro 
          ? Dialogues.bossIntroDialogues 
          : Dialogues.endingDialogues;
      if (_cutsceneIndex < dialogues.length) {
        currentSpeaker = dialogues[_cutsceneIndex].speaker;
      }
    }
    
    // Hero Properties
    double heroOpacity = (isCutscene && currentSpeaker != "주인공" && _showCutsceneDialog) ? 0.4 : 1.0;
    String heroImage = isCutscene ? 'assets/images/Dude_Monster_Idle_4.png' : 
                      (_heroState == 'attack' ? 'assets/images/Dude_Monster_Attack2_6.png' : 'assets/images/Dude_Monster_Walk_6.png');
    int heroFrames = isCutscene ? 4 : 6;
    bool heroLoop = isCutscene ? true : (_heroState != 'attack');

    // Spirit Properties
    double spiritBaseOpacity = (isCutscene && currentSpeaker != "정령" && _showCutsceneDialog) ? 0.4 : 1.0;
    String spiritImage = state.activePet == 'pet2' ? 'assets/images/Pet2_Walk.png' : 'assets/images/Pet1_Walk.png';
    int spiritFrames = 6;
    bool spiritLoop = true;
    
    if (_isSpiritFading) {
      spiritImage = 'assets/images/Pink_Monster_Death_8.png';
      spiritFrames = 8;
      spiritLoop = false;
      spiritBaseOpacity = 1.0; // Fade out will handle the opacity
    } else if (isCutscene) {
      spiritImage = 'assets/images/Pink_Monster_Idle_4.png';
      spiritFrames = 4;
      spiritLoop = true;
    }

    // Boss Properties
    double bossOpacity = (isCutscene && currentSpeaker != "보스" && _showCutsceneDialog) ? 0.4 : 1.0;
    String bossImage = _monsterState == 'dead' ? 'assets/images/boss_die.png' : (_isEngaged ? 'assets/images/final_boss1.png' : 'assets/images/final_boss2.png');
    int bossFrames = _monsterState == 'dead' ? 1 : (_isEngaged ? 6 : 4);
    bool bossLoop = _monsterState != 'dead';
    
    if (isCutscene && _monsterState != 'dead') {
      bossImage = 'assets/images/final_boss1.png'; // Idle
      bossFrames = 6;
      bossLoop = true;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
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
                  Text("🚩 ${state.distance.toStringAsFixed(1).replaceAll(RegExp(r'\\.0$'), '')}km", style: const TextStyle(color: Color(0xFFA8E6CF), fontSize: 13, fontWeight: FontWeight.bold)),
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
                          Text(
                            "💪 Lv.${state.getEffectiveStatLevel('str')}${state.outdoorDebuffActive ? ' (😷근손실)' : ''}", 
                            style: TextStyle(color: state.outdoorDebuffActive ? Colors.redAccent : Colors.white, fontSize: 13, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "⚡ Lv.${state.getEffectiveStatLevel('agi')}", 
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "🛡️ Lv.${state.getEffectiveStatLevel('end')}${state.isHydrationDebuffActive ? ' (🏜️탈수)' : ''}", 
                            style: TextStyle(color: state.isHydrationDebuffActive ? Colors.redAccent : Colors.white, fontSize: 13, fontWeight: FontWeight.bold)
                          ),
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
                      ],
                    ),
                  ),

                  // Characters
                  if (state.hasPet)
                    AnimatedPositioned(
                      duration: const Duration(seconds: 2),
                      bottom: petBottom, left: 20,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 500),
                            opacity: _isSpiritFading ? 0.0 : spiritBaseOpacity,
                            child: SpriteWidget(
                              imagePath: spiritImage,
                              frameCount: spiritFrames,
                              spriteWidth: _isSpiritFading ? 56 : 44, // Death sprite is larger
                              spriteHeight: _isSpiritFading ? 56 : 44,
                              scale: 1.2,
                              loop: spiritLoop,
                            ),
                          ),
                          if (_isSpiritFading)
                            _buildSpiritParticles(),
                        ],
                      ),
                    ),
                    
                  // Hero
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    bottom: charBottom, left: 60,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity: heroOpacity,
                      child: SpriteWidget(
                        imagePath: heroImage,
                        frameCount: heroFrames,
                        spriteWidth: 56,
                        spriteHeight: 56,
                        scale: 1.5,
                        loop: heroLoop,
                      ),
                    ),
                  ),
                  
                  // Monster (Hide in-game monster during boss intro cutscene)
                  if (_cutsceneType != CutsceneType.bossIntro)
                    AnimatedPositioned(
                      duration: Duration(seconds: _isEngaged || _isResetting || _cutsceneType != CutsceneType.none ? 0 : 2),
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
                        if (_currentStage == 3)
                          // Final Boss Animated Sprite
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 500),
                            opacity: bossOpacity,
                            child: Transform.scale(
                              scaleX: 1.0, // Face Left on screen
                              child: SpriteWidget(
                                imagePath: bossImage,
                                frameCount: bossFrames,
                                spriteWidth: 160,
                                spriteHeight: 160,
                                scale: 2.5, // giant boss size
                                animationDuration: const Duration(milliseconds: 800),
                                loop: bossLoop,
                              ),
                            ),
                          )
                        else
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
                      bottom: _currentStage == 3 ? 230 : 120,
                      right: _currentStage == 3 ? _monsterRight + 120 : _monsterRight + 10,
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
                  
                  // Floating Golds
                  ..._floatingGolds.map((fg) {
                    return Positioned(
                      bottom: 80,
                      right: _monsterRight + 20,
                      child: TweenAnimationBuilder(
                        key: ValueKey(fg['key']),
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, double val, child) {
                          return Opacity(
                            opacity: 1.0 - val,
                            child: Transform.translate(
                              offset: Offset(0, 40 * val),
                              child: Text(
                                "💰 +${fg['amount']} G",
                                style: const TextStyle(
                                  color: Color(0xFFFBC531),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 3,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
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
                  _navBtn(context, "정령방", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TrainingScreen()));
                  }),
                  _navBtn(context, "상점", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()));
                  }),
                ],
              ),
            ),
          ], // End of Column children
        ),
        if (_cutsceneType != CutsceneType.none && _showCutsceneDialog)
          Positioned.fill(
            child: _buildCutsceneOverlay(),
          ),
        if (_screenFadeOut)
          Positioned.fill(
            child: AnimatedOpacity(
              duration: const Duration(seconds: 2),
              opacity: 1.0,
              child: Container(color: Colors.black),
            ),
          ),
      ], // End of Stack children
    ),
  ),
);
  }

  Widget _buildCutsceneOverlay() {
    final dialogues = _cutsceneType == CutsceneType.bossIntro 
        ? Dialogues.bossIntroDialogues 
        : Dialogues.endingDialogues;
    
    if (_cutsceneIndex >= dialogues.length) return const SizedBox.shrink();
    
    final currentLine = dialogues[_cutsceneIndex];
    final isLastLine = _cutsceneIndex == dialogues.length - 1;
    final currentSpeaker = currentLine.speaker;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isLastLine && _cutsceneType == CutsceneType.bossIntro ? null : _nextCutsceneLine,
      child: Container(
        color: Colors.black, 
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Characters Layout
            SizedBox(
              height: 250,
              width: MediaQuery.of(context).size.width * 0.9,
              child: Stack(
                children: [
                  // Boss
                  Align(
                    alignment: Alignment.topCenter,
                    child: _buildCutsceneCharacter(
                      imagePath: _cutsceneType == CutsceneType.ending ? 'assets/images/boss_die.png' : 'assets/images/final_boss2.png',
                      frameCount: _cutsceneType == CutsceneType.ending ? 8 : 4,
                      spriteWidth: _cutsceneType == CutsceneType.ending ? 32 : 256,
                      spriteHeight: _cutsceneType == CutsceneType.ending ? 32 : 256,
                      opacity: currentSpeaker == "보스" ? 1.0 : 0.4,
                      scale: currentSpeaker == "보스" ? 1.05 : 1.0,
                      baseScale: _cutsceneType == CutsceneType.ending ? 6.0 : 0.8, 
                      loop: _cutsceneType != CutsceneType.ending,
                    ),
                  ),
                  // Hero
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: _buildCutsceneCharacter(
                        imagePath: 'assets/images/Dude_Monster_Idle_4.png',
                        frameCount: 4,
                        spriteWidth: 32,
                        spriteHeight: 32,
                        opacity: currentSpeaker == "주인공" ? 1.0 : 0.4,
                        scale: currentSpeaker == "주인공" ? 1.05 : 1.0,
                        baseScale: 5.5, 
                        loop: true,
                      ),
                    ),
                  ),
                  // Spirit
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: _buildCutsceneCharacter(
                        imagePath: _isSpiritFading ? 'assets/images/Pink_Monster_Death_8.png' : 'assets/images/Pink_Monster_Idle_4.png',
                        frameCount: _isSpiritFading ? 8 : 4,
                        spriteWidth: 32,
                        spriteHeight: 32,
                        opacity: _isSpiritFading ? 0.0 : (currentSpeaker == "정령" ? 1.0 : 0.4),
                        scale: currentSpeaker == "정령" ? 1.05 : 1.0,
                        baseScale: 5.5, 
                        loop: !_isSpiritFading,
                        isFading: _isSpiritFading,
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
                      Text(
                        currentLine.speaker,
                        style: const TextStyle(
                          color: Color(0xFFFBC531),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currentLine.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                  if (!(isLastLine && _cutsceneType == CutsceneType.bossIntro))
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: Icon(Icons.arrow_drop_down, color: Color(0xFFA8E6CF), size: 30),
                    )
                ],
              ),
            ),
            if (isLastLine && _cutsceneType == CutsceneType.bossIntro)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: () {
                    startBossBattle();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFBC531),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  child: const Text("준비 완료"),
                ),
              ),
          ],
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
    bool isFading = false,
  }) {
    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 300),
      child: AnimatedOpacity(
        opacity: opacity,
        duration: isFading ? const Duration(seconds: 3) : const Duration(milliseconds: 300),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SpriteWidget(
              imagePath: imagePath,
              frameCount: frameCount,
              spriteWidth: spriteWidth,
              spriteHeight: spriteHeight,
              scale: baseScale,
              loop: loop,
            ),
            if (isFading)
              _buildSpiritParticles(),
          ],
        ),
      ),
    );
  }

  Widget _buildSpiritParticles() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(seconds: 3),
      builder: (context, double val, child) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(8, (index) {
            final random = Random(index);
            final dx = (random.nextDouble() - 0.5) * 80 * val;
            final dy = (random.nextDouble() - 0.5) * 80 * val - (30 * val);
            return Transform.translate(
              offset: Offset(dx, dy),
              child: Opacity(
                opacity: 1.0 - val,
                child: Container(
                  width: 4 + random.nextDouble() * 4,
                  height: 4 + random.nextDouble() * 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFBEA),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.white, blurRadius: 4)],
                  ),
                ),
              ),
            );
          }),
        );
      },
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
