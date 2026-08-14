import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import 'atomic_orbital_node.dart';

/// Computes the winding S-curve positions for all level nodes
List<Offset> computeWorldMapNodeOffsets({
  required int totalLevels,
  required double width,
  required double totalHeight,
  double nodeSpacing = 135.0,
  double? waveWidth,
  double bottomPadding = 105.0,
}) {
  final nodeOffsets = <Offset>[];
  final actualWaveWidth = waveWidth ?? width;
  for (int i = 0; i < totalLevels; i++) {
    final y = totalHeight - bottomPadding - (i * nodeSpacing);
    // Winding sinusoid x alignment matching reference cyber design
    final wave = math.sin(i * 0.72);
    final x = (width / 2) + wave * (actualWaveWidth * 0.32);
    nodeOffsets.add(Offset(x, y));
  }
  return nodeOffsets;
}

/// Cybernetic Terrain & Multivariable Mathematical Graph Background Painter
class WorldMapTerrainPainter extends CustomPainter {
  final int totalLevels;
  final List<Offset> nodeOffsets;
  final double pulseValue;
  final double orbitProgress;
  final int currentLevel;
  final Offset? infiniteOffset;

  WorldMapTerrainPainter({
    required this.totalLevels,
    required this.nodeOffsets,
    required this.pulseValue,
    required this.orbitProgress,
    required this.currentLevel,
    this.infiniteOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    // ── 1. Cybernetic Biome Gradient Background ──────────────────────────────
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF02050E), // Deep Cyber Space (Top)
          Color(0xFF071738), // High Alpine Glaciers
          Color(0xFF03281E), // Emerald Cyber Forest
          Color(0xFF28070F), // Volcanic Magma Caverns
          Color(0xFF090306), // Magma Abyss (Bottom)
        ],
        stops: [0.0, 0.28, 0.58, 0.85, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // ── 2. Mathematical Coordinate Graph Grid & Axis Marks ───────────────────
    _drawMathGraphGrid(canvas, size);

    // ── 3. Multivariable 3D Height Contour Iso-Lines f(x, y, t) = c ───────────
    _drawMultivariateContours(canvas, size);

    // ── 4. Animated Vector Field Direction Arrows ∇f(x, y, t) ─────────────────
    _drawVectorField(canvas, size);

    // ── 5. Animated Mathematical Sine Harmonic Waves ─────────────────────────
    _drawMathHarmonicWaves(canvas, size);

    // ── 6. Multivariable Calculus Formulas & Equations ────────────────────────
    _drawMultivariableFormulas(canvas, size);

    // ── 7. Terrain Island Pods & Cyber Landmarks Along Nodes ─────────────────
    for (int i = 0; i < nodeOffsets.length; i++) {
      final pos = nodeOffsets[i];
      final lvl = i + 1;

      // Draw 3D Ground Island Pod under every node
      _drawTerrainIslandPod(canvas, pos, lvl);

      // Render Cyber Landmarks every 3 nodes
      if (i % 3 == 0) {
        if (lvl > 28) {
          // Snowy Icy Peaks Zone
          _drawCyberMountainPeak(canvas, pos, i % 2 == 0);
        } else if (lvl > 14) {
          // Emerald Cyber Pine Grove Zone
          _drawCyberPineGrove(canvas, pos);
        } else {
          // Volcanic Lava Crags Zone
          _drawVolcanicCrag(canvas, pos, i % 2 == 0);
        }
      }
    }

    // ── 8. Glowing Cyber Connecting Energy Path ──────────────────────────────
    if (nodeOffsets.length >= 2) {
      _drawGlowingEnergyPath(canvas, size);
    }

    // ── 9. Atmospheric Field Depth Particles (Field Depth Layer) ────────────
    _drawDepthParticles(canvas, size);
  }

  // ── Mathematical Coordinate Graph Grid ─────────────────────────────────────
  void _drawMathGraphGrid(Canvas canvas, Size size) {
    const minorSpacing = 28.0;
    const majorSpacing = minorSpacing * 4; // 112.0

    final minorGridPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.16)
      ..strokeWidth = 0.7;

