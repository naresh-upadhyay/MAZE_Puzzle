import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// A state-of-the-art, highly aesthetic cybernetic mathematical graph background.
///
/// Features:
/// - Deep space cosmic gradient with ambient glowing nebulae
/// - Cartesian Coordinate Grid with axis tick marks (-2π, -π, 0, π, 2π) & origin crosshairs
/// - Animated Parametric Curves (Lissajous knot figures & Logarithmic Golden Spirals)
/// - Multi-Harmonic Fourier & Standing Sine Waveforms with traveling comet runners
/// - Floating Mathematical Formulas & Equations (Euler's identity, Fourier, Golden ratio, Maxwell)
/// - Interactive Calculus Touch Dynamics (Tangent slope vectors, derivative ripple rings, spark bursts)
/// - Depth-of-Field atmospheric stardust embers & vignette
class MathGraphBackground extends StatefulWidget {
  final Widget child;
  final bool showGrid;
  final bool showWave;
  final bool showParametricCurves;
  final bool showFormulas;
  final bool showParticles;
  final bool enableInteractiveSparks;
  final double gridOpacity;
  final Color? primaryGlowColor;

  const MathGraphBackground({
    super.key,
    required this.child,
    this.showGrid = true,
    this.showWave = true,
    this.showParametricCurves = true,
    this.showFormulas = true,
    this.showParticles = true,
    this.enableInteractiveSparks = true,
    this.gridOpacity = 0.25,
    this.primaryGlowColor,
  });

  @override
  State<MathGraphBackground> createState() => _MathGraphBackgroundState();
}

