import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/math_graph_background.dart';

enum AchievementCategory { all, progress, perfection, starlight, mastery, cosmic }

enum AchievementTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  mythic,
  cosmic,
  apex,
  singularity
}

/// Dynamic Procedural Achievement Definition with Math Map Node Coordinates
class ProceduralAchievement {
  final String key;
  final String title;
  final String desc;
  final AchievementCategory category;
  final AchievementTier tier;
  final IconData icon;
  final int target;
  final int currentProgress;
  final int coinReward;
  final int gemReward;
  final String mathCoordinateLabel; // e.g. "P₁(π/2, 1.5)"
  final Offset mapPosition;         // Absolute position in map coordinate space

  const ProceduralAchievement({
    required this.key,
    required this.title,
    required this.desc,
    required this.category,
    required this.tier,
    required this.icon,
    required this.target,
    required this.currentProgress,
    required this.coinReward,
    required this.gemReward,
    required this.mathCoordinateLabel,
    required this.mapPosition,
  });
}

/// Procedural Achievement Generator Engine with Star Constellation Map Coordinates
class ProceduralAchievementEngine {
  static const double mapSize = 2200.0;
  static const Offset mapOrigin = Offset(1100.0, 1100.0);

  static List<ProceduralAchievement> generateAchievements(GameState state) {
    final list = <ProceduralAchievement>[];
    int pointIndex = 1;

    // Helper for arm angular positioning in constellation map layout
    // 5 constellation arms radiating out from Origin P₀(0,0)
    final armAngles = {
      AchievementCategory.progress: -math.pi / 2,        // 12 o'clock (North)
      AchievementCategory.perfection: -math.pi / 10,       // 2 o'clock (North-East)
      AchievementCategory.starlight: math.pi * 3 / 10,     // 4 o'clock (South-East)
      AchievementCategory.mastery: math.pi * 7 / 10,      // 8 o'clock (South-West)
      AchievementCategory.cosmic: math.pi * 11 / 10,      // 10 o'clock (North-West)
    };

    Offset calculateNodePosition(AchievementCategory category, int itemIndex, int totalInCat) {
      final baseAngle = armAngles[category] ?? 0.0;
      final spiralAngle = baseAngle + (itemIndex * 0.14) * (itemIndex % 2 == 0 ? 1 : -1);
      final radius = 180.0 + (itemIndex * 95.0);
      final jitterX = math.sin(itemIndex * 2.3) * 35.0;
      final jitterY = math.cos(itemIndex * 1.9) * 35.0;

      final x = mapOrigin.dx + radius * math.cos(spiralAngle) + jitterX;
      final y = mapOrigin.dy + radius * math.sin(spiralAngle) + jitterY;
      return Offset(x, y);
    }

    // 1. Level Milestones (Progress Arm)
    final levelTargets = _generateMilestones(
      maxReached: state.currentLevel,
      baseStep: 5,
      multiplier: 1.6,
      count: 16,
    );
    for (int i = 0; i < levelTargets.length; i++) {
      final target = levelTargets[i];
      final tier = _calculateTier(target, 5, 1000);
      final idx = pointIndex++;
      final mathLabel = 'P_$idx(${(target * 0.5).toStringAsFixed(1)}π, ${(target * 0.2).toStringAsFixed(1)})';
      list.add(ProceduralAchievement(
        key: 'level_milestone_$target',
        title: _getLevelTitle(target),
        desc: 'Reach Level $target on the World Map',
        category: AchievementCategory.progress,
        tier: tier,
        icon: _getLevelIcon(target),
        target: target,
        currentProgress: state.currentLevel,
        coinReward: (target * 22).clamp(100, 25000),
        gemReward: (target * 0.75).round().clamp(5, 1200),
        mathCoordinateLabel: mathLabel,
        mapPosition: calculateNodePosition(AchievementCategory.progress, i, levelTargets.length),
      ));
    }

    // 2. Perfection Flawless Run Milestones (Perfection Arm)
    final perfectTargets = _generateMilestones(
      maxReached: state.perfectRuns,
      baseStep: 3,
      multiplier: 1.7,
      count: 12,
    );
    for (int i = 0; i < perfectTargets.length; i++) {
      final target = perfectTargets[i];
      final tier = _calculateTier(target, 3, 500);
      final idx = pointIndex++;
      final mathLabel = 'P_$idx(e^${(target * 0.1).toStringAsFixed(1)}, √$target)';
      list.add(ProceduralAchievement(
        key: 'perfect_milestone_$target',
        title: _getPerfectionTitle(target),
        desc: 'Complete $target levels without any mistakes',
        category: AchievementCategory.perfection,
        tier: tier,
        icon: Icons.health_and_safety_rounded,
        target: target,
        currentProgress: state.perfectRuns,
        coinReward: (target * 35).clamp(150, 30000),
        gemReward: (target * 1.1).round().clamp(8, 1500),
        mathCoordinateLabel: mathLabel,
        mapPosition: calculateNodePosition(AchievementCategory.perfection, i, perfectTargets.length),
      ));
    }

    // 3. Starlight Star Collection Milestones (Starlight Arm)
    final starTargets = _generateMilestones(
      maxReached: state.totalStars,
      baseStep: 15,
      multiplier: 1.8,
      count: 14,
    );
    for (int i = 0; i < starTargets.length; i++) {
      final target = starTargets[i];
      final tier = _calculateTier(target, 15, 1500);
      final idx = pointIndex++;
      final mathLabel = 'P_$idx($target, Φ^${(target * 0.05).toStringAsFixed(1)})';
      list.add(ProceduralAchievement(
        key: 'stars_milestone_$target',
        title: _getStarTitle(target),
        desc: 'Collect a total of $target stars across all mazes',
        category: AchievementCategory.starlight,
        tier: tier,
        icon: Icons.stars_rounded,
        target: target,
        currentProgress: state.totalStars,
        coinReward: (target * 18).clamp(120, 28000),
        gemReward: (target * 0.65).round().clamp(5, 1400),
        mathCoordinateLabel: mathLabel,
        mapPosition: calculateNodePosition(AchievementCategory.starlight, i, starTargets.length),
      ));
    }

    // 4. Mazes Solved Milestones (Mastery Arm)
    final mazeTargets = _generateMilestones(
      maxReached: state.mazesSolved,
      baseStep: 5,
      multiplier: 1.65,
      count: 12,
    );
    for (int i = 0; i < mazeTargets.length; i++) {
      final target = mazeTargets[i];
      final tier = _calculateTier(target, 5, 800);
      final idx = pointIndex++;
      final mathLabel = 'P_$idx(${(target * 0.3).toStringAsFixed(1)}, ∇f)';
      list.add(ProceduralAchievement(
        key: 'mazes_milestone_$target',
        title: _getMazeTitle(target),
        desc: 'Solve $target complete cyber mazes',
        category: AchievementCategory.mastery,
        tier: tier,
        icon: Icons.grid_view_rounded,
        target: target,
        currentProgress: state.mazesSolved,
        coinReward: (target * 20).clamp(100, 20000),
        gemReward: (target * 0.70).round().clamp(5, 1000),
        mathCoordinateLabel: mathLabel,
        mapPosition: calculateNodePosition(AchievementCategory.mastery, i, mazeTargets.length),
      ));
    }

    // 5. Streak & Cosmic Mastery Milestones (Cosmic Arm)
    final streakTargets = [3, 5, 10, 15, 30, 60, 100, 180, 365, 500];
    for (int i = 0; i < streakTargets.length; i++) {
      final target = streakTargets[i];
      if (target <= state.streak + 30) {
        final tier = _calculateTier(target, 3, 365);
        final idx = pointIndex++;
        final mathLabel = 'P_$idx(Day_$target, ∫dt)';
        list.add(ProceduralAchievement(
          key: 'streak_milestone_$target',
          title: 'Day $target Matrix Streak',
          desc: 'Maintain a continuous $target-day play streak',
          category: AchievementCategory.cosmic,
          tier: tier,
          icon: Icons.local_fire_department_rounded,
          target: target,
          currentProgress: state.streak,
          coinReward: target * 120,
          gemReward: target * 3,
          mathCoordinateLabel: mathLabel,
          mapPosition: calculateNodePosition(AchievementCategory.cosmic, i, streakTargets.length),
        ));
      }
    }

    return list;
  }

