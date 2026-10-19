import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'language_provider.dart';
import 'tts_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
        // INI WIDGET BARU AGAR BISA DI-SCROLL KE BAWAH
        child: SingleChildScrollView(
          child: Container(
            width: 500,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
            margin: const EdgeInsets.symmetric(vertical: 20), // Tambahan margin agar tidak nempel atas/bawah
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
                // SLIDER 1: VOLUME SUARA
                Text(lang.getText('volume_label'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    const Icon(Icons.volume_down),
                    Expanded(
                      child: Slider(
                        value: tts.volume,
                        min: 0.0,
                        max: 1.0,
                        activeColor: Colors.blueAccent,
                        onChanged: (val) => tts.setVolume(val),
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
                    const Icon(Icons.directions_walk), // Ikon lambat
                    Expanded(
                      child: Slider(
                        value: tts.speechRate,
                        min: 0.1,
                        max: 1.0,
                        activeColor: Colors.green,
                        onChanged: (val) => tts.setSpeechRate(val),
                      ),
                    ),
                    const Icon(Icons.directions_run), // Ikon cepat
                  ],
                ),
                const SizedBox(height: 30),
                
                // SLIDER 3: KECEPATAN EJAAN (SPELL RATE)
                Text(lang.getText('spell_speed_label'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    const Icon(Icons.abc), // Ikon huruf
                    Expanded(
                      child: Slider(
                        value: tts.spellRate,
                        min: 0.1,
                        max: 1.0,
                        activeColor: Colors.orange, // Warna oranye
                        onChanged: (val) => tts.setSpellRate(val),
                      ),
                    ),
                    const Icon(Icons.spellcheck), // Ikon ejaan
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