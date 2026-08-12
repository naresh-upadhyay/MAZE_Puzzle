import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';

class LevelSelectScreen extends StatelessWidget {
  final VoidCallback onBack;
  final Function(int level, String mode) onSelectLevel;

  const LevelSelectScreen({
    super.key,
    required this.onBack,
    required this.onSelectLevel,
  });

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);
    final isSimple = state.selectedMode == 'simple';

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
                    onPressed: onBack,
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

              // TOP CARD: Level Mode Preview Container matching Reference Screenshot 2
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.glassCardDecoration(glowColor: AppTheme.primaryGlow),
                child: Column(
                  children: [
                    Text(
                      'LEVEL ${state.currentLevel}',
                      style: GoogleFonts.orbitron(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // SIMPLE MODE CARD
                        Expanded(
                          child: GestureDetector(
                            onTap: () => state.setMode('simple'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSimple ? const Color(0x2000FF9D) : Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSimple ? AppTheme.primaryGlow : Colors.white.withValues(alpha: 0.1),
                                  width: isSimple ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'SIMPLE',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGlow,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Green Neon Maze Thumbnail Icon
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF060713),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppTheme.primaryGlow.withValues(alpha: 0.5)),
                                    ),
                                    child: const Icon(Icons.grid_view, size: 36, color: AppTheme.primaryGlow),
                                  ),
                                  const SizedBox(height: 8),
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.star, size: 14, color: AppTheme.accentGold),
                                      Icon(Icons.star, size: 14, color: AppTheme.accentGold),
                                      Icon(Icons.star, size: 14, color: AppTheme.accentGold),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'BEST TIME',
                                    style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textMuted),
                                  ),
                                  Text(
                                    '00:28.34',
                                    style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // COMPLICATED MODE CARD
                        Expanded(
                          child: GestureDetector(
                            onTap: () => state.setMode('complicated'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: !isSimple ? const Color(0x20FF2A6D) : Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: !isSimple ? AppTheme.accentPink : Colors.white.withValues(alpha: 0.1),
                                  width: !isSimple ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'COMPLICATED',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.accentPink,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Red/Orange Neon Maze Thumbnail Icon
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF060713),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppTheme.accentPink.withValues(alpha: 0.5)),
                                    ),
                                    child: const Icon(Icons.apps, size: 36, color: AppTheme.accentPink),
                                  ),
                                  const SizedBox(height: 8),
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.star, size: 14, color: AppTheme.accentGold),
                                      Icon(Icons.star, size: 14, color: AppTheme.accentGold),
                                      Icon(Icons.star_border, size: 14, color: Colors.white24),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'BEST TIME',
                                    style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textMuted),
                                  ),
                                  Text(
                                    '01:24.58',
                                    style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // LEVEL GRID (2 Rows of Level Selection Buttons)
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: 8, // Levels 24 to 31 matching reference
                  itemBuilder: (context, index) {
                    final lvlNum = 24 + index;
                    final isUnlocked = lvlNum <= state.currentLevel + 2;
                    final isActive = lvlNum == state.currentLevel;

                    return GestureDetector(
                      onTap: () {
                        if (isUnlocked) {
                          onSelectLevel(lvlNum, state.selectedMode);
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
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.star, size: 10, color: AppTheme.accentGold),
                                  Icon(Icons.star, size: 10, color: AppTheme.accentGold),
                                  Icon(Icons.star, size: 10, color: AppTheme.accentGold),
                                ],
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

              // BOTTOM CARD: Wide INFINITE LEVELS Button Card
              GestureDetector(
                onTap: () => onSelectLevel(1, 'infinite'),
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