  static List<int> _generateMilestones({
    required int maxReached,
    required int baseStep,
    required double multiplier,
    required int count,
  }) {
    final targets = <int>[];
    double curr = baseStep.toDouble();

    for (int i = 0; i < count; i++) {
      int val = curr.round();
      if (val > 100) val = (val / 10).round() * 10;
      if (val > 1000) val = (val / 50).round() * 50;

      if (!targets.contains(val)) {
        targets.add(val);
      }

      curr *= multiplier;
      if (val > maxReached + 300 && targets.length >= 8) break;
    }
    return targets;
  }

  static AchievementTier _calculateTier(int value, int minVal, int maxVal) {
    final pct = (value - minVal) / (maxVal - minVal);
    if (pct < 0.08) return AchievementTier.bronze;
    if (pct < 0.18) return AchievementTier.silver;
    if (pct < 0.32) return AchievementTier.gold;
    if (pct < 0.48) return AchievementTier.platinum;
    if (pct < 0.65) return AchievementTier.diamond;
    if (pct < 0.80) return AchievementTier.mythic;
    if (pct < 0.92) return AchievementTier.cosmic;
    if (pct < 0.98) return AchievementTier.apex;
    return AchievementTier.singularity;
  }

  static String _getLevelTitle(int level) {
    if (level <= 5) return 'Novice Pathfinder';
    if (level <= 15) return 'Cyber Explorer';
    if (level <= 30) return 'Quantum Specialist';
    if (level <= 50) return 'Matrix Architect';
    if (level <= 100) return 'Grand Pathfinder';
    if (level <= 200) return 'Rift Overlord';
    if (level <= 500) return 'Cosmic Sovereign';
    if (level <= 1000) return 'Apex Singularity Master';
    return 'Multiverse Galaxy Deity';
  }

