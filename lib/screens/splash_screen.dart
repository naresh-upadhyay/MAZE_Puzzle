import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/math_graph_background.dart';

/// The primary opening / splash screen of MAZE GLOW PATH.
/// Features:
/// - Staggered cinematic entrance sequence
/// - Continuous chromatic neon border rotation and floating 3D hover on hero logo
/// - Expanding periodic radiant shockwave rings
/// - Dynamic laser shimmer gradient sweep across "GLOW PATH" title
/// - Ultra-premium glowing "TAP TO START" button
/// - Top currency indicators (Energy, Coins, Gems) & settings
/// - Glassmorphic bottom navigation deck with interactive micro-animations
/// - Interactive touch ripples & neon spark physics
class SplashScreen extends StatefulWidget {
  final VoidCallback onStart;
  final Function(String route) onNavigate;

  const SplashScreen({
    super.key,
    required this.onStart,
    required this.onNavigate,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Staggered cinematic entrance controller
  late AnimationController _entranceController;
  late Animation<double> _topBarEntrance;
  late Animation<double> _logoEntrance;
  late Animation<double> _titleEntrance;
  late Animation<double> _footerEntrance;

  // Continuous ambient loop controllers
  late AnimationController _loopController;
  late AnimationController _shimmerController;
  late AnimationController _shockwaveController;

  @override
  void initState() {
    super.initState();

    // 1. Entrance timeline
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _topBarEntrance = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );

    _logoEntrance = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.65, curve: Curves.elasticOut),
    );

