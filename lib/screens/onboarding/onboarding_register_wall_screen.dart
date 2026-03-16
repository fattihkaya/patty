import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';
import '../../models/pet_model.dart';
import '../auth/login_screen.dart';

class OnboardingRegisterWallScreen extends StatefulWidget {
  final XFile imageFile;
  final Uint8List? webImage;
  final String? aiAnalysisJson;

  const OnboardingRegisterWallScreen({
    super.key,
    required this.imageFile,
    this.webImage,
    this.aiAnalysisJson,
  });

  @override
  State<OnboardingRegisterWallScreen> createState() => _OnboardingRegisterWallScreenState();
}

class _OnboardingRegisterWallScreenState extends State<OnboardingRegisterWallScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isCreatingProfile = false;

  final _petNameController = TextEditingController();
  DateTime? _birthDate;
  String _selectedGender = 'Erkek';
  String _petType = 'Diğer';
  String _petBreed = 'Belirtilmedi';

  @override
  void initState() {
    super.initState();
    _parseAiData();
  }

  void _parseAiData() {
    if (widget.aiAnalysisJson != null) {
      try {
        final parsed = jsonDecode(widget.aiAnalysisJson!);
        final species = parsed['species']?.toString().toLowerCase() ?? '';
        if (species.contains('dog') || species.contains('köpek')) {
          _petType = 'Köpek';
        } else if (species.contains('cat') || species.contains('kedi')) {
          _petType = 'Kedi';
        } else if (species.contains('bird') || species.contains('kuş')) {
          _petType = 'Kuş';
        } else if (species.contains('hamster') || species.contains('kemirgen')) {
          _petType = 'Hamster';
        }
        final breed = parsed['breed']?.toString();
        if (breed != null && breed.trim().isNotEmpty && !breed.toLowerCase().contains('unknown') && !breed.toLowerCase().contains('bilinmiyor')) {
          _petBreed = breed;
        }
      } catch (_) {}
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppConstants.primaryColor,
              surface: AppConstants.surfaceColor,
              onSurface: AppConstants.darkTextColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _petNameController.dispose();
    super.dispose();
  }

  void _registerAndSave() async {
    if (_formKey.currentState!.validate()) {
      if (_birthDate == null) {
        final isEn = Localizations.localeOf(context).languageCode == 'en';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isEn ? 'Please select a birth date' : 'Lütfen doğum tarihini seçin', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppConstants.errorColor,
        ));
        return;
      }
      setState(() {
        _isCreatingProfile = true;
      });

      try {
        final authProvider = context.read<AuthProvider>();
        // 1. Sign Up
        await authProvider.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (authProvider.isAuthenticated && mounted) {
          // 2. Create Pet (returns created pet for first log)
          final petProvider = context.read<PetProvider>();
          final newPet = PetModel(
            id: '',
            ownerId: authProvider.user!.id,
            name: _petNameController.text.trim(),
            type: _petType,
            breed: _petBreed,
            birthDate: _birthDate!,
            photoUrl: '',
            gender: _selectedGender,
            energyLevel: 3,
          );

          final createdPet = await petProvider.addPet(newPet, widget.imageFile);

          // 3. Welcome’da yapılan analizi ilk post olarak ekle
          if (mounted && createdPet != null && widget.aiAnalysisJson != null && widget.aiAnalysisJson!.trim().isNotEmpty) {
            await petProvider.addFirstLogFromOnboarding(
              petId: createdPet.id,
              photoUrl: createdPet.photoUrl,
              aiAnalysisJson: widget.aiAnalysisJson!,
            );
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Harika! Profilin oluşturuldu ve analizin hazır.'),
                backgroundColor: AppConstants.successColor,
              ),
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $e'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isCreatingProfile = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 30),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppConstants.successColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppConstants.successColor,
                      size: 40,
                    ),
                  ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                  const SizedBox(height: 24),
                  Text(
                    isEn ? 'Analysis Complete! ✨' : 'Analiz Tamamlandı! ✨',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppConstants.primaryColor,
                    ),
                  ).animate().fadeIn(delay: 300.ms).moveY(begin: 10, end: 0),
                  
                  const SizedBox(height: 12),
                  Text(
                    isEn 
                        ? 'Create your free account to see all analysis results and save your profile.'
                        : 'Tüm analiz sonuçlarını görmek ve profilini kaydetmek için ücretsiz hesabını oluştur.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: AppConstants.lightTextColor,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 48),

                  // FORM FIELDS
                  _buildField(
                    controller: _emailController,
                    hint: isEn ? 'Email Address' : 'E-posta Adresi',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value != null && value.contains('@')
                        ? null
                        : (isEn ? 'Enter a valid email' : 'Geçerli bir e-posta girin'),
                  ).animate().fadeIn(delay: 600.ms).moveX(begin: -20, end: 0),
                  
                  const SizedBox(height: 16),
                  
                  _buildField(
                    controller: _passwordController,
                    hint: isEn ? 'Password' : 'Şifre',
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: AppConstants.lightTextColor,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) => value != null && value.length >= 6
                        ? null
                        : (isEn ? 'Password must be at least 6 characters' : 'Şifre en az 6 karakter olmalı'),
                  ).animate().fadeIn(delay: 700.ms).moveX(begin: -20, end: 0),
                  
                  const SizedBox(height: 30),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 20),
                  Text(
                    isEn ? 'Pet Information' : 'Dostunun Bilgileri',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.primaryColor,
                    ),
                  ).animate().fadeIn(delay: 750.ms),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _petNameController,
                    hint: isEn ? 'Pet Name' : 'Dostunun Adı',
                    icon: Icons.pets_outlined,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? (isEn ? 'Please enter a name' : 'Lütfen bir ad girin')
                        : null,
                  ).animate().fadeIn(delay: 750.ms).moveX(begin: -20, end: 0),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedGender,
                          style: GoogleFonts.plusJakartaSans(color: AppConstants.darkTextColor),
                          decoration: InputDecoration(
                            labelText: isEn ? 'Gender' : 'Cinsiyet',
                            labelStyle: TextStyle(color: AppConstants.lightTextColor.withValues(alpha: 0.8)),
                            fillColor: AppConstants.surfaceColor,
                            filled: true,
                            prefixIcon: const Icon(Icons.transgender_outlined, color: AppConstants.lightTextColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                            ),
                          ),
                          dropdownColor: AppConstants.surfaceColor,
                          items: ['Erkek', 'Dişi'].map((g) {
                            final label = g == 'Erkek' ? (isEn ? 'Male' : 'Erkek') : (isEn ? 'Female' : 'Dişi');
                            return DropdownMenuItem(value: g, child: Text(label, style: const TextStyle(color: AppConstants.lightTextColor)));
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedGender = v!),
                        ).animate().fadeIn(delay: 800.ms),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: _selectDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: isEn ? 'Birth Date' : 'Doğum Tarihi',
                              labelStyle: TextStyle(color: AppConstants.lightTextColor.withValues(alpha: 0.8)),
                              fillColor: AppConstants.surfaceColor,
                              filled: true,
                              prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppConstants.lightTextColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                              ),
                            ),
                            child: Text(
                              _birthDate == null 
                                ? (isEn ? 'Select' : 'Seçiniz') 
                                : DateFormat('dd MMM yyyy').format(_birthDate!),
                              style: GoogleFonts.plusJakartaSans(
                                color: _birthDate == null ? AppConstants.lightTextColor.withValues(alpha: 0.6) : AppConstants.darkTextColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 850.ms),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  Container(
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: AppConstants.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isCreatingProfile ? null : _registerAndSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isCreatingProfile
                          ? const CircularProgressIndicator(color: Color(0xFF0F172A))
                          : Text(
                              isEn ? 'Create My Account & See Results' : 'Hesabımı Oluştur & Sonuçları Gör',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                    ),
                  ).animate().fadeIn(delay: 900.ms).scale(),
                  
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    child: Text(
                      isEn ? 'I already have an account, log in' : 'Zaten hesabım var, giriş yap',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppConstants.lightTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ).animate().fadeIn(delay: 1100.ms),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppConstants.primaryColor),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        keyboardType: keyboardType,
        obscureText: obscure,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          color: AppConstants.darkTextColor,
        ),
        validator: validator,
      ),
    );
  }
}