    final majorGridPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.40)
      ..strokeWidth = 1.1;

    final crossPaint = Paint()
      ..color = const Color(0xFF00FF9D).withValues(alpha: 0.60)
      ..strokeWidth = 1.5;

    // Vertical grid lines
    for (double x = 0; x <= size.width; x += minorSpacing) {
      final isMajor = (x % majorSpacing).abs() < 1.0 || (x % majorSpacing - majorSpacing).abs() < 1.0;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), isMajor ? majorGridPaint : minorGridPaint);
    }

    // Horizontal grid lines
    for (double y = 0; y <= size.height; y += minorSpacing) {
      final isMajor = (y % majorSpacing).abs() < 1.0 || (y % majorSpacing - majorSpacing).abs() < 1.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), isMajor ? majorGridPaint : minorGridPaint);
    }

    // Intersection Crosses on Major Points
    for (double x = 0; x <= size.width; x += majorSpacing) {
      for (double y = 0; y <= size.height; y += majorSpacing) {
        const cSize = 4.5;
        canvas.drawLine(Offset(x - cSize, y), Offset(x + cSize, y), crossPaint);
        canvas.drawLine(Offset(x, y - cSize), Offset(x, y + cSize), crossPaint);
      }
    }
  }

  // ── Multivariable 3D Height Contour Iso-Lines f(x, y, t) = c ───────────────
  void _drawMultivariateContours(Canvas canvas, Size size) {
    final t = orbitProgress * 2 * math.pi;
    final w = size.width;
    final h = size.height;

    // Draw animated contour level sets down the height of the map
    const contourStep = 240.0;
    for (double centerY = 150; centerY < h; centerY += contourStep) {
      final centerX = w * 0.5 + math.sin(centerY * 0.005 + t * 0.5) * (w * 0.2);

      // Render 3 concentric multivariable potential level curves
      for (int ring = 1; ring <= 3; ring++) {
        final radiusX = ring * 45.0 + math.sin(t + ring) * 8.0;
        final radiusY = ring * 28.0 + math.cos(t * 0.8 + ring) * 5.0;

        final contourPath = Path();
        contourPath.addOval(Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: radiusX * 2,
          height: radiusY * 2,
        ));

        final alpha = 0.25 - (ring * 0.05);
        final color = ring == 1
            ? const Color(0xFF00FF9D)
            : (ring == 2 ? const Color(0xFF00F0FF) : const Color(0xFFC084FC));

        final contourPaint = Paint()
          ..color = color.withValues(alpha: alpha.clamp(0.05, 0.35))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

        canvas.drawPath(contourPath, contourPaint);

        // Iso-line level label text (c_1, c_2, c_3)
        if (ring == 2) {
          final tp = TextPainter(textDirection: TextDirection.ltr)
            ..text = TextSpan(
              text: 'f(x,y)=${(ring * 1.5).toStringAsFixed(1)}',
              style: GoogleFonts.orbitron(
                fontSize: 7.5,
                color: color.withValues(alpha: 0.45),
                fontWeight: FontWeight.w500,
              ),
            )
            ..layout();
          tp.paint(canvas, Offset(centerX + radiusX * 0.7, centerY - radiusY * 0.7));
        }
      }
    }
  }

  // ── Animated Vector Field Direction Arrows ∇f(x, y, t) ─────────────────────
  void _drawVectorField(Canvas canvas, Size size) {
    final t = orbitProgress * 2 * math.pi;
    final w = size.width;
    final h = size.height;

    const gridX = 90.0;
    const gridY = 160.0;

    final arrowPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.35)
      ..strokeWidth = 1.1;

    for (double x = 45; x < w; x += gridX) {
      for (double y = 80; y < h; y += gridY) {
        // Gradient vector ∇f(x,y,t) direction components
        final vx = math.sin((x / w) * 3 * math.pi + t) * 12.0;
        final vy = math.cos((y / h) * 4 * math.pi - t * 0.8) * 12.0;

        final start = Offset(x, y);
        final end = Offset(x + vx, y + vy);

        // Arrow Shaft
        canvas.drawLine(start, end, arrowPaint);

        // Arrowhead
        final angle = math.atan2(vy, vx);
        const headLen = 4.0;
        final p1 = Offset(
          end.dx - headLen * math.cos(angle - math.pi / 6),
          end.dy - headLen * math.sin(angle - math.pi / 6),
        );
        final p2 = Offset(
          end.dx - headLen * math.cos(angle + math.pi / 6),
          end.dy - headLen * math.sin(angle + math.pi / 6),
        );

        canvas.drawLine(end, p1, arrowPaint);
        canvas.drawLine(end, p2, arrowPaint);
      }
    }
  }

  // ── Animated Mathematical Sine Harmonic Waves Across the Map ──────────────
  void _drawMathHarmonicWaves(Canvas canvas, Size size) {
    final wavePhase = orbitProgress * 2 * math.pi;

    // Multiple mathematical sine waves running periodically down the map
    const waveSpacing = 320.0;
    for (double baseWaveY = 100; baseWaveY < size.height; baseWaveY += waveSpacing) {
      final wavePath1 = Path();
      wavePath1.moveTo(0, baseWaveY + math.sin(wavePhase + baseWaveY * 0.01) * 16);

      for (double x = 0; x <= size.width; x += 6) {
        final normalizedX = x / size.width;
        final y = baseWaveY +
            math.sin(normalizedX * 4 * math.pi + wavePhase + baseWaveY * 0.01) * 26 +
            math.cos(normalizedX * 2 * math.pi - wavePhase * 0.5) * 12;
        wavePath1.lineTo(x, y);
      }

      // Neon Wave Glow
      final glowPaint = Paint()
        ..color = const Color(0xFF00F0FF).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(wavePath1, glowPaint);

      // Core Wave Line
      final linePaint = Paint()
        ..color = const Color(0xFF00F0FF).withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawPath(wavePath1, linePaint);

      // Secondary Counter-Harmonic
      final wavePath2 = Path();
      final baseWaveY2 = baseWaveY + 110;
      if (baseWaveY2 < size.height) {
        wavePath2.moveTo(0, baseWaveY2 + math.cos(wavePhase) * 14);

        for (double x = 0; x <= size.width; x += 6) {
          final normalizedX = x / size.width;
          final y = baseWaveY2 +
              math.sin(normalizedX * 3 * math.pi - wavePhase * 0.8) * 18 +
              math.sin(normalizedX * 6 * math.pi + wavePhase) * 8;
          wavePath2.lineTo(x, y);
        }

        final linePaint2 = Paint()
          ..color = const Color(0xFF00FF9D).withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawPath(wavePath2, linePaint2);
      }
    }
  }

  // ── Multivariable Calculus Formulas & Equations ────────────────────────────
  void _drawMultivariableFormulas(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final multiVarFormulas = [
      {
        'text': 'ρ(∂u/∂t + u·∇u) = -∇p + μ∇²u + f',
        'y': h * 0.12,
        'x': w * 0.06,
        'color': const Color(0xFF38BDF8),
      },
      {
        'text': 'iħ (∂Ψ/∂t) = [-ħ²/2m ∇² + V(x,y,z)] Ψ',
        'y': h * 0.28,
        'x': w * 0.12,
        'color': const Color(0xFF00FF9D),
      },
      {
        'text': '∇f(x,y,z,t) = (∂f/∂x)i + (∂f/∂y)j + (∂f/∂z)k',
        'y': h * 0.45,
        'x': w * 0.05,
        'color': const Color(0xFFFACC15),
      },
      {
        'text': 'f(x,y) = (1/2πσ_x σ_y) e^(-1/2[(x/σ_x)²+(y/σ_y)²])',
        'y': h * 0.62,
        'x': w * 0.04,
        'color': const Color(0xFFC084FC),
      },
      {
        'text': '∇ × B = μ₀ J + μ₀ ε₀ (∂E/∂t)',
        'y': h * 0.78,
        'x': w * 0.10,
        'color': const Color(0xFF38BDF8),
      },
      {
        'text': '∬_R f(x,y) dx dy = lim ∑ f(x_i, y_j) ΔA',
        'y': h * 0.91,
        'x': w * 0.08,
        'color': const Color(0xFF00FF9D),
      },
    ];

    for (int i = 0; i < multiVarFormulas.length; i++) {
      final item = multiVarFormulas[i];
      final text = item['text'] as String;
      final posY = item['y'] as double;
      final posX = item['x'] as double;
      final color = item['color'] as Color;

      // Floating sine wave animation per formula
      final floatX = math.sin(orbitProgress * 2 * math.pi + i) * 6.0;
      final floatY = math.cos(orbitProgress * 2 * math.pi * 0.7 + i * 1.5) * 4.0;
      final opacity = 0.35 + math.sin(orbitProgress * 2 * math.pi * 0.5 + i) * 0.15;

      textPainter.text = TextSpan(
        text: text,
        style: GoogleFonts.outfit(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: opacity.clamp(0.2, 0.55)),
          letterSpacing: 0.8,
          shadows: [
            Shadow(
              color: color.withValues(alpha: opacity * 0.6),
              blurRadius: 8,
            ),
          ],
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(posX + floatX, posY + floatY));
    }
  }

  // ── 3D Terrain Island Pod Under Node Disc ──────────────────────────────────
  void _drawTerrainIslandPod(Canvas canvas, Offset pos, int level) {
    Color podColor;
    Color rimColor;

    if (level > 28) {
      podColor = const Color(0xFF0C2054).withValues(alpha: 0.45);
      rimColor = const Color(0xFF38BDF8).withValues(alpha: 0.60);
    } else if (level > 14) {
      podColor = const Color(0xFF043828).withValues(alpha: 0.50);
      rimColor = const Color(0xFF34D399).withValues(alpha: 0.60);
    } else {
      podColor = const Color(0xFF4C0F17).withValues(alpha: 0.50);
      rimColor = const Color(0xFFF87171).withValues(alpha: 0.60);
    }

    // Elliptical 3D Ground Pod Shadow
    canvas.drawOval(
      Rect.fromCenter(center: pos.translate(0, 10), width: 96, height: 46),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Elliptical 3D Ground Pod Base
    canvas.drawOval(
      Rect.fromCenter(center: pos, width: 88, height: 42),
      Paint()..color = podColor,
    );

    // Glowing Concentric Tech Rings
    canvas.drawOval(
      Rect.fromCenter(center: pos, width: 88, height: 42),
      Paint()
        ..color = rimColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    canvas.drawOval(
      Rect.fromCenter(center: pos, width: 72, height: 34),
      Paint()
        ..color = rimColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  // ── Glowing Cyber Connecting Energy Path ───────────────────────────────────
  void _drawGlowingEnergyPath(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(nodeOffsets[0].dx, nodeOffsets[0].dy);

    for (int i = 0; i < nodeOffsets.length - 1; i++) {
      final p1 = nodeOffsets[i];
      final p2 = nodeOffsets[i + 1];
      final controlY = (p1.dy + p2.dy) / 2;

      path.cubicTo(p1.dx, controlY, p2.dx, controlY, p2.dx, p2.dy);
    }

    // Connect Highest Level Node to Apex Infinity Portal
    if (infiniteOffset != null && nodeOffsets.isNotEmpty) {
      final pApex = nodeOffsets.last;
      final controlY = (pApex.dy + infiniteOffset!.dy) / 2;
      path.cubicTo(pApex.dx, controlY, infiniteOffset!.dx, controlY, infiniteOffset!.dx, infiniteOffset!.dy);
    }

    // 1. Broad Neon Ambient Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00FF9D).withValues(alpha: 0.40 + pulseValue * 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(path, glowPaint);

    // 2. Secondary Cyan Glow
    final cyanGlowPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(path, cyanGlowPaint);

    // 3. Dotted Dashed Line
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
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round;

    final pathCore = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(dottedPath, pathLine);
    canvas.drawPath(dottedPath, pathCore);

    // 4. Moving Energy Pulse Packet Travelling Along the Path
    for (final metric in metrics) {
      final pulseDistance = (orbitProgress * metric.length) % metric.length;
      final tangent = metric.getTangentForOffset(pulseDistance);
      if (tangent != null) {
        // Glowing Energy Particle travelling on wire
        canvas.drawCircle(
          tangent.position,
          7.5,
          Paint()
            ..color = const Color(0xFF00F0FF).withValues(alpha: 0.85)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.drawCircle(
          tangent.position,
          3.5,
          Paint()..color = Colors.white,
        );
      }
    }
  }

  // ── Snowy Mountain Peak Landmark Artwork ──────────────────────────────────
  void _drawCyberMountainPeak(Canvas canvas, Offset pos, bool alignRight) {
    final offsetX = alignRight ? pos.dx + 65 : pos.dx - 115;
    final offsetY = pos.dy - 22;

    // Mountain Left Facet
    final leftFacet = Path()
      ..moveTo(offsetX, offsetY + 65)
      ..lineTo(offsetX + 35, offsetY - 38)
      ..lineTo(offsetX + 35, offsetY + 65)
      ..close();

    canvas.drawPath(
      leftFacet,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF0F172A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(offsetX, offsetY - 38, 35, 103)),
    );

    // Mountain Right Facet
    final rightFacet = Path()
      ..moveTo(offsetX + 35, offsetY - 38)
      ..lineTo(offsetX + 72, offsetY + 65)
      ..lineTo(offsetX + 35, offsetY + 65)
      ..close();

    canvas.drawPath(
      rightFacet,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF050B18)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(offsetX + 35, offsetY - 38, 37, 103)),
    );

    // Snow Cap Glowing Tip
    final snowCap = Path()
      ..moveTo(offsetX + 35, offsetY - 38)
      ..lineTo(offsetX + 22, offsetY + 2)
      ..lineTo(offsetX + 35, offsetY - 3)
      ..lineTo(offsetX + 48, offsetY + 5)
      ..close();

    canvas.drawPath(
      snowCap,
      Paint()
        ..color = const Color(0xFFBAE6FD)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1),
    );
  }

  // ── Emerald Pine Grove Landmark Artwork ───────────────────────────────────
  void _drawCyberPineGrove(Canvas canvas, Offset pos) {
    final leftX = pos.dx - 90;
    final rightX = pos.dx + 68;
    final y = pos.dy + 4;

    _drawPine(canvas, Offset(leftX, y), 38, const Color(0xFF059669));
    _drawPine(canvas, Offset(leftX - 16, y + 10), 28, const Color(0xFF047857));
    _drawPine(canvas, Offset(rightX, y), 42, const Color(0xFF10B981));
    _drawPine(canvas, Offset(rightX + 18, y + 12), 30, const Color(0xFF059669));
  }

  void _drawPine(Canvas canvas, Offset bottom, double h, Color c) {
    final w = h * 0.46;
    final p = Path()
      ..moveTo(bottom.dx, bottom.dy - h)
      ..lineTo(bottom.dx - w / 2, bottom.dy)
      ..lineTo(bottom.dx + w / 2, bottom.dy)
      ..close();
    canvas.drawPath(p, Paint()..color = c);
  }

  // ── Volcanic Lava Crag Landmark Artwork ───────────────────────────────────
  void _drawVolcanicCrag(Canvas canvas, Offset pos, bool alignRight) {
    final offsetX = alignRight ? pos.dx + 65 : pos.dx - 105;
    final offsetY = pos.dy - 12;

    final vPath = Path()
      ..moveTo(offsetX, offsetY + 55)
      ..lineTo(offsetX + 28, offsetY - 28)
      ..lineTo(offsetX + 58, offsetY + 55)
      ..close();

    canvas.drawPath(
      vPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFF1C0508)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(offsetX, offsetY - 28, 58, 83)),
    );

    // Glowing Lava Stream Vein
    final lavaPath = Path()
      ..moveTo(offsetX + 28, offsetY - 28)
      ..lineTo(offsetX + 24, offsetY + 12)
      ..lineTo(offsetX + 32, offsetY + 38);

    canvas.drawPath(
      lavaPath,
      Paint()
        ..color = const Color(0xFFEF4444)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2),
    );
  }

  // ── Depth of Field Floating Particles ─────────────────────────────────────
  void _drawDepthParticles(Canvas canvas, Size size) {
    const pCount = 36;
    for (int i = 0; i < pCount; i++) {
      final seedX = (i * 127.31) % 1.0;
      final seedY = (i * 83.17) % 1.0;
      final speed = 0.2 + ((i * 11.3) % 0.6);
      final depth = (i % 3) + 1; // 1: distant, 2: mid, 3: foreground bokeh

      final curY = (seedY - (orbitProgress * speed)) % 1.0;
      final wobble = math.sin((orbitProgress * 2 * math.pi * speed) + i) * 18;
      final px = (seedX * size.width) + wobble;
      final py = curY * size.height;

      final radius = depth == 1 ? 1.5 : (depth == 2 ? 2.8 : 5.0);
      final alpha = depth == 1 ? 0.15 : (depth == 2 ? 0.35 : 0.65);
      final color = (i % 2 == 0 ? const Color(0xFF00F0FF) : const Color(0xFF00FF9D))
          .withValues(alpha: alpha);

      if (depth == 3) {
        // Foreground particle with camera bokeh blur
        canvas.drawCircle(
          Offset(px, py),
          radius * 2.2,
          Paint()
            ..color = color.withValues(alpha: 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }

      canvas.drawCircle(Offset(px, py), radius, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant WorldMapTerrainPainter oldDelegate) => true;
}

/// Standalone or embedded World Map Content View
class WorldMapContentView extends StatelessWidget {
  final int totalLevels;
  final int currentLevel;
  final GameState state;
  final double pulseValue;
  final double orbitProgress;
  final Function(int level)? onSelectLevel;
  final ScrollController? scrollController;
  final double? waveWidth;

  const WorldMapContentView({
    super.key,
    required this.totalLevels,
    required this.currentLevel,
    required this.state,
    required this.pulseValue,
    required this.orbitProgress,
    this.onSelectLevel,
    this.scrollController,
    this.waveWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const nodeSpacing = 135.0;
        const bottomPadding = 105.0;
        const portalSpacing = 120.0;
        const topPadding = 90.0;
        final totalHeight = (totalLevels - 1) * nodeSpacing + portalSpacing + topPadding + bottomPadding;

        final nodeOffsets = computeWorldMapNodeOffsets(
          totalLevels: totalLevels,
          width: width,
          totalHeight: totalHeight,
          nodeSpacing: nodeSpacing,
          waveWidth: waveWidth,
          bottomPadding: bottomPadding,
        );

        final infiniteOffset = Offset(width / 2, topPadding);

        final mapContent = SizedBox(
          width: width,
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Terrain Canvas Painter (Math Graph Grid, Landforms & Dotted Path)
              Positioned.fill(
                child: CustomPaint(
                  painter: WorldMapTerrainPainter(
                    totalLevels: totalLevels,
                    nodeOffsets: nodeOffsets,
                    pulseValue: pulseValue,
                    orbitProgress: orbitProgress,
                    currentLevel: currentLevel,
                    infiniteOffset: infiniteOffset,
                  ),
                ),
              ),

              // 2. Level Nodes with Atomic Orbital Animations (Centered at nodeOffsets[i])
              for (int i = 0; i < totalLevels; i++) ...[
                Positioned(
                  left: nodeOffsets[i].dx - 70,
                  top: nodeOffsets[i].dy - 70,
                  child: AtomicOrbitalNodeWidget(
                    level: i + 1,
                    currentLevel: currentLevel,
                    stars: state.levelProgress[state.selectedMode]?[i + 1]?.stars ??
                        (i + 1 < currentLevel ? 3 : 0),
                    pulseValue: pulseValue,
                    orbitProgress: orbitProgress,
                    onTap: onSelectLevel != null ? () => onSelectLevel!(i + 1) : null,
                  ),
                ),
              ],

              // 3. Start Base Marker above Level 1 (avoiding collision with stars below)
              if (nodeOffsets.isNotEmpty) ...[
                Positioned(
                  left: nodeOffsets[0].dx - 48,
                  top: nodeOffsets[0].dy - 56,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF9D).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF00FF9D).withValues(alpha: 0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00FF9D).withValues(alpha: 0.25),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: Color(0xFF00FF9D),
                          size: 11,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'START BASE',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 8.0,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: Color(0xFF00FF9D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // 4. Infinite Portal Node at Top
              Positioned(
                left: infiniteOffset.dx - 42,
                top: infiniteOffset.dy - 44,
                child: GestureDetector(
                  onTap: onSelectLevel != null ? () => onSelectLevel!(currentLevel) : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'APEX REALM',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: Color(0xFF00F0FF),
                          ),
                        ),
                      ),
                      Container(
                        width: 66,
                        height: 66,
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        if (scrollController != null) {
          return SingleChildScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            child: mapContent,
          );
        }

        return mapContent;
      },
    );
  }
}
