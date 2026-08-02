import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../widgets/sprite_widget.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "정령의 방 (${state.isAssessmentComplete ? 'Lv.${state.fitnessLevel} ${state.fitnessLevelName}' : '체력 진단 진행 중'})",
          style: const TextStyle(color: Color(0xFFA8E6CF), fontSize: 15, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A3622),
      ),
      body: Column(
        children: [
          // Animation Window
          Container(
            height: 140,
            color: const Color(0xFF1A3622),
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
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("정령이 생각하는 중...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
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
      ),
    );
  }
}
