import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/world_map_renderer.dart';

class LevelCompleteOverlay extends StatefulWidget {
  final VoidCallback onHome;
  final VoidCallback onNext;
  final int starsEarned;
  final String formattedTime;
  final int moves;
  final int coinsEarned;
  final int gemsEarned;

  const LevelCompleteOverlay({
    super.key,
    required this.onHome,
    required this.onNext,
    this.starsEarned = 3,
    this.formattedTime = '00:38',
    this.moves = 34,
    this.coinsEarned = 90,
    this.gemsEarned = 4,
  });

  @override
  State<LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<LevelCompleteOverlay>
    with TickerProviderStateMixin {
  late ConfettiController _confetti;

  // ── Entrance animation controllers ─────────────────────────────────────────
  late AnimationController _headerCtrl;
  late AnimationController _starsCtrl;
  late AnimationController _statsCtrl;
  late AnimationController _btnsCtrl;

  // ── Background World Map animation controllers ─────────────────────────────
  late AnimationController _orbitCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _panToNextLevelCtrl;

  // Star staggered animations
  late List<AnimationController> _starCtrls;
  late List<Animation<double>> _starScales;

  // Reward count-up counters
  int _displayedCoins = 0;
  int _displayedGems = 0;

  @override
  void initState() {
    super.initState();

    _confetti = ConfettiController(duration: const Duration(seconds: 3));

    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _starsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _statsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _btnsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Background World Map continuous loops
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _panToNextLevelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    // Per-star elastic bounce
    _starCtrls = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _starScales = _starCtrls
        .map(
          (c) => Tween<double>(begin: 0, end: 1.0).animate(
            CurvedAnimation(parent: c, curve: Curves.elasticOut),
          ),
        )
        .toList();

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _headerCtrl.forward();
    _confetti.play();

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 140));
      if (!mounted) return;
      _starCtrls[i].forward();
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _statsCtrl.forward();
    _countUpRewards();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _btnsCtrl.forward();
  }

  void _countUpRewards() {
    const steps = 20;
    const delay = 30;
    for (int i = 1; i <= steps; i++) {
      Future.delayed(Duration(milliseconds: i * delay), () {
        if (mounted) {
          setState(() {
            _displayedCoins = ((widget.coinsEarned * i) / steps).round();
            _displayedGems = ((widget.gemsEarned * i) / steps).round();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    _headerCtrl.dispose();
    _starsCtrl.dispose();
    _statsCtrl.dispose();
    _btnsCtrl.dispose();
    _orbitCtrl.dispose();
    _pulseCtrl.dispose();
    _panToNextLevelCtrl.dispose();
    for (final c in _starCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  String get _ratingLabel {
    switch (widget.starsEarned) {
      case 3:
        return 'PERFECT RUN!';
      case 2:
        return 'GREAT JOB!';
      default:
        return 'MAZE CLEARED!';
    }
  }

  String get _ratingReason {
    switch (widget.starsEarned) {
      case 3:
        return 'No mistakes • Fast time';
      case 2:
        return 'Some mistakes — keep practising';
      default:
        return 'Slow or many mistakes';
    }
  }

  Color get _ratingColor {
    switch (widget.starsEarned) {
      case 3:
        return AppTheme.primaryGlow;
      case 2:
        return AppTheme.accentGold;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);
    final currLevel = state.currentLevel;
    final totalLevels = (currLevel + 6).clamp(15, 60);
    final nextLevel = (currLevel + 1).clamp(1, totalLevels);

    return Scaffold(
      backgroundColor: const Color(0xFF030612),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Background World Map (85% Opacity with Centered Next Level) ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_orbitCtrl, _pulseCtrl, _panToNextLevelCtrl]),
              builder: (context, _) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final screenW = constraints.maxWidth;
                    final screenH = constraints.maxHeight;
                    // Provide 3.5x screen width so canvas never clips on left or right
                    final mapW = screenW * 3.5;

                    const nodeSpacing = 135.0;
                    const bottomPadding = 105.0;
                    const portalSpacing = 120.0;
                    const topPadding = 90.0;
                    final totalMapHeight = (totalLevels - 1) * nodeSpacing + portalSpacing + topPadding + bottomPadding;

                    // Calculate precise node offsets with wave amplitude scaled to screenW
                    final nodeOffsets = computeWorldMapNodeOffsets(
                      totalLevels: totalLevels,
                      width: mapW,
                      totalHeight: totalMapHeight,
                      nodeSpacing: nodeSpacing,
                      waveWidth: screenW,
                      bottomPadding: bottomPadding,
                    );

                    final currIndex = (currLevel - 1).clamp(0, totalLevels - 1);
                    final nextIndex = (nextLevel - 1).clamp(0, totalLevels - 1);

                    final fromPos = nodeOffsets[currIndex];
                    final toPos = nodeOffsets[nextIndex];

                    // Smooth easeInOut pan from cleared to next level
                    final t = CurvedAnimation(
                      parent: _panToNextLevelCtrl,
                      curve: Curves.easeInOutCubic,
                    ).value;

                    final camX = fromPos.dx + (toPos.dx - fromPos.dx) * t;
                    final camY = fromPos.dy + (toPos.dy - fromPos.dy) * t;

                    // Exact optical screen centering formula
                    final leftPos = (screenW / 2) - camX;
                    final topPos = (screenH * 0.46) - camY;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: leftPos,
                          top: topPos,
                          width: mapW,
                          height: totalMapHeight,
                          child: Opacity(
                            opacity: 0.85,
                            child: WorldMapContentView(
                              totalLevels: totalLevels,
                              currentLevel: nextLevel, // Active node centered in viewport
                              state: state,
                              pulseValue: _pulseCtrl.value,
                              orbitProgress: _orbitCtrl.value,
                              waveWidth: screenW,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ── 2. Subtle Dark Vignette (Preserves 85% Crisp Visibility) ────────
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.35,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.15),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 3. Victory Aura Glow Beacon Behind Cards ──────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, _) {
                  return Center(
                    child: Container(
                      width: 340,
                      height: 340,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.primaryGlow.withValues(
                              alpha: 0.16 + _pulseCtrl.value * 0.10,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── 4. Confetti Particles Burst ────────────────────────────────────
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 35,
              gravity: 0.25,
              colors: const [
                AppTheme.primaryGlow,
                AppTheme.secondaryGlow,
                AppTheme.accentGold,
                AppTheme.accentPink,
                AppTheme.accentPurple,
              ],
            ),
          ),

          // ── 5. Foreground Level Complete Glassmorphic Content ─────────────
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const SizedBox(height: 8),
                            _buildHeader(),
                            const SizedBox(height: 12),
                            _buildStars(),
                            const SizedBox(height: 8),
                            _buildRatingText(),
                            const SizedBox(height: 16),
                            _buildStatsCard(),
                            const SizedBox(height: 16),
                            _buildRewards(),
                            const SizedBox(height: 20),
                            _buildButtons(),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── LEVEL COMPLETE! Header Pill ────────────────────────────────────────────
  Widget _buildHeader() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.6),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: _headerCtrl,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00FF9D), Color(0xFF00B36B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGlow.withValues(alpha: 0.65),
                blurRadius: 28,
                spreadRadius: 3,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            'LEVEL COMPLETE!',
            style: GoogleFonts.orbitron(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  // ── Three 3D Stars ─────────────────────────────────────────────────────────
  Widget _buildStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final earned = i < widget.starsEarned;
        return ScaleTransition(
          scale: _starScales[i],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: earned
                    ? [
                        const Color(0xFFFFFAAA),
                        const Color(0xFFFFD000),
                        const Color(0xFFFF8C00),
                      ]
                    : [Colors.white24, Colors.white10],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: Icon(
                earned ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 76,
                color: Colors.white,
                shadows: earned
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFFB800).withValues(alpha: 0.8),
                          blurRadius: 24,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Rating Title and Description ──────────────────────────────────────────
  Widget _buildRatingText() {
    return FadeTransition(
      opacity: _starsCtrl,
      child: Column(
        children: [
          Text(
            _ratingLabel,
            style: GoogleFonts.orbitron(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _ratingColor,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: _ratingColor.withValues(alpha: 0.5),
                  blurRadius: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _ratingReason,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Glassmorphic Card (TIME, MOVES, RANK) ────────────────────────────
  Widget _buildStatsCard() {
    return FadeTransition(
      opacity: _statsCtrl,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(CurvedAnimation(parent: _statsCtrl, curve: Curves.easeOutCubic)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0C132E).withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.28),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 20,
              ),
              BoxShadow(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.10),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                icon: Icons.timer_outlined,
                label: 'TIME',
                value: widget.formattedTime,
                color: AppTheme.secondaryGlow,
              ),
              Container(width: 1, height: 44, color: Colors.white12),
              _StatItem(
                icon: Icons.directions_walk_rounded,
                label: 'MOVES',
                value: '${widget.moves}',
                color: const Color(0xFFD946EF), // Radiant Purple/Pink
              ),
              Container(width: 1, height: 44, color: Colors.white12),
              _StatItem(
                icon: Icons.emoji_events_outlined,
                label: 'RANK',
                value: widget.starsEarned == 3
                    ? 'S'
                    : widget.starsEarned == 2
                        ? 'A'
                        : 'B',
                color: AppTheme.accentGold,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Rewards Pills (+COINS, +GEMS) ──────────────────────────────────────────
  Widget _buildRewards() {
    return FadeTransition(
      opacity: _statsCtrl,
      child: Column(
        children: [
          Text(
            'REWARDS',
            style: GoogleFonts.orbitron(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RewardPill(
                icon: Icons.monetization_on_rounded,
                color: AppTheme.accentGold,
                text: '+$_displayedCoins',
                label: 'COINS',
              ),
              const SizedBox(width: 16),
              _RewardPill(
                icon: Icons.diamond_rounded,
                color: const Color(0xFF00D2FF),
                text: '+$_displayedGems',
                label: 'GEMS',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Action Buttons (HOME & NEXT LEVEL) ─────────────────────────────────────
  Widget _buildButtons() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero)
          .animate(CurvedAnimation(parent: _btnsCtrl, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: _btnsCtrl,
        child: Row(
          children: [
            // Home Outlined Button
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF0A0F26).withValues(alpha: 0.70),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.28),
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                onPressed: widget.onHome,
                icon: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
                label: Text(
                  'HOME',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Next Level Glow Button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryGlow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ).copyWith(
                  overlayColor: WidgetStateProperty.all(Colors.black12),
                ),
                onPressed: widget.onNext,
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 20),
                label: Text(
                  'NEXT LEVEL',
                  style: GoogleFonts.orbitron(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Item Widget ──────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 9.5,
            color: AppTheme.textMuted,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.orbitron(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ── Reward Pill Widget ────────────────────────────────────────────────────────
class _RewardPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String label;

  const _RewardPill({
    required this.icon,
    required this.color,
    required this.text,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withValues(alpha: 0.40), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.20),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
