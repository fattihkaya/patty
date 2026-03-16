import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_ai/core/constants.dart';
import 'package:pet_ai/providers/pet_provider.dart';
import 'package:provider/provider.dart';

void showPetSwitcherSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppConstants.surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _PetSwitcherSheet(),
  );
}

class _PetSwitcherSheet extends StatelessWidget {
  const _PetSwitcherSheet();

  @override
  Widget build(BuildContext context) {
    return Consumer<PetProvider>(
      builder: (context, provider, _) {
        if (provider.pets.isEmpty) {
          return _buildEmptyState(context);
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceColorAlt,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hesap Değiştir',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.darkTextColor,
                ),
              ),
              const SizedBox(height: 16),
              ...provider.pets.map(
                (pet) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(pet.photoUrl),
                    radius: 26,
                  ),
                  title: Text(
                    pet.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.darkTextColor,
                    ),
                  ),
                  subtitle: Text(
                    '${pet.type} • ${pet.breed}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppConstants.lightTextColor,
                    ),
                  ),
                  trailing: provider.selectedPetId == pet.id
                      ? const Icon(Icons.check_circle, color: AppConstants.primaryColor)
                      : null,
                  onTap: () {
                    provider.setSelectedPet(pet.id);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppConstants.surfaceColorAlt,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(Icons.pets_rounded, size: 48, color: AppConstants.primaryColor),
          const SizedBox(height: 12),
          Text(
            'Henüz ekli bir profil yok',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: AppConstants.darkTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni dost ekleyerek hesaplar arasında geçiş yapabilirsin.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: AppConstants.lightTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
