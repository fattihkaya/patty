import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants.dart';
import '../../core/health_parameters.dart';
import 'onboarding_register_wall_screen.dart';

class OnboardingResultScreen extends StatelessWidget {
  final XFile imageFile;
  final Uint8List? webImage;
  final String? aiAnalysisJson;

  const OnboardingResultScreen({
    super.key,
    required this.imageFile,
    this.webImage,
    this.aiAnalysisJson,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? parsedData;
    if (aiAnalysisJson != null) {
      try {
        parsedData = jsonDecode(aiAnalysisJson!);
      } catch (e) {
        debugPrint('JSON Decode Error (Onboarding): $e\nData: $aiAnalysisJson');
      }
    }
    
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    String? petVoice;
    String? summary;
    String? careTip;
    String? moodLabel;
    String? species;
    String? breed;
    
    if (parsedData != null) {
      petVoice = isEn 
          ? (parsedData['pet_voice_en'] ?? parsedData['pet_voice_tr']) 
          : (parsedData['pet_voice_tr'] ?? parsedData['pet_voice_en']);
          
      summary = isEn 
          ? (parsedData['summary_en'] ?? parsedData['summary_tr']) 
          : (parsedData['summary_tr'] ?? parsedData['summary_en']);
          
      careTip = isEn 
          ? (parsedData['care_tip_en'] ?? parsedData['care_tip_tr']) 
          : (parsedData['care_tip_tr'] ?? parsedData['care_tip_en']);
          
      moodLabel = parsedData['mood_label']?.toString();
      species = parsedData['species']?.toString();
      breed = parsedData['breed']?.toString();
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 30),
                      Text(
                        isEn ? 'First Analysis Complete! ✨' : 'İlk Analiz Tamamlandı! ✨',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppConstants.primaryColor,
                        ),
                      ).animate().fadeIn(delay: 300.ms).moveY(begin: 10, end: 0),
                      const SizedBox(height: 30),
                      
                      Center(
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.5), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.primaryColor.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: kIsWeb && webImage != null
                                ? Image.memory(webImage!, fit: BoxFit.cover)
                                : Image.file(File(imageFile.path), fit: BoxFit.cover),
                          ),
                        ),
                      ).animate().scale(delay: 500.ms, curve: Curves.easeOutBack),
                      
                      const SizedBox(height: 30),

                      if (petVoice != null || summary != null) ...[
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppConstants.surfaceColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppConstants.primaryColor.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (moodLabel != null || species != null || breed != null) ...[
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    if (moodLabel != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppConstants.primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          moodLabel.toString().toUpperCase(),
                                          style: GoogleFonts.plusJakartaSans(
                                            color: AppConstants.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                    if (species != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.pinkAccent.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          species.toString().toUpperCase(),
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.pinkAccent,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                    if (breed != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.orangeAccent.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          breed.toString().toUpperCase(),
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.orangeAccent,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (petVoice != null) ...[
                                Icon(Icons.format_quote_rounded, color: AppConstants.primaryColor.withValues(alpha: 0.5), size: 40),
                                const SizedBox(height: 8),
                                Text(
                                  petVoice,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              if (summary != null) ...[
                                const SizedBox(height: 20),
                                const Divider(color: Colors.white12),
                                const SizedBox(height: 16),
                                Text(
                                  summary,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    color: AppConstants.lightTextColor,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                              if (careTip != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppConstants.primaryLight.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.lightbulb_outline_rounded, color: AppConstants.primaryLight, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          careTip,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            color: AppConstants.primaryLight,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ).animate().fadeIn(delay: 700.ms).moveY(begin: 20, end: 0),
                        
                        if (parsedData != null) ...[
                          const SizedBox(height: 24),
                          Text(
                            isEn ? 'Health Parameters' : 'Sağlık Parametreleri',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppConstants.primaryColor,
                              letterSpacing: AppConstants.letterSpacingBold,
                            ),
                          ).animate().fadeIn(delay: 800.ms),
                          const SizedBox(height: 16),
                          GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.15,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: kHealthParameters.length,
                          itemBuilder: (context, index) {
                            final param = kHealthParameters[index];
                            final score = parsedData![param.key + '_score'];
                            final note = parsedData[param.key + '_note'];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppConstants.surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isEn ? param.shortLabelEn : param.shortLabel,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: param.color,
                                        ),
                                      ),
                                      if (score != null)
                                        Text(
                                          '$score/5',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: param.color,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (score != null) ...[
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: (score is num ? score.toDouble() : double.tryParse(score.toString()) ?? 0.0) / 5.0,
                                        minHeight: 6,
                                        backgroundColor: param.color.withValues(alpha: 0.15),
                                        valueColor: AlwaysStoppedAnimation<Color>(param.color),
                                      ),
                                    ),
                                  ],
                                  if (note != null && note.toString().trim().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: Text(
                                        note.toString(),
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: AppConstants.lightTextColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ).animate().fadeIn(delay: 900.ms).moveY(begin: 20, end: 0),
                        
                        const SizedBox(height: 24),
                        ]
                      ] else if (aiAnalysisJson != null && aiAnalysisJson!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                isEn ? 'Data could not be read (Debug):\n\n$aiAnalysisJson' : 'Gelen veri okunamadı (Debug):\n\n$aiAnalysisJson',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Text(
                          isEn ? 'Analysis results could not be retrieved. Please try again later.' : 'Analiz sonuçların alınamadı. Lütfen daha sonra tekrar dene.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            color: AppConstants.errorColor,
                            height: 1.5,
                          ),
                        ).animate().fadeIn(delay: 500.ms),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppConstants.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OnboardingRegisterWallScreen(
                            imageFile: imageFile,
                            webImage: webImage,
                            aiAnalysisJson: aiAnalysisJson,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isEn ? 'Save Results & Continue' : 'Sonuçları Kaydet & Devam Et',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F172A)),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 900.ms).scale(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
