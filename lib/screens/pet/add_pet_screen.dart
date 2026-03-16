import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/app_strings.dart';
import '../../models/pet_model.dart';
import '../../providers/pet_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/ai_service.dart';
import '../../widgets/premium_gate.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  static const List<String> _typeOptions = [
    'Köpek',
    'Kedi',
    'Kuş',
    'Hamster',
    'Diğer',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  String _selectedType = 'Köpek';
  String _selectedGender = 'Erkek';
  DateTime? _birthDate;
  XFile? _imageFile;
  Uint8List? _webImage;
  bool _isDetectingIdentity = false;
  String? _identityMessage;
  String? _identityTypeRaw;
  String? _identityBreedRaw;
  double? _identityConfidence;
  double? _identityWeightKg;
  String? _identityGender;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _detectPetIdentity(XFile file) async {
    setState(() {
      _isDetectingIdentity = true;
      _identityMessage = null;
      _identityTypeRaw = null;
      _identityBreedRaw = null;
      _identityConfidence = null;
      _identityWeightKg = null;
      _identityGender = null;
    });

    final result = await AIService.detectPetIdentity(file);
    if (!mounted) return;

    setState(() {
      _isDetectingIdentity = false;
      if (result == null || !result.hasAnyData) {
        _identityMessage =
            'AI tür tespiti yapamadı. Bilgileri manuel girebilirsin.';
        return;
      }

      _identityTypeRaw = result.typeLabel;
      _identityBreedRaw = result.breedLabel;
      _identityConfidence = result.confidence;
      _identityWeightKg = result.estimatedWeightKg;
      _identityGender = result.estimatedGender;

      if (result.typeLabel != null) {
        _selectedType = _normalizeTypeLabel(result.typeLabel!);
      }

      final breedGuess = result.breedLabel?.trim() ?? '';
      final isKnownBreed = breedGuess.isNotEmpty &&
          !['bilinmiyor', 'unknown'].contains(breedGuess.toLowerCase());
      if (isKnownBreed) {
        _breedController.text = breedGuess;
      }

      // Auto-fill weight
      if (result.estimatedWeightKg != null && result.estimatedWeightKg! > 0) {
        _weightController.text = result.estimatedWeightKg!.toStringAsFixed(1);
      }

      // Auto-fill gender
      if (result.estimatedGender != null) {
        final genderNorm = result.estimatedGender!.trim().toLowerCase();
        if (genderNorm.contains('erkek') || genderNorm.contains('male')) {
          _selectedGender = 'Erkek';
        } else if (genderNorm.contains('dişi') ||
            genderNorm.contains('female')) {
          _selectedGender = 'Dişi';
        }
      }

      final typeText = _selectedType;
      final breedText = isKnownBreed ? breedGuess : null;
      final weightText = result.estimatedWeightKg != null
          ? '${result.estimatedWeightKg!.toStringAsFixed(1)} kg'
          : null;
      final genderText = _selectedGender;

      final parts = <String>[typeText];
      if (breedText != null) parts.add(breedText);
      if (weightText != null) parts.add(weightText);
      parts.add(genderText);

      _identityMessage = 'AI: ${parts.join(' • ')}';
    });
  }

  String _normalizeTypeLabel(String raw) {
    final normalized = raw.trim().toLowerCase();
    for (final option in _typeOptions) {
      if (option.toLowerCase() == normalized) {
        return option;
      }
    }
    if (normalized.contains('cat') || normalized.contains('kedi')) {
      return 'Kedi';
    }
    if (normalized.contains('dog') || normalized.contains('köpek')) {
      return 'Köpek';
    }
    if (normalized.contains('bird') || normalized.contains('kuş')) {
      return 'Kuş';
    }
    if (normalized.contains('hamster') || normalized.contains('kemirgen')) {
      return 'Hamster';
    }
    return 'Diğer';
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      if (kIsWeb) {
        setState(() {
          _webImage = bytes;
          _imageFile = pickedFile;
          _identityMessage = null;
        });
      } else {
        setState(() {
          _imageFile = pickedFile;
          _webImage = bytes;
          _identityMessage = null;
        });
      }
      await _detectPetIdentity(pickedFile);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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

  void _savePet() async {
    if (_formKey.currentState!.validate() &&
        _imageFile != null &&
        _birthDate != null) {
      final pet = PetModel(
        id: '',
        ownerId: '',
        name: _nameController.text.trim(),
        type: _selectedType,
        breed: _breedController.text.trim(),
        birthDate: _birthDate!,
        photoUrl: '',
        weight: double.tryParse(_weightController.text),
        gender: _selectedGender,
        energyLevel: 3,
      );

      try {
        await context.read<PetProvider>().addPet(pet, _imageFile!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dostun başarıyla kaydedildi! 🐾'),
              backgroundColor: AppConstants.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $e'),
              backgroundColor: AppConstants.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lütfen bir fotoğraf seçin'),
            behavior: SnackBarBehavior.floating),
      );
    } else if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lütfen doğum tarihini seçin'),
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Pet limit check ──
    final subProvider = context.watch<SubscriptionProvider>();
    final petCount = context.watch<PetProvider>().pets.length;
    if (subProvider.isFree && petCount >= subProvider.maxPetsAllowed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showPremiumSheet(
            context,
            title: S.of(context).unlimitedPets,
            description: S.of(context).maxPetsReached,
          );
        }
      });
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          title: const Text('Profilini Oluştur'),
          backgroundColor: AppConstants.backgroundColor,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Text(
              S.of(context).maxPetsReached,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Profilini Oluştur'),
        backgroundColor: AppConstants.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceColor,
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: AppConstants.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_a_photo_rounded,
                                  size: 32, color: AppConstants.primaryColor),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Onun En Güzel Fotoğrafı',
                              style: GoogleFonts.plusJakartaSans(
                                  color: AppConstants.lightTextColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppConstants.borderRadius),
                          child: _webImage != null
                              ? Image.memory(_webImage!, fit: BoxFit.cover)
                              : Image.network(_imageFile!.path, fit: BoxFit.cover),
                        ),
                ),
              ).animate().scale(
                  begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
              const SizedBox(height: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                  border: Border.all(
                    color: _isDetectingIdentity
                        ? AppConstants.primaryColor.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (_isDetectingIdentity)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    else
                      const Icon(Icons.auto_awesome_rounded,
                          color: AppConstants.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _identityMessage ??
                            'Fotoğraf seçildiğinde tür ve cins otomatik tahmin edilir.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppConstants.lightTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_identityTypeRaw != null || _identityBreedRaw != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.2), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Output',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildAiLogRow(
                          'Type',
                          _identityTypeRaw?.isNotEmpty == true
                              ? _identityTypeRaw!
                              : '—'),
                      const SizedBox(height: 4),
                      _buildAiLogRow(
                          'Breed',
                          _identityBreedRaw?.isNotEmpty == true
                              ? _identityBreedRaw!
                              : '—'),
                      const SizedBox(height: 4),
                      _buildAiLogRow(
                          'Weight',
                          _identityWeightKg != null
                              ? '${_identityWeightKg!.toStringAsFixed(1)} kg'
                              : '—'),
                      const SizedBox(height: 4),
                      _buildAiLogRow('Gender', _identityGender ?? '—'),
                      if (_identityConfidence != null) ...[
                        const SizedBox(height: 4),
                        _buildAiLogRow('Confidence',
                            '${(_identityConfidence! * 100).toStringAsFixed(1)}%'),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.plusJakartaSans(),
                decoration: const InputDecoration(
                  labelText: 'Dostunun Adı',
                  hintText: 'Örn: Kuyruk',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Lütfen bir ad girin' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                style: GoogleFonts.plusJakartaSans(
                    color: AppConstants.darkTextColor),
                decoration: const InputDecoration(
                  labelText: 'Tür',
                  prefixIcon: Icon(Icons.pets_outlined),
                ),
                items: _typeOptions
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _breedController,
                style: GoogleFonts.plusJakartaSans(),
                decoration: const InputDecoration(
                  labelText: 'Cinsi',
                  hintText: 'Örn: Tekir',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Lütfen cins girin' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(),
                      decoration: const InputDecoration(
                        labelText: 'Ağırlık (kg)',
                        prefixIcon: Icon(Icons.monitor_weight_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      style: GoogleFonts.plusJakartaSans(
                          color: AppConstants.darkTextColor),
                      decoration: const InputDecoration(
                        labelText: 'Cinsiyet',
                        prefixIcon: Icon(Icons.transgender_outlined),
                      ),
                      items: ['Erkek', 'Dişi']
                          .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedGender = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Doğum Tarihi',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    _birthDate == null
                        ? 'Tarih Seçin'
                        : DateFormat('dd MMMM yyyy', 'tr_TR')
                            .format(_birthDate!),
                    style: GoogleFonts.plusJakartaSans(),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _savePet,
                child: const Text('Kaydet ve Başla'),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 20),
            ],
          ),
        ).animate().fadeIn().moveY(begin: 30, end: 0),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppConstants.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: AppConstants.lightTextColor)),
              Text(value,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.darkTextColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiLogRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppConstants.darkTextColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppConstants.lightTextColor,
            ),
          ),
        ),
      ],
    );
  }
}
