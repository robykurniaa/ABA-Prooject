import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:audioplayers/audioplayers.dart';

import 'language_provider.dart';
import 'tts_provider.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> with SingleTickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _currentIndex = 0;
  bool _isFlipped = false;

  late AnimationController _flipController;
  late Animation<double> _animation;

  // DAFTAR KARTU (9 Item)
  final List<Map<String, dynamic>> _flashcards = [
    {'nameKey': 'apple', 'icon': Icons.apple, 'color': const Color(0xFFFFB6C1)}, 
    {'nameKey': 'car', 'icon': Icons.directions_car, 'color': const Color(0xFFB0E0E6)}, 
    {'nameKey': 'cat', 'icon': Icons.pets, 'color': const Color(0xFFFFE4B5)}, 
    {'nameKey': 'house', 'icon': Icons.house, 'color': const Color(0xFF98FB98)}, 
    {'nameKey': 'dog', 'icon': FontAwesomeIcons.dog, 'color': const Color.fromARGB(255, 246, 222, 4)}, 
    {'nameKey': 'plane', 'icon': Icons.flight, 'color': const Color(0xFFE0FFFF)}, 
    {'nameKey': 'orange', 'icon': FontAwesomeIcons.lemon, 'color': const Color.fromRGBO(241, 130, 8, 1)}, 
    {'nameKey': 'tree', 'icon': Icons.park, 'color': const Color(0xFF90EE90)}, 
    {'nameKey': 'ball', 'icon': Icons.sports_soccer, 'color': const Color(0xFFDDA0DD)}, 
  ];

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // Animasinya mulus dan elegan
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack)
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _flutterTts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  // FUNGSI MEMBALIK KARTU & MENGATUR SUARA (ANTI STUCK)
  Future<void> _flipCard() async {
    final currentCard = _flashcards[_currentIndex];
    final lang = context.read<LanguageProvider>();
    final tts = context.read<TtsProvider>();
    
    // 1. PINDAHKAN ANIMASI DAN STATE KE PALING ATAS
    // Memastikan kartu dibalik terlebih dahulu, tidak peduli audio gagal atau tidak.
    final wasFlipped = _isFlipped;
    setState(() {
      _isFlipped = !_isFlipped;
    });

    if (wasFlipped) {
      _flipController.reverse(); // Putar kembali ke Ikon
    } else {
      _flipController.forward(); // Putar ke Teks
    }
    
    // 2. JALANKAN AUDIO DENGAN PELINDUNG (TRY-CATCH)
    try {
      await _flutterTts.stop();
      await _audioPlayer.stop(); 
      await _flutterTts.setPitch(1.3); 
      
      if (wasFlipped) {
        // KARTU KEMBALI KE DEPAN -> BACA KATA UTUH (TTS UNTUK SEMUA BAHASA)
        await _flutterTts.setVolume(tts.volume);
        await _flutterTts.setSpeechRate(tts.speechRate);
        await _flutterTts.setLanguage(lang.ttsLanguage);
        _flutterTts.speak(lang.getText(currentCard['nameKey'])); 

      } else {
        // KARTU DIBALIK KE BELAKANG -> EJA KATA (HYBRID)
        if (lang.ttsLanguage == 'en-US' || lang.ttsLanguage.startsWith('en')) {
          // --- INGGRIS: Pake TTS ---
          await _flutterTts.setVolume(tts.volume);
          await _flutterTts.setSpeechRate(tts.spellRate); 
          await _flutterTts.setLanguage(lang.ttsLanguage);
          
          String word = lang.getText(currentCard['nameKey']);
          String spelledText = word.split('').join('. '); 
          _flutterTts.speak(spelledText); 
          
        } else {
          // --- INDONESIA: Pake MP3 dari folder ---
          String fileName = '${currentCard['nameKey']}_spell.mp3';
          
          await _audioPlayer.setPlaybackRate(tts.spellRate); 
          // Jika MP3 belum ada, kode ini akan 'gagal dengan aman' tanpa merusak aplikasi
          await _audioPlayer.play(AssetSource('audio/Spell/$fileName'));
        }
      }
    } catch (e) {
      debugPrint("Audio dilewati (Mungkin file MP3 belum dimasukkan): $e");
    }
  }

  void _nextCard() {
    if (_currentIndex < _flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _resetCardState();
      });
    }
  }

  void _prevCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _resetCardState();
      });
    }
  }

  void _resetCardState() {
    if (_isFlipped) {
      _isFlipped = false;
      _flipController.value = 0.0; // Mengembalikan nilai ke depan tanpa stuck
    }
    _flutterTts.stop();
    _audioPlayer.stop();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final currentCard = _flashcards[_currentIndex];

    // UKURAN RESPONSIVE (Kartu membesar menyesuaikan tablet/layar)
    final size = MediaQuery.of(context).size;
    final double cardHeight = min(size.width, size.height) * 0.70; 
    final double cardWidth = cardHeight + 120; // Dibuat memanjang seperti lanskap
    final double iconSize = cardHeight * 0.5; 
    final double textSize = cardHeight * 0.18; 

    return Scaffold(
      backgroundColor: const Color(0xFFFAF0E6),
      appBar: AppBar(
        title: Text(lang.getText('flashcard_title'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: const Color(0xFFB0E0E6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TOMBOL PREVIOUS BUNDAR
            IconButton(
              iconSize: 70,
              color: const Color(0xFFFFA07A),
              icon: const Icon(Icons.arrow_circle_left),
              onPressed: _currentIndex > 0 ? _prevCard : null,
              splashRadius: 50,
            ),
            
            SizedBox(width: size.width * 0.05),

            // KARTU FLASHCARD
            GestureDetector(
              onTap: _flipCard,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final angle = _animation.value * pi;
                  final isBack = angle > pi / 2;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: Container(
                      width: cardWidth,
                      height: cardHeight,
                      decoration: BoxDecoration(
                        color: isBack ? Colors.white : currentCard['color'],
                        borderRadius: BorderRadius.circular(30),
                        // BORDER PUTIH TEBAL SEPERTI SCREENSHOT
                        border: Border.all(color: Colors.white, width: 10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15), 
                            blurRadius: 15, 
                            spreadRadius: 2, 
                            offset: const Offset(0, 8)
                          ),
                        ],
                      ),
                      child: Center(
                        child: isBack
                            ? Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(pi),
                                child: Text(
                                  lang.getText(currentCard['nameKey']).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: textSize, 
                                    fontWeight: FontWeight.bold, 
                                    color: Colors.black87, 
                                    letterSpacing: 5.0
                                  ),
                                ),
                              )
                            : currentCard['icon'] is IconData
                                ? Icon(currentCard['icon'], size: iconSize, color: Colors.black54)
                                : FaIcon(currentCard['icon'], size: iconSize, color: Colors.black54),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            SizedBox(width: size.width * 0.05),

            // TOMBOL NEXT BUNDAR
            IconButton(
              iconSize: 70,
              color: const Color(0xFF98FB98),
              icon: const Icon(Icons.arrow_circle_right),
              onPressed: _currentIndex < _flashcards.length - 1 ? _nextCard : null,
              splashRadius: 50,
            ),
          ],
        ),
      ),
    );
  }
}