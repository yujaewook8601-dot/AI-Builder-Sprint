import 'package:flutter_test/flutter_test.dart';
import 'package:libera/models/fitness_profile.dart';
import 'package:libera/models/recovery_condition.dart';
import 'package:libera/models/quest.dart';
import 'package:libera/services/quest_calculator.dart';

void main() {
  group('QuestCalculator Tests', () {
    test('Level 1 limits and base ratio', () {
      final profile = FitnessProfile(pushupMax: 10, squatMax: 15, runningMaxMinutes: 10, fitnessLevel: 1);
      final condition = RecoveryCondition(recoveryMode: false, fatigueLevel: 3, soreness: [], mood: 'neutral', sleepHours: 8);
      
      final quests = QuestCalculator.calculate(profile: profile, condition: condition, yesterdayCompletionRate: 1.0);
      
      expect(quests.length, 3);
      
      // Level 1 ratio is 0.60, Fatigue 3 is 1.0, Completion 1.0 => Global = 0.60
      // Pushup: 10 * 0.6 = 6. Min limit is 5. So 6.
      expect(quests[0].id, 'pushup');
      expect(quests[0].target, 6);
      expect(quests[0].sets, 2);
      expect(quests[0].isRecovery, false);

      // Squat: 15 * 0.6 = 9. Min limit is 8. So 9.
      expect(quests[1].id, 'squat');
      expect(quests[1].target, 9);
      expect(quests[1].sets, 2);

      // Running: 10 * 0.6 = 6. Min limit is 5. So 6.
      expect(quests[2].id, 'running');
      expect(quests[2].target, 6);
      expect(quests[2].sets, 1);
    });

    test('Max limits (Clamp)', () {
      final profile = FitnessProfile(pushupMax: 200, squatMax: 200, runningMaxMinutes: 200, fitnessLevel: 4);
      final condition = RecoveryCondition(recoveryMode: false, fatigueLevel: 1, soreness: [], mood: 'neutral', sleepHours: 8);
      
      // Fatigue 1 = 1.05 multiplier
      final quests = QuestCalculator.calculate(profile: profile, condition: condition, yesterdayCompletionRate: 1.0);
      
      expect(quests[0].target, 50); // Pushup max 50
      expect(quests[1].target, 80); // Squat max 80
      expect(quests[2].target, 40); // Running max 40
    });

    test('Min limits (Clamp)', () {
      final profile = FitnessProfile(pushupMax: 1, squatMax: 1, runningMaxMinutes: 1, fitnessLevel: 1);
      final condition = RecoveryCondition(recoveryMode: false, fatigueLevel: 5, soreness: [], mood: 'neutral', sleepHours: 8);
      
      // Fatigue 5 = 0.80 multiplier
      final quests = QuestCalculator.calculate(profile: profile, condition: condition, yesterdayCompletionRate: 1.0);
      
      expect(quests[0].target, 5); // Pushup min 5
      expect(quests[1].target, 8); // Squat min 8
      expect(quests[2].target, 5); // Running min 5
    });

    test('Severe Soreness causes Recovery Quest', () {
      final profile = FitnessProfile(pushupMax: 20, squatMax: 30, runningMaxMinutes: 20, fitnessLevel: 2);
      final condition = RecoveryCondition(
        recoveryMode: false, 
        fatigueLevel: 3, 
        soreness: [SorenessInfo(area: BodyArea.upperBody, severity: SorenessSeverity.severe)], 
        mood: 'neutral', 
        sleepHours: 8
      );
      
      final quests = QuestCalculator.calculate(profile: profile, condition: condition, yesterdayCompletionRate: 1.0);
      
      // UpperBody is severe -> Pushup should be Recovery
      expect(quests[0].id, 'pushup');
      expect(quests[0].isRecovery, true);
      expect(quests[0].title, '어깨·가슴 스트레칭');
      expect(quests[0].target, 5);
      expect(quests[0].unit, '분');
      expect(quests[0].expReward, 6); // 10 * 0.6 = 6

      // LowerBody is normal -> Squat and Running should be normal
      expect(quests[1].isRecovery, false);
      expect(quests[2].isRecovery, false);
      expect(quests[1].expReward, 10);
      expect(quests[2].expReward, 10);
    });

    test('Recovery Mode global multiplier', () {
      final profile = FitnessProfile(pushupMax: 30, squatMax: 40, runningMaxMinutes: 30, fitnessLevel: 3);
      final condition = RecoveryCondition(recoveryMode: true, fatigueLevel: 3, soreness: [], mood: 'neutral', sleepHours: 8);
      
      // Level 3 base 0.70. Recovery Mode = 0.8. Total = 0.56
      final quests = QuestCalculator.calculate(profile: profile, condition: condition, yesterdayCompletionRate: 1.0);
      
      // Pushup: 30 * 0.56 = 16.8 -> 16
      expect(quests[0].target, 16);
    });
  });
}
