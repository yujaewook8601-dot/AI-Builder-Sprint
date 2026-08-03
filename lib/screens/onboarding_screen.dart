import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import 'training_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  String selectedLevel = "초보";
  String selectedGoal = "근력 강화";

  void _submitOnboarding() {
    final name = nameController.text.trim();
    final ageText = ageController.text.trim();
    final heightText = heightController.text.trim();
    final weightText = weightController.text.trim();

    // 1. 이름 검증 (빈값 및 숫자 포함 여부 체크)
    if (name.isEmpty) {
      _showErrorSnackBar("이름을 입력해주세요.");
      return;
    }
    if (RegExp(r'\d').hasMatch(name)) {
      _showErrorSnackBar("이름에는 숫자를 입력할 수 없습니다.");
      return;
    }

    // 2. 나이 검증
    if (ageText.isEmpty) {
      _showErrorSnackBar("나이를 입력해주세요.");
      return;
    }
    final age = int.tryParse(ageText);
    if (age == null || age < 1 || age > 120) {
      _showErrorSnackBar("나이는 1~120 사이의 올바른 숫자로 입력해주세요.");
      return;
    }

    // 3. 키 검증
    if (heightText.isEmpty) {
      _showErrorSnackBar("키(cm)를 입력해주세요.");
      return;
    }
    final height = double.tryParse(heightText);
    if (height == null || height < 50 || height > 250) {
      _showErrorSnackBar("키는 50~250cm 사이의 올바른 숫자로 입력해주세요.");
      return;
    }

    // 4. 몸무게 검증
    if (weightText.isEmpty) {
      _showErrorSnackBar("몸무게(kg)를 입력해주세요.");
      return;
    }
    final weight = double.tryParse(weightText);
    if (weight == null || weight < 20 || weight > 300) {
      _showErrorSnackBar("몸무게는 20~300kg 사이의 올바른 숫자로 입력해주세요.");
      return;
    }

    // 검증 완료 후 전송
    context.read<GameState>().completeOnboarding(
      name,
      age,
      height,
      weight,
      selectedLevel,
      selectedGoal,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TrainingScreen()),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: const Color(0xFFC0392B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "여정의 시작",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFA8E6CF),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: Color(0xFF2D6A38), thickness: 2, endIndent: 20, indent: 20),
              const SizedBox(height: 30),
              
              _buildLabel("너의 이름은 뭐야? (문자만 입력 가능)"),
              TextField(
                controller: nameController,
                keyboardType: TextInputType.name,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\d')),
                ],
                decoration: _inputDecoration("예: 김용사"),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("나이는 어떻게 돼?"),
                        TextField(
                          controller: ageController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: _inputDecoration("예: 25"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("키 (cm)?"),
                        TextField(
                          controller: heightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                          decoration: _inputDecoration("예: 175"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildLabel("몸무게 (kg)?"),
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: _inputDecoration("예: 70"),
              ),
              const SizedBox(height: 20),

              _buildLabel("되찾고 싶은 목표가 뭐야?"),
              DropdownButtonFormField<String>(
                initialValue: selectedGoal,
                decoration: _inputDecoration(""),
                dropdownColor: const Color(0xFF1A1A1A),
                items: const [
                  DropdownMenuItem(value: "근력 강화", child: Text("강력한 파워 (근력 강화)")),
                  DropdownMenuItem(value: "체중 감량", child: Text("날렵한 몸 (체중 감량)")),
                  DropdownMenuItem(value: "체력 증진", child: Text("지치지 않는 끈기 (체력 증진)")),
                ],
                onChanged: (val) => setState(() => selectedGoal = val!),
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A38),
                  padding: const EdgeInsets.all(15),
                  side: const BorderSide(color: Colors.black, width: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                onPressed: _submitOnboarding,
                child: const Text("건강을 되찾으러 출발!", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(color: Color(0xFFA8E6CF), fontSize: 14)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2D6A38), width: 2)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFA8E6CF), width: 2)),
    );
  }
}
