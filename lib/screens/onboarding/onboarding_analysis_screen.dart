import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../core/constants.dart';
import '../../services/ai_service.dart';
import 'onboarding_result_screen.dart';

class OnboardingAnalysisScreen extends StatefulWidget {
  final XFile imageFile;
  final Uint8List? webImage;

  const OnboardingAnalysisScreen({
    super.key,
    required this.imageFile,
    this.webImage,
  });

  @override
  State<OnboardingAnalysisScreen> createState() => _OnboardingAnalysisScreenState();
}

class _OnboardingAnalysisScreenState extends State<OnboardingAnalysisScreen> {
  final List<String> _stages = [
    'Yapay zeka fotoğrafı inceliyor...',
    'Görsel öğeler tespit ediliyor...',
    'Tüy, göz ve post yapısı analiz ediliyor...',
    'Duygu durumu ve davranış analizi çıkarılıyor...',
    'Sağlık radar verileri derleniyor...',
  ];
  final List<String> _stagesEn = [
    'AI is analyzing the photo...',
    'Visual elements are being detected...',
    'Fur, eyes, and skin structure are being analyzed...',
    'Mood and behavioral analysis is being generated...',
    'Health radar data is being compiled...',
  ];
  int _currentStage = 0;
  Timer? _timer;
  String? _analysisJson;
  bool _analysisDone = false;
  bool _timerDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRoutine();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRoutine() {
    // 1. Start the animation timer
    _timer = Timer.periodic(const Duration(milliseconds: 1600), (timer) {
      if (_currentStage < _stages.length - 1) {
        setState(() {
          _currentStage++;
        });
      } else {
        timer.cancel();
        _timerDone = true;
        _checkAndFinish();
      }
    });

    // 2. Start the actual AI call
    _runAiAnalysis();
  }

  Future<void> _runAiAnalysis() async {
    try {
      final locale = Localizations.localeOf(context).languageCode;
      final result = await AIService.analyzePetPhoto(
        widget.imageFile,
        languageCode: locale,
      );
      
      // Basic extraction of JSON block
      String cleaned = result;
      if (cleaned.contains('```json')) {
        cleaned = cleaned.split('```json')[1].split('```')[0].trim();
      } else if (cleaned.contains('```')) {
        cleaned = cleaned.split('```')[1].split('```')[0].trim();
      } else {
        // Find first { and last }
        final startIndex = cleaned.indexOf('{');
        final endIndex = cleaned.lastIndexOf('}');
        if (startIndex != -1 && endIndex != -1) {
          cleaned = cleaned.substring(startIndex, endIndex + 1);
        }
      }
      
      _analysisJson = cleaned;
    } catch (e) {
      debugPrint('Onboarding AI Error: $e');
    } finally {
      _analysisDone = true;
      _checkAndFinish();
    }
  }

  void _checkAndFinish() {
    if (_timerDone && _analysisDone) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OnboardingResultScreen(
            imageFile: widget.imageFile,
            webImage: widget.webImage,
            aiAnalysisJson: _analysisJson,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final currentStages = isEn ? _stagesEn : _stages;

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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: const CircularProgressIndicator(
                        strokeWidth: 4,
                        color: AppConstants.primaryColor,
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .rotate(duration: 2000.ms),
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppConstants.surfaceColor,
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.primaryColor.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 48,
                        color: AppConstants.primaryColor,
                      ),
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1.1, 1.1),
                          duration: 1000.ms,
                          curve: Curves.easeInOut,
                        ),
                  ],
                ),
                const SizedBox(height: 50),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.5),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    currentStages[_currentStage],
                    key: ValueKey<int>(_currentStage),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.primaryLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: LinearProgressIndicator(
                    value: (_currentStage + 1) / _stages.length,
                    backgroundColor: AppConstants.surfaceColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  isEn ? 'This process may take a few seconds.' : 'Bu işlem birkaç saniye sürebilir.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppConstants.lightTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
