import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/pet_model.dart';
import '../../providers/pet_provider.dart';
import '../../services/ai_service.dart';

class EditPetScreen extends StatefulWidget {
  final PetModel pet;

  const EditPetScreen({super.key, required this.pet});

  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
  static const List<String> _typeOptions = [
    'Köpek',
    'Kedi',
    'Kuş',
    'Hamster',
    'Diğer',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _weightController;
  late String _selectedType;
  late String _selectedGender;
  late double _energyLevel;
  late DateTime _birthDate;
  XFile? _newImageFile;
  Uint8List? _webImage;
  bool _isDetectingIdentity = false;
  String? _identityMessage;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.pet.type;
    _selectedGender = widget.pet.gender ?? 'Erkek';
    _energyLevel = widget.pet.energyLevel.toDouble();
    _birthDate = widget.pet.birthDate;
    _nameController = TextEditingController(text: widget.pet.name);
    _breedController = TextEditingController(text: widget.pet.breed);
    _weightController =
        TextEditingController(text: widget.pet.weight?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
          _newImageFile = pickedFile;
          _identityMessage = null;
        });
      } else {
        setState(() {
          _newImageFile = pickedFile;
          _identityMessage = null;
        });
      }
      await _detectPetIdentity(pickedFile);
    }
  }

  Future<void> _detectPetIdentity(XFile file) async {
    setState(() {
      _isDetectingIdentity = true;
      _identityMessage = 'AI fotoğraftan tür ve cins tahmini yapıyor...';
    });

    final result = await AIService.detectPetIdentity(file);
    if (!mounted) return;

    setState(() {
      _isDetectingIdentity = false;
      if (result == null || !result.hasAnyData) {
        _identityMessage = 'AI tür tespiti yapamadı. Bilgileri kendin güncelleyebilirsin.';
        return;
      }

      if (result.typeLabel != null) {
        _selectedType = _normalizeTypeLabel(result.typeLabel!);
      }

      if (result.breedLabel != null && result.breedLabel!.trim().isNotEmpty) {
        _breedController.text = result.breedLabel!.trim();
      }

      final typeText = _selectedType;
      final breedText = _breedController.text.trim().isNotEmpty
          ? _breedController.text.trim()
          : 'Bilinmiyor';
      _identityMessage = 'AI tahmini: $typeText • $breedText';
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedPet = PetModel(
      id: widget.pet.id,
      ownerId: widget.pet.ownerId,
      name: _nameController.text.trim(),
      type: _selectedType,
      breed: _breedController.text.trim(),
      birthDate: _birthDate,
      photoUrl: widget.pet.photoUrl,
      weight: double.tryParse(_weightController.text),
      gender: _selectedGender,
      energyLevel: _energyLevel.toInt(),
    );

    try {
      await context
          .read<PetProvider>()
          .updatePet(updatedPet, newPhoto: _newImageFile);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil güncellendi! ✨'),
            backgroundColor: AppConstants.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        backgroundColor: AppConstants.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                  child: _buildPhotoPreview(),
                ),
              ).animate().scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1, 1),
                  ),
              const SizedBox(height: 12),
              _buildDetectionBanner(),
              const SizedBox(height: 32),
              _buildTextFields(),
            ],
          ),
        ).animate().fadeIn().moveY(begin: 30, end: 0),
      ),
    );
  }

  Widget _buildDetectionBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
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
            const Icon(Icons.auto_fix_high_rounded,
                color: AppConstants.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _identityMessage ??
                  'Yeni fotoğraf seçtiğinde AI tür ve cinsi otomatik önerir.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppConstants.lightTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview() {
    if (_newImageFile == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Image.network(widget.pet.photoUrl, fit: BoxFit.cover),
      );
    }

    if (kIsWeb && _webImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Image.memory(_webImage!, fit: BoxFit.cover),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Image.network(_newImageFile!.path, fit: BoxFit.cover),
    );
  }

  Widget _buildTextFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _nameController,
          style: GoogleFonts.plusJakartaSans(),
          decoration: const InputDecoration(
            labelText: 'Ad',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Lütfen bir ad girin' : null,
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: _selectedType,
          style:
              GoogleFonts.plusJakartaSans(color: AppConstants.darkTextColor),
          decoration: const InputDecoration(
            labelText: 'Tür',
            prefixIcon: Icon(Icons.pets_outlined),
          ),
          items: _typeOptions
              .map(
                (type) => DropdownMenuItem(value: type, child: Text(type)),
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
            prefixIcon: Icon(Icons.category_outlined),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Lütfen cinsi girin' : null,
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
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedGender = value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Doğum Tarihi',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
            child: Text(
              DateFormat('dd MMMM yyyy', 'tr_TR').format(_birthDate),
              style: GoogleFonts.plusJakartaSans(),
            ),
          ),
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Değişiklikleri Kaydet'),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 20),
      ],
    );
  }
}
