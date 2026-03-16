import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../core/app_config.dart';
import '../../core/app_strings.dart';
import '../../models/user_profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/subscription_provider.dart';
import '../subscription/subscription_screen.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final userProfile = authProvider.userProfile;
    final email = user?.email ?? '';
    final s = S.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          s.myAccount,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppConstants.primaryColor,
            letterSpacing: AppConstants.letterSpacingBold,
          ),
        ),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Header
            _buildUserProfileHeader(context, userProfile, email),
            const SizedBox(height: AppConstants.spacingXL),

            // Parent Info
            _buildSection(
              title: S.of(context).parentInfo,
              icon: Icons.person_outline_rounded,
              children: [
                _buildInfoTile(
                  icon: Icons.badge_outlined,
                  title: S.of(context).firstName,
                  subtitle:
                      userProfile?.firstName ?? S.of(context).notSpecified,
                ),
                _buildInfoTile(
                  icon: Icons.badge_outlined,
                  title: S.of(context).lastName,
                  subtitle: userProfile?.lastName ?? S.of(context).notSpecified,
                ),
                _buildInfoTile(
                  icon: Icons.email_outlined,
                  title: S.of(context).email,
                  subtitle: email,
                ),
                _buildActionTile(
                  icon: Icons.edit_rounded,
                  title: S.of(context).editProfile,
                  onTap: () => _navigateToEditProfile(context),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingXL),

            // Subscription section
            _buildSubscriptionSection(context),
            const SizedBox(height: AppConstants.spacingXL),

            // Language
            _buildLanguageSection(context),
            const SizedBox(height: AppConstants.spacingXL),

            // Pet voice label (customizable)
            _buildPetVoiceLabelSection(context),
            const SizedBox(height: AppConstants.spacingXL),

            _buildSection(
              title: S.of(context).myAccount,
              icon: Icons.settings_outlined,
              children: [
                _buildActionTile(
                  icon: Icons.logout_rounded,
                  title: S.of(context).logout,
                  color: AppConstants.errorColor,
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingXL),
            _buildSection(
              title: 'Info',
              icon: Icons.info_outline_rounded,
              children: [
                _buildInfoTile(
                  icon: Icons.phone_android_outlined,
                  title: S.of(context).version,
                  subtitle: '1.0.0',
                ),
                _buildActionTile(
                  icon: Icons.description_outlined,
                  title: S.of(context).termsOfUse,
                  onTap: () async {
                    final uri = Uri.parse(AppConfig.termsOfUseUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'URL açılamadı. Lütfen daha sonra tekrar deneyin.'),
                            backgroundColor: AppConstants.warningColor,
                          ),
                        );
                      }
                    }
                  },
                ),
                _buildActionTile(
                  icon: Icons.privacy_tip_outlined,
                  title: S.of(context).privacyPolicy,
                  onTap: () async {
                    final uri = Uri.parse(AppConfig.privacyPolicyUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'URL açılamadı. Lütfen daha sonra tekrar deneyin.'),
                            backgroundColor: AppConstants.warningColor,
                          ),
                        );
                      }
                    }
                  },
                ),
                _buildActionTile(
                  icon: Icons.help_outline_rounded,
                  title: s.supportAndFeedback,
                  onTap: () async {
                    final uri = Uri.parse(AppConfig.supportUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'URL açılamadı. Lütfen daha sonra tekrar deneyin.'),
                            backgroundColor: AppConstants.warningColor,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingXXL),
          ],
        ),
      ),
    );
  }

  Widget _buildPetVoiceLabelSection(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final s = S.of(context);
    final currentLabel = getPetVoiceLabel(context, 'Pet');
    return _buildSection(
      title: s.petVoiceLabelSetting,
      icon: Icons.pets_rounded,
      children: [
        InkWell(
          onTap: () => _showPetVoiceLabelDialog(context),
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.label_rounded,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.darkTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _petVoiceLabelStyleSubtitle(
                            localeProvider.petVoiceLabelStyle, s),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppConstants.lightTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppConstants.lightTextColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _petVoiceLabelStyleSubtitle(String style, S s) {
    switch (style) {
      case LocaleProvider.petVoiceStylePetSays:
        return s.petVoiceLabelPetSays;
      case LocaleProvider.petVoiceStylePetVoice:
        return s.petVoiceLabelPetVoice;
      case LocaleProvider.petVoiceStyleAiAnalysis:
        return s.petVoiceLabelAiAnalysis;
      case LocaleProvider.petVoiceStyleCustom:
        return s.petVoiceLabelCustom;
      default:
        return s.petVoiceLabelPetSays;
    }
  }

  void _showPetVoiceLabelDialog(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();
    final s = S.of(context);
    String selectedStyle = localeProvider.petVoiceLabelStyle;
    String customText = localeProvider.petVoiceLabelCustom ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppConstants.surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            ),
            title: Text(
              s.petVoiceLabelSetting,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppConstants.darkTextColor,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RadioListTile<String>(
                    title: Text(
                      s.petVoiceLabelPetSays,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppConstants.darkTextColor,
                        fontSize: 14,
                      ),
                    ),
                    value: LocaleProvider.petVoiceStylePetSays,
                    // ignore: deprecated_member_use
                    groupValue: selectedStyle,
                    // ignore: deprecated_member_use
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedStyle = v);
                    },
                    activeColor: AppConstants.primaryColor,
                  ),
                  RadioListTile<String>(
                    title: Text(
                      s.petVoiceLabelPetVoice,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppConstants.darkTextColor,
                        fontSize: 14,
                      ),
                    ),
                    value: LocaleProvider.petVoiceStylePetVoice,
                    // ignore: deprecated_member_use
                    groupValue: selectedStyle,
                    // ignore: deprecated_member_use
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedStyle = v);
                    },
                    activeColor: AppConstants.primaryColor,
                  ),
                  RadioListTile<String>(
                    title: Text(
                      s.petVoiceLabelAiAnalysis,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppConstants.darkTextColor,
                        fontSize: 14,
                      ),
                    ),
                    value: LocaleProvider.petVoiceStyleAiAnalysis,
                    // ignore: deprecated_member_use
                    groupValue: selectedStyle,
                    // ignore: deprecated_member_use
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedStyle = v);
                    },
                    activeColor: AppConstants.primaryColor,
                  ),
                  RadioListTile<String>(
                    title: Text(
                      s.petVoiceLabelCustom,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppConstants.darkTextColor,
                        fontSize: 14,
                      ),
                    ),
                    value: LocaleProvider.petVoiceStyleCustom,
                    // ignore: deprecated_member_use
                    groupValue: selectedStyle,
                    // ignore: deprecated_member_use
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedStyle = v);
                    },
                    activeColor: AppConstants.primaryColor,
                  ),
                  if (selectedStyle == LocaleProvider.petVoiceStyleCustom) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      autofocus: true,
                      initialValue: customText,
                      onChanged: (v) => setDialogState(() => customText = v),
                      decoration: InputDecoration(
                        hintText: s.petVoiceLabelCustomHint,
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: AppConstants.lightTextColor,
                        ),
                        filled: true,
                        fillColor: AppConstants.backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      style: GoogleFonts.plusJakartaSans(
                        color: AppConstants.darkTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  s.cancel,
                  style: const TextStyle(color: AppConstants.lightTextColor),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await localeProvider.setPetVoiceLabelStyle(selectedStyle);
                  if (selectedStyle == LocaleProvider.petVoiceStyleCustom) {
                    await localeProvider.setPetVoiceLabelCustom(
                        customText.trim().isEmpty ? null : customText.trim());
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(
                  s.save,
                  style: const TextStyle(color: AppConstants.primaryColor),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppConstants.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppConstants.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
            boxShadow: AppConstants.cardShadow,
          ),
          child: Column(
            children: _separateTiles(children),
          ),
        ),
      ],
    );
  }

  List<Widget> _separateTiles(List<Widget> tiles) {
    if (tiles.isEmpty) return [];
    final separated = <Widget>[tiles.first];
    for (var i = 1; i < tiles.length; i++) {
      separated.add(Divider(
        height: 1,
        indent: 70,
        color: Colors.white.withValues(alpha: 0.06),
      ));
      separated.add(tiles[i]);
    }
    return separated;
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.darkTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppConstants.lightTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (color ?? AppConstants.primaryColor).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color ?? AppConstants.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color ?? AppConstants.darkTextColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppConstants.lightTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppConstants.lightTextColor,
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.darkTextColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppConstants.lightTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              HapticFeedback.lightImpact();
              onChanged(newValue);
            },
            activeThumbColor: AppConstants.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection(BuildContext context) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final currentPlan = subscriptionProvider.currentPlan;
    final currentSubscription = subscriptionProvider.currentSubscription;
    final s = S.of(context);

    return _buildSection(
      title: s.subscription,
      icon: Icons.star_outline_rounded,
      children: [
        _buildInfoTile(
          icon: Icons.workspace_premium_rounded,
          title: s.currentPlan,
          subtitle: currentPlan?.displayName ?? s.freePlan,
        ),
        if (currentSubscription != null &&
            currentSubscription.isActive &&
            currentSubscription.expiresAt != null)
          _buildInfoTile(
            icon: Icons.calendar_today_rounded,
            title: s.birthDate,
            subtitle: _formatDate(currentSubscription.expiresAt!),
          ),
        _buildActionTile(
          icon: Icons.workspace_premium,
          title: s.managePlan,
          subtitle: s.upgradeToPremium,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SubscriptionScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLanguageSection(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final s = S.of(context);

    return _buildSection(
      title: s.language,
      icon: Icons.language_rounded,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildLanguageOption(
                context,
                label: 'Türkçe',
                flag: '🇹🇷',
                isSelected: localeProvider.isTurkish,
                onTap: () => localeProvider.setLocale(const Locale('tr', 'TR')),
              ),
              const SizedBox(width: 12),
              _buildLanguageOption(
                context,
                label: 'English',
                flag: '🇺🇸',
                isSelected: localeProvider.isEnglish,
                onTap: () => localeProvider.setLocale(const Locale('en', 'US')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required String label,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: isSelected ? AppConstants.primaryGradient : null,
            color: isSelected ? null : AppConstants.surfaceColorAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppConstants.primaryColor
                  : Colors.white.withValues(alpha: 0.06),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppConstants.primaryColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(flag, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppConstants.darkTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildUserProfileHeader(
      BuildContext context, UserProfile? userProfile, String email) {
    final displayName = userProfile?.displayName ?? email.split('@').first;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppConstants.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        title: Text(
          s.logout,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppConstants.darkTextColor,
          ),
        ),
        content: Text(
          s.logoutConfirm,
          style: GoogleFonts.plusJakartaSans(
            color: AppConstants.lightTextColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              s.cancel,
              style: const TextStyle(color: AppConstants.lightTextColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              Navigator.pop(context);
              await authProvider.signOut();
            },
            child: Text(
              s.logout,
              style: const TextStyle(color: AppConstants.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
