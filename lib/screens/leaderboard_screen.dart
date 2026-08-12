import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_tab_bar.dart';

class LeaderboardScreen extends StatelessWidget {
  final VoidCallback onBack;
  final Function(int tabIndex) onTabChanged;

  const LeaderboardScreen({
    super.key,
    required this.onBack,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);

    // Calculate user's best overall time
    double bestSec = 999999;
    String userBestTime = '00:24.18';
    state.levelProgress.forEach((mode, innerMap) {
      innerMap.forEach((lvl, lp) {
        if (lp.completed && lp.bestTimeSec < bestSec) {
          bestSec = lp.bestTimeSec;
          userBestTime = lp.bestTime;
        }
      });
    });

    final rankings = [
      {'rank': 4, 'name': 'Vihaan', 'time': '00:19.88', 'isUser': false},
      {'rank': 5, 'name': 'You', 'time': userBestTime, 'isUser': true},
      {'rank': 6, 'name': 'Aryan', 'time': '00:25.67', 'isUser': false},
      {'rank': 7, 'name': 'Neha', 'time': '00:27.31', 'isUser': false},
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'LEADERBOARD',
                    style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Time filter tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  children: [
                    _FilterTab(label: 'DAILY', isSelected: true),
                    _FilterTab(label: 'WEEKLY', isSelected: false),
                    _FilterTab(label: 'ALL TIME', isSelected: false),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top 3 Podium
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  // 2nd Place
                  _PodiumSpot(
                    rank: 2,
                    name: 'Ankush',
                    time: '00:18.32',
                    badgeColor: Color(0xFFC0C0C0),
                    height: 90,
                  ),
                  SizedBox(width: 16),
                  // 1st Place (Winner Crown)
                  _PodiumSpot(
                    rank: 1,
                    name: 'Riya',
                    time: '00:15.42',
                    badgeColor: AppTheme.accentGold,
                    height: 110,
                    hasCrown: true,
                  ),
                  SizedBox(width: 16),
                  // 3rd Place
                  _PodiumSpot(
                    rank: 3,
                    name: 'Karan',
                    time: '00:19.05',
                    badgeColor: Color(0xFFCD7F32),
                    height: 80,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Rankings list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: rankings.length,
                itemBuilder: (context, index) {
                  final p = rankings[index];
                  final isUser = p['isUser'] as bool;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppTheme.primaryGlow.withValues(alpha: 0.15)
                          : AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isUser
                            ? AppTheme.primaryGlow
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${p['rank']}',
                          style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            p['name'] as String,
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        Text(
                          p['time'] as String,
                          style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryGlow),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Text(
              'New leaderboard in 10:24:18',
              style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 8),

            // Bottom Navigation Tab Bar
            CustomBottomTabBar(
              selectedIndex: 2,
              onTabSelected: onTabChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterTab({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGlow : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _PodiumSpot extends StatelessWidget {
  final int rank;
  final String name;
  final String time;
  final Color badgeColor;
  final double height;
  final bool hasCrown;

  const _PodiumSpot({
    required this.rank,
    required this.name,
    required this.time,
    required this.badgeColor,
    required this.height,
    this.hasCrown = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasCrown) ...[
          const Icon(Icons.emoji_events, size: 24, color: AppTheme.accentGold),
          const SizedBox(height: 4),
        ],
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                color: Colors.white12,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 30),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  '$rank',
                  style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(name, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
        Text(time, style: GoogleFonts.orbitron(fontSize: 10, color: AppTheme.textMuted)),
      ],
    );
  }
}
