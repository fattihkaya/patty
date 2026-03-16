import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:pet_ai/core/constants.dart';
import 'package:pet_ai/core/supabase_config.dart';
import 'package:pet_ai/providers/pet_provider.dart';
import 'package:pet_ai/screens/subscription/subscription_screen.dart';
import 'package:pet_ai/screens/pet/add_pet_screen.dart';
import 'package:pet_ai/screens/pet/edit_pet_screen.dart';
import 'package:pet_ai/widgets/pet_switcher_sheet.dart';
import 'package:pet_ai/screens/shop/achievements_screen.dart';
import 'package:pet_ai/screens/shop/points_shop_screen.dart';
import 'package:pet_ai/screens/settings/settings_screen.dart';
import 'package:pet_ai/core/app_strings.dart';

class PetProfileScreen extends StatefulWidget {
  const PetProfileScreen({super.key});

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _memberController = TextEditingController();
  bool _noteSaving = false;
  bool _noteLoading = false;
  bool _noteLoaded = false;
  bool _membersLoading = false;
  bool _membersLoaded = false;
  String _memberRole = 'viewer';

  @override
  void dispose() {
    _noteController.dispose();
    _memberController.dispose();
    super.dispose();
  }

  Future<void> _loadNote(PetProvider petProvider) async {
    final pet = petProvider.selectedPet;
    if (pet == null || _noteLoaded || _noteLoading) return;

    setState(() => _noteLoading = true);
    try {
      final note = await petProvider.loadPetNote(pet.id);
      if (mounted) {
        _noteController.text = note ?? '';
        setState(() => _noteLoaded = true);
      }
    } catch (e) {
      debugPrint('Load note error: $e');
    } finally {
      if (mounted) {
        setState(() => _noteLoading = false);
      }
    }
  }

