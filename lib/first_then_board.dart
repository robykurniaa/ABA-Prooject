import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Tambahan Import

import 'language_provider.dart'; 
import 'tts_provider.dart';

class FirstThenScreen extends StatefulWidget {
  const FirstThenScreen({super.key});

  @override
  State<FirstThenScreen> createState() => _FirstThenScreenState();
}

class _FirstThenScreenState extends State<FirstThenScreen> {
  File? _firstImage;
  File? _thenImage;
  bool _isFirstTaskDone = false; 
  
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _loadSavedData(); // Muat data tersimpan saat layar dibuka
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  // --- LOGIKA PENYIMPANAN PERMANEN (SHARED PREFERENCES) ---
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      String? firstImagePath = prefs.getString('firstImagePath');
      String? thenImagePath = prefs.getString('thenImagePath');
      
      if (firstImagePath != null && File(firstImagePath).existsSync()) {
        _firstImage = File(firstImagePath);
      }
      if (thenImagePath != null && File(thenImagePath).existsSync()) {
        _thenImage = File(thenImagePath);
      }
      
      _isFirstTaskDone = prefs.getBool('isFirstTaskDone') ?? false;
    });
  }

  Future<void> _saveImagePath(bool isFirstCard, String path) async {
    final prefs = await SharedPreferences.getInstance();
    if (isFirstCard) {
      await prefs.setString('firstImagePath', path);
    } else {
      await prefs.setString('thenImagePath', path);
    }
  }

  Future<void> _saveTaskStatus(bool isDone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTaskDone', isDone);
  }
  // ---------------------------------------------------------

  Future<void> _pickImage(bool isFirstCard) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isFirstCard) {
          _firstImage = File(pickedFile.path);
          _isFirstTaskDone = false; 
          _saveTaskStatus(false); 
        } else {
          _thenImage = File(pickedFile.path);
        }
      });
      _saveImagePath(isFirstCard, pickedFile.path); 
    }
  }

  Future<void> _speakInstruction(String firstTask, String thenTask, LanguageProvider lang, TtsProvider tts) async {
    String instruction = "${lang.getText('first')}, $firstTask. ${lang.getText('then')}, $thenTask.";
    
    try {
      await _flutterTts.stop();
      await _flutterTts.setVolume(tts.volume);
      await _flutterTts.setSpeechRate(tts.speechRate);
      await _flutterTts.setLanguage(lang.ttsLanguage);
      await _flutterTts.speak(instruction); 
    } catch (e) {
      debugPrint("Error TTS First-Then: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final tts = context.watch<TtsProvider>(); 

    String firstTaskName = lang.getText('task_study');
    String thenTaskName = lang.getText('task_ipad');

    return Scaffold(
      backgroundColor: const Color(0xFFFAF0E6), 
      appBar: AppBar(
        backgroundColor: const Color(0xFFB0E0E6), 
        title: Text(lang.getText('first_then_title'), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 30),
            onPressed: () {
              setState(() {
                _isFirstTaskDone = false;
                _saveTaskStatus(false); 
              });
            },
          )
        ],
      ),
      body: SingleChildScrollView( 
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0), 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // KARTU PERTAMA (Bisa diklik untuk centang selesai)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isFirstTaskDone = !_isFirstTaskDone;
                          _saveTaskStatus(_isFirstTaskDone); 
                        });
                      },
                      child: _buildCard(
                        titleKey: 'first',
                        titleColor: const Color(0xFFFFA07A), 
                        icon: Icons.menu_book,
                        taskNameKey: 'task_study',
                        imageFile: _firstImage,
                        onTapGantiGambar: () => _pickImage(true), 
                        lang: lang,
                        isDone: _isFirstTaskDone, 
                      ),
                    ),
                    
                    const Icon(Icons.arrow_forward_rounded, size: 80, color: Colors.black38),
                    
                    // KARTU LALU (HADIAH)
                    _buildCard(
                      titleKey: 'then',
                      titleColor: const Color(0xFF98FB98), 
                      icon: Icons.tablet_mac,
                      taskNameKey: 'task_ipad',
                      imageFile: _thenImage,
                      onTapGantiGambar: () => _pickImage(false),
                      lang: lang, 
                      isDone: false, 
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB0E0E6),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                  ),
                  onPressed: () => _speakInstruction(firstTaskName, thenTaskName, lang, tts),
                  icon: const Icon(Icons.record_voice_over, color: Colors.black87, size: 30),
                  label: const Text("Bacakan Instruksi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String titleKey, 
    required Color titleColor, 
    required IconData icon, 
    required String taskNameKey,
    File? imageFile, 
    required VoidCallback onTapGantiGambar,
    required LanguageProvider lang,
    required bool isDone, 
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: isDone ? 0.4 : 1.0, 
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 5)),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min, 
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(color: titleColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                  child: Text(
                    lang.getText(titleKey),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0), 
                  child: Column(
                    children: [
                      imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(imageFile, width: 100, height: 100, fit: BoxFit.cover),
                            )
                          : Icon(icon, size: 100, color: Colors.black54),
                      
                      const SizedBox(height: 15),
                      Text(lang.getText(taskNameKey), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: TextButton.icon(
                    onPressed: onTapGantiGambar, 
                    icon: const Icon(Icons.photo_library, color: Colors.grey),
                    label: Text(lang.getText('change_image'), style: const TextStyle(color: Colors.grey)),
                  ),
                )
              ],
            ),
            if (isDone)
              const Icon(Icons.check_circle, size: 150, color: Colors.green),
          ],
        ),
      ),
    );
  }
}