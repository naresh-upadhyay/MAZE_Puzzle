import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/math_graph_background.dart';

/// State-of-the-art Cosmic Galaxy Preloader Screen.
/// Displays before the main splash screen with cybernetic progress bar & quantum status.
class PreloaderScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const PreloaderScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<PreloaderScreen> createState() => _PreloaderScreenState();
}

class _PreloaderScreenState extends State<PreloaderScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  double _progress = 0.0;
  Timer? _timer;
  int _statusIndex = 0;

  final List<String> _statusMessages = [
    'INITIALIZING QUANTUM MATRIX...',
    'CALCULATING PARALLEL PATHWAYS...',
    'CARVING LABYRINTH ARTERIES...',
    'CHARGING NEON GLOW NODES...',
    'SYNCHRONIZING SYSTEM LOGIC...',
    'MATRIX READY',
  ];

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // Smooth cybernetic preloader progression
    _timer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (!mounted) return;
      setState(() {
        if (_progress < 1.0) {
          // Dynamic acceleration curve
          final increment = 0.008 + (_progress * 0.012);
          _progress = math.min(1.0, _progress + increment);

          // Update status message
          _statusIndex = math.min(
            _statusMessages.length - 1,
            (_progress * (_statusMessages.length - 1)).floor(),
          );
        } else {
          _timer?.cancel();
          // Short pause at 100% then transition to Splash
          Future.delayed(const Duration(milliseconds: 350), () {
            if (mounted) widget.onComplete();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (_progress * 100).toInt();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: MathGraphBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // ── Master Emblem Showcase ───────────────────────────────────
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, child) {
                      final scale = 1.0 + math.sin(_pulseCtrl.value * math.pi) * 0.03;
                      final glow = 0.4 + math.sin(_pulseCtrl.value * math.pi) * 0.3;

                      return Transform.scale(
                        scale: scale,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Neon Halo Bloom
                            Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppTheme.primaryGlow.withValues(alpha: glow * 0.5),
                                    AppTheme.secondaryGlow.withValues(alpha: glow * 0.2),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),

                            // Chromatic Border Container
                            Container(
                              width: 135,
                              height: 135,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(34),
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryGlow,
                                    AppTheme.secondaryGlow,
                                    AppTheme.accentPink,
                                    AppTheme.accentGold,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryGlow.withValues(alpha: glow * 0.6),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF07091B),
                                  borderRadius: BorderRadius.circular(31),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(31),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 36),

                  // ── Title & Status Header ────────────────────────────────────
                  Text(
                    'MAZE GLOW PATH',
                    style: GoogleFonts.orbitron(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(
                          color: AppTheme.primaryGlow.withValues(alpha: 0.8),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _statusMessages[_statusIndex],
                      key: ValueKey<int>(_statusIndex),
                      style: GoogleFonts.orbitron(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryGlow.withValues(alpha: 0.9),
                        letterSpacing: 1.8,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ── Cybernetic Progress Bar Container ─────────────────────────
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppTheme.primaryGlow.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGlow.withValues(alpha: 0.15),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Progress Fill Track
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final fillWidth = constraints.maxWidth * _progress;
                            return Container(
                              height: 18,
                              width: fillWidth,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00FF9D),
                                    Color(0xFF00E5FF),
                                    Color(0xFF00C8FF),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryGlow.withValues(alpha: 0.7),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Percentage Text Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$percentage%',
                        style: GoogleFonts.orbitron(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
