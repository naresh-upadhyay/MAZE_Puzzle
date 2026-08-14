import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/math_graph_background.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onBack;

  const SettingsScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);

    return Scaffold(
      body: MathGraphBackground(
        child: SafeArea(
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
                    'SETTINGS',
                    style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Settings Toggles Card
              Container(
                decoration: AppTheme.glassCardDecoration(),
                child: Column(
                  children: [
                    _SettingToggleRow(
                      icon: Icons.volume_up,
                      label: 'SOUND',
                      value: state.soundEnabled,
                      onChanged: state.toggleSound,
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    _SettingToggleRow(
                      icon: Icons.music_note,
                      label: 'MUSIC',
                      value: state.musicEnabled,
                      onChanged: state.toggleMusic,
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    _SettingToggleRow(
                      icon: Icons.vibration,
                      label: 'HAPTIC FEEDBACK',
                      value: state.hapticEnabled,
                      onChanged: state.toggleHaptic,
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    _SettingToggleRow(
                      icon: Icons.dark_mode,
                      label: 'DARK MODE',
                      value: state.darkMode,
                      onChanged: state.toggleDarkMode,
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.language, size: 20, color: AppTheme.primaryGlow),
                              const SizedBox(width: 12),
                              Text(
                                'LANGUAGE',
                                style: GoogleFonts.orbitron(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                          DropdownButton<String>(
                            value: state.language,
                            dropdownColor: AppTheme.bgSurface,
                            style: GoogleFonts.orbitron(fontSize: 12, color: Colors.white),
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 'en', child: Text('ENGLISH >')),
                              DropdownMenuItem(value: 'es', child: Text('ESPAÑOL >')),
                              DropdownMenuItem(value: 'fr', child: Text('FRANÇAIS >')),
                              DropdownMenuItem(value: 'de', child: Text('DEUTSCH >')),
                              DropdownMenuItem(value: 'ja', child: Text('JAPANESE >')),
                            ],
                            onChanged: (val) {
                              if (val != null) state.setLanguage(val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Links
              _LinkRow(icon: Icons.headset_mic, label: 'SUPPORT'),
              const SizedBox(height: 8),
              _LinkRow(icon: Icons.security, label: 'PRIVACY POLICY'),
              const SizedBox(height: 8),
              _LinkRow(icon: Icons.favorite, label: 'RATE US'),

              const Spacer(),
              // Studio Branding Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primaryGlow),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MAZE GLOW PATH',
                          style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'VERSION 1.0.0 • BUILD 2026',
                          style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
}
}

class _SettingToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final Function(bool) onChanged;

  const _SettingToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryGlow),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.orbitron(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.black,
            activeTrackColor: AppTheme.primaryGlow,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _LinkRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppTheme.glassCardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.orbitron(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    );
  }
}
