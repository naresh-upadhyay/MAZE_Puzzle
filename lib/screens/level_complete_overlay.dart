import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class LevelCompleteOverlay extends StatefulWidget {
  final VoidCallback onHome;
  final VoidCallback onNext;
  final int starsEarned;
  final String formattedTime;
  final int coinsEarned;
  final int gemsEarned;

  const LevelCompleteOverlay({
    super.key,
    required this.onHome,
    required this.onNext,
    this.starsEarned = 3,
    this.formattedTime = '00:24.18',
    this.coinsEarned = 50,
    this.gemsEarned = 2,
  });

  @override
  State<LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<LevelCompleteOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti particle burst
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppTheme.primaryGlow,
                AppTheme.secondaryGlow,
                AppTheme.accentGold,
                AppTheme.accentPink,
                AppTheme.accentPurple,
              ],
            ),
          ),

          // Victory Card Box
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 340),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10163A), Color(0xFF080A1C)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primaryGlow, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGlow.withValues(alpha: 0.35),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // LEVEL COMPLETE Ribbon Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00B36B), Color(0xFF00FF9D)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'LEVEL COMPLETE!',
                      style: GoogleFonts.orbitron(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Stars earned row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.star,
                        color: index < widget.starsEarned ? AppTheme.accentGold : Colors.white24,
                        size: 44,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  widget.starsEarned == 3
                      ? 'PERFECT RUN!'
                      : (widget.starsEarned == 2 ? 'GREAT JOB!' : 'MAZE CLEARED!'),
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGlow,
                  ),
                ),
                Text(
                  widget.starsEarned == 3 ? 'NO MISTAKES' : 'WELL DONE',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),

                // Stopwatch record
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        widget.formattedTime,
                        style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'NEW BEST!',
                          style: GoogleFonts.orbitron(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Rewards pill
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'REWARDS',
                        style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textMuted, letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _RewardPill(
                            icon: Icons.monetization_on,
                            color: AppTheme.accentGold,
                            text: '+${widget.coinsEarned}',
                          ),
                          const SizedBox(width: 16),
                          _RewardPill(
                            icon: Icons.diamond,
                            color: AppTheme.accentBlue,
                            text: '+${widget.gemsEarned}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Actions (HOME / NEXT)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        ),
                        onPressed: widget.onHome,
                        icon: const Icon(Icons.home, color: Colors.white),
                        label: Text('HOME', style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppTheme.primaryGlow,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        ),
                        onPressed: widget.onNext,
                        icon: const Icon(Icons.play_arrow, color: Colors.black),
                        label: Text('NEXT', style: GoogleFonts.orbitron(color: Colors.black, fontWeight: FontWeight.w900)),
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

class _RewardPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _RewardPill({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
