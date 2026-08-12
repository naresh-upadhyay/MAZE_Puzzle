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
            // Header Row matching Reference Screenshot 7
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
            ),

            // Scrollable Dark Fantasy World Map Container matching Reference Screenshot 7
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [Color(0xFF0F183D), Color(0xFF03040B)],
                    radius: 1.1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  children: [
                    // Node 24 (Green Completed)
                    _MapNode(
                      level: 24,
                      stars: 3,
                      status: _MapNodeStatus.completed,
                      align: Alignment.centerLeft,
                      onTap: () => onSelectLevel(24),
                    ),
                    _PathConnector(),

                    // Node 25 (Green Completed)
                    _MapNode(
                      level: 25,
                      stars: 3,
                      status: _MapNodeStatus.completed,
                      align: Alignment.center,
                      onTap: () => onSelectLevel(25),
                    ),
                    _PathConnector(),

                    // Node 26 (Green Completed)
                    _MapNode(
                      level: 26,
                      stars: 3,
                      status: _MapNodeStatus.completed,
                      align: Alignment.centerRight,
                      onTap: () => onSelectLevel(26),
                    ),
                    _PathConnector(),

                    // Node 27 (ACTIVE PURPLE AVATAR HERO NODE matching Reference Screenshot 7)
                    _MapNode(
                      level: 27,
                      stars: 0,
                      status: _MapNodeStatus.active,
                      align: Alignment.center,
                      onTap: () => onSelectLevel(27),
                    ),
                    _PathConnector(),

                    // Node 28 (Locked)
                    _MapNode(
                      level: 28,
                      stars: 0,
                      status: _MapNodeStatus.locked,
                      align: Alignment.centerLeft,
                      onTap: () {},
                    ),
                    _PathConnector(),

                    // Node 29 (Locked)
                    _MapNode(
                      level: 29,
                      stars: 0,
                      status: _MapNodeStatus.locked,
                      align: Alignment.centerRight,
                      onTap: () {},
                    ),
                    _PathConnector(),

                    // Node Infinite Card
                    Center(
                      child: GestureDetector(
                        onTap: () => onSelectLevel(1),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C1026),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.accentBlue, width: 2),
                          ),
                          child: const Icon(Icons.all_inclusive, color: AppTheme.accentBlue, size: 32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar matching Reference Screenshot 7
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

enum _MapNodeStatus { completed, active, locked }

class _MapNode extends StatelessWidget {
  final int level;
  final int stars;
  final _MapNodeStatus status;
  final Alignment align;
  final VoidCallback onTap;

  const _MapNode({
    required this.level,
    required this.stars,
    required this.status,
    required this.align,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = status == _MapNodeStatus.active;
    final isCompleted = status == _MapNodeStatus.completed;

    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            children: [
              Container(
                width: isActive ? 72 : 60,
                height: isActive ? 72 : 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppTheme.accentPurple
                      : isCompleted
                          ? AppTheme.primaryGlow
                          : Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: isActive
                        ? AppTheme.accentPink
                        : isCompleted
                            ? Colors.white
                            : Colors.white24,
                    width: isActive ? 3.5 : 2,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppTheme.accentPurple.withValues(alpha: 0.8),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: AppTheme.accentPink.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ]
                      : isCompleted
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryGlow.withValues(alpha: 0.5),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                ),
                child: Center(
                  child: status == _MapNodeStatus.locked
                      ? const Icon(Icons.lock, color: AppTheme.textMuted, size: 22)
                      : Text(
                          '$level',
                          style: GoogleFonts.orbitron(
                            fontSize: isActive ? 22 : 18,
                            fontWeight: FontWeight.w900,
                            color: isActive ? Colors.white : (isCompleted ? Colors.black : Colors.white),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),

              // Star Row for completed nodes
              if (isCompleted)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (i) => Icon(
                      Icons.star,
                      size: 12,
                      color: i < stars ? AppTheme.accentGold : Colors.white24,
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

class _PathConnector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
