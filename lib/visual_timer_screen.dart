import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart'; 
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Tambahan TTS

import 'language_provider.dart';
import 'tts_provider.dart';
import 'lock_helper.dart'; // Tambahan Proteksi PIN

class VisualTimerScreen extends StatefulWidget {
  const VisualTimerScreen({super.key});

  @override
  State<VisualTimerScreen> createState() => _VisualTimerScreenState();
}

class _VisualTimerScreenState extends State<VisualTimerScreen> with TickerProviderStateMixin {
  int _totalSeconds = 300; 
  int _remainingSeconds = 300;
  Timer? _timer;
  bool _isRunning = false;
  bool _isAlarmRinging = false; 

  final AudioPlayer _tickPlayer = AudioPlayer();
  final AudioPlayer _alarmPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts(); // Inisialisasi TTS

  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(_blinkController);
  }

  @override
  void dispose() {
    if (_timer != null) _timer!.cancel();
    _tickPlayer.dispose(); 
    _alarmPlayer.dispose();
    _flutterTts.stop(); // Hentikan TTS saat keluar
    _blinkController.dispose();
    super.dispose();
  }

  // --- LOGIKA PROTEKSI PIN (HANYA BISA DIAKSES TERAPIS) ---
  Future<void> _secureAction(LanguageProvider lang, VoidCallback action) async {
    bool unlocked = await LockHelper.showPinDialog(context, 'enter_pin', lang);
    if (unlocked && mounted) {
      action();
    }
  }

  // --- LOGIKA SUARA TTS WAKTU HABIS ---
  Future<void> _speakTimeUp(LanguageProvider lang, TtsProvider tts) async {
    await _flutterTts.setVolume(tts.volume);
    await _flutterTts.setSpeechRate(tts.speechRate);
    await _flutterTts.setLanguage(lang.ttsLanguage);
    await _flutterTts.speak(lang.getText('time_up'));
  }

  void _stopAlarm() {
    _alarmPlayer.stop();
    _tickPlayer.stop();
    _flutterTts.stop();
    setState(() => _isAlarmRinging = false);
  }

  void _startTimer(LanguageProvider lang, TtsProvider tts) {
    if (_isAlarmRinging) _stopAlarm(); 
    if (_timer != null) _timer!.cancel();
    setState(() => _isRunning = true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
        if (_remainingSeconds == 10) _blinkController.repeat(reverse: true); 
        if (_remainingSeconds <= 10 && _remainingSeconds > 0) _tickPlayer.play(AssetSource('audio/tick.mp3')); 
      } else {
        _timer!.cancel();
        setState(() {
          _isRunning = false;
          _isAlarmRinging = true; 
        });
        _blinkController.stop(); 
        _blinkController.value = 1.0; 
        
        // Putar Alarm Lonceng dilanjutkan ucapan TTS
        _alarmPlayer.play(AssetSource('audio/alarm.mp3')); 
        _speakTimeUp(lang, tts);
      }
    });
  }

  void _pauseTimer() {
    if (_timer != null) _timer!.cancel();
    setState(() => _isRunning = false);
    _blinkController.stop(); 
    _blinkController.value = 1.0; 
    _tickPlayer.stop(); 
  }

  void _resetTimer() {
    if (_timer != null) _timer!.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _totalSeconds;
    });
    _blinkController.stop();
    _blinkController.value = 1.0; 
    _stopAlarm(); 
  }

  void _setTimeInSeconds(int seconds) {
    if (_timer != null) _timer!.cancel();
    setState(() {
      _totalSeconds = seconds;
      _remainingSeconds = _totalSeconds;
      _isRunning = false;
    });
    _blinkController.stop();
    _blinkController.value = 1.0;
    _stopAlarm(); 
  }

  // Jika timer sedang jalan atau alarm nyala, minta PIN untuk ganti waktu
  void _handleSetTime(int seconds, LanguageProvider lang) {
    if (_isRunning || _isAlarmRinging) {
      _secureAction(lang, () => _setTimeInSeconds(seconds));
    } else {
      _setTimeInSeconds(seconds);
    }
  }

  String get _formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final tts = context.watch<TtsProvider>();
    bool isWarning = _remainingSeconds <= 10 && _remainingSeconds > 0;

    return PopScope(
      canPop: false, 
      onPopInvoked: (didPop) async {
        if (didPop) return;
        _secureAction(lang, () => Navigator.of(context).pop());
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF0E6), 
        appBar: AppBar(
          backgroundColor: const Color(0xFFB0E0E6), 
          leading: IconButton(
            icon: const Icon(Icons.lock, color: Colors.redAccent, size: 30),
            tooltip: 'Keluar (Butuh PIN)',
            onPressed: () => _secureAction(lang, () => Navigator.of(context).pop()),
          ),
          title: Text(lang.getText('timer_title'), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: SingleChildScrollView( 
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimeButton('15_sec', 15, lang),
                    const SizedBox(height: 10), 
                    _buildTimeButton('1_min', 60, lang),
                    const SizedBox(height: 10), 
                    _buildTimeButton('3_min', 180, lang),
                    const SizedBox(height: 10), 
                    _buildTimeButton('5_min', 300, lang),
                    const SizedBox(height: 10), 
                    _buildTimeButton('10_min', 600, lang),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: isWarning ? _blinkAnimation : const AlwaysStoppedAnimation(1.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox( 
                            width: 200, height: 200,
                            child: CircularProgressIndicator(
                              value: _remainingSeconds / _totalSeconds, 
                              strokeWidth: 100, // PERUBAHAN: Ditebalkan maksimal menjadi Pie Chart
                              backgroundColor: Colors.grey.shade300,
                              color: isWarning ? Colors.redAccent : const Color(0xFFFFB6C1), 
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(15)
                            ),
                            child: Text(
                              _formattedTime,
                              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: isWarning ? Colors.redAccent : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20), 
                    
                    _isAlarmRinging 
                        ? ElevatedButton.icon(
                            // PROTEKSI PIN: Menghentikan alarm butuh PIN
                            onPressed: () => _secureAction(lang, _stopAlarm),
                            icon: const Icon(Icons.notifications_off, color: Colors.white, size: 28),
                            label: Text(lang.getText('stop_alarm'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FloatingActionButton(
                                heroTag: "btn_play", 
                                backgroundColor: const Color(0xFF98FB98), 
                                onPressed: _isRunning ? null : () => _startTimer(lang, tts), 
                                child: const Icon(Icons.play_arrow, color: Colors.black87, size: 24)
                              ),
                              const SizedBox(width: 15),
                              FloatingActionButton(
                                heroTag: "btn_pause", 
                                backgroundColor: const Color(0xFFFFE4B5), 
                                // PROTEKSI PIN: Pause butuh PIN
                                onPressed: _isRunning ? () => _secureAction(lang, _pauseTimer) : null, 
                                child: const Icon(Icons.pause, color: Colors.black87, size: 24)
                              ),
                              const SizedBox(width: 15),
                              FloatingActionButton(
                                heroTag: "btn_reset", 
                                backgroundColor: const Color(0xFFFFA07A), 
                                // PROTEKSI PIN: Reset butuh PIN
                                onPressed: () => _secureAction(lang, _resetTimer), 
                                child: const Icon(Icons.refresh, color: Colors.black87, size: 24)
                              ),
                            ],
                          )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeButton(String key, int seconds, LanguageProvider lang) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      onPressed: () => _handleSetTime(seconds, lang),
      child: Text(lang.getText(key), style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold)),
    );
  }
}