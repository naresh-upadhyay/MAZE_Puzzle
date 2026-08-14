import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A high-performance interactive cybernetic labyrinth background with:
/// - Breathing cosmic nebulae gradients
/// - High-tech coordinate maze grid with intersection nodes
/// - Autonomous glowing laser path runners with luminous comet tails
/// - Floating depth-of-field stardust and embers
/// - Interactive touch ripples and spark bursts on tap/drag
class CyberLabyrinthBackground extends StatefulWidget {
  final Widget child;
  final bool enableInteractiveSparks;
  final bool showGrid;
  final bool showLaserRunners;
  final bool showParticles;
  final Color? primaryGlowColor;

  const CyberLabyrinthBackground({
    super.key,
    required this.child,
    this.enableInteractiveSparks = true,
    this.showGrid = true,
    this.showLaserRunners = true,
    this.showParticles = true,
    this.primaryGlowColor,
  });

  @override
  State<CyberLabyrinthBackground> createState() => _CyberLabyrinthBackgroundState();
}

class _CyberLabyrinthBackgroundState extends State<CyberLabyrinthBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  final List<_TouchSpark> _touchSparks = [];
  final List<_TouchRipple> _touchRipples = [];
  final math.Random _rng = math.Random(42);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _spawnTouchEffects(Offset position) {
    if (!widget.enableInteractiveSparks) return;

    final primaryGlow = widget.primaryGlowColor ?? AppTheme.primaryGlow;
    final colors = [
      primaryGlow,
      AppTheme.secondaryGlow,
      AppTheme.accentPink,
      AppTheme.accentGold,
      AppTheme.accentBlue,
    ];

    // Spawn expanding ripple
    _touchRipples.add(_TouchRipple(
      center: position,
      createdAt: DateTime.now(),
      color: colors[_rng.nextInt(colors.length)],
    ));

    // Spawn spark particles
    const sparkCount = 14;
    for (int i = 0; i < sparkCount; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = 40.0 + _rng.nextDouble() * 110.0;
      final color = colors[_rng.nextInt(colors.length)];
      final size = 2.0 + _rng.nextDouble() * 3.5;

      _touchSparks.add(_TouchSpark(
        position: position,
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        color: color,
        maxLife: 0.6 + _rng.nextDouble() * 0.5,
        size: size,
        createdAt: DateTime.now(),
      ));
    }

    // Keep spark buffer under control
    if (_touchSparks.length > 80) {
      _touchSparks.removeRange(0, _touchSparks.length - 80);
    }
    if (_touchRipples.length > 10) {
      _touchRipples.removeRange(0, _touchRipples.length - 10);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _spawnTouchEffects(e.localPosition),
      onPointerMove: (e) {
        if (_rng.nextDouble() < 0.35) {
          _spawnTouchEffects(e.localPosition);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Deep Space Cosmic Base
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF03050F),
                  Color(0xFF070B22),
                  Color(0xFF040614),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 2. Animated Custom Canvas (Nebula + Grid + Laser Runners + Stardust + Touch Sparks)
          AnimatedBuilder(
            animation: _animCtrl,
            builder: (context, _) {
              final now = DateTime.now();

              // Prune old sparks
              _touchSparks.removeWhere((s) =>
                  now.difference(s.createdAt).inMilliseconds / 1000.0 >= s.maxLife);

              // Prune old ripples
              _touchRipples.removeWhere((r) =>
                  now.difference(r.createdAt).inMilliseconds / 1000.0 >= 0.85);

              return CustomPaint(
                painter: _CyberLabyrinthPainter(
                  progress: _animCtrl.value,
                  showGrid: widget.showGrid,
                  showLaserRunners: widget.showLaserRunners,
                  showParticles: widget.showParticles,
                  primaryGlow: widget.primaryGlowColor ?? AppTheme.primaryGlow,
                  touchSparks: List.unmodifiable(_touchSparks),
                  touchRipples: List.unmodifiable(_touchRipples),
                  now: now,
                ),
                size: Size.infinite,
              );
            },
          ),

          // 3. Radial Ambient Vignette for Screen Depth
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.25,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Foreground Content
          widget.child,
        ],
      ),
    );
  }
}

