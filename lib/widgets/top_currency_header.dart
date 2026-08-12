import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';

class TopCurrencyHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSettingsPressed;

  const TopCurrencyHeader({super.key, this.onSettingsPressed});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: AppTheme.bgDark.withValues(alpha: 0.85),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Branded Mini Logo
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryGlow, width: 1.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                  ),
                ),

                // Energy Badge
                _CurrencyPill(
                  icon: Icons.bolt,
                  iconColor: AppTheme.accentGold,
                  text: '${state.energy}/${state.maxEnergy}',
                  subText: 'FULL',
                  onAdd: () => state.refillEnergy(),
                ),
                const SizedBox(width: 6),

                // Coins Badge
                _CurrencyPill(
                  icon: Icons.monetization_on,
                  iconColor: AppTheme.accentGold,
                  text: '${state.coins}',
                  onAdd: () => state.addCoins(250),
                ),
                const SizedBox(width: 8),

                // Gems Badge
                _CurrencyPill(
                  icon: Icons.diamond,
                  iconColor: AppTheme.accentBlue,
                  text: '${state.gems}',
                  onAdd: () => state.addGems(10),
                ),
              ],
            ),

            // Settings Gear Button
            InkWell(
              onTap: onSettingsPressed,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: const Icon(Icons.settings, size: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final String? subText;
  final VoidCallback onAdd;

  const _CurrencyPill({
    required this.icon,
    required this.iconColor,
    required this.text,
    this.subText,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.orbitron(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (subText != null) ...[
            const SizedBox(width: 2),
            Text(
              subText!,
              style: GoogleFonts.orbitron(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGlow,
              ),
            ),
          ],
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppTheme.primaryGlow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 12, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
