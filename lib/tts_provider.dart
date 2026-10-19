import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Tambahkan import TTS

class TtsProvider extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts(); // Inisialisasi mesin suara

  double _volume = 0.6;
  double _speechRate = 0.35;
  double _spellRate = 0.15;
  bool _isMuted = false; // Status Mute Universal

  // Jika sedang Mute, paksa volume jadi 0. Jika tidak, pakai volume asli
  double get volume => _isMuted ? 0.0 : _volume;
  double get speechRate => _speechRate;
  double get spellRate => _spellRate;
  bool get isMuted => _isMuted;

  void setVolume(double newVolume) {
    _volume = newVolume;
    if (_volume > 0)
      _isMuted = false; // Otomatis lepas mute jika slider digeser
    notifyListeners();
  }

  void setSpeechRate(double newRate) {
    _speechRate = newRate;
    notifyListeners();
  }

  void setSpellRate(double newRate) {
    _spellRate = newRate;
    notifyListeners();
  }

  // Fungsi Toggle Mute
  void toggleMute(bool value) {
    _isMuted = value;
    notifyListeners();
  }

  // FUNGSI BARU UNTUK MEMBACA TEKS (GLOBAL)
  Future<void> speak(String text, String langCode) async {
    await _flutterTts.stop();
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setLanguage(langCode);
    await _flutterTts.speak(text);
  }
}
