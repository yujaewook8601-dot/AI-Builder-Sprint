import 'package:home_widget/home_widget.dart';
import '../models/quest.dart';

/// ============================================================
/// 📱 WidgetService
/// 바탕화면 홈 위젯(Android / iOS) 데이터 갱신 서비스
/// ============================================================
class WidgetService {
  static const String appGroupId = 'group.com.example.pixelHero';
  static const String androidWidgetName = 'QuestWidgetProvider';
  static const String iOSWidgetName = 'QuestWidget';

  /// 홈 위젯 데이터 갱신 메서드
  static Future<void> updateQuestWidget(List<Quest> quests) async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);

      final activeQuests = quests.where((q) => !q.completed).toList();

      String titleText;
      String statusText;

      if (quests.isEmpty) {
        titleText = "정령의 방에서 퀘스트를 받아보세요!";
        statusText = "대기 중";
      } else if (activeQuests.isEmpty) {
        titleText = "🎉 오늘의 모든 퀘스트 완료!";
        statusText = "완료됨 (${quests.length}/${quests.length})";
      } else {
        final currentQuest = activeQuests.first;
        titleText = "${currentQuest.title} (${currentQuest.current}/${currentQuest.target}${currentQuest.unit})";
        statusText = "진행 중 (${activeQuests.length}개 남음)";
      }

      await HomeWidget.saveWidgetData<String>('quest_title', titleText);
      await HomeWidget.saveWidgetData<String>('quest_status', statusText);

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (e) {
      // 위젯 업데이트 중 예외 발생 시 앱 실행에 영향 없도록 방어
    }
  }
}
