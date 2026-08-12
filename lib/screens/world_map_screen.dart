import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_tab_bar.dart';

class WorldMapScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                    onPressed: onBack,
                  ),
                  Text(
                    'WORLD MAP',
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
            ),

            // Scrollable Map Nodes Timeline
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [Color(0xFF0E1436), Color(0xFF03040B)],
                    radius: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    final nodeLvl = 24 + index;
                    final isCurrent = nodeLvl == state.currentLevel;
                    final isCompleted = nodeLvl < state.currentLevel;

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: GestureDetector(
                          onTap: () => onSelectLevel(nodeLvl),
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppTheme.primaryGlow
                                      : Colors.white.withValues(alpha: isCompleted ? 0.15 : 0.05),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isCurrent ? Colors.white : AppTheme.primaryGlow.withValues(alpha: 0.4),
                                    width: 2,
                                  ),
                                  boxShadow: isCurrent
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.primaryGlow.withValues(alpha: 0.6),
                                            blurRadius: 25,
                                            spreadRadius: 2,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    '$nodeLvl',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isCurrent ? Colors.black : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  3,
                                  (s) => const Icon(Icons.star, size: 12, color: AppTheme.accentGold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Bottom Navigation Tab Bar
            CustomBottomTabBar(
              selectedIndex: 0,
              onTabSelected: onTabChanged,
            ),
          ],
        ),
      ),
    );
  }
}
