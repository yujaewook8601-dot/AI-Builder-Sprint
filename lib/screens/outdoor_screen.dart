import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:light/light.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/game_state.dart';

class OutdoorScreen extends StatefulWidget {
  const OutdoorScreen({super.key});

  @override
  State<OutdoorScreen> createState() => _OutdoorScreenState();
}

class _OutdoorScreenState extends State<OutdoorScreen> {
  late Stream<StepCount> _stepCountStream;
  late Light _light;
  late StreamSubscription _lightSubscription;

  int _steps = 0;
  int _initialSteps = -1;
  int _luxString = 0;
  
  final int targetSteps = 50;
  final int targetLux = 1000;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndInitSensors();
  }

  Future<void> _checkPermissionsAndInitSensors() async {
    try {
      var status = await Permission.activityRecognition.request();
      if (status.isGranted) {
        _initPedometer();
      } else {
        debugPrint("Activity Recognition permission denied");
      }
    } catch (e) {
      debugPrint("Permission check error: $e");
    }
    _initLightSensor();
  }

  void _initPedometer() {
    try {
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream.listen(onStepCount, onError: onStepCountError);
    } catch (e) {
      debugPrint("Pedometer Error: $e");
    }
  }

  void _initLightSensor() {
    try {
      _light = Light();
      _lightSubscription = _light.lightSensorStream.listen(onData);
    } catch (e) {
      debugPrint("Light Sensor Error: $e");
    }
  }

  void onData(int luxValue) {
    if (mounted) {
      setState(() {
        _luxString = luxValue;
      });
    }
  }

  void onStepCount(StepCount event) {
    if (_initialSteps == -1) {
      _initialSteps = event.steps;
    }
    if (mounted) {
      setState(() {
        _steps = event.steps - _initialSteps;
      });
    }
  }

  void onStepCountError(dynamic error) {
    debugPrint('Step Count Error: $error');
  }

  @override
  void dispose() {
    try {
      _lightSubscription.cancel();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    
    double luxPercent = (_luxString / targetLux).clamp(0.0, 1.0);
    double stepPercent = (_steps / targetSteps).clamp(0.0, 1.0);
    bool canComplete = _luxString >= targetLux && _steps >= targetSteps;

    return Scaffold(
      appBar: AppBar(
        title: const Text("야외 활동 센서 인증", style: TextStyle(color: Color(0xFFA8E6CF))),
        backgroundColor: const Color(0xFF1A3622),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("☀️ 밖에 나가기 (야외 활동)", style: TextStyle(color: Color(0xFFA8E6CF), fontSize: 22)),
            const SizedBox(height: 10),
            const Text("보상: 외출 미완료 디버프 해제", style: TextStyle(color: Color(0xFFFBC531))),
            const SizedBox(height: 30),
            
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                border: Border.all(color: const Color(0xFF2D6A38), width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("📱 센서 측정 결과", style: TextStyle(color: Color(0xFFFBC531), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("☀️ 밝기 (조도):"),
                      Text("$_luxString / $targetLux Lux", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(value: luxPercent, backgroundColor: Colors.black, color: const Color(0xFF44BD32)),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("🚶 걸음 수:"),
                      Text("$_steps / $targetSteps 보", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(value: stepPercent, backgroundColor: Colors.black, color: const Color(0xFF44BD32)),
                ],
              ),
            ),

            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canComplete ? const Color(0xFF2D6A38) : Colors.grey,
                padding: const EdgeInsets.all(15),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: canComplete || state.outdoorCompletedToday ? () {
                context.read<GameState>().completeOutdoorQuest();
                Navigator.pop(context);
              } : null,
              child: Text(
                state.outdoorCompletedToday ? "이미 완료됨" : "야외 활동 인증하기",
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }
}
