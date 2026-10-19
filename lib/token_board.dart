import 'package:flutter/material.dart';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// IMPORT FILE BANTUAN KITA
import 'token_provider.dart'; 
import 'language_provider.dart'; 
import 'lock_helper.dart'; 

class TokenBoardScreen extends StatefulWidget {
  const TokenBoardScreen({super.key});

  @override
  State<TokenBoardScreen> createState() => _TokenBoardScreenState();
}

class _TokenBoardScreenState extends State<TokenBoardScreen> {
  late ConfettiController _confettiController;
  bool _isSad = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound(String fileName) async {
    await _audioPlayer.stop();
    try {
      await _audioPlayer.play(AssetSource('audio/$fileName'));
    } catch (e) {
      debugPrint("Audio belum ada: $e");
    }
  }

  void _onTokenTapped(int index, TokenProvider provider) {
    int currentTokens = provider.currentTokens;
    int maxTokens = provider.maxTokens;

    // SKENARIO 1: MENAMBAH TOKEN
    if (index == currentTokens && currentTokens < maxTokens) {
      provider.addToken(); 
      setState(() => _isSad = false);
      
      if (provider.currentTokens == maxTokens) {
        _confettiController.play();
        _playSound('celebrate.mp3');
      } else {
        _playSound('happy.mp3');
      }
    } 
    // SKENARIO 2: MENGURANGI TOKEN
    else if (index < currentTokens) {
      provider.setTokens(index); 
      setState(() => _isSad = true);
      _playSound('sad.mp3');
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isSad = false);
      });
    }
  }

  void _resetBoard(TokenProvider provider) {
    provider.resetTokens();
    setState(() => _isSad = false);
    _confettiController.stop();
    _audioPlayer.stop();
  }

  // ==========================================
  // DIALOG MEMILIH HADIAH (REWARD)
  // ==========================================
  void _showRewardPicker(BuildContext context, TokenProvider provider, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAF0E6),
        title: Text(lang.getText('reward_title'), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 20,
          children: [
            _buildRewardOption(context, provider, Icons.tablet_mac, 'reward_gadget', lang),
            _buildRewardOption(context, provider, Icons.cookie, 'reward_snack', lang),
            _buildRewardOption(context, provider, Icons.toys, 'reward_toy', lang),
            _buildRewardOption(context, provider, Icons.park, 'reward_park', lang),
            _buildRewardOption(context, provider, Icons.tv, 'reward_tv', lang),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardOption(BuildContext context, TokenProvider provider, IconData icon, String nameKey, LanguageProvider lang) {
    return InkWell(
      onTap: () {
        provider.setReward(nameKey); // Hanya simpan string nameKey agar aman di SharedPreferences
        Navigator.pop(context);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 35, backgroundColor: const Color(0xFFB0E0E6), child: Icon(icon, size: 40, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(lang.getText(nameKey), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ==========================================
  // DIALOG MEMILIH BENTUK TOKEN (CUSTOM ICON)
  // ==========================================
  void _showTokenPicker(BuildContext context, TokenProvider provider, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAF0E6),
        title: Text(lang.getText('choose_token'), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 20,
          children: [
            _buildTokenOption(context, provider, Icons.star, 'star', Colors.orange),
            _buildTokenOption(context, provider, FontAwesomeIcons.fish, 'fish', Colors.teal),
            _buildTokenOption(context, provider, Icons.directions_car, 'car', Colors.blueAccent),
            _buildTokenOption(context, provider, Icons.rocket_launch, 'rocket', Colors.deepPurple),
            _buildTokenOption(context, provider, Icons.apple, 'apple', Colors.redAccent),
            _buildTokenOption(context, provider, FontAwesomeIcons.dog, 'dog', Colors.brown),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenOption(BuildContext context, TokenProvider provider, dynamic iconData, String iconKey, Color color) {
    return InkWell(
      onTap: () {
        provider.setTokenIcon(iconKey); // Simpan nama icon (string)
        Navigator.pop(context);
      },
      child: CircleAvatar(
        radius: 35,
        backgroundColor: Colors.white,
        child: iconData is IconData
            ? Icon(iconData, size: 40, color: color)
            : FaIcon(iconData, size: 40, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokenProvider = context.watch<TokenProvider>();
    final lang = context.watch<LanguageProvider>();
    
    int currentTokens = tokenProvider.currentTokens;
    int maxTokens = tokenProvider.maxTokens;
    dynamic currentTokenIcon = tokenProvider.getTokenIcon(); // Ambil Icon dinamis
    IconData? currentRewardIcon = tokenProvider.getRewardIcon(); 

    return PopScope(
      canPop: false, 
      onPopInvoked: (didPop) async {
        if (didPop) return;
        // PERBAIKAN: Gunakan kunci kamus 'enter_pin' dan kirimkan variabel 'lang'
        bool unlocked = await LockHelper.showPinDialog(context, 'enter_pin', lang);
        if (unlocked && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF0E6),
        appBar: AppBar(
          backgroundColor: const Color(0xFFB0E0E6),
          leading: IconButton(
            icon: const Icon(Icons.lock, color: Colors.redAccent, size: 30),
            tooltip: 'Keluar (Butuh PIN)',
            onPressed: () async {
              // PERBAIKAN: Gunakan kunci kamus 'enter_pin' dan kirimkan variabel 'lang'
              bool unlocked = await LockHelper.showPinDialog(context, 'enter_pin', lang);
              if (unlocked && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          // ... (Sisa kode ke bawah tetap sama) ...
          title: Text(lang.getText('token_title'), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.black87),
          actions: [
            // TOMBOL GANTI BENTUK TOKEN
            IconButton(
              icon: const Icon(Icons.category, size: 30),
              tooltip: lang.getText('choose_token'),
              onPressed: () => _showTokenPicker(context, tokenProvider, lang),
            ),
            const SizedBox(width: 10),
            // TOMBOL GANTI TARGET TOKEN
            PopupMenuButton<int>(
              icon: const Icon(Icons.settings, size: 30),
              tooltip: lang.getText('change_target'),
              onSelected: (value) => tokenProvider.setMaxTokens(value),
              itemBuilder: (context) => [
                PopupMenuItem(value: 3, child: Text(lang.getText('target_3'))),
                PopupMenuItem(value: 5, child: Text(lang.getText('target_5'))),
                PopupMenuItem(value: 10, child: Text(lang.getText('target_10'))),
              ],
            ),
            const SizedBox(width: 10),
            // TOMBOL RESET
            IconButton(
              icon: const Icon(Icons.refresh, size: 30),
              tooltip: lang.getText('reset_board'),
              onPressed: () => _resetBoard(tokenProvider),
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            // EFEK CONFETTI
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
            ),
            
            // KONTEN UTAMA PAPAN
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // BAGIAN HADIAH (REWARD)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(lang.getText('working_for'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () => _showRewardPicker(context, tokenProvider, lang),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.black12, width: 2),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)],
                        ),
                        child: Row(
                          children: [
                            if (currentRewardIcon != null) ...[
                              Icon(currentRewardIcon, size: 40, color: Colors.blueAccent),
                              const SizedBox(width: 10),
                            ],
                            Text(
                              lang.getText(tokenProvider.rewardNameKey), 
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),

                // BAGIAN TOKEN (Bisa Ikan, Bintang, Mobil, dll)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 15,
                  runSpacing: 15,
                  children: List.generate(maxTokens, (index) {
                    bool isActive = index < currentTokens;
                    return GestureDetector(
                      onTap: () => _onTokenTapped(index, tokenProvider),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.bounceOut,
                        transform: Matrix4.identity()..scale(isActive ? 1.1 : 1.0),
                        child: currentTokenIcon is IconData
                            ? Icon(
                                currentTokenIcon, 
                                size: 80, 
                                color: isActive ? Colors.orange : Colors.grey.shade300
                              )
                            : FaIcon(
                                currentTokenIcon, 
                                size: 80, 
                                color: isActive ? Colors.orange : Colors.grey.shade300
                              ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 40),
                
                // TEKS MOTIVASI
                Text(
                  _isSad ? lang.getText('try_again') : 
                  (currentTokens == maxTokens ? lang.getText('hooray') : lang.getText('collect_stars')),
                  style: TextStyle(
                    fontSize: 26, 
                    fontWeight: FontWeight.bold, 
                    color: _isSad ? Colors.redAccent : Colors.black54
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}