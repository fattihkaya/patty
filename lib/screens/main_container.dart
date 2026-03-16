import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:pet_ai/core/constants.dart';
import 'package:pet_ai/core/app_strings.dart';
import 'package:pet_ai/providers/pet_provider.dart';
import 'package:pet_ai/providers/locale_provider.dart';
import 'package:pet_ai/screens/subscription/subscription_screen.dart';
import 'package:pet_ai/screens/social/discover_screen.dart';
import 'package:pet_ai/screens/your_pets/your_pets_screen.dart';
import 'package:pet_ai/screens/profile/profile_screen.dart';

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<String?> _pickVisibility(BuildContext context) async {
    final s = S.of(context);
    final options = [
      ('members', Icons.lock_open_rounded, s.familyOnly),
      ('followers', Icons.group_rounded, s.followersOnly),
      ('public', Icons.public_rounded, s.everyone),
    ];
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(s.selectVisibility,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.darkTextColor)),
            const SizedBox(height: 8),
            ...options.map((o) {
              final (value, icon, label) = o;
              return ListTile(
                leading:
                    Icon(icon, color: AppConstants.primaryColor),
                title: Text(label,
                    style: const TextStyle(color: AppConstants.darkTextColor)),
                onTap: () => Navigator.pop(ctx, value),
              );
            }),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  void _showAddLogBottomSheet(BuildContext context, String petId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && mounted) {
      if (!mounted) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: AppConstants.cardDecoration,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(S.of(ctx).analyzingPhoto,
                    style: GoogleFonts.plusJakartaSans(
                        color: AppConstants.darkTextColor)),
              ],
            ),
          ),
        ),
      );

      try {
        final languageCode = context.read<LocaleProvider>().languageCode;
        final draft = await context
            .read<PetProvider>()
            .prepareLogDraft(petId, pickedFile, languageCode: languageCode);

        if (!mounted) return;
        final visibility = await _pickVisibility(context);
        
        if (!mounted) return;
        if (visibility != null) {
          await context
              .read<PetProvider>()
              .submitLogDraft(draft, visibility: visibility);
        }
        
        if (!mounted) return;
        Navigator.pop(context);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).aiAnalysisSaved),
            backgroundColor: AppConstants.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e, _) {
        if (!mounted) return;
        Navigator.pop(context);
        
        if (!mounted) return;
        final s = S.of(context);
        final isConfigError = e is StateError &&
            (e.message.contains('GEMINI') || e.message.contains('API'));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isConfigError ? s.apiKeyNotConfigured : s.analysisFailed,
              ),
              backgroundColor: AppConstants.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // ignore: unused_element
  void _showUpgradeDialog(BuildContext context, int remaining) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        ),
        title: Row(
          children: [
            const Icon(Icons.star_rounded, color: AppConstants.primaryColor),
            const SizedBox(width: 8),
            Text(
              s.aiLimitReachedDialogTitle,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: AppConstants.darkTextColor,
              ),
            ),
          ],
        ),
        content: Text(
          remaining == 0
              ? s.aiLimitReachedDialogDesc
              : s.aiRemainingDialogDesc(remaining),
          style: GoogleFonts.plusJakartaSans(
              color: AppConstants.lightTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              s.cancel,
              style: GoogleFonts.plusJakartaSans(
                color: AppConstants.lightTextColor,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppConstants.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: Text(
                s.upgradeToPremium,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final screens = [
      const DiscoverScreen(),
      YourPetsScreen(onAddLog: _showAddLogBottomSheet),
      const PetProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(
            AppConstants.bottomNavMargin,
            0,
            AppConstants.bottomNavMargin,
            AppConstants.bottomNavMargin),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                      0, Icons.explore_rounded, S.of(context).discover),
                  _buildNavItem(
                      1, Icons.pets_rounded, S.of(context).myPets),
                  _buildNavItem(
                      2, Icons.person_rounded, S.of(context).profile),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton:
          _selectedIndex == 1 && petProvider.pets.isNotEmpty
              ? Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppConstants.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.primaryColor
                            .withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showAddLogBottomSheet(
                          context,
                          petProvider.selectedPetId ??
                              petProvider.pets.first.id);
                    },
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: const Icon(Icons.add_rounded,
                        color: Color(0xFF0F172A), size: 28),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                      duration: 400.ms,
                    )
                    .fadeIn(duration: 300.ms)
              : null,
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterFloat,
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _onItemTapped(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected
              ? AppConstants.spacingMD
              : AppConstants.spacingSM,
          vertical: isSelected
              ? AppConstants.spacingSM
              : AppConstants.spacingXS,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppConstants.primaryGradient : null,
          borderRadius:
              BorderRadius.circular(AppConstants.smallBorderRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF0F172A)
                  : AppConstants.lightTextColor,
              size: AppConstants.iconMD,
            ),
            if (isSelected) ...[
              const SizedBox(width: AppConstants.spacingSM),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
