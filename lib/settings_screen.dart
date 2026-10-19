import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'language_provider.dart';
import 'tts_provider.dart';
import 'lock_helper.dart'; // Wajib Import LockHelper untuk Ganti PIN

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // FUNGSI GANTI PIN
  Future<void> _changePin(BuildContext context, LanguageProvider lang) async {
    // 1. Minta PIN lama dulu untuk keamanan
    bool isAuthorized = await LockHelper.showPinDialog(context, 'enter_pin', lang);
    
    if (isAuthorized && context.mounted) {
      String newPin = "";
      
      // 2. Tampilkan dialog untuk memasukkan PIN baru
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFFFAF0E6),
          title: Text(lang.getText('new_pin_title'), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 10),
            decoration: const InputDecoration(hintText: "****", counterText: ""),
            onChanged: (value) => newPin = value,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.getText('cancel'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF98FB98)),
              onPressed: () async {
                if (newPin.length == 4) {
                  await LockHelper.setTherapistPin(newPin); // Simpan PIN Baru secara permanen
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(lang.getText('pin_changed_success')), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              child: Text(lang.getText('save'), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final tts = context.watch<TtsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.getText('settings_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFB0E0E6),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 500,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
            margin: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // KOTAK MENU MUTE & GANTI PIN
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100, 
                    borderRadius: BorderRadius.circular(15)
                  ),
                  child: Column(
                    children: [
                      // SAKLAR MUTE
                      SwitchListTile(
                        title: Text(lang.getText('mute_universal'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(lang.getText('mute_desc')),
                        value: tts.isMuted,
                        activeColor: Colors.red,
                        secondary: Icon(tts.isMuted ? Icons.volume_off : Icons.volume_up, color: tts.isMuted ? Colors.red : Colors.green),
                        onChanged: (val) => tts.toggleMute(val),
                      ),
                      const Divider(),
                      // TOMBOL GANTI PIN
                      ListTile(
                        leading: const Icon(Icons.lock_reset, color: Colors.orange, size: 30),
                        title: Text(lang.getText('change_pin'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _changePin(context, lang),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // SLIDER 1: VOLUME SUARA
                Text(lang.getText('volume_label'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    const Icon(Icons.volume_down),
                    Expanded(
                      child: Slider(
                        value: tts.volume,
                        min: 0.0, max: 1.0, activeColor: Colors.blueAccent,
                        onChanged: tts.isMuted ? null : (val) => tts.setVolume(val), // Kunci slider jika mute aktif
                      ),
                    ),
                    const Icon(Icons.volume_up),
                  ],
                ),
                const SizedBox(height: 30),
                
                // SLIDER 2: KECEPATAN BICARA (SPEECH RATE)
                Text(lang.getText('speed_label'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    const Icon(Icons.directions_walk), 
                    Expanded(
                      child: Slider(
                        value: tts.speechRate,
                        min: 0.1, max: 1.0, activeColor: Colors.green,
                        onChanged: (val) => tts.setSpeechRate(val),
                      ),
                    ),
                    const Icon(Icons.directions_run), 
                  ],
                ),
                const SizedBox(height: 30),
                
                // SLIDER 3: KECEPATAN EJAAN (SPELL RATE)
                Text(lang.getText('spell_speed_label'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    const Icon(Icons.abc), 
                    Expanded(
                      child: Slider(
                        value: tts.spellRate,
                        min: 0.1, max: 1.0, activeColor: Colors.orange, 
                        onChanged: (val) => tts.setSpellRate(val),
                      ),
                    ),
                    const Icon(Icons.spellcheck), 
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}