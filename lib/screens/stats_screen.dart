import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_tab_bar.dart';

class StatsScreen extends StatelessWidget {
  final VoidCallback onBack;
  final Function(int tabIndex) onTabChanged;

  const StatsScreen({
    super.key,
    required this.onBack,
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
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'STATS',
                    style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Grid of 4 Stat Boxes
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _StatBox(label: 'MAZES SOLVED', val: '${state.mazesSolved}'),
                        _StatBox(label: 'PERFECT RUNS', val: '${state.perfectRuns}'),
                        _StatBox(label: 'BEST TIME', val: '00:18.42'),
                        _StatBox(label: 'TOTAL TIME', val: '2h 34m'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Longest Streak Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.deepOrange.withValues(alpha: 0.25), Colors.orange.withValues(alpha: 0.1)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.deepOrange),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department, size: 36, color: Colors.deepOrange),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LONGEST STREAK',
                                style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              Text(
                                '${state.longestStreak}',
                                style: GoogleFonts.orbitron(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Completion Donut Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.glassCardDecoration(),
                      child: Column(
                        children: [
                          Text(
                            'COMPLETION',
                            style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: CircularProgressIndicator(
                                    value: 0.78,
                                    strokeWidth: 12,
                                    backgroundColor: Colors.white10,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGlow),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '78%',
                                      style: GoogleFonts.orbitron(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                                    ),
                                    Text(
                                      'ALL LEVELS',
                                      style: GoogleFonts.outfit(fontSize: 9, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Tab Bar
            CustomBottomTabBar(
              selectedIndex: 1,
              onTabSelected: onTabChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String val;

  const _StatBox({required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            val,
            style: GoogleFonts.orbitron(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryGlow,
            ),
          ),
        ],
      ),
    );
  }
}
