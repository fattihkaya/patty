import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_ai/core/constants.dart';
import 'package:pet_ai/core/supabase_config.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _weeklyLeaders = [];
  List<Map<String, dynamic>> _globalLeaders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final weeklyResponse = await SupabaseConfig.client
          .from('weekly_leaderboard')
          .select()
          .limit(50);
      
      final globalResponse = await SupabaseConfig.client
          .from('global_leaderboard')
          .select()
          .limit(50);

      setState(() {
        _weeklyLeaders = (weeklyResponse as List).cast<Map<String, dynamic>>();
        _globalLeaders = (globalResponse as List).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint('Leaderboard load failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Liderlik Tablosu'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppConstants.primaryColor,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: AppConstants.lightTextColor,
          indicatorColor: AppConstants.primaryColor,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: 'Haftalık'),
            Tab(text: 'Genel'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLeaderboard,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLeaderboardList(_weeklyLeaders, isWeekly: true),
                  _buildLeaderboardList(_globalLeaders, isWeekly: false),
                ],
              ),
            ),
    );
  }

  Widget _buildLeaderboardList(List<Map<String, dynamic>> leaders, {required bool isWeekly}) {
    if (leaders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: AppConstants.lightTextColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz lider yok',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                color: AppConstants.lightTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isWeekly
                  ? 'Bu hafta henüz kayıt yok'
                  : 'Henüz kayıt yok',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppConstants.lightTextColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leaders.length,
      itemBuilder: (context, index) {
        final leader = leaders[index];
        final rank = index + 1;
        final avgScore = (leader['avg_score'] as num?)?.toDouble() ?? 0.0;
        final logCount = leader['log_count'] as int? ?? 0;
        final petName = leader['pet_name'] as String? ?? 'Bilinmiyor';
        final photoUrl = leader['photo_url'] as String?;

        return _buildLeaderCard(
          rank: rank,
          petName: petName,
          photoUrl: photoUrl,
          avgScore: avgScore,
          logCount: logCount,
        );
      },
    );
  }

  Widget _buildLeaderCard({
    required int rank,
    required String petName,
    required String? photoUrl,
    required double avgScore,
    required int logCount,
  }) {
    final isTopThree = rank <= 3;
    final medalColors = [
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isTopThree
            ? Border.all(
                color: medalColors[rank - 1],
                width: 2,
              )
            : Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTopThree
                  ? medalColors[rank - 1].withValues(alpha: 0.15)
                  : AppConstants.primaryColor.withValues(alpha: 0.15),
            ),
            child: Center(
              child: isTopThree
                  ? Icon(
                      Icons.emoji_events_rounded,
                      color: medalColors[rank - 1],
                      size: 28,
                    )
                  : Text(
                      '$rank',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.primaryColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          if (photoUrl != null && photoUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                photoUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 48,
                    height: 48,
                    color: AppConstants.primaryColor.withValues(alpha: 0.15),
                    child: const Icon(
                      Icons.pets_rounded,
                      color: AppConstants.primaryColor,
                    ),
                  );
                },
              ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: AppConstants.primaryColor,
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  petName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: AppConstants.warningColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${avgScore.toStringAsFixed(1)}/5',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.photo_library_rounded,
                      size: 14,
                      color: AppConstants.lightTextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$logCount kayıt',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppConstants.lightTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