    _titleEntrance = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOutBack),
    );

    _footerEntrance = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.70, 1.0, curve: Curves.easeOutCubic),
    );

    // 2. Ambient loop (breathing, hover, border rotation)
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    // 3. Shimmer sheen sweep
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // 4. Radiant shockwave pulse
    _shockwaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _loopController.dispose();
    _shimmerController.dispose();
    _shockwaveController.dispose();
    super.dispose();
  }

  void _handleStartGame() {
    widget.onStart();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: MathGraphBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── 1. Top Currency & Status Header ───────────────────────────
              AnimatedBuilder(
                animation: _topBarEntrance,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -30 * (1.0 - _topBarEntrance.value)),
                    child: Opacity(
                      opacity: _topBarEntrance.value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: _buildTopBar(state),
              ),

              // ── 2. Center Hero Showcase (Logo + Shimmer Title + Subtitle) ─
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Hero Emblem with Chromatic Glow & Floating Physics
                          AnimatedBuilder(
                            animation: _logoEntrance,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _logoEntrance.value,
                                child: child,
                              );
                            },
                            child: _buildHeroLogoSection(),
                          ),
                          const SizedBox(height: 22),

                          // Animated Title & Laser Glow Text
                          AnimatedBuilder(
                            animation: _titleEntrance,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1.0 - _titleEntrance.value)),
                                child: Opacity(
                                  opacity: _titleEntrance.value.clamp(0.0, 1.0),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildTitleSection(),
                          ),
                          const SizedBox(height: 32),

                          // Static "TAP TO START" CTA Button
                          _buildTapToStartButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── 3. Glassmorphic Footer Navigation Deck ───────────────────
              AnimatedBuilder(
                animation: _footerEntrance,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1.0 - _footerEntrance.value)),
                    child: Opacity(
                      opacity: _footerEntrance.value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: _buildFooterDeck(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Header Widget ─────────────────────────────────────────────────────
  Widget _buildTopBar(GameState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Currency Pills
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCurrencyBadge(
                icon: Icons.bolt,
                iconColor: AppTheme.accentGold,
                text: '${state.energy}/${state.maxEnergy}',
                subText: 'FULL',
                onAdd: () => state.refillEnergy(),
              ),
              const SizedBox(width: 6),
              _buildCurrencyBadge(
                icon: Icons.monetization_on,
                iconColor: AppTheme.accentGold,
                text: '${state.coins}',
                onAdd: () => state.addCoins(250),
              ),
              const SizedBox(width: 6),
              _buildCurrencyBadge(
                icon: Icons.diamond,
                iconColor: AppTheme.accentBlue,
                text: '${state.gems}',
                onAdd: () => state.addGems(10),
              ),
            ],
          ),

          // Right: Settings Gear Icon
          InkWell(
            onTap: () => widget.onNavigate('/settings'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.16),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.settings, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyBadge({
    required IconData icon,
    required Color iconColor,
    required String text,
    String? subText,
    required VoidCallback onAdd,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.12),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.orbitron(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (subText != null) ...[
            const SizedBox(width: 3),
            Text(
              subText,
              style: GoogleFonts.orbitron(
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGlow,
              ),
            ),
          ],
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppTheme.primaryGlow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 12, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Logo with Chromatic Glow & Hover Physics ─────────────────────────
  Widget _buildHeroLogoSection() {
    return AnimatedBuilder(
      animation: Listenable.merge([_loopController, _shockwaveController]),
      builder: (context, _) {
        final loopVal = _loopController.value;
        final shockVal = _shockwaveController.value;

        // Floating hover displacement (smooth sine wave)
        final hoverY = math.sin(loopVal * 2 * math.pi) * 7.0;
        final rotationAngle = loopVal * 2 * math.pi;

        // Breathing glow parameters
        final glowAlpha = 0.55 + math.sin(loopVal * 2 * math.pi) * 0.35;

        return Transform.translate(
          offset: Offset(0, hoverY),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // 1. Expanding Radiant Shockwave Ring
              Opacity(
                opacity: (1.0 - shockVal) * 0.65,
                child: Container(
                  width: 150 + shockVal * 65,
                  height: 150 + shockVal * 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryGlow.withValues(alpha: (1.0 - shockVal) * 0.8),
                      width: 2.0 * (1.0 - shockVal * 0.7),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryGlow.withValues(alpha: (1.0 - shockVal) * 0.4),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Multi-tier Background Neon Halo Bloom
              Container(
                width: 165,
                height: 165,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryGlow.withValues(alpha: glowAlpha * 0.35),
                      AppTheme.secondaryGlow.withValues(alpha: glowAlpha * 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // 3. Chromatic Rotating Gradient Border Box
              Container(
                width: 148,
                height: 148,
                padding: const EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  gradient: SweepGradient(
                    transform: GradientRotation(rotationAngle),
                    colors: const [
                      AppTheme.primaryGlow,
                      AppTheme.secondaryGlow,
                      AppTheme.accentPink,
                      AppTheme.accentPurple,
                      AppTheme.accentGold,
                      AppTheme.primaryGlow,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGlow.withValues(alpha: glowAlpha * 0.65),
                      blurRadius: 36,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: AppTheme.secondaryGlow.withValues(alpha: 0.35),
                      blurRadius: 20,
                    ),
                    BoxShadow(
                      color: AppTheme.accentPink.withValues(alpha: glowAlpha * 0.3),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF07091B),
                    borderRadius: BorderRadius.circular(33),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(33),
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
    );
  }

  // ── Title & Animated Laser Typography ────────────────────────────────────
  Widget _buildTitleSection() {
    return Column(
      children: [
        // "MAZE" 3D Chrome Header
        Text(
          'MAZE',
          style: GoogleFonts.orbitron(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 8,
            shadows: [
              Shadow(
                color: AppTheme.primaryGlow.withValues(alpha: 0.55),
                blurRadius: 22,
                offset: const Offset(0, 2),
              ),
              const Shadow(
                color: Colors.black,
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),

        // "GLOW PATH" with Animated Laser Beam Sweep
        AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            final shimmerVal = _shimmerController.value;
            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: const [
                    AppTheme.primaryGlow,
                    Colors.white,
                    AppTheme.secondaryGlow,
                    AppTheme.accentPink,
                    AppTheme.primaryGlow,
                  ],
                  stops: [
                    (shimmerVal - 0.3).clamp(0.0, 1.0),
                    (shimmerVal - 0.1).clamp(0.0, 1.0),
                    shimmerVal.clamp(0.0, 1.0),
                    (shimmerVal + 0.15).clamp(0.0, 1.0),
                    (shimmerVal + 0.3).clamp(0.0, 1.0),
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: Text(
                'GLOW PATH',
                style: GoogleFonts.orbitron(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 7,
                  shadows: [
                    Shadow(
                      color: AppTheme.primaryGlow.withValues(alpha: 0.8),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),

        // Subtitle Pill Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: AppTheme.primaryGlow.withValues(alpha: 0.25),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGlow.withValues(alpha: 0.08),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 12, color: AppTheme.primaryGlow),
              const SizedBox(width: 6),
              Text(
                'Swipe  •  Glow  •  Find the Exit',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted.withValues(alpha: 0.95),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Static "TAP TO START" CTA Button ──────────────────────────────────────
  Widget _buildTapToStartButton() {
    return GestureDetector(
      onTap: _handleStartGame,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 290),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF00FF9D),
              Color(0xFF00E5FF),
              Color(0xFF00C8FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TAP TO START',
                style: GoogleFonts.orbitron(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF030712),
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.play_arrow_rounded,
                size: 24,
                color: Color(0xFF030712),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Glassmorphic Footer Navigation Deck ───────────────────────────────────
  Widget _buildFooterDeck() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _FooterDeckButton(
              icon: Icons.emoji_events_rounded,
              iconColor: AppTheme.accentGold,
              label: 'Achievements',
              onTap: () => widget.onNavigate('/achievements'),
            ),
            Container(
              width: 1,
              height: 24,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            _FooterDeckButton(
              icon: Icons.storefront_rounded,
              iconColor: AppTheme.accentPink,
              label: 'Store',
              onTap: () => widget.onNavigate('/level_select'),
            ),
            Container(
              width: 1,
              height: 24,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            _FooterDeckButton(
              icon: Icons.map_rounded,
              iconColor: AppTheme.primaryGlow,
              label: 'World Map',
              onTap: () => widget.onNavigate('/world_map'),
            ),
            Container(
              width: 1,
              height: 24,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            _FooterDeckButton(
              icon: Icons.tune_rounded,
              iconColor: AppTheme.secondaryGlow,
              label: 'Settings',
              onTap: () => widget.onNavigate('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterDeckButton extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _FooterDeckButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  State<_FooterDeckButton> createState() => _FooterDeckButtonState();
}

class _FooterDeckButtonState extends State<_FooterDeckButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      onHighlightChanged: (val) => setState(() => _isHovered = val),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedScale(
        scale: _isHovered ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? widget.iconColor.withValues(alpha: 0.2)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: _isHovered ? widget.iconColor : Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: _isHovered ? Colors.white : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