  Future<void> _saveNote(PetProvider petProvider) async {
    final pet = petProvider.selectedPet;
    if (pet == null) return;

    setState(() => _noteSaving = true);
    try {
      final text = _noteController.text.trim();
      await petProvider.savePetNote(pet.id, text.isEmpty ? null : text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).noteSaved),
            backgroundColor: AppConstants.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${S.of(context).noteFailedSave}: ${e.toString()}'),
            backgroundColor: AppConstants.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _noteSaving = false);
      }
    }
  }

  Future<void> _handleAddPet(
      BuildContext context, PetProvider petProvider) async {
    // Premium limit kontrolü devre dışı bırakıldı
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPetScreen()),
    );
  }

  // ignore: unused_element
  void _showUpgradeDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).premiumRequired),
        content: Text('$featureName ${S.of(context).premiumRequired.toLowerCase()}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionScreen(),
                ),
              );
            },
            child: Text(S.of(context).upgradeToPremium),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final pet = petProvider.selectedPet;

    // Reset note loaded flag when pet changes
    final currentPetId = pet?.id;
    if (currentPetId != null && _noteLoaded) {
      // Check if pet changed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && petProvider.selectedPet?.id != currentPetId) {
          setState(() {
            _noteLoaded = false;
            _noteController.clear();
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          pet == null ? S.of(context).petProfile : pet.name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppConstants.primaryColor,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          if (petProvider.pets.length > 1)
            IconButton(
              icon: const Icon(Icons.switch_account_rounded,
                  color: AppConstants.primaryColor),
              tooltip: S.of(context).changePet,
              onPressed: () => showPetSwitcherSheet(context),
            ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppConstants.primaryColor),
            tooltip: S.of(context).addNewPet,
            onPressed: () => _handleAddPet(context, petProvider),
          ),
          if (pet != null)
            IconButton(
              icon: const Icon(Icons.edit_rounded,
                  color: AppConstants.primaryColor),
              tooltip: S.of(context).editPetProfile,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditPetScreen(pet: pet),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings_rounded,
                color: AppConstants.primaryColor),
            tooltip: S.of(context).accountSettings,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: pet == null
          ? _buildEmptyProfile(context)
          : _buildProfileContent(context, petProvider, pet),
    );
  }

  // ignore: unused_element
  Widget _buildMembersCard(
      BuildContext context, PetProvider petProvider, dynamic pet) {
    final members = petProvider.membersOf(pet.id);
    final isOwner = SupabaseConfig.client.auth.currentUser?.id == pet.ownerId;
    return Container(
      padding: const EdgeInsets.all(AppConstants.mobileCardPadding),
      decoration: AppConstants.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
                ),
                child: const Icon(
                  Icons.group_rounded,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  S.of(context).familyMembers,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.darkTextColor,
                  ),
                ),
              ),
              if (_membersLoading)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (members.isEmpty && !_membersLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  S.of(context).noMembersYet,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppConstants.lightTextColor,
                  ),
                ),
              ),
            ),
          ...members.map((m) {
            final isSelf =
                SupabaseConfig.client.auth.currentUser?.id == m.userId;
            final email = m.email ?? m.userId;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.person),
              title: Text(
                email,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.darkTextColor,
                ),
              ),
              subtitle: Text(
                m.role == 'owner'
                    ? S.of(context).owner
                    : m.role == 'editor'
                        ? S.of(context).editor
                        : S.of(context).viewer,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppConstants.lightTextColor,
                ),
              ),
              trailing: isOwner && !isSelf
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: AppConstants.errorColor),
                      onPressed: () async {
                        try {
                          await petProvider.removeMember(pet.id, m.userId);
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(S.of(this.context).memberRemoved),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('${S.of(this.context).memberRemoved}: $e'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppConstants.errorColor,
                            ),
                          );
                        }
                      },
                    )
                  : null,
            );
          }),
          if (isOwner) ...[
            const Divider(height: 24),
            Text(
              S.of(context).addNewMember,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppConstants.darkTextColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _memberController,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppConstants.darkTextColor,
              ),
              decoration: InputDecoration(
                labelText: S.of(context).emailAddress,
                hintText: 'ornek@eposta.com',
                filled: true,
                fillColor: AppConstants.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppConstants.primaryLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppConstants.primaryLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppConstants.primaryColor, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _memberRole,
              items: [
                DropdownMenuItem(value: 'viewer', child: Text(S.of(context).viewer)),
                DropdownMenuItem(value: 'editor', child: Text(S.of(context).editor)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _memberRole = v);
              },
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppConstants.darkTextColor,
              ),
              decoration: InputDecoration(
                labelText: S.of(context).role,
                filled: true,
                fillColor: AppConstants.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppConstants.primaryLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppConstants.primaryLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppConstants.primaryColor, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _membersLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.person_add_alt_1_rounded),
                label: Text(
                  _membersLoading ? S.of(context).adding : S.of(context).addMember,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: _membersLoading
                    ? null
                    : () async {
                        final target = _memberController.text.trim();
                        if (target.isEmpty) return;
                        setState(() => _membersLoading = true);

                        // Capture localized strings before async gap
                        final s = S.of(context);

                        try {
                          await petProvider.addMember(pet.id, target,
                              role: _memberRole);
                          _memberController.clear();
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(s.memberAdded),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text('${s.memberAdded}: $e'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppConstants.errorColor,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _membersLoading = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyProfile(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppConstants.paddingMD,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pets_rounded,
                size: AppConstants.iconXL, color: AppConstants.primaryLight),
            const SizedBox(height: AppConstants.spacingMD),
            Text(
              S.of(context).noPetProfile,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18, color: AppConstants.lightTextColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(
      BuildContext context, PetProvider petProvider, dynamic pet) {
    if (!_noteLoaded && !_noteLoading) {
      // load once when profile content builds
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadNote(petProvider);
      });
    }
    if (!_membersLoaded && !_membersLoading) {
      _membersLoading = true;
      petProvider.fetchMembers(pet.id).whenComplete(() {
        if (mounted) {
          setState(() {
            _membersLoading = false;
            _membersLoaded = true;
          });
        }
      });
    }
    return SingleChildScrollView(
      padding: AppConstants.screenPaddingMobile.copyWith(bottom: AppConstants.bottomNavHeight),
      child: Column(
        children: [
          _buildHeader(pet),
          const SizedBox(height: AppConstants.spacingLG),
          _buildDetailCard(pet),
          const SizedBox(height: AppConstants.spacingMD),
          _buildNoteCard(petProvider, pet),
          const SizedBox(height: AppConstants.bottomNavHeight), // Bottom padding for navigation
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildGamificationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.accentColor.withValues(alpha: 0.1),
            AppConstants.secondaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: AppConstants.accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConstants.accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppConstants.accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Oyunlaştırma',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.darkTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            icon: const Icon(Icons.emoji_events_rounded),
            label: const Text('Başarımları Görüntüle'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side:
                  const BorderSide(color: AppConstants.accentColor, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AchievementsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.shopping_bag_rounded),
            label: const Text('Puan Marketi'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side:
                  const BorderSide(color: AppConstants.accentColor, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PointsShopScreen(),
                ),
              );
            },
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.1, end: 0, duration: 600.ms);
  }

  Widget _buildHeader(dynamic pet) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: AppConstants.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppConstants.primaryColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 70,
              backgroundColor: Colors.white,
              backgroundImage: NetworkImage(pet.photoUrl),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            pet.name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${pet.type} • ${pet.breed ?? "Cins belirtilmedi"}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(begin: const Offset(0.9, 0.9), duration: 600.ms);
  }

  Widget _buildDetailCard(dynamic pet) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        children: [
          _buildDetailItem(
            Icons.calendar_today_rounded,
            'Doğum Tarihi',
            DateFormat('dd MMMM yyyy', 'tr_TR').format(pet.birthDate),
            AppConstants.primaryColor,
          ),
          _buildDivider(),
          _buildDetailItem(
            Icons.monitor_weight_outlined,
            'Ağırlık',
            pet.weight != null ? '${pet.weight} kg' : 'Belirtilmedi',
            AppConstants.accentColor,
          ),
          _buildDivider(),
          _buildDetailItem(
            Icons.transgender_rounded,
            'Cinsiyet',
            pet.gender ?? 'Belirtilmedi',
            AppConstants.secondaryColor,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.1, end: 0, duration: 600.ms);
  }

  // ignore: unused_element
  Widget _buildStatsCard(dynamic pet) {
    final energyLevel = pet.energyLevel ?? 3;
    final energyPercentage = (energyLevel / 5) * 100;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.accentColor.withValues(alpha: 0.1),
            AppConstants.secondaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: AppConstants.accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConstants.accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: AppConstants.accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Enerji Seviyesi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.darkTextColor,
                ),
              ),
              const Spacer(),
              Text(
                '$energyLevel/5',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppConstants.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEnergyBar(energyLevel),
          const SizedBox(height: 12),
          Text(
            '%${energyPercentage.toInt()} enerji',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppConstants.lightTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.15, end: 0, duration: 600.ms);
  }

  Widget _buildEnergyBar(int level) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: AppConstants.primaryLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: level / 5,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppConstants.accentColor,
                AppConstants.secondaryColor,
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppConstants.accentColor.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
      IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppConstants.lightTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.darkTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.white.withValues(alpha: 0.06), indent: 70);
  }

  Widget _buildNoteCard(PetProvider petProvider, dynamic pet) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConstants.secondaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.note_rounded,
                  color: AppConstants.secondaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${pet.name} için Notlar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.darkTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            minLines: 4,
            maxLines: 6,
            enabled: !_noteSaving && !_noteLoading,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppConstants.darkTextColor,
            ),
            decoration: InputDecoration(
              hintText:
                  'Örn: Sağ kulak kontrolü 2 haftaya tekrar, aşı tarihi yaklaşıyor...',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppConstants.lightTextColor,
              ),
              filled: true,
              fillColor: AppConstants.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppConstants.primaryLight,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppConstants.primaryLight,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppConstants.primaryColor,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _noteSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _noteSaving ? 'Kaydediliyor...' : 'Notu Kaydet',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: (_noteSaving || _noteLoading)
                  ? null
                  : () => _saveNote(petProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.1, end: 0, duration: 600.ms);
  }

  // ignore: unused_element
  Widget _buildManageCard(
      BuildContext context, PetProvider petProvider, dynamic pet) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Pet Yönetimi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.darkTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Pet Profilini Düzenle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditPetScreen(pet: pet)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Yeni Pet Ekle'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(
                  color: AppConstants.primaryColor, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            onPressed: () => _handleAddPet(context, petProvider),
          ),
          if (petProvider.pets.length > 1) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.switch_account_rounded),
              label: const Text('Pet Değiştir'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => showPetSwitcherSheet(context),
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.1, end: 0, duration: 600.ms);
  }
}
