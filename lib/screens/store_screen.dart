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
      {'id': 'neon', 'name': 'NEON GREEN', 'desc': 'Classic glow path theme', 'price': 0, 'label': 'EQUIPPED', 'icon': Icons.shield, 'color': const Color(0xFF00FF9D)},
      {'id': 'forest', 'name': 'EMERALD FOREST', 'desc': 'Deep woods emerald glow', 'price': 10, 'label': '10 GEMS', 'icon': Icons.park, 'color': const Color(0xFF00FF66)},
      {'id': 'ocean', 'name': 'CYBER OCEAN', 'desc': 'Neon cyan water theme', 'price': 15, 'label': '15 GEMS', 'icon': Icons.water_drop, 'color': const Color(0xFF00D2FF)},
      {'id': 'lava', 'name': 'MOLTEN LAVA', 'desc': 'Fiery crimson path theme', 'price': 20, 'label': '20 GEMS', 'icon': Icons.local_fire_department, 'color': const Color(0xFFFF3366)},
      {'id': 'space', 'name': 'DEEP SPACE', 'desc': 'Cosmic purple glow theme', 'price': 25, 'label': '25 GEMS', 'icon': Icons.blur_on, 'color': const Color(0xFFB537FF)},
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header
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
              const SizedBox(height: 16),

              // Category Tabs
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

              // Items List
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

                    String btnText = 'EQUIPPED ✔';
                    if (!isEquipped) {
                      btnText = isUnlocked ? 'EQUIP' : '${item['label']}';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: AppTheme.glassCardDecoration(),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Icon(
                                item['icon'] as IconData,
                                size: 24,
                                color: itemColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] as String,
                                  style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                Text(
                                  item['desc'] as String,
                                  style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isEquipped
                                  ? AppTheme.primaryGlow.withValues(alpha: 0.2)
                                  : AppTheme.accentBlue.withValues(alpha: 0.2),
                              side: BorderSide(
                                color: isEquipped ? AppTheme.primaryGlow : AppTheme.accentBlue,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                            onPressed: () {
                              state.buyAndEquipTheme(itemId, gemPrice);
                            },
                            child: Text(
                              btnText,
                              style: GoogleFonts.orbitron(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isEquipped ? AppTheme.primaryGlow : AppTheme.accentBlue,
                              ),
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
          color: isSelected ? AppTheme.primaryGlow : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
