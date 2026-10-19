import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'language_provider.dart'; // Import Provider Bahasa

class FirstThenScreen extends StatefulWidget {
  const FirstThenScreen({super.key});

  @override
  State<FirstThenScreen> createState() => _FirstThenScreenState();
}

class _FirstThenScreenState extends State<FirstThenScreen> {
  File? _firstImage;
  File? _thenImage;

  Future<void> _pickImage(bool isFirstCard) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isFirstCard) {
          _firstImage = File(pickedFile.path);
        } else {
          _thenImage = File(pickedFile.path);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF0E6), 
      appBar: AppBar(
        backgroundColor: const Color(0xFFB0E0E6), 
        title: Text(lang.getText('first_then_title'), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCard(
                titleKey: 'first',
                titleColor: const Color(0xFFFFA07A), 
                icon: Icons.menu_book,
                taskNameKey: 'task_study',
                imageFile: _firstImage,
                onTapGantiGambar: () => _pickImage(true), 
                lang: lang,
              ),
              const Icon(Icons.arrow_forward_rounded, size: 80, color: Colors.black38),
              _buildCard(
                titleKey: 'then',
                titleColor: const Color(0xFF98FB98), 
                icon: Icons.tablet_mac,
                taskNameKey: 'task_ipad',
                imageFile: _thenImage,
                onTapGantiGambar: () => _pickImage(false),
                lang: lang, 
              ),
            ],
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
  }) {
    return Container(
      width: 250,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
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
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(imageFile, width: 100, height: 100, fit: BoxFit.cover),
                      )
                    : Icon(icon, size: 100, color: Colors.black54),
                
                const SizedBox(height: 10),
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
    );
  }
}