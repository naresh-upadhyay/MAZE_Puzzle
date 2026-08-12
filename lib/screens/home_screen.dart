import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/top_currency_header.dart';

class HomeScreen extends StatelessWidget {
  final Function(String route) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);

    return Scaffold(
      appBar: TopCurrencyHeader(
        onSettingsPressed: () => onNavigate('/settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Title Header
            Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryGlow, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGlow.withValues(alpha: 0.4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'MAZE',
                  style: GoogleFonts.orbitron(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                Text(
                  'GLOW PATH',
                  style: GoogleFonts.orbitron(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryGlow,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    'Swipe • Glow • Find the Exit',
                    style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // PLAY HERO BUTTON
            GestureDetector(
              onTap: () => onNavigate('/gameplay'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFC107), Color(0xFFFF9800)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC107).withValues(alpha: 0.5),
                      blurRadius: 25,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.play_arrow, size: 28, color: Color(0xFFFFC107)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PLAY',
                          style: GoogleFonts.orbitron(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF040814),
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'Level ${state.currentLevel}',
                          style: GoogleFonts.orbitron(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xCC040814),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Menu List Cards
            _MenuCard(
              icon: Icons.calendar_today,
              iconColor: AppTheme.accentBlue,
              title: 'DAILY MAZE',
              subtitle: 'New maze in 12h 34m',
              onTap: () => onNavigate('/gameplay'),
            ),
            const SizedBox(height: 10),
            _MenuCard(
              icon: Icons.border_all,
              iconColor: AppTheme.accentPurple,
              title: 'SELECT LEVEL',
              subtitle: 'Simple & Complicated Puzzles',
              onTap: () => onNavigate('/level_select'),
            ),
            const SizedBox(height: 10),
            _MenuCard(
              icon: Icons.card_giftcard,
              iconColor: AppTheme.accentGold,
              title: 'STORE',
              subtitle: 'Themes, Trails & Boosters',
              onTap: () => onNavigate('/store'),
            ),
            const SizedBox(height: 10),
            _MenuCard(
              icon: Icons.emoji_events,
              iconColor: Colors.orange,
              title: 'ACHIEVEMENTS',
              subtitle: '32 / 150 Unlocked',
              onTap: () => onNavigate('/achievements'),
            ),
            const SizedBox(height: 10),
            _MenuCard(
              icon: Icons.help_outline,
              iconColor: AppTheme.secondaryGlow,
              title: 'HOW TO PLAY',
              subtitle: 'Learn the Rules & Controls',
              onTap: () => onNavigate('/how_to_play'),
            ),
            const SizedBox(height: 10),
            _MenuCard(
              icon: Icons.map,
              iconColor: AppTheme.primaryGlow,
              title: 'WORLD MAP',
              subtitle: 'Explore Your Progress',
              onTap: () => onNavigate('/world_map'),
            ),
            const SizedBox(height: 20),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _StatPill(
                    icon: Icons.local_fire_department,
                    iconColor: Colors.deepOrange,
                    val: '${state.streak}',
                    label: 'CURRENT STREAK',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatPill(
                    icon: Icons.extension,
                    iconColor: AppTheme.accentBlue,
                    val: '${state.mazesSolved}',
                    label: 'MAZES SOLVED',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatPill(
                    icon: Icons.star,
                    iconColor: AppTheme.accentGold,
                    val: '${state.totalStars}',
                    label: 'TOTAL STARS',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: AppTheme.glassCardDecoration(),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Icon(icon, size: 20, color: iconColor)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String val;
  final String label;

  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.val,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 4),
          Text(
            val,
            style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
