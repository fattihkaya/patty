import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants.dart';
import 'onboarding_analysis_screen.dart';

class OnboardingPhotoScreen extends StatefulWidget {
  const OnboardingPhotoScreen({super.key});

  @override
  State<OnboardingPhotoScreen> createState() => _OnboardingPhotoScreenState();
}

class _OnboardingPhotoScreenState extends State<OnboardingPhotoScreen> {
  XFile? _imageFile;
  Uint8List? _webImage;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _imageFile = pickedFile;
          });
        } else {
          setState(() {
            _imageFile = pickedFile;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotoğraf seçilemedi.')),
      );
    }
  }

  void _analyze() {
    if (_imageFile == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingAnalysisScreen(
          imageFile: _imageFile!,
          webImage: _webImage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(isEn ? 'Upload Photo' : 'Fotoğraf Yükle'),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  isEn 
                      ? 'Great! Now choose a photo of your furry friend, and let\'s start the first AI analysis.'
                      : 'Harika! Şimdi can dostunun bir fotoğrafını seç, ilk AI analizini başlatalım.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.primaryColor,
                    height: 1.3,
                  ),
                ).animate().fadeIn(delay: 200.ms).moveY(begin: 10, end: 0),
                const SizedBox(height: 40),
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          color: AppConstants.surfaceColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _imageFile == null
                                ? AppConstants.primaryLight.withValues(alpha: 0.5)
                                : AppConstants.primaryColor,
                            width: 2,
                          ),
                          boxShadow: [
                            if (_imageFile != null)
                              BoxShadow(
                                color: AppConstants.primaryColor.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                          ],
                        ),
                        child: _imageFile == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_rounded,
                                    size: 64,
                                    color: AppConstants.primaryColor.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    isEn ? 'Choose from Gallery' : 'Galeriden Seç',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppConstants.lightTextColor,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: kIsWeb && _webImage != null
                                    ? Image.memory(_webImage!, fit: BoxFit.contain)
                                    : Image.file(File(_imageFile!.path), fit: BoxFit.contain),
                              ),
                      ),
                    ).animate().fadeIn(delay: 400.ms).scale(),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 56,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    gradient: AppConstants.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _imageFile != null ? [
                      BoxShadow(
                        color: AppConstants.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ] : null,
                  ),
                  child: ElevatedButton(
                    onPressed: _imageFile == null ? null : _analyze,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isEn ? 'Start AI Analysis ✨' : 'AI Analizini Başlat ✨',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
