import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/app_strings.dart';
import '../../core/supabase_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';
import '../../models/log_model.dart';
import '../../models/pet_model.dart';
import '../pet/add_pet_screen.dart';
import 'widgets/timeline_list.dart';

import 'package:flutter/rendering.dart';
import '../home/widgets/pet_calendar_view.dart';
import 'widgets/streak_celebration_widget.dart';
import '../shop/achievements_screen.dart';
import '../shop/points_shop_screen.dart';
import '../health/health_screen.dart';
import 'widgets/stories_widget.dart';

class HomeScreen extends StatefulWidget {
  final void Function(BuildContext context, String petId)? onAddLog;
  final bool showDiaryAnalysis;

  const HomeScreen({super.key, this.onAddLog, this.showDiaryAnalysis = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _userStreak;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PetProvider>().fetchPets();
      _loadUserStreak();
    });
  }

  int? _previousStreak;

  Future<void> _loadUserStreak() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await SupabaseConfig.client
          .from('profiles')
          .select('current_streak, longest_streak, total_pati_points')
          .eq('id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        final newStreak = response['current_streak'] as int? ?? 0;

        // Check for milestone (7, 14, 30, 60, 100)
        if (_previousStreak != null &&
            _previousStreak! < newStreak &&
            ([7, 14, 30, 60, 100].contains(newStreak))) {
          _showStreakCelebration(context, newStreak);
        }

        setState(() {
          _previousStreak = newStreak;
          _userStreak = response;
        });
      }
    } catch (e) {
      debugPrint('Streak load failed: $e');
    }
  }

  void _showStreakCelebration(BuildContext context, int streakDays) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        StreakCelebrationWidget.show(
          context,
          streakDays: streakDays,
          rewardPoints: _getStreakRewardPoints(streakDays),
        );
      }
    });
  }

  int? _getStreakRewardPoints(int streakDays) {
    // Match with streak_rewards table
    switch (streakDays) {
      case 7:
        return 50;
      case 14:
        return 200;
      case 30:
        return 500;
      case 60:
        return 1000;
      case 100:
        return 1500;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          final selectedPetId = petProvider.selectedPetId;
          if (selectedPetId != null) {
            await petProvider.fetchLogs(selectedPetId);
          }
          await petProvider.fetchPets();
        },
        color: AppConstants.primaryColor,
        child: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (notification.direction == ScrollDirection.forward) {
              petProvider.setFabExpanded(true);
            } else if (notification.direction == ScrollDirection.reverse) {
              petProvider.setFabExpanded(false);
            }
            return true;
          },
          child: CustomScrollView(
            slivers: [
              _buildAppBar(authProvider, petProvider),
              if (petProvider.pets.isNotEmpty)
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildPetSwitcher(petProvider),
                      _buildMilestoneHeader(petProvider),
                      _buildHealthScoreCard(petProvider),
                      const StoriesWidget(),
                      _buildStreakAndLeaderboardRow(),
                    ],
                  ),
                ),
              SliverPadding(
                padding: AppConstants.paddingVerticalLG,
                sliver: SliverToBoxAdapter(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.05),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _buildHomeBody(petProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetSwitcher(PetProvider petProvider) {
    if (petProvider.pets.length <= 1) return const SizedBox.shrink();

    return Container(
      height: 90,
      margin: const EdgeInsets.only(top: 0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: AppConstants.paddingHorizontalMD,
        itemCount: petProvider.pets.length,
        itemBuilder: (context, index) {
          final pet = petProvider.pets[index];
          final isSelected = pet.id == petProvider.selectedPetId;

          return GestureDetector(
            onTap: () => petProvider.setSelectedPet(pet.id),
            child: AnimatedContainer(
              duration: AppConstants.fastDuration,
              margin: const EdgeInsets.only(right: AppConstants.spacingMD),
              curve: Curves.easeInOut,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: AppConstants.fastDuration,
                    padding: EdgeInsets.all(isSelected ? 3 : 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppConstants.primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    AppConstants.primaryColor.withValues(alpha: 0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: CircleAvatar(
                      radius: isSelected ? 28 : 24,
                      backgroundColor: AppConstants.mutedColor,
                      backgroundImage: NetworkImage(pet.photoUrl),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pet.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? AppConstants.primaryColor
                          : AppConstants.lightTextColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMilestoneHeader(PetProvider petProvider) {
    final pet = petProvider.selectedPet;
    if (pet == null) return const SizedBox.shrink();

    final days = DateTime.now().difference(pet.birthDate).inDays;

    return Container(
      margin: AppConstants.paddingHorizontalMD.copyWith(top: AppConstants.spacingMD, bottom: AppConstants.spacingMD),
      padding: AppConstants.paddingMD,
      decoration: BoxDecoration(
        gradient: AppConstants.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Paw print decoration (bottom right)
          Positioned(
            right: AppConstants.spacingMD,
            bottom: AppConstants.spacingMD,
            child: Icon(
              Icons.pets_rounded,
              color: Colors.white.withValues(alpha: 0.15),
              size: 50,
            ),
          ),
          // Pet icon decoration (top right)
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white.withValues(alpha: 0.08),
              size: 70,
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).togetherDay(days + 1),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      S.of(context).keepCollecting(pet.name),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildHealthScoreCard(PetProvider petProvider) {
    final pet = petProvider.selectedPet;
    if (pet == null) return const SizedBox.shrink();

    final healthScore = petProvider.calculateHealthScore(pet.id);
    if (healthScore == null) return const SizedBox.shrink();

    final scoreColor = healthScore >= 8
        ? AppConstants.successColor
        : healthScore >= 6
            ? AppConstants.warningColor
            : AppConstants.errorColor;

    final scoreLabel = healthScore >= 8
        ? S.of(context).excellent
        : healthScore >= 6
            ? S.of(context).good
            : healthScore >= 4
                ? S.of(context).average
                : S.of(context).attention;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.favorite_rounded,
              color: scoreColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).healthScore,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppConstants.lightTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      healthScore.toStringAsFixed(1),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: scoreColor,
                        height: 1.0,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '/10',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.lightTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        scoreLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: scoreColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            color: AppConstants.lightTextColor.withValues(alpha: 0.6),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HealthScreen(),
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStreakAndLeaderboardRow() {
    final currentStreak = _userStreak?['current_streak'] as int? ?? 0;
    final longestStreak = _userStreak?['longest_streak'] as int? ?? 0;
    final totalPoints = _userStreak?['total_pati_points'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          // Streak Card
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AchievementsScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppConstants.warmGradient,
                  borderRadius:
                      BorderRadius.circular(AppConstants.cardBorderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.accentColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          S.of(context).streak,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$currentStreak',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      S.of(context).longestStreak(longestStreak),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Points Card
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PointsShopScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius:
                      BorderRadius.circular(AppConstants.cardBorderRadius),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
                  boxShadow: AppConstants.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppConstants.warningColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.stars_rounded,
                              color: AppConstants.warningColor, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          S.of(context).patiPoints,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.lightTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$totalPoints',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.primaryColor,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeBody(PetProvider petProvider) {
    if (petProvider.isLoading) {
      return const SizedBox(
        height: 400,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (petProvider.pets.isEmpty) {
      return _buildEmptyState();
    }

    if (petProvider.isLoadingLogs) {
      return Padding(
        padding: AppConstants.paddingHorizontalMD,
        child: Shimmer.fromColors(
          baseColor: AppConstants.surfaceColor,
          highlightColor: AppConstants.surfaceColorAlt,
          child: Column(
            children: List.generate(3, (index) => _buildShimmerItem()),
          ),
        ),
      );
    }

    final selectedPet = petProvider.selectedPet;
    if (selectedPet == null) return const SizedBox.shrink();
    final logs = petProvider.getLogsForPet(selectedPet.id);

    // Toggle between List and Calendar
    if (petProvider.viewMode == TimelineViewMode.calendar) {
      return PetCalendarView(
        key: const ValueKey('calendar_view'),
        pet: selectedPet,
        logs: logs,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInsightsRow(selectedPet, logs),
        TimelineList(
          key: const ValueKey('timeline_list'),
          pet: selectedPet,
          logs: logs,
          showAnalysis: widget.showDiaryAnalysis,
          onAddLog: widget.onAddLog == null
              ? null
              : () => widget.onAddLog!(context, selectedPet.id),
        ),
      ],
    );
  }

  Widget _buildShimmerItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMD),
      height: 250,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
    );
  }

  Widget _buildAppBar(AuthProvider authProvider, PetProvider petProvider) {
    return SliverAppBar(
      expandedHeight: 100.0,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 20),
        centerTitle: false,
        title: Text(
          S.of(context).petAITimeline,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppConstants.primaryColor,
            letterSpacing: -0.5,
          ),
        ),
      ),
      actions: [
        _buildViewSwitcher(petProvider),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildViewSwitcher(PetProvider petProvider) {
    final isCalendar = petProvider.viewMode == TimelineViewMode.calendar;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSwitcherItem(
            icon: Icons.view_headline_rounded,
            isSelected: !isCalendar,
            onTap: () => petProvider.setViewMode(TimelineViewMode.list),
          ),
          _buildSwitcherItem(
            icon: Icons.calendar_month_rounded,
            isSelected: isCalendar,
            onTap: () => petProvider.setViewMode(TimelineViewMode.calendar),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitcherItem({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.white : AppConstants.lightTextColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor.withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: 10,
                )
              ],
            ),
            child: const Icon(Icons.pets_rounded,
                size: 80, color: AppConstants.primaryColor),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2.seconds, color: AppConstants.primaryLight),
          const SizedBox(height: 40),
          Text(
            S.of(context).noPetYet,
            style:
                GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            S.of(context).createProfile,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppConstants.lightTextColor, height: 1.5),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddPetScreen()),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(S.of(context).addYourPet),
          ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),
        ],
      ),
    );
  }

  Widget _buildInsightsRow(PetModel pet, List<LogModel> logs) {
    final totalLogs = logs.length;
    final lastLog = logs.isNotEmpty ? logs.first : null;
    final daysSinceLast = lastLog != null
        ? DateTime.now().difference(lastLog.createdAt).inDays
        : null;
    final summary = lastLog?.summaryTr?.trim();
    final moodLabel = lastLog?.moodLabel?.trim();
    final petVoice = lastLog?.petVoiceTr?.trim();
    final moodSnippet = lastLog == null
        ? S.of(context).noAIComment
        : summary?.isNotEmpty == true
            ? summary!
            : moodLabel?.isNotEmpty == true
                ? 'Mood: $moodLabel'
                : petVoice?.isNotEmpty == true
                    ? petVoice!
                    : S.of(context).noAIComment;

    return Padding(
      padding: AppConstants.paddingHorizontalMD.copyWith(bottom: AppConstants.spacingSM),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 112,
              padding: const EdgeInsets.all(AppConstants.spacingMD),
              decoration: BoxDecoration(
                color: AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).totalMemories,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppConstants.lightTextColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$totalLogs',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    daysSinceLast == null
                        ? S.of(context).noRecordsYet
                        : (daysSinceLast == 0
                            ? S.of(context).addedToday
                            : S.of(context).daysAgo(daysSinceLast)),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppConstants.lightTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacingMD),
          Expanded(
            child: Container(
              height: 112,
              padding: const EdgeInsets.all(AppConstants.spacingMD),
              decoration: BoxDecoration(
                gradient: AppConstants.luxeGradient,
                borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.accentColor.withValues(alpha: 0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'AI Mood',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      if (moodLabel?.isNotEmpty == true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            moodLabel!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Spacer(),
                  Text(
                    moodSnippet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.3,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lastLog == null
                        ? S.of(context).addPhotoForAI
                        : S.of(context).lastUpdate(DateFormat('dd MMM', 'tr_TR')
                            .format(lastLog.createdAt)),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
    );
  }
}
