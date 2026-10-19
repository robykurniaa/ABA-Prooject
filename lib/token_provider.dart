import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TokenProvider extends ChangeNotifier {
  int _currentTokens = 0;
  int _maxTokens = 5; 
  String _rewardNameKey = "choose_reward"; 
  String _tokenIconKey = "star"; // Ikon token default

  int get currentTokens => _currentTokens;
  int get maxTokens => _maxTokens;
  String get rewardNameKey => _rewardNameKey;
  String get tokenIconKey => _tokenIconKey;

  TokenProvider() {
    _loadData(); // Langsung muat data saat aplikasi dibuka
  }

  dynamic getTokenIcon() {
    switch (_tokenIconKey) {
      case 'fish': return FontAwesomeIcons.fish;
      case 'car': return Icons.directions_car;
      case 'apple': return Icons.apple;
      case 'rocket': return Icons.rocket_launch;
      case 'dog': return FontAwesomeIcons.dog;
      case 'star':
      default: return Icons.star;
    }
  }

  // Menerjemahkan kode string menjadi gambar ikon Hadiah
  IconData? getRewardIcon() {
    switch (_rewardNameKey) {
      case 'reward_gadget': return Icons.tablet_mac;
      case 'reward_snack': return Icons.cookie;
      case 'reward_toy': return Icons.toys;
      case 'reward_park': return Icons.park;
      case 'reward_tv': return Icons.tv;
      default: return null;
    }
  }

  // --- LOGIKA SHARED PREFERENCES (PENYIMPANAN PERMANEN) ---
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _currentTokens = prefs.getInt('currentTokens') ?? 0;
    _maxTokens = prefs.getInt('maxTokens') ?? 5;
    _rewardNameKey = prefs.getString('rewardNameKey') ?? "choose_reward";
    _tokenIconKey = prefs.getString('tokenIconKey') ?? "star";
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentTokens', _currentTokens);
    await prefs.setInt('maxTokens', _maxTokens);
    await prefs.setString('rewardNameKey', _rewardNameKey);
    await prefs.setString('tokenIconKey', _tokenIconKey);
  }

  // --- FUNGSI UPDATE DATA ---
  void setMaxTokens(int target) {
    _maxTokens = target;
    if (_currentTokens > _maxTokens) _currentTokens = _maxTokens;
    _saveData();
    notifyListeners();
  }

  void setReward(String nameKey) {
    _rewardNameKey = nameKey;
    _saveData();
    notifyListeners();
  }

  void setTokenIcon(String iconKey) {
    _tokenIconKey = iconKey;
    _saveData();
    notifyListeners();
  }

  void addToken() {
    if (_currentTokens < _maxTokens) {
      _currentTokens++;
      _saveData();
      notifyListeners();
    }
  }

  void setTokens(int tokens) {
    if (tokens >= 0 && tokens <= _maxTokens) {
      _currentTokens = tokens;
      _saveData();
      notifyListeners();
    }
  }

  void resetTokens() {
    _currentTokens = 0;
    _saveData();
    notifyListeners();
  }
}