import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';

class LevelSelectScreen extends StatefulWidget {
  final VoidCallback onBack;
  final Function(int level, String mode) onSelectLevel;

  const LevelSelectScreen({
    super.key,
    required this.onBack,
    required this.onSelectLevel,
  });

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLevel();
    });
  }

  void _scrollToCurrentLevel() {
    final state = Provider.of<GameState>(context, listen: false);
    final targetIndex = (state.currentLevel - 1).clamp(0, 100);
    final rowIndex = (targetIndex / 4).floor();
    final targetOffset = rowIndex * 92.0;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);
    final totalLevels = (state.currentLevel + 24).clamp(60, 120);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header Row matching Reference Screenshot 2
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                    onPressed: widget.onBack,
                  ),
                  Text(
                    'SELECT LEVEL',
                    style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.diamond, size: 16, color: AppTheme.accentBlue),
                      const SizedBox(width: 4),
                      Text(
                        '${state.gems}',
                        style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accentBlue),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // TOP CARD: Level Stage Preview Container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: AppTheme.glassCardDecoration(glowColor: AppTheme.primaryGlow),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CURRENT LEVEL: ${state.currentLevel}',
                          style: GoogleFonts.orbitron(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '2 Puzzles: Simple ➔ Complicated Multi-Path',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppTheme.primaryGlow,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0x2000FF9D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryGlow.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(Icons.extension, color: AppTheme.primaryGlow, size: 28),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // LEVEL GRID (Full Scrollable Grid starting from Level 1 to 60+)
              Expanded(
                child: GridView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: totalLevels,
                  itemBuilder: (context, index) {
                    final lvlNum = index + 1;
                    final isUnlocked = lvlNum <= state.currentLevel + 2;
                    final isActive = lvlNum == state.currentLevel;
                    final lp = state.levelProgress[state.selectedMode]?[lvlNum];
                    final stars = lp?.stars ?? (lvlNum < state.currentLevel ? 3 : 0);

                    return GestureDetector(
                      onTap: () {
                        if (isUnlocked) {
                          widget.onSelectLevel(lvlNum, state.selectedMode);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.accentPurple
                              : isUnlocked
                                  ? AppTheme.bgSurface
                                  : Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive
                                ? AppTheme.accentPink
                                : isUnlocked
                                    ? AppTheme.primaryGlow.withValues(alpha: 0.5)
                                    : Colors.white12,
                            width: isActive ? 2 : 1,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppTheme.accentPurple.withValues(alpha: 0.6),
                                    blurRadius: 16,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$lvlNum',
                              style: GoogleFonts.orbitron(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isUnlocked ? Colors.white : AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (isUnlocked && !isActive)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  3,
                                  (i) => Icon(
                                    Icons.star,
                                    size: 10,
                                    color: i < stars ? AppTheme.accentGold : Colors.white24,
                                  ),
                                ),
                              )
                            else if (!isUnlocked)
                              const Icon(Icons.lock, size: 14, color: AppTheme.textMuted),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // BOTTOM CARD: Wide INFINITE LEVELS Button Card
              GestureDetector(
                onTap: () => widget.onSelectLevel(1, 'infinite'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.all_inclusive, size: 24, color: AppTheme.accentBlue),
                      const SizedBox(width: 10),
                      Text(
                        'INFINITE LEVELS',
                        style: GoogleFonts.orbitron(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
