import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';

enum AchievementCategory { all, progress, perfection, mastery }

enum AchievementTier { bronze, silver, gold, platinum, diamond }

class AchievementDef {
  final String key;
  final String title;
  final String desc;
  final AchievementCategory category;
  final AchievementTier tier;
  final IconData icon;
  final int target;
  final int Function(GameState state) getProgress;
  final int coinReward;
  final int gemReward;

  const AchievementDef({
    required this.key,
    required this.title,
    required this.desc,
    required this.category,
    required this.tier,
    required this.icon,
    required this.target,
    required this.getProgress,
    required this.coinReward,
    required this.gemReward,
  });
}

class AchievementsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const AchievementsScreen({super.key, required this.onBack});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  AchievementCategory _selectedCategory = AchievementCategory.all;

  // 16 Comprehensive Achievements
  static final List<AchievementDef> _achievements = [
    // ── PROGRESS CATEGORY ────────────────────────────────────────────────────
    AchievementDef(
      key: 'first_steps',
      title: 'First Explorer',
      desc: 'Complete 5 maze levels',
      category: AchievementCategory.progress,
      tier: AchievementTier.bronze,
      icon: Icons.directions_walk,
      target: 5,
      getProgress: (s) => s.mazesSolved,
      coinReward: 100,
      gemReward: 5,
    ),
    AchievementDef(
      key: 'apprentice',
      title: 'Maze Pathfinder',
      desc: 'Complete 15 maze levels',
      category: AchievementCategory.progress,
      tier: AchievementTier.silver,
      icon: Icons.explore,
      target: 15,
      getProgress: (s) => s.mazesSolved,
      coinReward: 250,
      gemReward: 10,
    ),
    AchievementDef(
      key: 'adventurer',
      title: 'Dungeon Master',
      desc: 'Complete 30 maze levels',
      category: AchievementCategory.progress,
      tier: AchievementTier.gold,
      icon: Icons.map,
      target: 30,
      getProgress: (s) => s.mazesSolved,
      coinReward: 500,
      gemReward: 20,
    ),
    AchievementDef(
      key: 'maze_master',
      title: 'Grand Architect',
      desc: 'Complete 50 maze levels',
      category: AchievementCategory.progress,
      tier: AchievementTier.platinum,
      icon: Icons.emoji_events,
      target: 50,
      getProgress: (s) => s.mazesSolved,
      coinReward: 1000,
      gemReward: 40,
    ),
    AchievementDef(
      key: 'legendary_explorer',
      title: 'Cyber Legend',
      desc: 'Complete 100 maze levels',
      category: AchievementCategory.progress,
      tier: AchievementTier.diamond,
      icon: Icons.workspace_premium,
      target: 100,
      getProgress: (s) => s.mazesSolved,
      coinReward: 2000,
      gemReward: 75,
    ),

    // ── PERFECTION CATEGORY ──────────────────────────────────────────────────
    AchievementDef(
      key: 'flawless_start',
      title: 'Flawless Touch',
      desc: 'Complete 1 level without any mistakes',
      category: AchievementCategory.perfection,
      tier: AchievementTier.bronze,
      icon: Icons.favorite_border,
      target: 1,
      getProgress: (s) => s.perfectRuns,
      coinReward: 150,
      gemReward: 5,
    ),
    AchievementDef(
      key: 'perfect_run',
      title: 'Precision Specialist',
      desc: 'Complete 10 levels without any mistakes',
      category: AchievementCategory.perfection,
      tier: AchievementTier.silver,
      icon: Icons.favorite,
      target: 10,
      getProgress: (s) => s.perfectRuns,
      coinReward: 400,
      gemReward: 15,
    ),
    AchievementDef(
      key: 'perfectionist',
      title: 'Untouchable Master',
      desc: 'Complete 25 levels without any mistakes',
      category: AchievementCategory.perfection,
      tier: AchievementTier.gold,
      icon: Icons.health_and_safety,
      target: 25,
      getProgress: (s) => s.perfectRuns,
      coinReward: 800,
      gemReward: 30,
    ),
    AchievementDef(
      key: 'star_novice',
      title: 'Star Chaser',
      desc: 'Collect 25 total stars',
      category: AchievementCategory.perfection,
      tier: AchievementTier.bronze,
      icon: Icons.star_border,
      target: 25,
      getProgress: (s) => s.totalStars,
      coinReward: 150,
      gemReward: 5,
    ),
    AchievementDef(
      key: 'star_collector',
      title: 'Star Champion',
      desc: 'Collect 75 total stars',
      category: AchievementCategory.perfection,
      tier: AchievementTier.gold,
      icon: Icons.star,
      target: 75,
      getProgress: (s) => s.totalStars,
      coinReward: 500,
      gemReward: 20,
    ),
    AchievementDef(
      key: 'starlight_legend',
      title: 'Constellation God',
      desc: 'Collect 150 total stars',
      category: AchievementCategory.perfection,
      tier: AchievementTier.diamond,
      icon: Icons.stars,
      target: 150,
      getProgress: (s) => s.totalStars,
      coinReward: 1200,
      gemReward: 50,
    ),

    // ── MASTERY CATEGORY ─────────────────────────────────────────────────────
    AchievementDef(
      key: 'speedster',
      title: 'Lightning Runner',
      desc: 'Complete 5 mazes with 3 stars',
      category: AchievementCategory.mastery,
      tier: AchievementTier.silver,
      icon: Icons.bolt,
      target: 5,
      getProgress: (s) => (s.totalStars / 3).floor(),
      coinReward: 250,
      gemReward: 10,
    ),
    AchievementDef(
      key: 'sonic_runner',
      title: 'Velocity Demon',
      desc: 'Complete 20 mazes with 3 stars',
      category: AchievementCategory.mastery,
      tier: AchievementTier.gold,
      icon: Icons.flash_on,
      target: 20,
      getProgress: (s) => (s.totalStars / 3).floor(),
      coinReward: 600,
      gemReward: 25,
    ),
    AchievementDef(
      key: 'coin_hoarder',
      title: 'Treasure Hunter',
      desc: 'Accumulate 500 total coins',
      category: AchievementCategory.mastery,
      tier: AchievementTier.bronze,
      icon: Icons.monetization_on,
      target: 500,
      getProgress: (s) => s.coins,
      coinReward: 200,
      gemReward: 10,
    ),
    AchievementDef(
      key: 'gem_tycoon',
      title: 'Gem Tycoon',
      desc: 'Accumulate 50 total gems',
      category: AchievementCategory.mastery,
      tier: AchievementTier.gold,
      icon: Icons.diamond,
      target: 50,
      getProgress: (s) => s.gems,
      coinReward: 500,
      gemReward: 25,
    ),
    AchievementDef(
      key: 'streak_master',
      title: 'Unstoppable Streak',
      desc: 'Reach a 5-day play streak',
      category: AchievementCategory.mastery,
      tier: AchievementTier.platinum,
      icon: Icons.local_fire_department,
      target: 5,
      getProgress: (s) => s.streak,
      coinReward: 400,
      gemReward: 15,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Color _getTierColor(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementTier.gold:
        return const Color(0xFFFFD700);
      case AchievementTier.platinum:
        return const Color(0xFFE5E4E2);
      case AchievementTier.diamond:
        return const Color(0xFF00FFFF);
    }
  }

  String _getTierName(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return 'BRONZE';
      case AchievementTier.silver:
        return 'SILVER';
      case AchievementTier.gold:
        return 'GOLD';
      case AchievementTier.platinum:
        return 'PLATINUM';
      case AchievementTier.diamond:
        return 'DIAMOND';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);

    // Compute stats
    int totalUnlocked = 0;
    for (final ach in _achievements) {
      final progress = ach.getProgress(state);
      if (progress >= ach.target || state.claimedAchievements.contains(ach.key)) {
        totalUnlocked++;
      }
    }

    final filteredAchs = _achievements.where((ach) {
      if (_selectedCategory == AchievementCategory.all) return true;
      return ach.category == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // ── Top Header ─────────────────────────────────────────────
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
                        onPressed: widget.onBack,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ACHIEVEMENTS',
                        style: GoogleFonts.orbitron(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      // Energy/Gems pill header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.emoji_events_rounded, size: 14, color: AppTheme.accentGold),
                            const SizedBox(width: 6),
                            Text(
                              '$totalUnlocked / ${_achievements.length}',
                              style: GoogleFonts.orbitron(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentGold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Trophy Summary Banner ─────────────────────────────────
                  _buildSummaryBanner(totalUnlocked, _achievements.length),
                  const SizedBox(height: 14),

                  // ── Category Filter Tabs ──────────────────────────────────
                  _buildCategoryFilterTabs(),
                  const SizedBox(height: 14),

                  // ── Achievements List ──────────────────────────────────────
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredAchs.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final item = filteredAchs[index];
                        final rawProgress = item.getProgress(state);
                        final progress = rawProgress.clamp(0, item.target);
                        final claimed = state.claimedAchievements.contains(item.key);
                        final canClaim = progress >= item.target && !claimed;
                        final pct = (progress / item.target).clamp(0.0, 1.0);
                        final tierColor = _getTierColor(item.tier);
                        final tierName = _getTierName(item.tier);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E122B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: canClaim
                                  ? AppTheme.primaryGlow
                                  : (claimed
                                      ? tierColor.withValues(alpha: 0.35)
                                      : Colors.white.withValues(alpha: 0.08)),
                              width: canClaim ? 1.8 : 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: canClaim
                                    ? AppTheme.primaryGlow.withValues(alpha: 0.25)
                                    : (claimed ? tierColor.withValues(alpha: 0.10) : Colors.transparent),
                                blurRadius: canClaim ? 16 : 8,
                                spreadRadius: canClaim ? 1 : 0,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Icon with Tier Aura Frame
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: tierColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: tierColor.withValues(alpha: 0.6), width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: tierColor.withValues(alpha: 0.2),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        item.icon,
                                        size: 24,
                                        color: tierColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: GoogleFonts.orbitron(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            // Tier Badge Label
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: tierColor.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: tierColor.withValues(alpha: 0.5)),
                                              ),
                                              child: Text(
                                                tierName,
                                                style: GoogleFonts.orbitron(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  color: tierColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.desc,
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Progress Bar & Ratio
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        minHeight: 8,
                                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          claimed
                                              ? AppTheme.primaryGlow
                                              : (canClaim ? AppTheme.accentGold : tierColor),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${(pct * 100).round()}%',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Rewards & Action Button Footer
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Rewards Pill
                                  Row(
                                    children: [
                                      _RewardBadge(
                                        icon: Icons.monetization_on_rounded,
                                        color: AppTheme.accentGold,
                                        text: '+${item.coinReward}',
                                      ),
                                      const SizedBox(width: 8),
                                      _RewardBadge(
                                        icon: Icons.diamond_rounded,
                                        color: AppTheme.accentBlue,
                                        text: '+${item.gemReward}',
                                      ),
                                    ],
                                  ),

                                  // Action / Status
                                  if (claimed)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGlow.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppTheme.primaryGlow.withValues(alpha: 0.4)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.primaryGlow),
                                          const SizedBox(width: 4),
                                          Text(
                                            'UNLOCKED',
                                            style: GoogleFonts.orbitron(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: AppTheme.primaryGlow,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (canClaim)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryGlow,
                                        elevation: 6,
                                        shadowColor: AppTheme.primaryGlow.withValues(alpha: 0.5),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      onPressed: () {
                                        HapticFeedback.heavyImpact();
                                        _confettiController.play();
                                        state.claimAchievement(item.key, item.coinReward, item.gemReward);
                                      },
                                      child: Text(
                                        'CLAIM REWARD',
                                        style: GoogleFonts.orbitron(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    )
                                  else
                                    Text(
                                      '$progress / ${item.target}',
                                      style: GoogleFonts.orbitron(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Confetti Overlay on Claim
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 25,
              gravity: 0.2,
              colors: const [
                AppTheme.primaryGlow,
                AppTheme.secondaryGlow,
                AppTheme.accentGold,
                AppTheme.accentPink,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary Banner Widget ────────────────────────────────────────────────
  Widget _buildSummaryBanner(int unlocked, int total) {
    final double pct = unlocked / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF161B42), Color(0xFF0E122B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGold.withValues(alpha: 0.12),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Glowing Trophy Cup
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGold.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.emoji_events_rounded, size: 30, color: Colors.black),
            ),
          ),
          const SizedBox(width: 16),

          // Progress text & bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TROPHY HALL OF FAME',
                  style: GoogleFonts.orbitron(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.accentGold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Unlocked $unlocked of $total Achievements',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Category Filter Tabs Widget ──────────────────────────────────────────
  Widget _buildCategoryFilterTabs() {
    final categories = [
      {'cat': AchievementCategory.all, 'label': 'ALL (16)'},
      {'cat': AchievementCategory.progress, 'label': 'PROGRESS'},
      {'cat': AchievementCategory.perfection, 'label': 'PERFECTION'},
      {'cat': AchievementCategory.mastery, 'label': 'MASTERY'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((c) {
          final cat = c['cat'] as AchievementCategory;
          final label = c['label'] as String;
          final isSelected = _selectedCategory == cat;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryGlow
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryGlow
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryGlow.withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  label,
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.black : Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Reusable Reward Badge ────────────────────────────────────────────────────
class _RewardBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _RewardBadge({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.orbitron(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
