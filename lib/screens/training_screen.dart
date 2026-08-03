import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../widgets/sprite_widget.dart';
import 'quests_screen.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<GameState>();
      state.initSpiritGreeting();
    });
  }

  void _sendMessage([String? text]) async {
    String msgText = text ?? _controller.text.trim();
    if (msgText.isEmpty) return;
    
    if (text == null) {
      _controller.clear();
    }
    
    final state = context.read<GameState>();
    bool wasConversationDone = state.isDailyConversationDone;

    await state.sendChatMessage(msgText);
    
    _scrollToBottom();

    if (mounted && !wasConversationDone && state.isDailyConversationDone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("오늘의 퀘스트가 자동으로 추가되었습니다!"),
          backgroundColor: Color(0xFF2D6A38),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();

    return PopScope(
      canPop: state.isDailyQuestsCompleted,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("용사님 아직 퀘스트를 안깨셔서 몬스터와 싸울 수 없어요!"),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFA8E6CF)),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            "정령의 방 (${state.isAssessmentComplete ? 'Lv.${state.fitnessLevel} ${state.fitnessLevelName}' : '체력 진단 진행 중'})",
            style: const TextStyle(color: Color(0xFFA8E6CF), fontSize: 14, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF1A3622),
        actions: [
          TextButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF162521),
                builder: (BuildContext context) {
                  return SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text("🛠️ 개발자 메뉴 (Cheat)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              context.read<GameState>().devCompleteAllQuests();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF44BD32)),
                            child: const Text("✅ 퀘스트 즉시 완료", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              double newDist = state.distance <= 200 ? 100 : 200;
                              context.read<GameState>().devSetDistance(newDist);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            child: const Text("⏭️ 다음 스테이지 강제 이동 (홈에서 반영됨)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              context.read<GameState>().devAddGold(1000);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
                            child: const Text("💰 +1000 G 획득", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              context.read<GameState>().devLevelUpStat('str');
                              context.read<GameState>().devLevelUpStat('agi');
                              context.read<GameState>().devLevelUpStat('end');
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                            child: const Text("💪 모든 스탯 +1 레벨업", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            child: const Text("🛠️ Dev", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Animation Window
          Container(
            height: 140,
            decoration: const BoxDecoration(
              color: Color(0xFF1A3622),
              image: DecorationImage(
                image: AssetImage('assets/images/spirit_room2.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 15,
                  left: MediaQuery.of(context).size.width * 0.2,
                  child: const SpriteWidget(
                    imagePath: 'assets/images/Dude_Monster_Idle_4.png',
                    frameCount: 4,
                    spriteWidth: 56,
                    spriteHeight: 56,
                    scale: 1.2,
                  ),
                ),
                Positioned(
                  bottom: 15,
                  right: MediaQuery.of(context).size.width * 0.2,
                  child: SpriteWidget(
                    imagePath: state.isDailyConversationDone 
                        ? 'assets/images/Pink_Monster_Death_8.png'
                        : 'assets/images/Pink_Monster_Idle_4.png',
                    frameCount: state.isDailyConversationDone ? 8 : 4,
                    loop: !state.isDailyConversationDone, // 대화 종료 시 1번만 재생 후 멈춤
                    spriteWidth: 56,
                    spriteHeight: 56,
                    scale: 1.2,
                  ),
                ),
              ],
            ),
          ),
          
          // Quests Button (Appears above chat when quests exist)
          if (state.dailyQuests.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              color: const Color(0xFF111111),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestsScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A38),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.black, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.assignment, color: Colors.amber),
                label: const Text("오늘의 퀘스트 확인하기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),

          // Chat History
          Expanded(
            child: Container(
              color: const Color(0xFF111111),
              padding: const EdgeInsets.all(15),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: state.chatHistory.length + (state.isChatLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.chatHistory.length && state.isChatLoading) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SpriteWidget(
                              imagePath: 'assets/images/Pink_jump.png',
                              frameCount: 8,
                              spriteWidth: 32,
                              spriteHeight: 32,
                              scale: 0.8,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "정령이 생각하는 중...",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  var msg = state.chatHistory[index];
                  return Align(
                    alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                      decoration: BoxDecoration(
                        color: msg.isUser ? const Color(0xFF1A3622) : const Color(0xFF1A1A1A),
                        border: Border.all(color: const Color(0xFF2D6A38), width: 2),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(8),
                          topRight: const Radius.circular(8),
                          bottomLeft: Radius.circular(msg.isUser ? 8 : 0),
                          bottomRight: Radius.circular(msg.isUser ? 0 : 8),
                        ),
                      ),
                      child: Text(msg.text, style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 13, height: 1.4)),
                    ),
                  );
                },
              ),
            ),
          ),


          // Input Area
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFF0A0A0A),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "정령에게 말하기...",
                      hintStyle: TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Color(0xFF1A1A1A),
                      border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2D6A38))),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _sendMessage(),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D6A38), padding: const EdgeInsets.all(15)),
                  child: const Text("전송", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          )
        ],
      ), // Closes Column
    ), // Closes Scaffold
  ); // Closes PopScope
}
}
