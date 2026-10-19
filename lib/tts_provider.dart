import 'package:flutter/material.dart';

class TtsProvider extends ChangeNotifier {
  double _volume = 0.6;
  double _speechRate = 0.35;
  double _spellRate = 0.15; // Kecepatan ejaan default, lebih lambat dari bicara normal

  double get volume => _volume;
  double get speechRate => _speechRate;
  double get spellRate => _spellRate;

  void setVolume(double newVolume) {
    _volume = newVolume;
    notifyListeners();
  }

  void setSpeechRate(double newRate) {
    _speechRate = newRate;
    notifyListeners();
  }
  
  // Fungsi baru untuk mengatur kecepatan ejaan
  void setSpellRate(double newRate) {
    _spellRate = newRate;
    notifyListeners();
  }
}