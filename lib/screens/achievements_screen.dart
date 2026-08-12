import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';

class AchievementsScreen extends StatelessWidget {
  final VoidCallback onBack;

  const AchievementsScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);

    final achs = [
      {'title': 'First Steps', 'desc': 'Complete 10 levels', 'progress': 10, 'total': 10, 'icon': Icons.directions_walk, 'claimed': true},
      {'title': 'Perfect Run', 'desc': 'Complete 10 levels without any mistakes', 'progress': 6, 'total': 10, 'icon': Icons.favorite, 'claimed': false},
      {'title': 'Speedster', 'desc': 'Complete a maze in under 15 seconds', 'progress': 3, 'total': 5, 'icon': Icons.bolt, 'claimed': false},
      {'title': 'Star Collector', 'desc': 'Collect 100 stars', 'progress': state.totalStars, 'total': 100, 'icon': Icons.star, 'claimed': false},
      {'title': 'Maze Master', 'desc': 'Complete 100 levels', 'progress': state.mazesSolved, 'total': 100, 'icon': Icons.emoji_events, 'claimed': false},
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ACHIEVEMENTS',
                    style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  itemCount: achs.length,
                  itemBuilder: (context, index) {
                    final item = achs[index];
                    final progress = item['progress'] as int;
                    final total = item['total'] as int;
                    final claimed = item['claimed'] as bool;
                    final pct = (progress / total).clamp(0.0, 1.0);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: AppTheme.glassCardDecoration(),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.accentGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Icon(
                                item['icon'] as IconData,
                                size: 22,
                                color: AppTheme.accentGold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] as String,
                                  style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                Text(
                                  item['desc'] as String,
                                  style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 6,
                                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGlow),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (claimed)
                            const Icon(Icons.check_circle, color: AppTheme.primaryGlow, size: 24)
                          else
                            Text(
                              '$progress/$total',
                              style: GoogleFonts.orbitron(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMuted,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
