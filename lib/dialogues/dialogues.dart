enum DialogueEvent {
  none,
  spiritFade,
}

class DialogueLine {
  final String speaker;
  final String text;
  final DialogueEvent event;

  const DialogueLine({
    required this.speaker,
    required this.text,
    this.event = DialogueEvent.none,
  });
}

class Dialogues {
  // 인트로 화면 대사
  static const List<String> introDialogues = [
    "그날도\n평소와 다르지 않은 하루였습니다.",
    "늦은 밤,\n당신은 깊은 잠에 빠져들었습니다.",
    "...",
    "정체를 알 수 없는 존재가 나타나\n당신에게서\n무언가를 빼앗아 갔습니다.",
    "그리고…\n보이지 않던 것들이 보이기 시작했습니다."
  ];
  
  // 튜토리얼 (정령 첫 만남) 대사
  static const List<String> tutorialDialogues = [
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

  // 보스방 진입 대사
  static const List<DialogueLine> bossIntroDialogues = [
    DialogueLine(speaker: "주인공", text: "..."),
    DialogueLine(speaker: "주인공", text: "저건..."),
    DialogueLine(speaker: "정령", text: "..."),
    DialogueLine(speaker: "정령", text: "이번 지역의 보스야."),
    DialogueLine(speaker: "정령", text: "조심해."),
    DialogueLine(speaker: "정령", text: "지금까지 만난 몬스터와는 달라."),
    DialogueLine(speaker: "보스", text: "..."),
    DialogueLine(speaker: "보스", text: "왔네."),
    DialogueLine(speaker: "보스", text: "...기다리고 있었어."),
    DialogueLine(speaker: "주인공", text: "..."),
    DialogueLine(speaker: "정령", text: "쓰러뜨려."),
    DialogueLine(speaker: "정령", text: "그리고 앞으로 나아가."),
  ];

  // 최종 보스 엔딩 대사
  static const List<DialogueLine> endingDialogues = [
    DialogueLine(speaker: "주인공", text: "...끝난 거야?"),
    DialogueLine(speaker: "정령", text: "응."),
    DialogueLine(speaker: "정령", text: "...이제 끝이야."),
    DialogueLine(speaker: "주인공", text: "...저 보스는."),
    DialogueLine(speaker: "주인공", text: "도대체 누구였던 거야?"),
    DialogueLine(speaker: "정령", text: "..."),
    DialogueLine(speaker: "정령", text: "너였어."),
    DialogueLine(speaker: "정령", text: "건강을 잃은."),
    DialogueLine(speaker: "정령", text: "너의 모습."),
    DialogueLine(speaker: "주인공", text: "..."),
    DialogueLine(speaker: "정령", text: "정령은 떠나지 않았습니다."),
    DialogueLine(speaker: "정령", text: "당신의 일부가 되었을 뿐."),
    DialogueLine(speaker: "정령", text: "이 순간을 잊지 말고, 당신의 길을 걸어가세요."),
    DialogueLine(speaker: "주인공", text: "...이제 어떻게 되는 거야?"),
    DialogueLine(speaker: "정령", text: "내 역할은 끝났어."),
    DialogueLine(speaker: "정령", text: "이제는."),
    DialogueLine(speaker: "정령", text: "내가 없어도."),
    DialogueLine(speaker: "정령", text: "스스로 걸어갈 수 있으니까."),
    DialogueLine(speaker: "주인공", text: "..."),
    DialogueLine(speaker: "정령", text: "가끔 힘들 때도 있을 거야."),
    DialogueLine(speaker: "정령", text: "그래도."),
    DialogueLine(speaker: "정령", text: "오늘처럼."),
    DialogueLine(speaker: "정령", text: "한 걸음만 내디뎌."),
    DialogueLine(speaker: "정령", text: "그걸로 충분해."),
    DialogueLine(speaker: "주인공", text: "...가지 마."),
    DialogueLine(speaker: "정령", text: "난 사라지는 게 아니야."),
    DialogueLine(speaker: "정령", text: "...이제."),
    DialogueLine(speaker: "정령", text: "네 안에 있을 거야."),
    DialogueLine(speaker: "정령", text: "잘 가."),
    DialogueLine(speaker: "정령", text: "...그리고."),
    DialogueLine(speaker: "정령", text: "건강해.", event: DialogueEvent.spiritFade),
    DialogueLine(speaker: "주인공", text: "..."),
    DialogueLine(speaker: "주인공", text: "...고마워."),
  ];

  // 정령 오류 메시지 - Timeout
  static const List<String> timeoutMessages = [
    "앗, 답이 조금 늦어졌네요. 다시 한 번 말씀해 주시겠어요?",
    "답변이 조금 밀렸나 봐요. 한 번만 더 적어주세요.",
    "잠시 놓친 것 같아요. 다시 한 번 말씀해 주세요.",
    "메시지가 조금 늦게 닿은 것 같아요. 다시 한 번 말씀해 주시겠어요?",
    "제가 조금 늦었네요. 다시 한 번 이야기해 주세요.",
  ];

  // 정령 오류 메시지 - Network Error
  static const List<String> networkMessages = [
    "앗, 메시지가 중간에 끊긴 것 같아요. 다시 한 번 말씀해 주시겠어요?",
    "메시지가 끝까지 전달되지 않은 것 같아요. 다시 한 번 적어주세요.",
    "잠시 연결이 멈췄던 것 같아요. 다시 한 번 말씀해 주세요.",
    "이야기가 중간에 안 들린 것 같아요. 다시 한 번 말씀해 주시겠어요?",
    "제대로 전달되지 않은 것 같아요. 한 번만 더 적어주세요.",
  ];

  // 정령 오류 메시지 - Parse Error (이해 불가)
  static const List<String> parseMessages = [
    "제가 제대로 이해하지 못했어요. 다시 한 번 말씀해 주시겠어요?",
    "앗, 제가 잘 못 알아들은 것 같아요. 다시 한 번 적어주세요.",
    "제가 놓친 부분이 있는 것 같아요. 다시 한 번 말씀해 주세요.",
    "뜻을 정확히 이해하지 못했어요. 한 번만 더 이야기해 주시겠어요?",
    "조금 다르게 이해한 것 같아요. 다시 한 번 말씀해 주세요.",
  ];

  // 정령 오류 메시지 - Unknown Error (알 수 없음)
  static const List<String> unknownMessages = [
    "앗, 잠시 문제가 있었나 봐요. 다시 한 번 말씀해 주시겠어요?",
    "한 번만 더 말씀해 주시면 이어서 도와드릴게요.",
    "잠깐 멈칫한 것 같아요. 다시 한 번 말씀해 주세요.",
    "앗, 제가 놓친 것 같아요. 다시 한 번 적어주세요.",
    "제대로 파악하지 못한 것 같아요. 한 번만 더 이야기해 주시겠어요?",
  ];
}
