import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';

class StoreScreen extends StatelessWidget {
  final VoidCallback onBack;

  const StoreScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);

    final shopItems = [
      {
        'id': 'neon',
        'name': 'NEON',
        'desc': 'Classic cyber neon maze path',
        'price': 0,
        'color': const Color(0xFF00FF9D),
        'bgGradient': const [Color(0xFF0E2E20), Color(0xFF040B08)],
        'icon': Icons.shield,
      },
      {
        'id': 'forest',
        'name': 'FOREST',
        'desc': 'Mystic emerald canopy theme',
        'price': 100,
        'color': const Color(0xFF00FF66),
        'bgGradient': const [Color(0xFF0C2B14), Color(0xFF030A05)],
        'icon': Icons.park,
      },
      {
        'id': 'ocean',
        'name': 'OCEAN',
        'desc': 'Deep cyber abyss blue theme',
        'price': 150,
        'color': const Color(0xFF00D2FF),
        'bgGradient': const [Color(0xFF0A2436), Color(0xFF02090F)],
        'icon': Icons.water_drop,
      },
      {
        'id': 'lava',
        'name': 'LAVA',
        'desc': 'Molten volcanic magma path',
        'price': 200,
        'color': const Color(0xFFFF3366),
        'bgGradient': const [Color(0xFF380D17), Color(0xFF0F0205)],
        'icon': Icons.local_fire_department,
      },
      {
        'id': 'space',
        'name': 'SPACE',
        'desc': 'Cosmic nebula galaxy theme',
        'price': 250,
        'color': const Color(0xFFB537FF),
        'bgGradient': const [Color(0xFF260D38), Color(0xFF09020F)],
        'icon': Icons.blur_on,
      },
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header Row matching Reference Screenshot 8
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                    onPressed: onBack,
                  ),
                  Text(
                    'STORE',
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
              const SizedBox(height: 16),

              // Category Tabs matching Reference Screenshot 8
              Row(
                children: [
                  _StoreTab(label: 'THEMES', isSelected: true),
                  const SizedBox(width: 8),
                  _StoreTab(label: 'TRAILS', isSelected: false),
                  const SizedBox(width: 8),
                  _StoreTab(label: 'BOOSTERS', isSelected: false),
                ],
              ),
              const SizedBox(height: 16),

              // Rich Theme List matching Reference Screenshot 8
              Expanded(
                child: ListView.builder(
                  itemCount: shopItems.length,
                  itemBuilder: (context, index) {
                    final item = shopItems[index];
                    final itemId = item['id'] as String;
                    final itemColor = item['color'] as Color;
                    final isEquipped = itemId == state.equippedTheme;
                    final isUnlocked = state.unlockedThemes.contains(itemId);
                    final gemPrice = item['price'] as int;
                    final bgGradient = item['bgGradient'] as List<Color>;

                    return Container(
                      height: 80,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: bgGradient,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isEquipped
                              ? AppTheme.primaryGlow
                              : itemColor.withValues(alpha: 0.3),
                          width: isEquipped ? 2 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            // Theme Artwork Preview Box
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: itemColor, width: 1.5),
                              ),
                              child: Center(
                                child: Icon(
                                  item['icon'] as IconData,
                                  color: itemColor,
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Theme Info
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] as String,
                                    style: GoogleFonts.orbitron(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['desc'] as String,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Action Button matching Reference Screenshot 8
                            GestureDetector(
                              onTap: () {
                                if (!isEquipped) {
                                  state.buyAndEquipTheme(itemId, gemPrice);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isEquipped
                                      ? AppTheme.primaryGlow.withValues(alpha: 0.15)
                                      : (isUnlocked ? AppTheme.accentBlue : AppTheme.bgSurface),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isEquipped
                                        ? AppTheme.primaryGlow
                                        : (isUnlocked ? AppTheme.accentBlue : Colors.white24),
                                  ),
                                ),
                                child: isEquipped
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'EQUIPPED',
                                            style: GoogleFonts.orbitron(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryGlow,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.check_circle, size: 14, color: AppTheme.primaryGlow),
                                        ],
                                      )
                                    : isUnlocked
                                        ? Text(
                                            'EQUIP',
                                            style: GoogleFonts.orbitron(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'UNLOCK',
                                                style: GoogleFonts.orbitron(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.diamond, size: 12, color: AppTheme.accentBlue),
                                              const SizedBox(width: 2),
                                              Text(
                                                '$gemPrice',
                                                style: GoogleFonts.orbitron(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.accentBlue,
                                                ),
                                              ),
                                            ],
                                          ),
                              ),
                            ),
                          ],
                        ),
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

class _StoreTab extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _StoreTab({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.bgSurface : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGlow : Colors.white10,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppTheme.primaryGlow : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
