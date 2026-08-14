import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_tab_bar.dart';
import '../widgets/world_map_renderer.dart';

class WorldMapScreen extends StatefulWidget {
  final VoidCallback onBack;
  final Function(int level) onSelectLevel;
  final Function(int tabIndex) onTabChanged;

  const WorldMapScreen({
    super.key,
    required this.onBack,
    required this.onSelectLevel,
    required this.onTabChanged,
  });

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pulseCtrl;
  late AnimationController _orbitCtrl;

  @override
  void initState() {
    super.initState();
    // Breathing pulse for glowing halos
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Continuous 3D atomic orbital rotational revolution
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLevel();
    });
  }

  void _scrollToCurrentLevel() {
    final state = Provider.of<GameState>(context, listen: false);
    final currLevel = state.currentLevel;
    final totalLevels = (currLevel + 10).clamp(25, 100);
    const nodeSpacing = 135.0;
    const bottomPadding = 105.0;
    const portalSpacing = 120.0;
    const topPadding = 90.0;
    final totalHeight = (totalLevels - 1) * nodeSpacing + portalSpacing + topPadding + bottomPadding;

    final targetIndex = (currLevel - 1).clamp(0, totalLevels - 1);
    final targetY = totalHeight - bottomPadding - (targetIndex * nodeSpacing);

    if (_scrollController.hasClients) {
      final viewportH = _scrollController.position.viewportDimension;
      final targetOffset = targetY - (viewportH / 2);
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseCtrl.dispose();
    _orbitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);
    final currLevel = state.currentLevel;
    final totalLevels = (currLevel + 10).clamp(25, 100);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Top Cyber Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
                    onPressed: widget.onBack,
                  ),
                  Text(
                    'WORLD MAP',
                    style: GoogleFonts.orbitron(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.accentBlue.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.diamond_rounded,
                          size: 14,
                          color: AppTheme.accentBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${state.gems}',
                          style: GoogleFonts.orbitron(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Multivariable Math Vector HUD Sub-Bar
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3.5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primaryGlow.withValues(alpha: 0.25),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.functions_rounded, size: 12, color: AppTheme.primaryGlow),
                  const SizedBox(width: 6),
                  Text(
                    '∇f(x,y,z,t)  •  ∂z/∂x  •  ∬ f(x,y) dA',
                    style: GoogleFonts.orbitron(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGlow.withValues(alpha: 0.9),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),

            // ── 2. World Map Viewport with Field Depth Border ───────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF02050E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 28,
                    ),
                    BoxShadow(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.10),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_pulseCtrl, _orbitCtrl]),
                    builder: (context, _) {
                      return WorldMapContentView(
                        totalLevels: totalLevels,
                        currentLevel: currLevel,
                        state: state,
                        pulseValue: _pulseCtrl.value,
                        orbitProgress: _orbitCtrl.value,
                        onSelectLevel: widget.onSelectLevel,
                        scrollController: _scrollController,
                      );
                    },
                  ),
                ),
              ),
            ),

            // ── 3. Bottom Navigation Bar ─────────────────────────────────────
            CustomBottomTabBar(
              selectedIndex: 0,
              onTabSelected: widget.onTabChanged,
            ),
          ],
        ),
      ),
    );
  }
}
