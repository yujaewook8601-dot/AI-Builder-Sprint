class Quest {
  String id;
  String title;
  int current;
  int target;
  bool completed;
  bool isPast;
  String stat;
  
  // 신규 추가 필드
  int sets;
  String unit;
  bool isRecovery;
  int expReward;

  Quest({
    required this.id,
    required this.title,
    this.current = 0,
    required this.target,
    this.completed = false,
    this.isPast = false,
    required this.stat,
    this.sets = 1,
    this.unit = '회',
    this.isRecovery = false,
    this.expReward = 10,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'current': current,
    'target': target,
    'completed': completed,
    'isPast': isPast,
    'stat': stat,
    'sets': sets,
    'unit': unit,
    'isRecovery': isRecovery,
    'expReward': expReward,
  };

  factory Quest.fromJson(Map<String, dynamic> json) => Quest(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    current: json['current'] ?? 0,
    target: json['target'] ?? 0,
    completed: json['completed'] ?? false,
    isPast: json['isPast'] ?? false,
    stat: json['stat'] ?? 'str',
    sets: json['sets'] ?? 1,
    unit: json['unit'] ?? '회',
    isRecovery: json['isRecovery'] ?? false,
    expReward: json['expReward'] ?? 10,
  );
}
