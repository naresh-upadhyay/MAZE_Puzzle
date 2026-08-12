import 'package:confetti/confetti.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

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
    this.formattedTime = '00:24',
    this.moves = 15,
    this.coinsEarned = 50,
    this.gemsEarned = 2,
  });

  @override
  State<LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<LevelCompleteOverlay>
    with TickerProviderStateMixin {

  late ConfettiController _confetti;

  // ── Element entrance animations ───────────────────────────────────────────
  late AnimationController _headerCtrl;   // title slide in
  late AnimationController _starsCtrl;    // stars stagger
  late AnimationController _statsCtrl;    // stats fade
  late AnimationController _btnsCtrl;     // buttons slide up
  late AnimationController _glowCtrl;     // background glow pulse

  // Star-specific controllers (staggered)
  late List<AnimationController> _starCtrls;
  late List<Animation<double>>   _starScales;

  // ── Coin counter animation ────────────────────────────────────────────────
  int _displayedCoins = 0;
  int _displayedGems  = 0;

  @override
  void initState() {
    super.initState();

    _confetti = ConfettiController(duration: const Duration(seconds: 3));

    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _starsCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _statsCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _btnsCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _glowCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);

    // Per-star staggered bounce
    _starCtrls  = List.generate(3, (i) => AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400)));
    _starScales = _starCtrls.map((c) => Tween<double>(begin: 0, end: 1.0)
        .animate(CurvedAnimation(parent: c, curve: Curves.elasticOut))).toList();

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _headerCtrl.forward();
    _confetti.play();

    await Future.delayed(const Duration(milliseconds: 350));
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 140));
      _starCtrls[i].forward();
    }

    await Future.delayed(const Duration(milliseconds: 300));
    _statsCtrl.forward();
    _countUpRewards();

    await Future.delayed(const Duration(milliseconds: 300));
    _btnsCtrl.forward();
  }

  void _countUpRewards() {
    final steps = 20;
    final delay = 30;
    for (int i = 1; i <= steps; i++) {
      Future.delayed(Duration(milliseconds: i * delay), () {
        if (mounted) {
          setState(() {
            _displayedCoins = ((widget.coinsEarned * i) / steps).round();
            _displayedGems  = ((widget.gemsEarned  * i) / steps).round();
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
    _glowCtrl.dispose();
    for (final c in _starCtrls) { c.dispose(); }
    super.dispose();
  }

  String get _ratingLabel {
    switch (widget.starsEarned) {
      case 3:  return 'PERFECT RUN!';
      case 2:  return 'GREAT JOB!';
      default: return 'MAZE CLEARED!';
    }
  }

  String get _ratingReason {
    switch (widget.starsEarned) {
      case 3:  return 'No mistakes · Fast time';
      case 2:  return 'Some mistakes — keep practising';
      default: return 'Slow or many mistakes';
    }
  }

  Color get _ratingColor {
    switch (widget.starsEarned) {
      case 3:  return AppTheme.primaryGlow;
      case 2:  return AppTheme.accentGold;
      default: return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Animated background ─────────────────────────────────────────
          _AnimatedBackground(glowCtrl: _glowCtrl),

          // ── Confetti (top center) ───────────────────────────────────────
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30,
              gravity: 0.3,
              colors: const [
                AppTheme.primaryGlow,
                AppTheme.secondaryGlow,
                AppTheme.accentGold,
                AppTheme.accentPink,
                AppTheme.accentPurple,
              ],
            ),
          ),

          // ── Main content (fills screen responsively) ─────────────────────
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

  Widget _buildHeader() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.6),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: _headerCtrl,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00B36B), Color(0xFF00FF9D)],
                ),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGlow.withValues(alpha: 0.45),
                    blurRadius: 24,
                    spreadRadius: 2,
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
          ],
        ),
      ),
    );
  }

  Widget _buildStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final earned = i < widget.starsEarned;
        return ScaleTransition(
          scale: _starScales[i],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: earned
                    ? [const Color(0xFFFFE066), const Color(0xFFFFC107), const Color(0xFFFF8C00)]
                    : [Colors.white12, Colors.white12],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: Icon(
                earned ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 72,
                color: Colors.white,
              ),
            ),
          ),
        );
      }),
    );
  }

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
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _ratingReason,
            style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return FadeTransition(
      opacity: _statsCtrl,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(CurvedAnimation(parent: _statsCtrl, curve: Curves.easeOut)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0E122B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
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
              Container(width: 1, height: 40, color: Colors.white12),
              _StatItem(
                icon: Icons.directions_walk,
                label: 'MOVES',
                value: '${widget.moves}',
                color: AppTheme.accentPurple,
              ),
              Container(width: 1, height: 40, color: Colors.white12),
              _StatItem(
                icon: Icons.emoji_events_outlined,
                label: 'RANK',
                value: widget.starsEarned == 3 ? 'S' : widget.starsEarned == 2 ? 'A' : 'B',
                color: AppTheme.accentGold,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewards() {
    return FadeTransition(
      opacity: _statsCtrl,
      child: Column(
        children: [
          Text(
            'REWARDS',
            style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textMuted, letterSpacing: 2),
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
                color: AppTheme.accentBlue,
                text: '+$_displayedGems',
                label: 'GEMS',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero)
          .animate(CurvedAnimation(parent: _btnsCtrl, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: _btnsCtrl,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                ),
                onPressed: widget.onHome,
                icon: const Icon(Icons.home_rounded, color: Colors.white),
                label: Text('HOME',
                    style: GoogleFonts.orbitron(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryGlow,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                  elevation: 0,
                ).copyWith(
                  overlayColor: WidgetStateProperty.all(Colors.black12),
                ),
                onPressed: widget.onNext,
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.black),
                label: Text('NEXT LEVEL',
                    style: GoogleFonts.orbitron(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated background with floating glow orbs ───────────────────────────────
class _AnimatedBackground extends StatelessWidget {
  final AnimationController glowCtrl;
  const _AnimatedBackground({required this.glowCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowCtrl,
      builder: (context, _) {
        final t = glowCtrl.value;
        return CustomPaint(
          painter: _BgPainter(t),
        );
      },
    );
  }
}

class _BgPainter extends CustomPainter {
  final double t;
  _BgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Dark gradient base
    final bgGrad = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF060713), Color(0xFF0D1040)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgGrad);

    // Floating glow orbs
    _drawOrb(canvas, size, Offset(size.width * 0.2, size.height * 0.2),
        AppTheme.primaryGlow, 120, 0.08 + t * 0.06);
    _drawOrb(canvas, size, Offset(size.width * 0.8, size.height * 0.35),
        AppTheme.accentPink, 100, 0.06 + (1 - t) * 0.05);
    _drawOrb(canvas, size, Offset(size.width * 0.5, size.height * 0.85),
        AppTheme.accentPurple, 140, 0.07 + t * 0.04);
  }

  void _drawOrb(Canvas canvas, Size size, Offset center,
      Color color, double radius, double alpha) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}

// ── Stat item ─────────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;

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
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.outfit(fontSize: 9, color: AppTheme.textMuted, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// ── Reward pill ───────────────────────────────────────────────────────────────
class _RewardPill extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   text;
  final String   label;

  const _RewardPill({
    required this.icon,
    required this.color,
    required this.text,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 12),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text,
                  style: GoogleFonts.orbitron(
                      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(label,
                  style: GoogleFonts.outfit(fontSize: 9, color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
