import 'package:flutter/material.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'language_provider.dart';

class LockHelper {
  // 1. Mengambil PIN dari memori HP (Default: 1111)
  static Future<String> getTherapistPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('therapist_pin') ?? '1111';
  }

  // 2. Menyimpan PIN baru ke memori HP secara permanen
  static Future<void> setTherapistPin(String newPin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('therapist_pin', newPin);
  }

  static Future<bool> showPinDialog(BuildContext context, String titleKey, LanguageProvider lang) async {
    String enteredPin = "";
    bool isUnlocked = false;
    String correctPin = await getTherapistPin(); // Ambil PIN aslinya

    if (!context.mounted) return false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFAF0E6),
          title: Text(lang.getText(titleKey), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 10),
            decoration: const InputDecoration(hintText: "****", counterText: ""),
            onChanged: (value) => enteredPin = value,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.getText('cancel'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF98FB98)),
              onPressed: () {
                if (enteredPin == correctPin) {
                  isUnlocked = true;
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(lang.getText('wrong_pin'), style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
                  );
                }
              },
              child: Text(lang.getText('unlock'), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
    return isUnlocked;
  }

  static Future<void> toggleKioskMode(BuildContext context, LanguageProvider lang) async {
    final mode = await getKioskMode();
    bool isCurrentlyLocked = mode == KioskMode.enabled;

    if (isCurrentlyLocked) {
      bool unlocked = await showPinDialog(context, 'kiosk_off_pin', lang);
      if (unlocked) {
        await stopKioskMode();
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.getText('kiosk_disabled'))));
        }
      }
    } else {
      await startKioskMode();
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.getText('kiosk_enabled'))));
      }
    }
  }
}