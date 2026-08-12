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
              // Header
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
                      const Icon(Icons.diamond, size: 14, color: AppTheme.accentBlue),
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

              // Mode Tabs
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => state.setMode('simple'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSimple ? AppTheme.primaryGlow : Colors.transparent,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Center(
                            child: Text(
                              'SIMPLE',
                              style: GoogleFonts.orbitron(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSimple ? Colors.black : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => state.setMode('complicated'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isSimple ? AppTheme.primaryGlow : Colors.transparent,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Center(
                            child: Text(
                              'COMPLICATED',
                              style: GoogleFonts.orbitron(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: !isSimple ? Colors.black : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Preview Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: AppTheme.glassCardDecoration(),
                child: Column(
                  children: [
                    Text(
                      'LEVEL 27 - ${state.selectedMode.toUpperCase()}',
                      style: GoogleFonts.orbitron(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGlow,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (index) => const Icon(Icons.star, color: AppTheme.accentGold, size: 24),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'BEST TIME: 00:28.34',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Level Grid (1 to 32)
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 32,
                  itemBuilder: (context, index) {
                    final lvl = index + 1;
                    final modeProgress = state.levelProgress[state.selectedMode] ?? {};
                    final lvlData = modeProgress[lvl];

                    // Unlocked if Level 1, or previous level is completed, or already completed
                    final isUnlocked = lvl == 1 || (modeProgress[lvl - 1]?.completed ?? false) || (lvlData?.completed ?? false) || lvl <= 28;
                    final isActive = lvl == state.currentLevel;
                    final starsEarned = lvlData?.stars ?? (isUnlocked ? 3 : 0);

                    return GestureDetector(
                      onTap: isUnlocked ? () => onSelectLevel(lvl, state.selectedMode) : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primaryGlow.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: isUnlocked ? 0.08 : 0.03),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive
                                ? AppTheme.primaryGlow
                                : Colors.white.withValues(alpha: isUnlocked ? 0.15 : 0.05),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isUnlocked) ...[
                              Text(
                                '$lvl',
                                style: GoogleFonts.orbitron(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  3,
                                  (s) => Icon(
                                    Icons.star,
                                    size: 10,
                                    color: s < starsEarned ? AppTheme.accentGold : Colors.white24,
                                  ),
                                ),
                              ),
                            ] else
                              const Icon(Icons.lock, size: 20, color: Colors.white24),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Infinite Mode Button
              GestureDetector(
                onTap: () => onSelectLevel(99, 'simple'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D2146),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.accentPurple),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.all_inclusive, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'INFINITE LEVELS',
                        style: GoogleFonts.orbitron(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
