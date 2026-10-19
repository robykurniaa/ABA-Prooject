import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'token_provider.dart';
import 'language_provider.dart';
import 'lock_helper.dart';
import 'tts_provider.dart';

import 'token_board.dart';
import 'first_then_board.dart';
import 'visual_timer_screen.dart';
import 'flashcard_screen.dart';
import 'settings_screen.dart'; // IMPORT LAYAR PENGATURAN

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Mengunci orientasi layar ke landscape
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TokenProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()), 
        ChangeNotifierProvider(create: (context) => TtsProvider()), // PROVIDER TTS
      ],
      child: const AbaApp(),
    ),
  );
}

class AbaApp extends StatelessWidget {
  const AbaApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ABA Project',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAF0E6),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 150,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 10.0),
          child: ElevatedButton.icon(
            onPressed: () => LockHelper.toggleKioskMode(context, lang),
            icon: const Icon(Icons.screen_lock_portrait, color: Colors.white),
            label: const Text('Kunci OS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ),
        actions: [
          // TOMBOL GANTI BAHASA
          Padding(
            padding: const EdgeInsets.only(right: 10.0, top: 10.0),
            child: ElevatedButton.icon(
              onPressed: () => lang.toggleLanguage(),
              icon: const Icon(Icons.language, color: Colors.black87),
              label: Text(lang.currentLangCode, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFE4B5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
          
          // TOMBOL PENGATURAN (GERIGI)
          Padding(
            padding: const EdgeInsets.only(right: 20.0, top: 10.0),
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.black87, size: 35),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMenuButton(lang.getText('menu_token'), Icons.star_border, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TokenBoardScreen()));
            }),
            _buildMenuButton(lang.getText('menu_first_then'), Icons.compare_arrows, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FirstThenScreen()));
            }),
            _buildMenuButton(lang.getText('menu_timer'), Icons.timer, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const VisualTimerScreen()));
            }),
            _buildMenuButton(lang.getText('menu_flashcard'), Icons.style, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FlashcardScreen()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(String title, IconData icon, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFB0E0E6),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 60, color: Colors.black54),
          const SizedBox(height: 15),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}