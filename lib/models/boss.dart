class Boss {
  final String id;
  final String name;
  final double maxHp;
  final String imagePath;
  final bool isFinalBoss;

  const Boss({
    required this.id,
    required this.name,
    required this.maxHp,
    required this.imagePath,
    this.isFinalBoss = false,
  });
}

class BossDatabase {
  static const Boss stage3Boss = Boss(
    id: 'boss_3',
    name: '최종 보스',
    maxHp: 300.0,
    imagePath: 'assets/images/Pink_Monster_Walk_6.png', // Assuming Pink Monster is the boss
    isFinalBoss: true,
  );

  static Boss? getBossForStage(int stage) {
    if (stage == 3) return stage3Boss;
    return null;
  }
}
