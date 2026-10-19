import 'package:flutter/material.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'language_provider.dart'; // Import kamus bahasa

class LockHelper {
  // PIN RAHASIA TERAPIS
  static const String therapistPin = "1111";

  // Fungsi Dialog PIN sekarang butuh 'LanguageProvider' dan 'titleKey' dari kamus
  static Future<bool> showPinDialog(BuildContext context, String titleKey, LanguageProvider lang) async {
    String enteredPin = "";
    bool isUnlocked = false;

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
            decoration: const InputDecoration(
              hintText: "****",
              counterText: "",
            ),
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
                if (enteredPin == therapistPin) {
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

  // Fungsi Toggle Kiosk juga dikirim 'LanguageProvider' agar Snackbarnya berbahasa Inggris/Indonesia
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