class _MathGraphBackgroundState extends State<MathGraphBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  final List<_MathTouchSpark> _touchSparks = [];
  final List<_MathTangentEffect> _tangentEffects = [];
  final math.Random _rng = math.Random(1337);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _handleTouch(Offset localPos) {
    if (!widget.enableInteractiveSparks) return;

    // Ignore touches over the TAP TO START button zone to keep the button completely static
    final mediaQuery = MediaQuery.maybeOf(context);
    final size = mediaQuery?.size ?? const Size(360, 640);
    final buttonYMin = size.height * 0.58;
    final buttonYMax = size.height * 0.74;
    final buttonXMin = size.width * 0.12;
    final buttonXMax = size.width * 0.88;

    if (localPos.dy >= buttonYMin &&
        localPos.dy <= buttonYMax &&
        localPos.dx >= buttonXMin &&
        localPos.dx <= buttonXMax) {
      return;
    }

    final glowColor = widget.primaryGlowColor ?? AppTheme.primaryGlow;
    final colors = [
      glowColor,
      AppTheme.secondaryGlow,
      AppTheme.accentPink,
      AppTheme.accentGold,
      AppTheme.accentPurple,
    ];

    // Spawn Tangent Line Vector Effect
    final angle = (_rng.nextDouble() - 0.5) * math.pi;
    final slope = math.tan(angle);
    _tangentEffects.add(_MathTangentEffect(
      position: localPos,
      slope: slope,
      color: colors[_rng.nextInt(colors.length)],
      createdAt: DateTime.now(),
    ));

    // Spawn Spark Burst Particles
    const count = 16;
    for (int i = 0; i < count; i++) {
      final sparkAngle = _rng.nextDouble() * 2 * math.pi;
      final speed = 50.0 + _rng.nextDouble() * 120.0;
      final c = colors[_rng.nextInt(colors.length)];

      _touchSparks.add(_MathTouchSpark(
        position: localPos,
        velocity: Offset(math.cos(sparkAngle) * speed, math.sin(sparkAngle) * speed),
        color: c,
        maxLife: 0.6 + _rng.nextDouble() * 0.4,
        size: 2.0 + _rng.nextDouble() * 3.0,
        createdAt: DateTime.now(),
      ));
    }

    if (_touchSparks.length > 90) {
      _touchSparks.removeRange(0, _touchSparks.length - 90);
    }
    if (_tangentEffects.length > 8) {
      _tangentEffects.removeRange(0, _tangentEffects.length - 8);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _handleTouch(e.localPosition),
      onPointerMove: (e) {
        if (_rng.nextDouble() < 0.4) {
          _handleTouch(e.localPosition);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Deep Space Cosmic Base Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF02040D),
                  Color(0xFF06091E),
                  Color(0xFF030514),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 2. Animated Mathematical Custom Canvas
          AnimatedBuilder(
            animation: _animCtrl,
            builder: (context, _) {
              final now = DateTime.now();

              _touchSparks.removeWhere((s) =>
                  now.difference(s.createdAt).inMilliseconds / 1000.0 >= s.maxLife);
              _tangentEffects.removeWhere((t) =>
                  now.difference(t.createdAt).inMilliseconds / 1000.0 >= 0.8);

              return CustomPaint(
                painter: _AestheticMathPainter(
                  progress: _animCtrl.value,
                  showGrid: widget.showGrid,
                  showWave: widget.showWave,
                  showParametricCurves: widget.showParametricCurves,
                  showFormulas: widget.showFormulas,
                  showParticles: widget.showParticles,
                  gridOpacity: widget.gridOpacity,
                  glowColor: widget.primaryGlowColor ?? AppTheme.secondaryGlow,
                  primaryGlow: AppTheme.primaryGlow,
                  touchSparks: List.unmodifiable(_touchSparks),
                  tangentEffects: List.unmodifiable(_tangentEffects),
                  now: now,
                ),
                size: Size.infinite,
              );
            },
          ),

          // 3. Radial Vignette Frame
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.60),
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

class _MathTouchSpark {
  final Offset position;
  final Offset velocity;
  final Color color;
  final double maxLife;
  final double size;
  final DateTime createdAt;

  _MathTouchSpark({
    required this.position,
    required this.velocity,
    required this.color,
    required this.maxLife,
    required this.size,
    required this.createdAt,
  });
}

class _MathTangentEffect {
  final Offset position;
  final double slope;
  final Color color;
  final DateTime createdAt;

  _MathTangentEffect({
    required this.position,
    required this.slope,
    required this.color,
    required this.createdAt,
  });
}

class _AestheticMathPainter extends CustomPainter {
  final double progress;
  final bool showGrid;
  final bool showWave;
  final bool showParametricCurves;
  final bool showFormulas;
  final bool showParticles;
  final double gridOpacity;
  final Color glowColor;
  final Color primaryGlow;
  final List<_MathTouchSpark> touchSparks;
  final List<_MathTangentEffect> tangentEffects;
  final DateTime now;

  _AestheticMathPainter({
    required this.progress,
    required this.showGrid,
    required this.showWave,
    required this.showParametricCurves,
    required this.showFormulas,
    required this.showParticles,
    required this.gridOpacity,
    required this.glowColor,
    required this.primaryGlow,
    required this.touchSparks,
    required this.tangentEffects,
    required this.now,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;
    final center = Offset(w / 2, h / 2);

    // ── 1. Breathing Cosmic Nebulae ──────────────────────────────────────────
    _drawNebulae(canvas, w, h);

    // ── 2. Cartesian Coordinate Grid & Axes with Math Labels ───────────────
    if (showGrid) {
      _drawCartesianGrid(canvas, w, h, center);
    }

    // ── 3. Parametric Lissajous & Logarithmic Spirals ───────────────────────
    if (showParametricCurves) {
      _drawParametricCurves(canvas, w, h, center);
    }

    // ── 4. Fourier Harmonics & Sine Waveforms ──────────────────────────────
    if (showWave) {
      _drawFourierWaveforms(canvas, w, h);
    }

    // ── 5. Floating Mathematical Formulas & Equations ───────────────────────
    if (showFormulas) {
      _drawFloatingMathFormulas(canvas, w, h);
    }

    // ── 6. Atmospheric Stardust Embers ──────────────────────────────────────
    if (showParticles) {
      _drawAtmosphericEmbers(canvas, w, h);
    }

    // ── 7. Interactive Tangents & Spark Bursts ─────────────────────────────
    _drawInteractiveTouchFX(canvas);
  }

  void _drawNebulae(Canvas canvas, double w, double h) {
    final p1 = (math.sin(progress * 2 * math.pi) + 1.0) / 2.0;
    final p2 = (math.cos(progress * 2 * math.pi * 0.6) + 1.0) / 2.0;

    final n1 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.7, -0.6),
        radius: 0.8 + p1 * 0.2,
        colors: [
          glowColor.withValues(alpha: 0.16 + p1 * 0.06),
          glowColor.withValues(alpha: 0.03),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), n1);

    final n2 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.65, 0.65),
        radius: 0.85 + p2 * 0.25,
        colors: [
          primaryGlow.withValues(alpha: 0.14 + p2 * 0.06),
          AppTheme.accentPurple.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), n2);
  }

  void _drawCartesianGrid(Canvas canvas, double w, double h, Offset center) {
    const spacing = 32.0;
    const majorSpacing = spacing * 4; // 128.0

    final minorPaint = Paint()
      ..color = glowColor.withValues(alpha: gridOpacity * 0.25)
      ..strokeWidth = 0.5;

    final majorPaint = Paint()
      ..color = glowColor.withValues(alpha: gridOpacity * 0.70)
      ..strokeWidth = 0.9;

    final axisPaint = Paint()
      ..color = primaryGlow.withValues(alpha: gridOpacity * 1.4)
      ..strokeWidth = 1.6;

    final crossPaint = Paint()
      ..color = AppTheme.accentGold.withValues(alpha: 0.55)
      ..strokeWidth = 1.2;

    // Vertical Lines
    for (double x = 0; x <= w; x += spacing) {
      final isMajor = (x % majorSpacing).abs() < 1.0;
      canvas.drawLine(Offset(x, 0), Offset(x, h), isMajor ? majorPaint : minorPaint);
    }

    // Horizontal Lines
    for (double y = 0; y <= h; y += spacing) {
      final isMajor = (y % majorSpacing).abs() < 1.0;
      canvas.drawLine(Offset(0, y), Offset(w, y), isMajor ? majorPaint : minorPaint);
    }

    // Major Axes (X & Y axes running through origin / center)
    canvas.drawLine(Offset(0, center.dy), Offset(w, center.dy), axisPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, h), axisPaint);

    // Axis Tick Marks & Labels (-2π, -π, 0, π, 2π)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final axisLabels = [
      {'val': -2 * math.pi, 'text': '-2π'},
      {'val': -math.pi, 'text': '-π'},
      {'val': 0.0, 'text': '0'},
      {'val': math.pi, 'text': 'π'},
      {'val': 2 * math.pi, 'text': '2π'},
    ];

    const unitScale = 64.0; // 64 pixels per π
    for (final item in axisLabels) {
      final val = item['val'] as double;
      final text = item['text'] as String;

      final posX = center.dx + (val / math.pi) * unitScale;
      if (posX >= 0 && posX <= w) {
        // Tick Mark
        canvas.drawLine(
          Offset(posX, center.dy - 4),
          Offset(posX, center.dy + 4),
          axisPaint,
        );

        // Text Label
        textPainter.text = TextSpan(
          text: text,
          style: GoogleFonts.orbitron(
            fontSize: 9,
            color: primaryGlow.withValues(alpha: 0.65),
            fontWeight: FontWeight.w600,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(posX - textPainter.width / 2, center.dy + 6));
      }

      final posY = center.dy - (val / math.pi) * unitScale;
      if (posY >= 0 && posY <= h && val != 0.0) {
        canvas.drawLine(
          Offset(center.dx - 4, posY),
          Offset(center.dx + 4, posY),
          axisPaint,
        );
        textPainter.text = TextSpan(
          text: text,
          style: GoogleFonts.orbitron(
            fontSize: 9,
            color: primaryGlow.withValues(alpha: 0.65),
            fontWeight: FontWeight.w600,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(center.dx + 8, posY - textPainter.height / 2));
      }
    }

    // Origin Glowing Crosshair (0,0)
    canvas.drawCircle(
      center,
      4.0,
      Paint()
        ..color = AppTheme.accentGold.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(center, 1.8, Paint()..color = Colors.white);

    // Major Intersection Crosshairs
    for (double x = 0; x <= w; x += majorSpacing) {
      for (double y = 0; y <= h; y += majorSpacing) {
        const cLen = 4.0;
        canvas.drawLine(Offset(x - cLen, y), Offset(x + cLen, y), crossPaint);
        canvas.drawLine(Offset(x, y - cLen), Offset(x, y + cLen), crossPaint);
      }
    }
  }

  void _drawParametricCurves(Canvas canvas, double w, double h, Offset center) {
    final t = progress * 2 * math.pi;

    // ── 1. Parametric Lissajous Knot Figure (x = A sin(3t + delta), y = B sin(2t)) ─
    final lissajousPath = Path();
    final lissCenter = Offset(w * 0.78, h * 0.28);
    const lissScaleX = 75.0;
    const lissScaleY = 55.0;
    final delta = t * 0.8;

    bool first = true;
    for (double theta = 0; theta <= 2 * math.pi; theta += 0.05) {
      final lx = lissCenter.dx + math.sin(3 * theta + delta) * lissScaleX;
      final ly = lissCenter.dy + math.sin(2 * theta) * lissScaleY;
      if (first) {
        lissajousPath.moveTo(lx, ly);
        first = false;
      } else {
        lissajousPath.lineTo(lx, ly);
      }
    }

    final lissGlowPaint = Paint()
      ..color = AppTheme.accentPink.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(lissajousPath, lissGlowPaint);

    final lissLinePaint = Paint()
      ..color = AppTheme.accentPink.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(lissajousPath, lissLinePaint);

    // Traveling spark runner on Lissajous figure
    final runnerTheta = (progress * 4 * math.pi) % (2 * math.pi);
    final rx = lissCenter.dx + math.sin(3 * runnerTheta + delta) * lissScaleX;
    final ry = lissCenter.dy + math.sin(2 * runnerTheta) * lissScaleY;
    final runnerPos = Offset(rx, ry);

    canvas.drawCircle(
      runnerPos,
      6.0,
      Paint()
        ..color = AppTheme.accentPink
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(runnerPos, 2.2, Paint()..color = Colors.white);

    // ── 2. Logarithmic Golden Ratio Spiral (r = a * e^(b * theta)) ──────────
    final spiralPath = Path();
    final spiralCenter = Offset(w * 0.22, h * 0.72);
    const a = 3.5;
    const b = 0.14;

    first = true;
    for (double theta = 0; theta <= 4.5 * math.pi; theta += 0.08) {
      final r = a * math.exp(b * theta);
      final sx = spiralCenter.dx + r * math.cos(theta + t * 0.5);
      final sy = spiralCenter.dy + r * math.sin(theta + t * 0.5);
      if (first) {
        spiralPath.moveTo(sx, sy);
        first = false;
      } else {
        spiralPath.lineTo(sx, sy);
      }
    }

    final spiralGlowPaint = Paint()
      ..color = AppTheme.accentPurple.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(spiralPath, spiralGlowPaint);

    final spiralLinePaint = Paint()
      ..color = AppTheme.accentPurple.withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawPath(spiralPath, spiralLinePaint);
  }

  void _drawFourierWaveforms(Canvas canvas, double w, double h) {
    final phase = progress * 2 * math.pi;

    // ── 1. Primary Composite Sine Wave ─────────────────────────────────────
    final wavePath1 = Path();
    final waveY1 = h * 0.44;
    wavePath1.moveTo(0, waveY1);

    for (double x = 0; x <= w; x += 5) {
      final nx = x / w;
      final y = waveY1 +
          math.sin(nx * 4 * math.pi + phase) * 28 +
          math.cos(nx * 8 * math.pi - phase * 1.5) * 12 +
          math.sin(nx * 2 * math.pi + phase * 0.5) * 8;
      wavePath1.lineTo(x, y);
    }

    final waveGlow1 = Paint()
      ..color = primaryGlow.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(wavePath1, waveGlow1);

    final waveLine1 = Paint()
      ..color = primaryGlow.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(wavePath1, waveLine1);

    // Traveling Comet Head on Wave 1
    final cometX = (progress * 1.2 % 1.0) * w;
    final cometNX = cometX / w;
    final cometY = waveY1 +
        math.sin(cometNX * 4 * math.pi + phase) * 28 +
        math.cos(cometNX * 8 * math.pi - phase * 1.5) * 12 +
        math.sin(cometNX * 2 * math.pi + phase * 0.5) * 8;
    final cometPos = Offset(cometX, cometY);

    canvas.drawCircle(
      cometPos,
      9.0,
      Paint()
        ..color = primaryGlow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(cometPos, 3.0, Paint()..color = Colors.white);

    // ── 2. Fourier Square Wave Harmonic Series Approximation ───────────────
    final wavePath2 = Path();
    final waveY2 = h * 0.76;
    wavePath2.moveTo(0, waveY2);

    for (double x = 0; x <= w; x += 4) {
      final nx = x / w;
      double yVal = 0.0;
      // Sum first 4 odd harmonics: sin(kx)/k
      for (int k = 1; k <= 7; k += 2) {
        yVal += (1.0 / k) * math.sin(k * (nx * 6 * math.pi - phase));
      }
      wavePath2.lineTo(x, waveY2 + yVal * 25);
    }

    final waveLine2 = Paint()
      ..color = glowColor.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawPath(wavePath2, waveLine2);
  }

  void _drawFloatingMathFormulas(Canvas canvas, double w, double h) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final formulas = [
      {
        'text': 'e^(iπ) + 1 = 0',
        'pos': Offset(w * 0.12, h * 0.18),
        'speed': 0.3,
        'color': primaryGlow,
        'size': 13.0,
      },
      {
        'text': 'f̂(ξ) = ∫ f(x) e^(-2πi x ξ) dx',
        'pos': Offset(w * 0.55, h * 0.12),
        'speed': 0.4,
        'color': glowColor,
        'size': 12.0,
      },
      {
        'text': '∇²Ψ - (1/c²) ∂²Ψ/∂t² = 0',
        'pos': Offset(w * 0.08, h * 0.52),
        'speed': 0.25,
        'color': AppTheme.accentGold,
        'size': 11.5,
      },
      {
        'text': 'Φ = (1 + √5) / 2 ≈ 1.618',
        'pos': Offset(w * 0.62, h * 0.82),
        'speed': 0.35,
        'color': AppTheme.accentPurple,
        'size': 12.0,
      },
      {
        'text': '∫_(-∞)^(∞) e^(-x²) dx = √π',
        'pos': Offset(w * 0.15, h * 0.86),
        'speed': 0.28,
        'color': AppTheme.accentPink,
        'size': 11.5,
      },
      {
        'text': 'iħ (∂Ψ/∂t) = ĤΨ',
        'pos': Offset(w * 0.72, h * 0.48),
        'speed': 0.38,
        'color': primaryGlow,
        'size': 12.5,
      },
    ];

    for (int i = 0; i < formulas.length; i++) {
      final f = formulas[i];
      final basePos = f['pos'] as Offset;
      final speed = f['speed'] as double;
      final color = f['color'] as Color;
      final size = f['size'] as double;
      final text = f['text'] as String;

      // Floating sine oscillation physics
      final floatY = math.sin((progress * 2 * math.pi * speed) + i) * 8.0;
      final floatX = math.cos((progress * 2 * math.pi * speed * 0.7) + i) * 5.0;
      final opacity = 0.35 + math.sin((progress * 2 * math.pi * 0.5) + i * 1.5) * 0.20;

      textPainter.text = TextSpan(
        text: text,
        style: GoogleFonts.outfit(
          fontSize: size,
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: opacity),
          letterSpacing: 1.0,
          shadows: [
            Shadow(
              color: color.withValues(alpha: opacity * 0.7),
              blurRadius: 10,
            ),
          ],
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(basePos.dx + floatX, basePos.dy + floatY),
      );
    }
  }

  void _drawAtmosphericEmbers(Canvas canvas, double w, double h) {
    const count = 30;
    for (int i = 0; i < count; i++) {
      final seedX = (i * 89.31) % 1.0;
      final seedY = (i * 41.17) % 1.0;
      final speed = 0.2 + ((i * 13.7) % 0.6);
      final depth = (i % 3) + 1; // 1: far blur, 2: mid, 3: sharp near

      final currentY = (seedY - (progress * speed)) % 1.0;
      final wobble = math.sin((progress * 2 * math.pi * speed) + i * 1.2) * 12.0;
      final px = (seedX * w) + wobble;
      final py = currentY * h;

      // Don't draw embers over the TAP TO START button zone
      if (py >= h * 0.58 && py <= h * 0.74 && px >= w * 0.12 && px <= w * 0.88) {
        continue;
      }

      final radius = depth == 1 ? 1.5 : (depth == 2 ? 2.5 : 3.8);
      final alpha = depth == 1 ? 0.18 : (depth == 2 ? 0.40 : 0.75);
      final pColor = (i % 3 == 0
              ? primaryGlow
              : (i % 3 == 1 ? glowColor : AppTheme.accentGold))
          .withValues(alpha: alpha);

      if (depth == 3) {
        canvas.drawCircle(
          Offset(px, py),
          radius * 2.0,
          Paint()
            ..color = pColor.withValues(alpha: 0.20)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }

      canvas.drawCircle(Offset(px, py), radius, Paint()..color = pColor);
    }
  }

  void _drawInteractiveTouchFX(Canvas canvas) {
    // Tangent Vectors
    for (final t in tangentEffects) {
      final elapsed = now.difference(t.createdAt).inMilliseconds / 1000.0;
      final pFraction = (elapsed / 0.8).clamp(0.0, 1.0);
      final alpha = (1.0 - pFraction) * 0.7;
      final len = pFraction * 70.0;

      final dx = len * math.cos(math.atan(t.slope));
      final dy = len * math.sin(math.atan(t.slope));

      final tangentPaint = Paint()
        ..color = t.color.withValues(alpha: alpha)
        ..strokeWidth = 1.8 * (1.0 - pFraction * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawLine(
        Offset(t.position.dx - dx, t.position.dy - dy),
        Offset(t.position.dx + dx, t.position.dy + dy),
        tangentPaint,
      );

      // Derivative point indicator
      canvas.drawCircle(
        t.position,
        3.5 * (1.0 - pFraction * 0.4),
        Paint()..color = t.color.withValues(alpha: alpha),
      );
    }

    // Spark Particles
    for (final spark in touchSparks) {
      final elapsed = now.difference(spark.createdAt).inMilliseconds / 1000.0;
      final lifeFraction = (elapsed / spark.maxLife).clamp(0.0, 1.0);
      if (lifeFraction >= 1.0) continue;

      final currentPos = Offset(
        spark.position.dx + spark.velocity.dx * elapsed,
        spark.position.dy + spark.velocity.dy * elapsed + (elapsed * elapsed * 70.0),
      );

      final alpha = (1.0 - lifeFraction) * 0.85;
      final radius = spark.size * (1.0 - lifeFraction * 0.5);

      canvas.drawCircle(
        currentPos,
        radius * 1.8,
        Paint()
          ..color = spark.color.withValues(alpha: alpha * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      canvas.drawCircle(
        currentPos,
        radius,
        Paint()..color = spark.color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AestheticMathPainter oldDelegate) => true;
}