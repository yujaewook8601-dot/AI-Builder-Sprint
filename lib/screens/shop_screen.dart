import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../providers/game_state.dart';
import '../widgets/sprite_widget.dart';

class ShopItem {
  final String id;
  final String name;
  final String desc;
  final int price;
  final String type;
  final String? stat;
  final int? minBuff;
  final int? maxBuff;
  final String? imagePath;
  final int? frameCount;
  final int? spriteWidth;
  final int? spriteHeight;
  final bool isVertical;
  final int? columns; // 신규: 2D 그리드 지원

  ShopItem({
    required this.id,
    required this.name,
    required this.desc,
    required this.price,
    required this.type,
    this.stat,
    this.minBuff,
    this.maxBuff,
    this.imagePath,
    this.frameCount,
    this.spriteWidth,
    this.spriteHeight,
    this.isVertical = false,
    this.columns,
  });
}

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  static List<ShopItem> get items => [
    ShopItem(
      id: 'str_buff_potion',
      name: '랜덤 근력 강화 포션',
      desc: '근력 능력치 버프를 랜덤하게 부여합니다. (근력 +2~10 증가)',
      price: 50,
      type: 'buff_potion',
      stat: 'str',
      minBuff: 2,
      maxBuff: 10,
      imagePath: 'assets/images/strength potion.png',
      frameCount: 3,
      spriteWidth: 16,
      spriteHeight: 16,
      columns: 3,
    ),
    ShopItem(
      id: 'agi_buff_potion',
      name: '랜덤 민첩 강화 포션',
      desc: '민첩 능력치 버프를 랜덤하게 부여합니다. (민첩 +2~10 증가)',
      price: 50,
      type: 'buff_potion',
      stat: 'agi',
      minBuff: 2,
      maxBuff: 10,
      imagePath: 'assets/images/dex potion.png',
      frameCount: 3,
      spriteWidth: 16,
      spriteHeight: 16,
      columns: 3,
    ),
    ShopItem(
      id: 'end_buff_potion',
      name: '랜덤 지구력 강화 포션',
      desc: '지구력 능력치 버프를 랜덤하게 부여합니다. (지구력 +2~10 증가)',
      price: 50,
      type: 'buff_potion',
      stat: 'end',
      minBuff: 2,
      maxBuff: 10,
      imagePath: 'assets/images/endurance_potion.png',
      frameCount: 3,
      spriteWidth: 16,
      spriteHeight: 16,
      columns: 3,
    ),
    ShopItem(
      id: 'portable_sunlight',
      name: '간이 햇빛',
      desc: '센서 인증 없이 오늘의 야외 활동(밖에 나가기) 퀘스트를 바로 완료합니다.',
      price: 100,
      type: 'instant_sunlight',
      imagePath: 'assets/images/sun_.png',
    ),
    ShopItem(
      id: 'pet_spirit1',
      name: '🐾 정령 펫 1호',
      desc: '용사 곁에서 함께 걷는 강아지 펫입니다.',
      price: 200,
      type: 'pet',
    ),
    ShopItem(
      id: 'pet_spirit2',
      name: '🐾 정령 펫 2호',
      desc: '용사 곁에서 함께 걷는 아기 정령 펫입니다.',
      price: 200,
      type: 'pet',
    ),
  ];

  void _buyItem(BuildContext context, ShopItem item) {
    final state = context.read<GameState>();

    if (state.gold < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("골드가 부족합니다!"), backgroundColor: Colors.red),
      );
      return;
    }

    if (item.type == 'pet' && (state.hasPet && state.activePet == (item.id == 'pet_spirit1' ? 'pet1' : 'pet2'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이미 보유 중인 펫입니다!"), backgroundColor: Colors.orange),
      );
      return;
    }

    state.buyItem(item.price, () {
      if (item.type == 'buff_potion') {
        int buffVal = Random().nextInt((item.maxBuff! - item.minBuff!) + 1) + item.minBuff!;
        
        final now = DateTime.now();
        final midnight = DateTime(now.year, now.month, now.day, 23, 59, 59);
        final secondsUntilMidnight = midnight.difference(now).inSeconds;
        
        state.applyBuff(item.id, item.stat!, buffVal, secondsUntilMidnight);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${item.name} 사용! 당일 자정까지 ${item.stat!.toUpperCase()} +$buffVal 버프 유지"), backgroundColor: Colors.green),
        );
      } else if (item.type == 'instant_sunlight') {
        state.completeOutdoorQuest();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("간이 햇빛 사용! 오늘 야외 활동 퀘스트가 완료되었습니다!"), backgroundColor: Colors.green),
        );
      } else if (item.type == 'pet') {
        state.buyPet(item.id == 'pet_spirit1' ? 'pet1' : 'pet2');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${item.name} 보유 완료! 메인 화면 뒤에 펫이 나타납니다."), backgroundColor: Colors.green),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();

    return Scaffold(
      appBar: AppBar(
        title: Text("상점 (💰 ${state.gold} G)", style: const TextStyle(color: Color(0xFFA8E6CF), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A3622),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          bool canAfford = state.gold >= item.price;

          return Card(
            color: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Color(0xFF2D6A38), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (item.imagePath != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: item.frameCount != null
                              ? SpriteWidget(
                                  imagePath: item.imagePath!,
                                  frameCount: item.frameCount!,
                                  spriteWidth: item.spriteWidth!,
                                  spriteHeight: item.spriteHeight!,
                                  isVertical: item.isVertical,
                                  columns: item.columns,
                                )
                              : Image.asset(item.imagePath!),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(item.desc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAfford ? const Color(0xFF2D6A38) : Colors.grey,
                      side: const BorderSide(color: Colors.black, width: 2),
                    ),
                    onPressed: canAfford ? () => _buyItem(context, item) : null,
                    child: Text("${item.price} G", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
