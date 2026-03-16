import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';
import '../../core/app_strings.dart';
import '../../providers/social_provider.dart';
import '../home/widgets/timeline_item.dart';
import '../../models/log_model.dart';
import 'package:shimmer/shimmer.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialProvider>().fetchPublicLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final socialProvider = context.watch<SocialProvider>();
    final logs = socialProvider.publicLogs;
    final s = S.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 110,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                centerTitle: false,
                title: Text(
                  s.discover,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.darkTextColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => socialProvider.fetchPublicLogs(),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: () => socialProvider.fetchPublicLogs(),
          color: AppConstants.primaryColor,
          child: socialProvider.isLoading && logs.isEmpty
              ? _buildLoadingState()
              : logs.isEmpty
                  ? _buildEmptyState(s)
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                          left: 20, right: 20, top: 10, bottom: 100),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final logData = logs[index];
                        final log = LogModel.fromJson(logData);
                        final profile = logData['pets']?['profiles']
                            as Map<String, dynamic>?;
                        final pets = logData['pets'];
                        final petMap = pets is Map<String, dynamic>
                            ? pets
                            : (pets is Map ? Map<String, dynamic>.from(pets) : null);
                        final petName = petMap?['name'] as String?;
                        final petPhotoUrl = petMap?['photo_url'] as String?;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: AppConstants.surfaceColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppConstants.primaryColor.withValues(alpha: 0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildUserHeader(
                                  profile,
                                  logData['pets']?['name'] as String?,
                                  logData['pets']?['photo_url'] as String?,
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: TimelineItem(
                                    log: log,
                                    isLast: index == logs.length - 1,
                                    petName: petName,
                                    avatarUrl: petPhotoUrl,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: (index * 80).ms)
                            .slideY(begin: 0.05, end: 0);
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(
      Map<String, dynamic>? profile, String? petName, String? petPhotoUrl) {
    if (profile == null) return const SizedBox.shrink();

    final username = profile['username'] as String?;
    final firstName = profile['first_name'] as String?;
    final lastName = profile['last_name'] as String?;
    final email = profile['email'] as String?;

    String displayName = 'User';
    if (username != null && username.isNotEmpty) {
      displayName = username;
    } else if (firstName != null && firstName.isNotEmpty) {
      displayName = firstName;
      if (lastName != null && lastName.isNotEmpty) {
        displayName += ' $lastName';
      }
    } else if (email != null && email.isNotEmpty) {
      displayName = email.split('@')[0];
    }

    if (petName != null && petName.isNotEmpty) {
      displayName = '$petName • $displayName';
    }

    final avatarUrl = petPhotoUrl ?? profile['avatar_url'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppConstants.primaryColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppConstants.primaryLight,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Icon(
                      petName != null ? Icons.pets_rounded : Icons.person,
                      size: 18,
                      color: AppConstants.primaryColor,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              displayName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppConstants.darkTextColor,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppConstants.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.public_rounded,
                    size: 12, color: AppConstants.primaryColor),
                const SizedBox(width: 4),
                Text(
                  S.of(context).everyone,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: AppConstants.surfaceColor,
      highlightColor: AppConstants.surfaceColorAlt,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 24),
          height: 300,
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(S s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: AppConstants.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.explore_rounded,
                size: 48, color: AppConstants.primaryColor.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          Text(
            s.noPublicPosts,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppConstants.darkTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
