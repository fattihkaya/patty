import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pet_ai/core/constants.dart';
import 'package:pet_ai/providers/gamification_provider.dart';
import 'package:pet_ai/models/achievement_model.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GamificationProvider>().fetchAllAchievements();
      context.read<GamificationProvider>().fetchUserAchievements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gamificationProvider = context.watch<GamificationProvider>();
    final allAchievements = gamificationProvider.allAchievements;
    final unlockedCodes = gamificationProvider.unlockedAchievementCodes;

    final filteredAchievements = _selectedCategory == 'all'
        ? allAchievements
        : allAchievements.where((a) => a.category == _selectedCategory).toList();

    final unlockedCount = unlockedCodes.length;
    final totalCount = allAchievements.length;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Başarımlar'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppConstants.primaryColor,
      ),
      body: gamificationProvider.isLoading && allAchievements.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await gamificationProvider.fetchAllAchievements();
                await gamificationProvider.fetchUserAchievements();
              },
              child: Column(
                children: [
                  _buildProgressCard(unlockedCount, totalCount),
                  _buildCategoryFilter(allAchievements),
                  Expanded(
                    child: filteredAchievements.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(AppConstants.defaultPadding),
                            itemCount: filteredAchievements.length,
                            itemBuilder: (context, index) {
                              final achievement = filteredAchievements[index];
                              final isUnlocked = unlockedCodes.contains(achievement.code);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppConstants.spacingMD),
                                child: _buildAchievementCard(achievement, isUnlocked),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressCard(int unlocked, int total) {
    final progress = total > 0 ? unlocked / total : 0.0;

    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      padding: const EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        gradient: AppConstants.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Başarım İlerlemesi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$unlocked / $total',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Center(
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(List<Achievement> achievements) {
    final categories = ['all', 'streak', 'log_count', 'health', 'social', 'financial'];
    final categoryNames = {
      'all': 'Tümü',
      'streak': 'Seri',
      'log_count': 'Kayıt',
      'health': 'Sağlık',
      'social': 'Sosyal',
      'financial': 'Finans',
    };

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: AppConstants.spacingSM),
            child: FilterChip(
              selected: isSelected,
              label: Text(categoryNames[category] ?? category),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = category);
                }
              },
              selectedColor: AppConstants.primaryColor,
              backgroundColor: AppConstants.surfaceColor,
              checkmarkColor: const Color(0xFF0F172A),
              side: BorderSide(
                color: isSelected
                    ? AppConstants.primaryColor
                    : Colors.white.withValues(alpha: 0.06),
              ),
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF0F172A) : AppConstants.darkTextColor,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isUnlocked) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppConstants.surfaceColor
            : AppConstants.surfaceColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: isUnlocked
              ? achievement.rarity.color.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? achievement.rarity.color.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isUnlocked
                    ? achievement.rarity.color
                    : AppConstants.lightTextColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              _getAchievementIcon(achievement.code),
              color: isUnlocked
                  ? achievement.rarity.color
                  : AppConstants.lightTextColor.withValues(alpha: 0.5),
              size: 28,
            ),
          ),
          const SizedBox(width: AppConstants.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isUnlocked
                              ? AppConstants.darkTextColor
                              : AppConstants.lightTextColor,
                        ),
                      ),
                    ),
                    if (isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppConstants.successColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          achievement.rarity.value.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.successColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isUnlocked
                        ? AppConstants.lightTextColor
                        : AppConstants.lightTextColor.withValues(alpha: 0.7),
                  ),
                ),
                if (!isUnlocked)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: AppConstants.lightTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Kilitli',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppConstants.lightTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (isUnlocked && achievement.pointsReward > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppConstants.warningColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: AppConstants.warningColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+${achievement.pointsReward}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.warningColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXXL),
        child: Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: AppConstants.primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz başarım yok',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: AppConstants.lightTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAchievementIcon(String code) {
    if (code.contains('streak')) return Icons.local_fire_department;
    if (code.contains('log')) return Icons.check_circle;
    if (code.contains('health')) return Icons.favorite;
    if (code.contains('social')) return Icons.people;
    if (code.contains('financial')) return Icons.account_balance_wallet;
    return Icons.emoji_events;
  }
}
