import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/game_state.dart';
import 'screens/intro_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameState()),
      ],
      child: const PixelHeroApp(),
    ),
  );
}

class PixelHeroApp extends StatelessWidget {
  const PixelHeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel Hero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        primaryColor: const Color(0xFF2D6A38),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF2D6A38),
          secondary: const Color(0xFFA8E6CF),
          surface: const Color(0xFF111111),
        ),
        // We will use standard font since custom font failed to download.
        // If font was present, we would set fontFamily: 'NeoDunggeunmo'
      ),
      home: const AppRouter(),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    
    if (!state.isIntroDone || !state.isTutorialDone) {
      return const IntroScreen();
    } else if (!state.isOnboardingDone) {
      return const OnboardingScreen();
    } else {
      return const HomeScreen();
    }
  }
}