class _TouchSpark {
  final Offset position;
  final Offset velocity;
  final Color color;
  final double maxLife;
  final double size;
  final DateTime createdAt;

  _TouchSpark({
    required this.position,
    required this.velocity,
    required this.color,
    required this.maxLife,
    required this.size,
    required this.createdAt,
  });
}

class _TouchRipple {
  final Offset center;
  final DateTime createdAt;
  final Color color;

  _TouchRipple({
    required this.center,
    required this.createdAt,
    required this.color,
  });
}

class _CyberLabyrinthPainter extends CustomPainter {
  final double progress;
  final bool showGrid;
  final bool showLaserRunners;
  final bool showParticles;
  final Color primaryGlow;
  final List<_TouchSpark> touchSparks;
  final List<_TouchRipple> touchRipples;
  final DateTime now;

  _CyberLabyrinthPainter({
    required this.progress,
    required this.showGrid,
    required this.showLaserRunners,
    required this.showParticles,
    required this.primaryGlow,
    required this.touchSparks,
    required this.touchRipples,
    required this.now,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── 1. Cosmic Breathing Nebulae ─────────────────────────────────────────
    final pulse1 = (math.sin(progress * 2 * math.pi) + 1.0) / 2.0;
    final pulse2 = (math.cos(progress * 2 * math.pi * 0.7) + 1.0) / 2.0;

    // Top-right Cyan/Green Nebula
    final nebula1 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.65, -0.65),
        radius: 0.75 + pulse1 * 0.25,
        colors: [
          primaryGlow.withValues(alpha: 0.14 + pulse1 * 0.08),
          primaryGlow.withValues(alpha: 0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), nebula1);

    // Bottom-left Purple/Magenta Nebula
    final nebula2 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.6, 0.7),
        radius: 0.85 + pulse2 * 0.2,
        colors: [
          AppTheme.accentPurple.withValues(alpha: 0.16 + pulse2 * 0.08),
          AppTheme.accentPink.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), nebula2);

    // Center Blue Glow Accent
    final nebula3 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 0.1),
        radius: 0.6,
        colors: [
          AppTheme.accentBlue.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), nebula3);

    // ── 2. High-Tech Cyber Labyrinth Coordinate Grid ────────────────────────
    if (showGrid) {
      const step = 32.0;
      const majorStep = step * 4; // 128.0

      final minorGridPaint = Paint()
        ..color = primaryGlow.withValues(alpha: 0.06)
        ..strokeWidth = 0.6;

      final majorGridPaint = Paint()
        ..color = primaryGlow.withValues(alpha: 0.14)
        ..strokeWidth = 1.0;

      final crossPaint = Paint()
        ..color = AppTheme.secondaryGlow.withValues(alpha: 0.35)
        ..strokeWidth = 1.3;

      for (double x = 0; x <= w; x += step) {
        final isMajor = (x % majorStep).abs() < 1.0;
        canvas.drawLine(Offset(x, 0), Offset(x, h), isMajor ? majorGridPaint : minorGridPaint);
      }

      for (double y = 0; y <= h; y += step) {
        final isMajor = (y % majorStep).abs() < 1.0;
        canvas.drawLine(Offset(0, y), Offset(w, y), isMajor ? majorGridPaint : minorGridPaint);
      }

      // Intersection Crosshairs & Diamond Nodes on Major Junctions
      for (double x = 0; x <= w; x += majorStep) {
        for (double y = 0; y <= h; y += majorStep) {
          const crossSize = 5.0;
          canvas.drawLine(Offset(x - crossSize, y), Offset(x + crossSize, y), crossPaint);
          canvas.drawLine(Offset(x, y - crossSize), Offset(x, y + crossSize), crossPaint);

          // Subtle pulsing node
          final nodePulse = (math.sin(progress * 4 * math.pi + (x + y)) + 1.0) / 2.0;
          canvas.drawCircle(
            Offset(x, y),
            1.8 + nodePulse * 1.2,
            Paint()..color = AppTheme.secondaryGlow.withValues(alpha: 0.4 + nodePulse * 0.4),
          );
        }
      }
    }

    // ── 3. Autonomous Laser Path Runners (Comet Laser Streaks) ─────────────
    if (showLaserRunners) {
      _drawLaserRunners(canvas, w, h);
    }

    // ── 4. Floating Atmospheric Embers / Stardust ───────────────────────────
    if (showParticles) {
      _drawAtmosphericParticles(canvas, w, h);
    }

    // ── 5. Interactive Touch Ripples & Sparks ──────────────────────────────
    _drawTouchEffects(canvas);
  }

  void _drawLaserRunners(Canvas canvas, double w, double h) {
    // Define 5 distinct intricate circuit maze trajectories
    final runners = [
      _LaserTrack(
        points: [
          Offset(w * 0.05, h * 0.15),
          Offset(w * 0.40, h * 0.15),
          Offset(w * 0.40, h * 0.32),
          Offset(w * 0.85, h * 0.32),
          Offset(w * 0.85, h * 0.52),
          Offset(w * 0.60, h * 0.52),
        ],
        speed: 0.85,
        color: primaryGlow,
        tailLength: 80.0,
      ),
      _LaserTrack(
        points: [
          Offset(w * 0.95, h * 0.22),
          Offset(w * 0.65, h * 0.22),
          Offset(w * 0.65, h * 0.44),
          Offset(w * 0.20, h * 0.44),
          Offset(w * 0.20, h * 0.68),
          Offset(w * 0.50, h * 0.68),
        ],
        speed: 1.1,
        color: AppTheme.secondaryGlow,
        tailLength: 95.0,
      ),
      _LaserTrack(
        points: [
          Offset(w * 0.10, h * 0.78),
          Offset(w * 0.45, h * 0.78),
          Offset(w * 0.45, h * 0.62),
          Offset(w * 0.80, h * 0.62),
          Offset(w * 0.80, h * 0.88),
          Offset(w * 0.95, h * 0.88),
        ],
        speed: 0.7,
        color: AppTheme.accentPink,
        tailLength: 75.0,
      ),
      _LaserTrack(
        points: [
          Offset(w * 0.15, h * 0.92),
          Offset(w * 0.55, h * 0.92),
          Offset(w * 0.55, h * 0.75),
          Offset(w * 0.88, h * 0.75),
        ],
        speed: 0.95,
        color: AppTheme.accentGold,
        tailLength: 70.0,
      ),
      _LaserTrack(
        points: [
          Offset(w * 0.08, h * 0.38),
          Offset(w * 0.28, h * 0.38),
          Offset(w * 0.28, h * 0.18),
          Offset(w * 0.78, h * 0.18),
          Offset(w * 0.78, h * 0.08),
        ],
        speed: 1.25,
        color: AppTheme.accentBlue,
        tailLength: 85.0,
      ),
    ];

    for (final runner in runners) {
      // 1. Draw static faint circuit conduit
      final conduitPath = Path();
      conduitPath.moveTo(runner.points[0].dx, runner.points[0].dy);
      for (int i = 1; i < runner.points.length; i++) {
        conduitPath.lineTo(runner.points[i].dx, runner.points[i].dy);
      }

      final conduitPaint = Paint()
        ..color = runner.color.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawPath(conduitPath, conduitPaint);

      // 2. Compute total path length
      double totalDist = 0.0;
      final segLengths = <double>[];
      for (int i = 0; i < runner.points.length - 1; i++) {
        final dist = (runner.points[i + 1] - runner.points[i]).distance;
        segLengths.add(dist);
        totalDist += dist;
      }
      if (totalDist <= 0) continue;

      // 3. Compute current head position along path
      final t = (progress * runner.speed) % 1.0;
      final currentDist = t * totalDist;

      final headPos = _getPointAlongPolyline(runner.points, segLengths, currentDist);
      if (headPos == null) continue;

      // 4. Draw glowing laser head & luminous aura
      // Outer blur bloom
      canvas.drawCircle(
        headPos,
        10.0,
        Paint()
          ..color = runner.color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Mid glow
      canvas.drawCircle(
        headPos,
        5.0,
        Paint()
          ..color = runner.color.withValues(alpha: 0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // Bright white core
      canvas.drawCircle(
        headPos,
        2.2,
        Paint()..color = Colors.white,
      );

      // 5. Draw glowing laser tail segments
      const sampleCount = 10;
      for (int s = 1; s <= sampleCount; s++) {
        final tailDist = currentDist - (s / sampleCount) * runner.tailLength;
        if (tailDist < 0) continue;

        final tailPos = _getPointAlongPolyline(runner.points, segLengths, tailDist);
        if (tailPos == null) continue;

        final fraction = 1.0 - (s / sampleCount);
        final tailRadius = 1.2 + fraction * 2.2;
        final tailAlpha = fraction * 0.55;

        canvas.drawCircle(
          tailPos,
          tailRadius,
          Paint()..color = runner.color.withValues(alpha: tailAlpha),
        );
      }
    }
  }

  Offset? _getPointAlongPolyline(List<Offset> points, List<double> segLengths, double dist) {
    double accumulated = 0.0;
    for (int i = 0; i < segLengths.length; i++) {
      final segLen = segLengths[i];
      if (dist <= accumulated + segLen) {
        final segFraction = (dist - accumulated) / segLen;
        return Offset.lerp(points[i], points[i + 1], segFraction);
      }
      accumulated += segLen;
    }
    return points.last;
  }

  void _drawAtmosphericParticles(Canvas canvas, double w, double h) {
    const count = 36;
    for (int i = 0; i < count; i++) {
      final seedX = (i * 73.19) % 1.0;
      final seedY = (i * 37.43) % 1.0;
      final speed = 0.25 + ((i * 19.3) % 0.75);
      final depth = (i % 3) + 1; // 1: far bokeh, 2: mid, 3: sharp near

      final currentY = (seedY - (progress * speed)) % 1.0;
      final wobble = math.sin((progress * 2 * math.pi * speed) + i * 1.5) * 14.0;
      final px = (seedX * w) + wobble;
      final py = currentY * h;

      final radius = depth == 1 ? 1.6 : (depth == 2 ? 2.8 : 4.5);
      final alpha = depth == 1 ? 0.20 : (depth == 2 ? 0.45 : 0.80);
      final particleColor = (i % 3 == 0
              ? primaryGlow
              : (i % 3 == 1 ? AppTheme.secondaryGlow : AppTheme.accentPink))
          .withValues(alpha: alpha);

      if (depth == 3) {
        canvas.drawCircle(
          Offset(px, py),
          radius * 2.2,
          Paint()
            ..color = particleColor.withValues(alpha: 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }

      canvas.drawCircle(Offset(px, py), radius, Paint()..color = particleColor);
    }
  }

  void _drawTouchEffects(Canvas canvas) {
    // Draw expanding touch ripples
    for (final ripple in touchRipples) {
      final elapsed = now.difference(ripple.createdAt).inMilliseconds / 1000.0;
      final progress = (elapsed / 0.85).clamp(0.0, 1.0);
      final radius = 10.0 + progress * 75.0;
      final alpha = (1.0 - progress) * 0.65;

      canvas.drawCircle(
        ripple.center,
        radius,
        Paint()
          ..color = ripple.color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 * (1.0 - progress * 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // Draw spark particles
    for (final spark in touchSparks) {
      final elapsed = now.difference(spark.createdAt).inMilliseconds / 1000.0;
      final lifeFraction = (elapsed / spark.maxLife).clamp(0.0, 1.0);
      if (lifeFraction >= 1.0) continue;

      final currentPos = Offset(
        spark.position.dx + spark.velocity.dx * elapsed,
        spark.position.dy + spark.velocity.dy * elapsed + (elapsed * elapsed * 80.0), // gravity
      );

      final alpha = (1.0 - lifeFraction) * 0.9;
      final radius = spark.size * (1.0 - lifeFraction * 0.5);

      // Glow halo
      canvas.drawCircle(
        currentPos,
        radius * 2.0,
        Paint()
          ..color = spark.color.withValues(alpha: alpha * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Core
      canvas.drawCircle(
        currentPos,
        radius,
        Paint()..color = spark.color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CyberLabyrinthPainter oldDelegate) => true;
}

class _LaserTrack {
  final List<Offset> points;
  final double speed;
  final Color color;
  final double tailLength;

  _LaserTrack({
    required this.points,
    required this.speed,
    required this.color,
    required this.tailLength,
  });
}
