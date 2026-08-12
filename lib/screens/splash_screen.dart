import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback onStart;
  final Function(String route) onNavigate;

  const SplashScreen({super.key, required this.onStart, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF0F153A), Color(0xFF04050D)],
            radius: 1.2,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 20),

              // Hero Logo Box
              Column(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppTheme.primaryGlow, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGlow.withValues(alpha: 0.5),
                          blurRadius: 35,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: AppTheme.accentPink.withValues(alpha: 0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'MAZE',
                    style: GoogleFonts.orbitron(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  Text(
                    'GLOW PATH',
                    style: GoogleFonts.orbitron(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryGlow,
                      letterSpacing: 6,
                      shadows: [
                        Shadow(color: AppTheme.primaryGlow, blurRadius: 15),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '"One Path. Infinite Mazes."',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),

              // TAP TO START BUTTON
              GestureDetector(
                onTap: onStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                  decoration: AppTheme.primaryButtonDecoration(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TAP TO START',
                        style: GoogleFonts.orbitron(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.play_arrow, size: 20, color: Colors.black),
                    ],
                  ),
                ),
              ),

              // Footer Navigation Links
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FooterLink(
                      icon: Icons.emoji_events,
                      label: 'Achievements',
                      onTap: () => onNavigate('/achievements'),
                    ),
                    const SizedBox(width: 48),
                    _FooterLink(
                      icon: Icons.tune,
                      label: 'Settings',
                      onTap: () => onNavigate('/settings'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FooterLink({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 22, color: Colors.white),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