  static IconData _getLevelIcon(int level) {
    if (level <= 15) return Icons.directions_walk_rounded;
    if (level <= 50) return Icons.explore_rounded;
    if (level <= 150) return Icons.map_rounded;
    if (level <= 500) return Icons.workspace_premium_rounded;
    return Icons.all_inclusive_rounded;
  }

  static String _getPerfectionTitle(int count) {
    if (count <= 1) return 'Flawless Touch';
    if (count <= 5) return 'Precision Runner';
    if (count <= 15) return 'Untouchable Master';
    if (count <= 35) return 'Zero Error Specialist';
    if (count <= 100) return 'Impervious Guardian';
    return 'Absolute Perfect Deity';
  }

  static String _getStarTitle(int count) {
    if (count <= 25) return 'Star Chaser';
    if (count <= 75) return 'Constellation Hunter';
    if (count <= 200) return 'Galaxy Collector';
    if (count <= 500) return 'Cosmic Starlight Deity';
    return 'Universal Star Sovereign';
  }

  static String _getMazeTitle(int count) {
    if (count <= 10) return 'Labyrinth Solver';
    if (count <= 30) return 'Grid Specialist';
    if (count <= 100) return 'Master Decipherer';
    if (count <= 300) return 'Hypercube Conqueror';
    return 'Omnipresent Maze Overlord';
  }

  static Color getTierColor(AchievementTier tier) {
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
        return const Color(0xFF00F0FF);
      case AchievementTier.mythic:
        return const Color(0xFFFF2A85);
      case AchievementTier.cosmic:
        return const Color(0xFFA855F7);
      case AchievementTier.apex:
        return const Color(0xFF00FF9D);
      case AchievementTier.singularity:
        return const Color(0xFFFFD700);
    }
  }

  static String getTierName(AchievementTier tier) {
    return tier.name.toUpperCase();
  }
}

class AchievementsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const AchievementsScreen({super.key, required this.onBack});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _mapPulseAnimCtrl;
  final TransformationController _transformationController = TransformationController();

  AchievementCategory _selectedCategory = AchievementCategory.all;
  ProceduralAchievement? _selectedNode;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _mapPulseAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Center map view on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerMapOnOrigin();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _mapPulseAnimCtrl.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _centerMapOnOrigin() {
    final screenSize = MediaQuery.of(context).size;
    final targetX = (screenSize.width / 2) - ProceduralAchievementEngine.mapOrigin.dx;
    final targetY = (screenSize.height / 2) - ProceduralAchievementEngine.mapOrigin.dy;

    _transformationController.value = Matrix4.translationValues(targetX, targetY, 0.0);
  }

  void _centerMapOnNode(Offset nodePos) {
    final screenSize = MediaQuery.of(context).size;
    final targetX = (screenSize.width / 2) - nodePos.dx;
    final targetY = (screenSize.height / 2) - nodePos.dy + 80; // Offset for bottom card

    _transformationController.value = Matrix4.translationValues(targetX, targetY, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);
    final allAchievements = ProceduralAchievementEngine.generateAchievements(state);

    int totalUnlocked = 0;
    int totalClaimable = 0;
    for (final ach in allAchievements) {
      final claimed = state.claimedAchievements.contains(ach.key);
      final canClaim = ach.currentProgress >= ach.target && !claimed;
      if (ach.currentProgress >= ach.target || claimed) {
        totalUnlocked++;
      }
      if (canClaim) {
        totalClaimable++;
      }
    }

    // Auto-select claimable node if none selected
    if (_selectedNode == null && allAchievements.isNotEmpty) {
      final claimable = allAchievements.firstWhere(
        (ach) => ach.currentProgress >= ach.target && !state.claimedAchievements.contains(ach.key),
        orElse: () => allAchievements.first,
      );
      _selectedNode = claimable;
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: MathGraphBackground(
        showGrid: true,
        showWave: true,
        showFormulas: true,
        gridOpacity: 0.18,
        child: Stack(
          children: [
            // ── 1. Interactive Star Constellation Achievement Map Canvas ──────
            InteractiveViewer(
              transformationController: _transformationController,
              boundaryMargin: const EdgeInsets.all(800),
              minScale: 0.45,
              maxScale: 2.2,
              constrained: false,
              child: SizedBox(
                width: ProceduralAchievementEngine.mapSize,
                height: ProceduralAchievementEngine.mapSize,
                child: Stack(
                  children: [
                    // Constellation Connecting Lines Custom Painter
                    AnimatedBuilder(
                      animation: _mapPulseAnimCtrl,
                      builder: (context, _) {
                        return CustomPaint(
                          size: const Size(
                            ProceduralAchievementEngine.mapSize,
                            ProceduralAchievementEngine.mapSize,
                          ),
                          painter: _ConstellationMapPainter(
                            achievements: allAchievements,
                            claimedKeys: state.claimedAchievements,
                            selectedCategory: _selectedCategory,
                            pulseProgress: _mapPulseAnimCtrl.value,
                            origin: ProceduralAchievementEngine.mapOrigin,
                          ),
                        );
                      },
                    ),

                    // Origin Node P₀(0,0) - Apex Hall of Fame
                    Positioned(
                      left: ProceduralAchievementEngine.mapOrigin.dx - 36,
                      top: ProceduralAchievementEngine.mapOrigin.dy - 36,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedNode = null;
                          });
                          _centerMapOnOrigin();
                        },
                        child: _OriginMapNodeWidget(
                          unlockedCount: totalUnlocked,
                          totalCount: allAchievements.length,
                          animCtrl: _mapPulseAnimCtrl,
                        ),
                      ),
                    ),

                    // Achievement Map Nodes
                    ...allAchievements.map((ach) {
                      final isSelected = _selectedNode?.key == ach.key;
                      final isClaimed = state.claimedAchievements.contains(ach.key);
                      final canClaim = ach.currentProgress >= ach.target && !isClaimed;
                      final matchesCategory = _selectedCategory == AchievementCategory.all ||
                          ach.category == _selectedCategory;

                      return Positioned(
                        left: ach.mapPosition.dx - 28,
                        top: ach.mapPosition.dy - 28,
                        child: Opacity(
                          opacity: matchesCategory ? 1.0 : 0.25,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _selectedNode = ach;
                              });
                              _centerMapOnNode(ach.mapPosition);
                            },
                            child: _MapNodeWidget(
                              achievement: ach,
                              isSelected: isSelected,
                              isClaimed: isClaimed,
                              canClaim: canClaim,
                              animCtrl: _mapPulseAnimCtrl,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ── 2. Top Floating Header Bar ────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Back Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 26),
                            onPressed: widget.onBack,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ACHIEVEMENT MAP',
                                style: GoogleFonts.orbitron(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                'Explore the Cybernetic Constellation',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Unlocked Counter Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGold.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.45)),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentGold.withValues(alpha: 0.2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.emoji_events_rounded, size: 14, color: AppTheme.accentGold),
                              const SizedBox(width: 5),
                              Text(
                                '$totalUnlocked Unlocked',
                                style: GoogleFonts.orbitron(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Floating Category Filter Chips
                    _buildCategoryFilterTabs(totalClaimable),
                  ],
                ),
              ),
            ),

            // ── 3. Floating Re-Center Button ─────────────────────────────────
            Positioned(
              right: 16,
              bottom: _selectedNode != null ? 220 : 20,
              child: FloatingActionButton.small(
                heroTag: 'recenter_btn',
                backgroundColor: const Color(0xFF0C1026).withValues(alpha: 0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.primaryGlow.withValues(alpha: 0.5)),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (_selectedNode != null) {
                    _centerMapOnNode(_selectedNode!.mapPosition);
                  } else {
                    _centerMapOnOrigin();
                  }
                },
                child: const Icon(Icons.my_location_rounded, color: AppTheme.primaryGlow, size: 18),
              ),
            ),

            // ── 4. Selected Node Detail Bottom Card (Frosted Glass Panel) ────
            if (_selectedNode != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _buildNodeDetailPanel(state, allAchievements),
              ),

            // Confetti Overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 35,
                gravity: 0.2,
                colors: const [
                  AppTheme.primaryGlow,
                  AppTheme.secondaryGlow,
                  AppTheme.accentGold,
                  AppTheme.accentPink,
                  AppTheme.accentBlue,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Category Filter Tabs Widget ──────────────────────────────────────────
  Widget _buildCategoryFilterTabs(int claimableCount) {
    final categories = [
      {'cat': AchievementCategory.all, 'label': 'ALL MAP'},
      {'cat': AchievementCategory.progress, 'label': 'PROGRESS'},
      {'cat': AchievementCategory.perfection, 'label': 'PERFECTION'},
      {'cat': AchievementCategory.starlight, 'label': 'STARLIGHT'},
      {'cat': AchievementCategory.mastery, 'label': 'MASTERY'},
      {'cat': AchievementCategory.cosmic, 'label': 'COSMIC'},
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
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedCategory = cat;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryGlow
                      : Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryGlow
                        : Colors.white.withValues(alpha: 0.15),
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
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.black : Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Selected Node Bottom Detail Panel ───────────────────────────────────
  Widget _buildNodeDetailPanel(GameState state, List<ProceduralAchievement> allAchievements) {
    final item = _selectedNode!;
    final progress = item.currentProgress.clamp(0, item.target);
    final isClaimed = state.claimedAchievements.contains(item.key);
    final canClaim = progress >= item.target && !isClaimed;
    final pct = (progress / item.target).clamp(0.0, 1.0);
    final tierColor = ProceduralAchievementEngine.getTierColor(item.tier);
    final tierName = ProceduralAchievementEngine.getTierName(item.tier);

    final currentIndex = allAchievements.indexWhere((a) => a.key == item.key);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF090D22).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: canClaim
              ? AppTheme.primaryGlow
              : tierColor.withValues(alpha: 0.55),
          width: canClaim ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: canClaim
                ? AppTheme.primaryGlow.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with Coordinates & Tier & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tierColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: tierColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 11, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          item.mathCoordinateLabel,
                          style: GoogleFonts.orbitron(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: tierColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: tierColor.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: tierColor.withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      tierName,
                      style: GoogleFonts.orbitron(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: tierColor,
                      ),
                    ),
                  ),
                ],
              ),

              // Navigation Controls
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chevron_left, color: Colors.white70, size: 20),
                    onPressed: currentIndex > 0
                        ? () {
                            HapticFeedback.selectionClick();
                            final prev = allAchievements[currentIndex - 1];
                            setState(() {
                              _selectedNode = prev;
                            });
                            _centerMapOnNode(prev.mapPosition);
                          }
                        : null,
                  ),
                  Text(
                    '${currentIndex + 1}/${allAchievements.length}',
                    style: GoogleFonts.orbitron(fontSize: 10, color: AppTheme.textMuted),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
                    onPressed: currentIndex < allAchievements.length - 1
                        ? () {
                            HapticFeedback.selectionClick();
                            final next = allAchievements[currentIndex + 1];
                            setState(() {
                              _selectedNode = next;
                            });
                            _centerMapOnNode(next.mapPosition);
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Main Info Row
          Row(
            children: [
              // Glowing Node Icon Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: tierColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: tierColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(item.icon, color: tierColor, size: 22),
              ),
              const SizedBox(width: 12),

              // Title & Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.orbitron(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.desc,
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress Bar & Percentage Text
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6.5,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isClaimed
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

          // Rewards & Claim Button Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Reward Pills
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

              // Action Button
              if (isClaimed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                          fontSize: 9.5,
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
                    elevation: 8,
                    shadowColor: AppTheme.primaryGlow.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    _confettiController.play();
                    state.claimAchievement(item.key, item.coinReward, item.gemReward);
                    setState(() {});
                  },
                  child: Text(
                    'CLAIM REWARD',
                    style: GoogleFonts.orbitron(
                      fontSize: 10.5,
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
  }
}

// ── Map Node Painter & Custom Connection Line Renderer ────────────────────────
class _ConstellationMapPainter extends CustomPainter {
  final List<ProceduralAchievement> achievements;
  final List<String> claimedKeys;
  final AchievementCategory selectedCategory;
  final double pulseProgress;
  final Offset origin;

  _ConstellationMapPainter({
    required this.achievements,
    required this.claimedKeys,
    required this.selectedCategory,
    required this.pulseProgress,
    required this.origin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Concentric Distance Orbital Rings around Origin P₀(0,0)
    final ringPaint = Paint()
      ..color = AppTheme.secondaryGlow.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double r = 200; r <= 1000; r += 200) {
      canvas.drawCircle(origin, r, ringPaint);
    }

    // Group achievements by category to connect sequential constellation lines
    final catGroups = <AchievementCategory, List<ProceduralAchievement>>{};
    for (final ach in achievements) {
      catGroups.putIfAbsent(ach.category, () => []).add(ach);
    }

    // 2. Draw Constellation Connection Lines from Origin & Sequential Nodes
    for (final entry in catGroups.entries) {
      final category = entry.key;
      final group = entry.value;
      final isCategoryActive = selectedCategory == AchievementCategory.all || selectedCategory == category;
      final baseAlphaMult = isCategoryActive ? 1.0 : 0.25;

      Offset lastPos = origin;
      for (int i = 0; i < group.length; i++) {
        final ach = group[i];
        final isUnlocked = ach.currentProgress >= ach.target || claimedKeys.contains(ach.key);
        final tierColor = ProceduralAchievementEngine.getTierColor(ach.tier);

        final linePaint = Paint()
          ..color = (isUnlocked ? tierColor : AppTheme.primaryGlow)
              .withValues(alpha: (isUnlocked ? 0.45 : 0.15) * baseAlphaMult)
          ..strokeWidth = isUnlocked ? 1.8 : 1.0
          ..style = PaintingStyle.stroke;

        if (isUnlocked) {
          // Glow background line for unlocked paths
          final glowPaint = Paint()
            ..color = tierColor.withValues(alpha: 0.2 * baseAlphaMult)
            ..strokeWidth = 4.0
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawLine(lastPos, ach.mapPosition, glowPaint);
        }

        canvas.drawLine(lastPos, ach.mapPosition, linePaint);

        // Traveling Light Pulse Energy Along Unlocked Constellation Lines
        if (isUnlocked && isCategoryActive) {
          final dist = (ach.mapPosition - lastPos).distance;
          if (dist > 0) {
            final travelT = (pulseProgress + (i * 0.15)) % 1.0;
            final pulsePos = Offset.lerp(lastPos, ach.mapPosition, travelT)!;

            canvas.drawCircle(
              pulsePos,
              3.5,
              Paint()
                ..color = tierColor.withValues(alpha: 0.9)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
            );
            canvas.drawCircle(pulsePos, 1.5, Paint()..color = Colors.white);
          }
        }

        lastPos = ach.mapPosition;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationMapPainter oldDelegate) => true;
}

// ── Origin Hall of Fame Map Node Widget P₀(0,0) ──────────────────────────────
class _OriginMapNodeWidget extends StatelessWidget {
  final int unlockedCount;
  final int totalCount;
  final AnimationController animCtrl;

  const _OriginMapNodeWidget({
    required this.unlockedCount,
    required this.totalCount,
    required this.animCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animCtrl,
      builder: (context, _) {
        final loop = animCtrl.value * 2 * math.pi;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  transform: GradientRotation(loop),
                  colors: const [
                    Color(0xFFFFD700),
                    Color(0xFFFF8C00),
                    Color(0xFF00FF9D),
                    Color(0xFFFFD700),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGold.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(3.5),
                decoration: const BoxDecoration(
                  color: Color(0xFF090D22),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.emoji_events_rounded, size: 34, color: AppTheme.accentGold),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.5)),
              ),
              child: Text(
                'P₀ ORIGIN NODE',
                style: GoogleFonts.orbitron(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentGold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Map Node Widget ─────────────────────────────────────────────────────────
class _MapNodeWidget extends StatelessWidget {
  final ProceduralAchievement achievement;
  final bool isSelected;
  final bool isClaimed;
  final bool canClaim;
  final AnimationController animCtrl;

  const _MapNodeWidget({
    required this.achievement,
    required this.isSelected,
    required this.isClaimed,
    required this.canClaim,
    required this.animCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final tierColor = ProceduralAchievementEngine.getTierColor(achievement.tier);
    final displayColor = canClaim ? AppTheme.accentGold : (isClaimed ? tierColor : tierColor.withValues(alpha: 0.6));

    return AnimatedBuilder(
      animation: animCtrl,
      builder: (context, _) {
        final pulseVal = math.sin((animCtrl.value * 2 * math.pi) + (achievement.target * 0.1)) * 0.5 + 0.5;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Selection Target Lock Reticle
                if (isSelected)
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryGlow, width: 1.8),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGlow.withValues(alpha: 0.4),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                  ),

                // Pulsing Aura for Claimable Node
                if (canClaim)
                  Container(
                    width: 56 + (pulseVal * 10),
                    height: 56 + (pulseVal * 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentGold.withValues(alpha: 0.25 * (1.0 - pulseVal)),
                      border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.6), width: 1.5),
                    ),
                  ),

                // Main Node Orb
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF090D22),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryGlow
                          : (canClaim ? AppTheme.accentGold : tierColor),
                      width: canClaim || isSelected ? 2.0 : 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: displayColor.withValues(alpha: canClaim ? 0.5 : 0.25),
                        blurRadius: canClaim ? 16 : 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      isClaimed
                          ? Icons.check_circle_rounded
                          : (canClaim ? Icons.card_giftcard_rounded : achievement.icon),
                      size: 24,
                      color: displayColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Node Label Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryGlow
                      : displayColor.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                achievement.title,
                style: GoogleFonts.orbitron(
                  fontSize: 8.5,
                  fontWeight: isSelected || canClaim ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryGlow : Colors.white,
                ),
              ),
            ),
          ],
        );
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
