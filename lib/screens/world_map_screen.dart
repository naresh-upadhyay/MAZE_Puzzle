import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_tab_bar.dart';

class WorldMapScreen extends StatefulWidget {
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
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLevel();
    });
  }

  void _scrollToCurrentLevel() {
    final state = Provider.of<GameState>(context, listen: false);
    final targetIndex = (state.currentLevel - 1).clamp(0, 100);
    // Height per node step is ~140px
    final targetOffset = targetIndex * 140.0 - 220;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);
    final currLevel = state.currentLevel;
    final totalLevels = (currLevel + 10).clamp(25, 100);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
                    onPressed: widget.onBack,
                  ),
                  Text(
                    'WORLD MAP',
                    style: GoogleFonts.orbitron(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.diamond_rounded, size: 14, color: AppTheme.accentBlue),
                        const SizedBox(width: 4),
                        Text(
                          '${state.gems}',
                          style: GoogleFonts.orbitron(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Rich 3D Mountain Terrain Map ────────────────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.7),
                      blurRadius: 25,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, child) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final nodeSpacing = 140.0;
                          final totalHeight = (totalLevels + 1) * nodeSpacing + 140.0;

                          // Compute winding S-curve positions for all level nodes
                          final nodeOffsets = <Offset>[];
                          for (int i = 0; i < totalLevels; i++) {
                            final y = totalHeight - 140.0 - (i * nodeSpacing);
                            // Winding sinusoid x alignment matching Reference Image #8
                            final wave = math.sin(i * 0.72);
                            final x = (width / 2) + wave * (width * 0.32);
                            nodeOffsets.add(Offset(x, y));
                          }

                          // Infinite portal node position at top of map
                          final infiniteOffset = Offset(width / 2, 70);

                          return SingleChildScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            child: SizedBox(
                              width: width,
                              height: totalHeight,
                              child: Stack(
                                children: [
                                  // 1. Terrain Canvas Painter (Mountain Landmarks, Trees, Lava Rivers & Dotted Path)
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _MountainTerrainMapPainter(
                                        totalLevels: totalLevels,
                                        nodeOffsets: nodeOffsets,
                                        pulseValue: _pulseCtrl.value,
                                        currLevel: currLevel,
                                      ),
                                    ),
                                  ),

                                  // 2. Level Nodes Overlay
                                  for (int i = 0; i < totalLevels; i++) ...[
                                    _buildNodeWidget(
                                      level: i + 1,
                                      currLevel: currLevel,
                                      offset: nodeOffsets[i],
                                      state: state,
                                    ),
                                  ],

                                  // 3. Infinite Node at Top
                                  Positioned(
                                    left: infiniteOffset.dx - 34,
                                    top: infiniteOffset.dy - 34,
                                    child: GestureDetector(
                                      onTap: () => widget.onSelectLevel(currLevel),
                                      child: Container(
                                        width: 68,
                                        height: 68,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF0C1026),
                                          border: Border.all(color: AppTheme.accentBlue, width: 3),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.accentBlue.withValues(alpha: 0.6),
                                              blurRadius: 20,
                                              spreadRadius: 3,
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.all_inclusive_rounded,
                                            color: AppTheme.accentBlue,
                                            size: 34,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

            // ── Bottom Navigation Bar ─────────────────────────────────────────
            CustomBottomTabBar(
              selectedIndex: 0,
              onTabSelected: widget.onTabChanged,
            ),
          ],
        ),
      ),
    );
  }

  // ── Node Builder Widget matching Reference Screenshot 8 ──────────────────
  Widget _buildNodeWidget({
    required int level,
    required int currLevel,
    required Offset offset,
    required GameState state,
  }) {
    final isCompleted = level < currLevel;
    final isActive = level == currLevel;
    final isLocked = level > currLevel;

    final stars = state.levelProgress[state.selectedMode]?[level]?.stars ??
        (isCompleted ? 3 : 0);

    return Positioned(
      left: offset.dx - (isActive ? 38 : 31),
      top: offset.dy - (isActive ? 38 : 31),
      child: GestureDetector(
        onTap: () {
          if (!isLocked) {
            widget.onSelectLevel(level);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Node Disc Circle matching Reference Screenshot 8
            Container(
              width: isActive ? 76 : 62,
              height: isActive ? 76 : 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isActive
                    ? const LinearGradient(
                        colors: [Color(0xFFB000FF), Color(0xFFFF007F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : isCompleted
                        ? const LinearGradient(
                            colors: [Color(0xFF00FF9D), Color(0xFF00B36B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                color: isLocked ? const Color(0xFF0E132A) : null,
                border: Border.all(
                  color: isActive
                      ? Colors.white
                      : (isCompleted
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.25)),
                  width: isActive ? 4 : 2.5,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF007F).withValues(alpha: 0.85),
                          blurRadius: 26,
                          spreadRadius: 4 + _pulseCtrl.value * 4,
                        ),
                        BoxShadow(
                          color: const Color(0xFFB000FF).withValues(alpha: 0.7),
                          blurRadius: 14,
                        ),
                      ]
                    : isCompleted
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00FF9D).withValues(alpha: 0.55),
                              blurRadius: 16,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ],
              ),
              child: Center(
                child: isLocked
                    ? const Icon(Icons.lock_rounded, color: AppTheme.textMuted, size: 22)
                    : Text(
                        '$level',
                        style: GoogleFonts.orbitron(
                          fontSize: isActive ? 24 : 19,
                          fontWeight: FontWeight.w900,
                          color: isActive ? Colors.white : Colors.black,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),

            // Stars Row for Completed Levels
            if (isCompleted)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (idx) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: idx < stars ? AppTheme.accentGold : Colors.white24,
                    ),
                  ),
                ),
              )
            else if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF007F).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFF007F), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF007F).withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  'NOW',
                  style: GoogleFonts.orbitron(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Mountain Terrain Custom Painter ──────────────────────────────────────────
class _MountainTerrainMapPainter extends CustomPainter {
  final int totalLevels;
  final List<Offset> nodeOffsets;
  final double pulseValue;
  final int currLevel;

  _MountainTerrainMapPainter({
    required this.totalLevels,
    required this.nodeOffsets,
    required this.pulseValue,
    required this.currLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── 1. Biome Background Gradient (Space -> Snow -> Emerald Forest -> Lava)
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: const [
          Color(0xFF030712), // Deep Space (Top)
          Color(0xFF0B1936), // Snowy Mountain Sky
          Color(0xFF033324), // Emerald Pine Forest
          Color(0xFF3B0808), // Volcanic Lava Caverns
          Color(0xFF0A0408), // Magma Core (Bottom)
        ],
        stops: const [0.0, 0.28, 0.58, 0.85, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // ── 2. Terrain Island Pods & Mountain Landmarks Along Node Offsets ───────
    for (int i = 0; i < nodeOffsets.length; i++) {
      final pos = nodeOffsets[i];
      final lvl = i + 1;

      // Draw 3D Ground Island Pod under every node
      _drawTerrainIslandPod(canvas, pos, lvl);

      // Render Mountain / Tree Landmarks every 3-4 nodes
      if (i % 3 == 0) {
        if (lvl > 28) {
          // Snowy Icy Peaks Zone
          _drawSnowyMountainPeak(canvas, pos, i % 2 == 0);
        } else if (lvl > 14) {
          // Emerald Pine Forest Zone
          _drawPineTreeGrove(canvas, pos);
        } else {
          // Volcanic Lava Crags Zone
          _drawVolcanicCrag(canvas, pos, i % 2 == 0);
        }
      }
    }

    // ── 3. Glowing Dotted Cyber Path matching Reference Screenshot 8 ────────
    if (nodeOffsets.length >= 2) {
      final path = Path();
      path.moveTo(nodeOffsets[0].dx, nodeOffsets[0].dy);

      for (int i = 0; i < nodeOffsets.length - 1; i++) {
        final p1 = nodeOffsets[i];
        final p2 = nodeOffsets[i + 1];
        final controlY = (p1.dy + p2.dy) / 2;

        path.cubicTo(
          p1.dx,
          controlY,
          p2.dx,
          controlY,
          p2.dx,
          p2.dy,
        );
      }

      // 3A. Outer Neon Glow Blur
      final pathGlow = Paint()
        ..color = const Color(0xFF00FF9D).withValues(alpha: 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(path, pathGlow);

      // 3B. Dotted Dash Neon Line (Using PathMetrics)
      final dottedPath = Path();
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        double distance = 0;
        const dashWidth = 8.0;
        const dashSpace = 6.0;
        while (distance < metric.length) {
          dottedPath.addPath(
            metric.extractPath(distance, distance + dashWidth),
            Offset.zero,
          );
          distance += dashWidth + dashSpace;
        }
      }

      final pathLine = Paint()
        ..color = const Color(0xFF00FF9D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round;

      final pathCore = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(dottedPath, pathLine);
      canvas.drawPath(dottedPath, pathCore);
    }
  }

  // ── 3D Terrain Island Pod Under Node Disc ─────────────────────────────────
  void _drawTerrainIslandPod(Canvas canvas, Offset pos, int level) {
    Color podColor;
    Color rimColor;

    if (level > 28) {
      podColor = const Color(0xFF1E3A8A).withValues(alpha: 0.35);
      rimColor = const Color(0xFF60A5FA).withValues(alpha: 0.5);
    } else if (level > 14) {
      podColor = const Color(0xFF064E3B).withValues(alpha: 0.45);
      rimColor = const Color(0xFF10B981).withValues(alpha: 0.5);
    } else {
      podColor = const Color(0xFF7F1D1D).withValues(alpha: 0.40);
      rimColor = const Color(0xFFEF4444).withValues(alpha: 0.5);
    }

    // Elliptical 3D Ground Pod Shadow
    canvas.drawOval(
      Rect.fromCenter(center: pos.translate(0, 8), width: 90, height: 44),
      Paint()..color = Colors.black.withValues(alpha: 0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Elliptical 3D Ground Pod Base
    canvas.drawOval(
      Rect.fromCenter(center: pos, width: 84, height: 40),
      Paint()..color = podColor,
    );

    // Glowing Rim
    canvas.drawOval(
      Rect.fromCenter(center: pos, width: 84, height: 40),
      Paint()
        ..color = rimColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // ── Snowy Mountain Peak Landmark Artwork ──────────────────────────────────
  void _drawSnowyMountainPeak(Canvas canvas, Offset pos, bool alignRight) {
    final offsetX = alignRight ? pos.dx + 70 : pos.dx - 110;
    final offsetY = pos.dy - 20;

    // Mountain Pyramid Path
    final mPath = Path()
      ..moveTo(offsetX, offsetY + 60)
      ..lineTo(offsetX + 35, offsetY - 35)
      ..lineTo(offsetX + 70, offsetY + 60)
      ..close();

    final mPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1D4ED8), Color(0xFF0F172A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(offsetX, offsetY - 35, 70, 95));

    canvas.drawPath(mPath, mPaint);

    // Snow Cap Tip
    final sCap = Path()
      ..moveTo(offsetX + 35, offsetY - 35)
      ..lineTo(offsetX + 24, offsetY + 5)
      ..lineTo(offsetX + 35, offsetY)
      ..lineTo(offsetX + 46, offsetY + 8)
      ..close();

    canvas.drawPath(sCap, Paint()..color = const Color(0xFF93C5FD));
  }

  // ── Pine Tree Grove Landmark Artwork ─────────────────────────────────────
  void _drawPineTreeGrove(Canvas canvas, Offset pos) {
    final leftX = pos.dx - 85;
    final rightX = pos.dx + 65;
    final y = pos.dy;

    // Left Pine Tree
    _drawPineTree(canvas, Offset(leftX, y), 38, const Color(0xFF047857));
    _drawPineTree(canvas, Offset(leftX - 16, y + 10), 30, const Color(0xFF065F46));

    // Right Pine Tree
    _drawPineTree(canvas, Offset(rightX, y), 42, const Color(0xFF10B981));
    _drawPineTree(canvas, Offset(rightX + 18, y + 12), 32, const Color(0xFF047857));
  }

  void _drawPineTree(Canvas canvas, Offset bottom, double h, Color c) {
    final w = h * 0.45;
    final p = Path()
      ..moveTo(bottom.dx, bottom.dy - h)
      ..lineTo(bottom.dx - w / 2, bottom.dy)
      ..lineTo(bottom.dx + w / 2, bottom.dy)
      ..close();
    canvas.drawPath(p, Paint()..color = c);
  }

  // ── Volcanic Lava Crag Landmark Artwork ──────────────────────────────────
  void _drawVolcanicCrag(Canvas canvas, Offset pos, bool alignRight) {
    final offsetX = alignRight ? pos.dx + 65 : pos.dx - 100;
    final offsetY = pos.dy - 10;

    // Volcanic Crag Shape
    final vPath = Path()
      ..moveTo(offsetX, offsetY + 50)
      ..lineTo(offsetX + 25, offsetY - 25)
      ..lineTo(offsetX + 55, offsetY + 50)
      ..close();

    final vPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF991B1B), Color(0xFF180505)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(offsetX, offsetY - 25, 55, 75));

    canvas.drawPath(vPath, vPaint);

    // Glowing Lava Vein Stream
    final lavaPath = Path()
      ..moveTo(offsetX + 25, offsetY - 25)
      ..lineTo(offsetX + 22, offsetY + 15)
      ..lineTo(offsetX + 28, offsetY + 35);

    final lavaPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);

    canvas.drawPath(lavaPath, lavaPaint);
  }

  @override
  bool shouldRepaint(_MountainTerrainMapPainter old) =>
      old.pulseValue != pulseValue || old.currLevel != currLevel;
}
