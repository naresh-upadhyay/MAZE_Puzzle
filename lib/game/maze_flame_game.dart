import 'dart:math' as math;
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/maze_generator.dart';

// ── Sparkle particle ──────────────────────────────────────────────────────────
class _GlowParticle {
  Offset position;
  double radius;
  double opacity;
  double vx, vy;
  final Color color;

  _GlowParticle({
    required this.position,
    required this.radius,
    required this.opacity,
    required this.vx,
    required this.vy,
    required this.color,
  });

  bool update(double dt) {
    position = Offset(position.dx + vx * dt * 60, position.dy + vy * dt * 60);
    opacity -= dt * 1.6;
    radius -= dt * 10;
    return opacity > 0 && radius > 0;
  }
}

// ── Game event callbacks ───────────────────────────────────────────────────────
typedef OnWrongPath = void Function();

class MazeFlameGame extends FlameGame with PanDetector, TapCallbacks {
  final MazeGenerator generator;
  final Color themeColor;
  final VoidCallback onWin;
  final Function(int moves) onMove;
  final OnWrongPath? onWrongPath;

  // ── Public state ──────────────────────────────────────────────────────────
  List<CellPosition> userPath = [];
  List<CellPosition> hintPath = [];
  bool isCompleted = false;
  int mistakeCount = 0;

  /// 0.0 – 1.0 progress through the solution path
  double get progressPercent {
    final total = generator.solutionPath.length;
    if (total <= 1) return 1.0;
    return (userPath.length / total).clamp(0.0, 1.0);
  }

  // ── Animation state ───────────────────────────────────────────────────────
  double _pulsePhase = 0.0;
  double _errorTimer = 0.0; // seconds remaining of red-flash error state
  double _hintTimer = 0.0; // seconds remaining for animated hint guide

  // ── Smooth Head & Touch Tracking ───────────────────────────────────────────
  Offset? _headPos; // Continuous sub-cell position along the open corridor
  Vector2? currentTouchPos; // Raw finger touch position

  // ── Particles ─────────────────────────────────────────────────────────────
  final List<_GlowParticle> _particles = [];
  final List<_GlowParticle> _winParticles = [];
  final math.Random _rng = math.Random();
  double _particleTimer = 0;

  // ── Win completion animation ───────────────────────────────────────────────
  bool _winAnimating = false;
  double _winAnimTimer = 0.0;
  double _winWaveProgress = 0.0; // 0→1 energy wave along path

  // ── Wall path cache ────────────────────────────────────────────────────────
  Path? _cachedShadowPath;
  Path? _cachedBodyPath;
  Path? _cachedHighlightPath;
  double _cachedSizeX = 0;
  double _cachedSizeY = 0;

  // ── Pre-cached static paints ───────────────────────────────────────────────
  // Floor grid
  final Paint _gridPaint = Paint()
    ..color = const Color(0x0DFFFFFF)
    ..strokeWidth = 0.8
    ..style = PaintingStyle.stroke;

  // Start / Exit markers
  final Paint _startBgPaint = Paint()
    ..color = const Color(0xFF00FF9D).withValues(alpha: 0.10);
  final Paint _exitBgPaint = Paint()
    ..color = const Color(0xFFFF2A6D).withValues(alpha: 0.12);

  // Hint
  final Paint _hintPaint = Paint()
    ..color = const Color(0xAAFFD700)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // Misc shared paints
  final Paint _sharedFill = Paint()..style = PaintingStyle.fill;
  final Paint _sharedStroke = Paint()..style = PaintingStyle.stroke;

  // ── Theme-dependent paints (set in constructor) ────────────────────────────
  late final Paint _wallShadow;
  late final Paint _wallBody;
  late final Paint _wallHighlight;

  // Trail layers (4 layers, thin, ultra-glow)
  late final Paint _trailBloom;
  late final Paint _trailGlow;
  late final Paint _trailBody;
  late final Paint _trailCore;

  // Error flash
  final Paint _trailError = Paint()
    ..color = const Color(0xFFFF3030)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // Orb cursor
  late final Paint _orbGlow;
  late final Paint _orbCore;

  // Sparkle
  late final Paint _sparklePaint;

  MazeFlameGame({
    required this.generator,
    required this.themeColor,
    required this.onWin,
    required this.onMove,
    this.onWrongPath,
  }) {
    userPath = [generator.startPos];

    // ── Wall paints ────────────────────────────────────────────────────────
    _wallShadow = Paint()
      ..color = const Color(0xFF010207)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    _wallBody = Paint()
      ..color = const Color(0xFF1A1F55) // dark navy/indigo body
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    _wallHighlight = Paint()
      ..color = const Color(0xFF2D3490) // brighter indigo bevel highlight
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    // ── Trail paints (thin, layered) ──────────────────────────────────────
    _trailBloom = Paint()
      ..color = themeColor.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _trailGlow = Paint()
      ..color = themeColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _trailBody = Paint()
      ..color = themeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _trailCore = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ── Orb cursor ────────────────────────────────────────────────────────
    _orbGlow = Paint()..color = themeColor.withValues(alpha: 0.38);
    _orbCore = Paint()..color = Colors.white;

    // ── Sparkle ───────────────────────────────────────────────────────────
    _sparklePaint = Paint()..style = PaintingStyle.fill;
  }

  @override
  Color backgroundColor() => const Color(0xFF060713);

  // ── Update (game loop) ────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);

    _pulsePhase = (_pulsePhase + dt * 3.2) % (2 * math.pi);

    // Error flash timer
    if (_errorTimer > 0) {
      _errorTimer = (_errorTimer - dt).clamp(0.0, 1.0);
    }

    // Hint timer countdown
    if (_hintTimer > 0) {
      _hintTimer -= dt;
      if (_hintTimer <= 0) {
        hintPath = [];
      }
    }

    if (size.x > 0 && size.y > 0) {
      final cw = size.x / generator.cols;
      final ch = size.y / generator.rows;
      final targetCenter = _cellCenter(userPath.last, cw, ch);

      if (currentTouchPos == null) {
        // Smoothly return head to current cell center when not dragging
        if (_headPos != null) {
          final diff = targetCenter - _headPos!;
          if (diff.distance < 1.0) {
            _headPos = targetCenter;
          } else {
            _headPos = Offset.lerp(_headPos!, targetCenter, (18.0 * dt).clamp(0.0, 1.0))!;
          }
        } else {
          _headPos = targetCenter;
        }
      }
    }

    // Sparkles while moving
    if (_headPos != null && !isCompleted && currentTouchPos != null) {
      _particleTimer += dt;
      if (_particleTimer >= 0.035) {
        _particleTimer = 0;
        _emitParticles(_headPos!, 2);
      }
    }
    _particles.retainWhere((p) => p.update(dt));

    // Win animation
    if (_winAnimating) {
      _winAnimTimer += dt;
      _winWaveProgress = (_winAnimTimer / 0.8).clamp(0.0, 1.0);
      _winParticles.retainWhere((p) => p.update(dt));
    }
  }

  // ── Wall cache ────────────────────────────────────────────────────────────
  void _buildWallsIfNeeded(double cw, double ch) {
    if (_cachedShadowPath != null && _cachedSizeX == size.x && _cachedSizeY == size.y) {
      return;
    }
    _cachedSizeX = size.x;
    _cachedSizeY = size.y;

    final shadow = Path(), body = Path(), highlight = Path();
    final cols = generator.cols, rows = generator.rows;

    final wallThick = (cw * 0.22).clamp(5.0, 16.0);
    final halfWall = wallThick / 2.0;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = generator.grid[r][c];
        final x = c * cw, y = r * ch;

        if (cell.walls.top) {
          final wy = (r == 0) ? halfWall : y;
          _seg(shadow, x, wy, x + cw, wy, dx: 2.0, dy: 2.0);
          _seg(body, x, wy, x + cw, wy);
          _seg(highlight, x, wy, x + cw, wy, dx: -0.8, dy: -0.8);
        }
        if (cell.walls.left) {
          final wx = (c == 0) ? halfWall : x;
          _seg(shadow, wx, y, wx, y + ch, dx: 2.0, dy: 2.0);
          _seg(body, wx, y, wx, y + ch);
          _seg(highlight, wx, y, wx, y + ch, dx: -0.8, dy: -0.8);
        }
        if (c == cols - 1 && cell.walls.right) {
          final wx = size.x - halfWall;
          _seg(shadow, wx, y, wx, y + ch, dx: 2.0, dy: 2.0);
          _seg(body, wx, y, wx, y + ch);
          _seg(highlight, wx, y, wx, y + ch, dx: -0.8, dy: -0.8);
        }
        if (r == rows - 1 && cell.walls.bottom) {
          final wy = size.y - halfWall;
          _seg(shadow, x, wy, x + cw, wy, dx: 2.0, dy: 2.0);
          _seg(body, x, wy, x + cw, wy);
          _seg(highlight, x, wy, x + cw, wy, dx: -0.8, dy: -0.8);
        }
      }
    }
    _cachedShadowPath = shadow;
    _cachedBodyPath = body;
    _cachedHighlightPath = highlight;
  }

  void _seg(
    Path p,
    double x1,
    double y1,
    double x2,
    double y2, {
    double dx = 0,
    double dy = 0,
  }) {
    p.moveTo(x1 + dx, y1 + dy);
    p.lineTo(x2 + dx, y2 + dy);
  }

  // ── Main render ───────────────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (size.x <= 0 || size.y <= 0) return;

    final cols = generator.cols;
    final rows = generator.rows;
    final cw = size.x / cols;
    final ch = size.y / rows;

    // Default head position if not set
    _headPos ??= _cellCenter(userPath.last, cw, ch);

    // 1. Floor grid
    for (int r = 0; r <= rows; r++) {
      canvas.drawLine(Offset(0, r * ch), Offset(size.x, r * ch), _gridPaint);
    }
    for (int c = 0; c <= cols; c++) {
      canvas.drawLine(Offset(c * cw, 0), Offset(c * cw, size.y), _gridPaint);
    }

    // 2. START cell tint (Bottom)
    canvas.drawRect(
      Rect.fromLTWH(generator.startPos.c * cw, generator.startPos.r * ch, cw, ch),
      _startBgPaint,
    );

    // 3. EXIT cell tint (Top)
    canvas.drawRect(
      Rect.fromLTWH(generator.exitPos.c * cw, generator.exitPos.r * ch, cw, ch),
      _exitBgPaint,
    );

    // 4. Thick 3D Walls
    _buildWallsIfNeeded(cw, ch);
    final wallThick = (cw * 0.22).clamp(5.0, 16.0);
    _wallShadow.strokeWidth = wallThick + 3;
    _wallBody.strokeWidth = wallThick;
    _wallHighlight.strokeWidth = (wallThick * 0.4).clamp(2.0, 6.0);

    if (_cachedShadowPath != null) canvas.drawPath(_cachedShadowPath!, _wallShadow);
    if (_cachedBodyPath != null) canvas.drawPath(_cachedBodyPath!, _wallBody);
    if (_cachedHighlightPath != null) canvas.drawPath(_cachedHighlightPath!, _wallHighlight);

    // 5. START node (animated)
    _drawStartNode(canvas, cw, ch);

    // 6. EXIT node (animated)
    _drawExitNode(canvas, cw, ch, cols, rows);

    // 7. Hint path (Animated Golden Energy Beam Guide)
    if (hintPath.isNotEmpty && _hintTimer > 0) {
      final hintOpacity = (_hintTimer / 0.8).clamp(0.0, 1.0);
      final pulse = (math.sin(_pulsePhase * 2.5) + 1) / 2;
      _hintPaint
        ..strokeWidth = (cw * 0.24).clamp(3.5, 9.0)
        ..color = const Color(0xFFFFD700).withValues(alpha: (0.40 + pulse * 0.35) * hintOpacity);
      canvas.drawPath(_buildCellPath(hintPath, cw, ch), _hintPaint);

      // Inner bright core
      _sharedStroke
        ..strokeWidth = (cw * 0.10).clamp(1.8, 4.0)
        ..color = Colors.white.withValues(alpha: (0.85 + pulse * 0.15) * hintOpacity)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(_buildCellPath(hintPath, cw, ch), _sharedStroke);
    }

    // 8. Player glowing laser beam trail
    if (userPath.isNotEmpty) {
      _drawTrail(canvas, cw, ch);
    }

    // 9. Energy orb cursor at exact corridor head position
    if (_headPos != null && !isCompleted) {
      _drawOrb(canvas, _headPos!);
    }

    // 10. Sparkle particles
    _drawParticles(canvas, _particles);

    // 11. Win animation wave + particles
    if (_winAnimating) {
      _drawWinWave(canvas, cw, ch);
      _drawParticles(canvas, _winParticles);
    }
  }

  // ── ENTRY GATE (Bottom Boundary Opening) ──────────────────────────────────
  void _drawStartNode(Canvas canvas, double cw, double ch) {
    final pulse = (math.sin(_pulsePhase) + 1) / 2;
    final center = _cellCenter(generator.startPos, cw, ch);
    final r = (cw * 0.28).clamp(4.0, 14.0);

    // Draw glowing Entry Gate Pillars on bottom boundary wall opening
    final gateX1 = generator.startPos.c * cw;
    final gateX2 = (generator.startPos.c + 1) * cw;
    final gateY = size.y;

    _sharedStroke
      ..color = const Color(0xFF00FF9D).withValues(alpha: 0.85 + pulse * 0.15)
      ..strokeWidth = 3.0;
    // Left pillar bracket
    canvas.drawLine(Offset(gateX1, gateY - 12), Offset(gateX1, gateY + 4), _sharedStroke);
    // Right pillar bracket
    canvas.drawLine(Offset(gateX2, gateY - 12), Offset(gateX2, gateY + 4), _sharedStroke);

    // Entry Threshold Glow Line
    _sharedStroke
      ..color = const Color(0xFF00FF9D).withValues(alpha: 0.35 + pulse * 0.40)
      ..strokeWidth = 4.0;
    canvas.drawLine(Offset(gateX1, gateY), Offset(gateX2, gateY), _sharedStroke);

    // Portal rings
    _sharedStroke
      ..color = const Color(0xFF00FF9D).withValues(alpha: 0.20 + pulse * 0.25)
      ..strokeWidth = 2.0 + pulse * 1.5;
    canvas.drawCircle(center, r + 4 + pulse * 4, _sharedStroke);

    _sharedStroke
      ..color = const Color(0xFF00FF9D).withValues(alpha: 0.75)
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, r, _sharedStroke);

    _sharedFill.color = const Color(0xFF00FF9D).withValues(alpha: 0.30 + pulse * 0.20);
    canvas.drawCircle(center, r * 0.55, _sharedFill);

    _drawLabel(
      canvas,
      center - Offset(0, r + 8),
      'ENTRY GATE',
      const Color(0xFF00FF9D),
      6.5 + cw * 0.03,
    );
  }

  // ── EXIT GATE (Top Boundary Opening) ──────────────────────────────────────
  void _drawExitNode(Canvas canvas, double cw, double ch, int cols, int rows) {
    final pulse = (math.sin(_pulsePhase + math.pi) + 1) / 2;
    final center = _cellCenter(generator.exitPos, cw, ch);
    final r = (cw * 0.30).clamp(5.0, 16.0);

    double boost = 0.0;
    if (userPath.isNotEmpty) {
      final last = userPath.last;
      final dr = (last.r - generator.exitPos.r).abs();
      final dc = (last.c - generator.exitPos.c).abs();
      final dist = dr + dc;
      boost = (1.0 - (dist / 4.0)).clamp(0.0, 1.0);
    }

    // Draw glowing Exit Gate Pillars on top boundary wall opening
    final gateX1 = generator.exitPos.c * cw;
    final gateX2 = (generator.exitPos.c + 1) * cw;
    const gateY = 0.0;

    _sharedStroke
      ..color = const Color(0xFFFF2A6D).withValues(alpha: 0.85 + pulse * 0.15)
      ..strokeWidth = 3.0;
    // Left pillar bracket
    canvas.drawLine(Offset(gateX1, gateY - 4), Offset(gateX1, gateY + 12), _sharedStroke);
    // Right pillar bracket
    canvas.drawLine(Offset(gateX2, gateY - 4), Offset(gateX2, gateY + 12), _sharedStroke);

    // Exit Threshold Glow Line
    _sharedStroke
      ..color = const Color(0xFFFF2A6D).withValues(alpha: 0.35 + pulse * 0.40)
      ..strokeWidth = 4.0;
    canvas.drawLine(Offset(gateX1, gateY), Offset(gateX2, gateY), _sharedStroke);

    _sharedStroke
      ..color = const Color(0xFFFF2A6D).withValues(alpha: 0.25 + pulse * 0.30 + boost * 0.25)
      ..strokeWidth = 2.5 + pulse * 2.0;
    canvas.drawCircle(center, r + 5 + pulse * 4 + boost * 6, _sharedStroke);

    _sharedStroke
      ..color = const Color(0xFFFF2A6D).withValues(alpha: 0.80 + boost * 0.20)
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, r, _sharedStroke);

    final arm = r * 0.55;
    _sharedStroke
      ..color = const Color(0xFFFF2A6D).withValues(alpha: 0.70 + boost * 0.30)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(center.dx - arm, center.dy), Offset(center.dx + arm, center.dy), _sharedStroke);
    canvas.drawLine(Offset(center.dx, center.dy - arm), Offset(center.dx, center.dy + arm), _sharedStroke);

    _sharedFill.color = const Color(0xFFFF2A6D).withValues(alpha: 0.60 + pulse * 0.40 + boost * 0.20);
    canvas.drawCircle(center, r * 0.22, _sharedFill);

    _drawLabel(
      canvas,
      center + Offset(0, r + 9),
      'EXIT GATE',
      const Color(0xFFFF2A6D),
      6.5 + cw * 0.03,
    );
  }

  // ── Trail (Smooth Continuous Path) ─────────────────────────────────────────
  void _drawTrail(Canvas canvas, double cw, double ch) {
    final trailPath = Path();

    for (int i = 0; i < userPath.length; i++) {
      final c = _cellCenter(userPath[i], cw, ch);
      if (i == 0) {
        trailPath.moveTo(c.dx, c.dy);
      } else {
        trailPath.lineTo(c.dx, c.dy);
      }
    }

    // Connect smoothly to current continuous head position
    if (_headPos != null) {
      trailPath.lineTo(_headPos!.dx, _headPos!.dy);
    }

    final bloomW = (cw * 0.55).clamp(6.0, 18.0);
    final glowW = (cw * 0.32).clamp(4.0, 12.0);
    final bodyW = (cw * 0.16).clamp(2.5, 7.0);
    final coreW = (cw * 0.06).clamp(1.0, 3.0);

    if (_errorTimer > 0.05) {
      _trailError.strokeWidth = glowW;
      _trailError.color = Color.lerp(
        const Color(0xFFFF3030),
        themeColor,
        1.0 - _errorTimer / 0.45,
      )!;
      canvas.drawPath(trailPath, _trailError);
    } else {
      _trailBloom.strokeWidth = bloomW;
      _trailGlow.strokeWidth = glowW;
      _trailBody.strokeWidth = bodyW;
      _trailCore.strokeWidth = coreW;

      canvas.drawPath(trailPath, _trailBloom);
      canvas.drawPath(trailPath, _trailGlow);
      canvas.drawPath(trailPath, _trailBody);
      canvas.drawPath(trailPath, _trailCore);
    }
  }

  // ── Energy orb cursor ──────────────────────────────────────────────────────
  void _drawOrb(Canvas canvas, Offset pos) {
    final pulse = (math.sin(_pulsePhase) + 1) / 2;
    final r = 7.0 + pulse * 2.0;

    _orbGlow.color = (_errorTimer > 0.05 ? const Color(0xFFFF3030) : themeColor)
        .withValues(alpha: 0.35 + pulse * 0.25);
    canvas.drawCircle(pos, r * 2.2, _orbGlow);

    _orbCore.color = _errorTimer > 0.05 ? const Color(0xFFFF7070) : Colors.white;
    canvas.drawCircle(pos, r, _orbCore);
  }

  // ── Win wave ───────────────────────────────────────────────────────────────
  void _drawWinWave(Canvas canvas, double cw, double ch) {
    if (userPath.isEmpty) return;
    final count = (userPath.length * _winWaveProgress).floor().clamp(0, userPath.length - 1);
    for (int i = 0; i <= count; i++) {
      final c = _cellCenter(userPath[i], cw, ch);
      final age = (_winWaveProgress * userPath.length - i).clamp(0.0, 3.0);
      final alpha = (1.0 - age / 3.0).clamp(0.0, 1.0);
      _sharedFill.color = Colors.white.withValues(alpha: alpha * 0.7);
      canvas.drawCircle(c, cw * 0.35 * (1 + (1 - alpha)), _sharedFill);
    }
  }

  // ── Particles ──────────────────────────────────────────────────────────────
  void _emitParticles(Offset origin, int count) {
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = _rng.nextDouble() * 25.0 + 10.0;
      _particles.add(_GlowParticle(
        position: origin,
        radius: _rng.nextDouble() * 3.5 + 1.5,
        opacity: 0.85,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        color: [themeColor, Colors.white, const Color(0xFF00FF9D)][_rng.nextInt(3)],
      ));
    }
  }

  void _emitWinBurst(Offset origin) {
    for (int i = 0; i < 48; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = _rng.nextDouble() * 120.0 + 40.0;
      _winParticles.add(_GlowParticle(
        position: origin,
        radius: _rng.nextDouble() * 6.0 + 2.0,
        opacity: 1.0,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        color: [themeColor, Colors.white, const Color(0xFFFFD700)][_rng.nextInt(3)],
      ));
    }
  }

  void _drawParticles(Canvas canvas, List<_GlowParticle> list) {
    for (final p in list) {
      _sparklePaint.color = p.color.withValues(alpha: p.opacity.clamp(0.0, 1.0));
      canvas.drawCircle(p.position, p.radius.clamp(0.0, 12.0), _sparklePaint);
    }
  }

  // ── Path helpers ───────────────────────────────────────────────────────────
  Path _buildCellPath(List<CellPosition> cells, double cw, double ch) {
    final path = Path();
    for (int i = 0; i < cells.length; i++) {
      final c = _cellCenter(cells[i], cw, ch);
      if (i == 0) {
        path.moveTo(c.dx, c.dy);
      } else {
        path.lineTo(c.dx, c.dy);
      }
    }
    return path;
  }

  Offset _cellCenter(CellPosition p, double cw, double ch) =>
      Offset(p.c * cw + cw / 2, p.r * ch + ch / 2);

  void _drawLabel(Canvas canvas, Offset pos, String text, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    double dx = pos.dx;
    if (dx - tp.width / 2 < 6) dx = tp.width / 2 + 6;
    if (size.x > 0 && dx + tp.width / 2 > size.x - 6) dx = size.x - tp.width / 2 - 6;

    tp.paint(canvas, Offset(dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  /* ── Smooth, Precise Touch Gesture Handlers ──────────────────────────────── */

  @override
  void onTapDown(TapDownEvent event) {
    if (isCompleted) return;
    currentTouchPos = event.localPosition;
    _processSmoothDrag(event.localPosition.toOffset(), isInitialTouch: true);
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (isCompleted) return;
    currentTouchPos = info.eventPosition.widget;
    _processSmoothDrag(info.eventPosition.widget.toOffset(), isInitialTouch: true);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (isCompleted) return;
    currentTouchPos = info.eventPosition.widget;
    _processSmoothDrag(info.eventPosition.widget.toOffset(), isInitialTouch: false);
  }

  @override
  void onPanEnd(DragEndInfo info) {
    currentTouchPos = null;
  }

  @override
  void onPanCancel() {
    currentTouchPos = null;
  }

  /// Butter-smooth corridor-constrained finger tracking
  void _processSmoothDrag(Offset touchPos, {bool isInitialTouch = false}) {
    if (size.x <= 0 || size.y <= 0 || isCompleted) return;

    final cw = size.x / generator.cols;
    final ch = size.y / generator.rows;

    int maxIterations = 8; // Allows rapid continuous finger swipes through multiple cells
    bool changed = false;

    while (maxIterations > 0) {
      maxIterations--;

      final curr = userPath.last;
      final currCenter = _cellCenter(curr, cw, ch);

      // Check available open directions from current cell
      final canUp = generator.canMove(curr, CellPosition(curr.r - 1, curr.c));
      final canDown = generator.canMove(curr, CellPosition(curr.r + 1, curr.c));
      final canLeft = generator.canMove(curr, CellPosition(curr.r, curr.c - 1));
      final canRight = generator.canMove(curr, CellPosition(curr.r, curr.c + 1));

      final hasBacktrack = userPath.length > 1;
      final prev = hasBacktrack ? userPath[userPath.length - 2] : null;
      final prevCenter = prev != null ? _cellCenter(prev, cw, ch) : null;

      final dx = touchPos.dx - currCenter.dx;
      final dy = touchPos.dy - currCenter.dy;

      // ── 1. Check Backtrack First ──────────────────────────────────────────
      if (prev != null && prevCenter != null) {
        final toPrev = prevCenter - currCenter;
        final isBacktrackHorizontal = toPrev.dx != 0;
        final isBacktrackVertical = toPrev.dy != 0;

        if (isBacktrackHorizontal && (dx * toPrev.dx > 0)) {
          final progress = (dx / toPrev.dx).clamp(0.0, 1.0);
          _headPos = Offset(currCenter.dx + toPrev.dx * progress, currCenter.dy);
          if (progress >= 0.65) {
            userPath.removeLast();
            changed = true;
            HapticFeedback.selectionClick();
            continue;
          }
          break;
        } else if (isBacktrackVertical && (dy * toPrev.dy > 0)) {
          final progress = (dy / toPrev.dy).clamp(0.0, 1.0);
          _headPos = Offset(currCenter.dx, currCenter.dy + toPrev.dy * progress);
          if (progress >= 0.65) {
            userPath.removeLast();
            changed = true;
            HapticFeedback.selectionClick();
            continue;
          }
          break;
        }
      }

      // ── 2. Forward Movement Along Open Corridors ──────────────────────────
      final absDx = dx.abs();
      final absDy = dy.abs();

      // If finger is very close to cell center, align head to center
      if (absDx < 2.0 && absDy < 2.0) {
        _headPos = currCenter;
        break;
      }

      bool advanced = false;

      // Dominant horizontal intent
      if (absDx >= absDy) {
        if (dx > 0 && canRight) {
          final maxAdvance = cw;
          final advance = dx.clamp(0.0, maxAdvance);
          _headPos = Offset(currCenter.dx + advance, currCenter.dy);
          if (advance >= cw * 0.65) {
            final next = CellPosition(curr.r, curr.c + 1);
            _advanceTo(next);
            changed = true;
            advanced = true;
          }
        } else if (dx < 0 && canLeft) {
          final maxAdvance = cw;
          final advance = (-dx).clamp(0.0, maxAdvance);
          _headPos = Offset(currCenter.dx - advance, currCenter.dy);
          if (advance >= cw * 0.65) {
            final next = CellPosition(curr.r, curr.c - 1);
            _advanceTo(next);
            changed = true;
            advanced = true;
          }
        } else if (absDy > 6.0) {
          // Secondary fallback to vertical if horizontal is blocked by wall
          if (dy > 0 && canDown) {
            final advance = dy.clamp(0.0, ch);
            _headPos = Offset(currCenter.dx, currCenter.dy + advance);
            if (advance >= ch * 0.65) {
              final next = CellPosition(curr.r + 1, curr.c);
              _advanceTo(next);
              changed = true;
              advanced = true;
            }
          } else if (dy < 0 && canUp) {
            final advance = (-dy).clamp(0.0, ch);
            _headPos = Offset(currCenter.dx, currCenter.dy - advance);
            if (advance >= ch * 0.65) {
              final next = CellPosition(curr.r - 1, curr.c);
              _advanceTo(next);
              changed = true;
              advanced = true;
            }
          } else {
            _headPos = currCenter;
          }
        } else {
          _headPos = currCenter;
        }
      } else {
        // Dominant vertical intent
        if (dy > 0 && canDown) {
          final maxAdvance = ch;
          final advance = dy.clamp(0.0, maxAdvance);
          _headPos = Offset(currCenter.dx, currCenter.dy + advance);
          if (advance >= ch * 0.65) {
            final next = CellPosition(curr.r + 1, curr.c);
            _advanceTo(next);
            changed = true;
            advanced = true;
          }
        } else if (dy < 0 && canUp) {
          final maxAdvance = ch;
          final advance = (-dy).clamp(0.0, maxAdvance);
          _headPos = Offset(currCenter.dx, currCenter.dy - advance);
          if (advance >= ch * 0.65) {
            final next = CellPosition(curr.r - 1, curr.c);
            _advanceTo(next);
            changed = true;
            advanced = true;
          }
        } else if (absDx > 6.0) {
          // Secondary fallback to horizontal if vertical is blocked by wall
          if (dx > 0 && canRight) {
            final advance = dx.clamp(0.0, cw);
            _headPos = Offset(currCenter.dx + advance, currCenter.dy);
            if (advance >= cw * 0.65) {
              final next = CellPosition(curr.r, curr.c + 1);
              _advanceTo(next);
              changed = true;
              advanced = true;
            }
          } else if (dx < 0 && canLeft) {
            final advance = (-dx).clamp(0.0, cw);
            _headPos = Offset(currCenter.dx - advance, currCenter.dy);
            if (advance >= cw * 0.65) {
              final next = CellPosition(curr.r, curr.c - 1);
              userPath.add(next);
              changed = true;
              advanced = true;
              HapticFeedback.selectionClick();
              _checkWin(next);
            }
          } else {
            _headPos = currCenter;
          }
        } else {
          _headPos = currCenter;
        }
      }

      if (!advanced) break;
    }

    if (changed) {
      onMove(userPath.length - 1);
    }
  }

  void _advanceTo(CellPosition next) {
    userPath.add(next);
    HapticFeedback.selectionClick();

    // Check if entered dead-end cell (only 1 open passage)
    final cell = generator.grid[next.r][next.c];
    int openCount = 0;
    if (!cell.walls.top) openCount++;
    if (!cell.walls.bottom) openCount++;
    if (!cell.walls.left) openCount++;
    if (!cell.walls.right) openCount++;

    if (openCount == 1 && next != generator.exitPos && next != generator.startPos) {
      mistakeCount++;
      _errorTimer = 0.45;
      HapticFeedback.heavyImpact();
      onWrongPath?.call();
    }

    _checkWin(next);
  }

  void _checkWin(CellPosition pos) {
    if (pos == generator.exitPos) {
      _triggerWin();
    }
  }

  void _triggerWin() {
    if (isCompleted) return;
    isCompleted = true;
    _winAnimating = true;
    _winAnimTimer = 0;

    final cw = size.x / generator.cols;
    final ch = size.y / generator.rows;
    final exitPos = _cellCenter(
      generator.exitPos,
      cw,
      ch,
    );
    _headPos = exitPos;
    _emitWinBurst(exitPos);

    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 900), onWin);
  }

  // ── Public controls ───────────────────────────────────────────────────────
  void showHint() {
    hintPath = List.from(generator.solutionPath);
    _hintTimer = 6.0; // Show animated golden guide for 6 seconds without auto-clearing
    HapticFeedback.mediumImpact();
  }

  void undoStep() {
    if (userPath.length > 1) {
      userPath.removeLast();
      if (size.x > 0 && size.y > 0) {
        final cw = size.x / generator.cols;
        final ch = size.y / generator.rows;
        _headPos = _cellCenter(userPath.last, cw, ch);
      }
      onMove(userPath.length - 1);
    }
  }

  void restart() {
    isCompleted = false;
    currentTouchPos = null;
    _headPos = null;
    _errorTimer = 0;
    _hintTimer = 0;
    _winAnimating = false;
    _winAnimTimer = 0;
    _winWaveProgress = 0;
    _cachedShadowPath = null;
    _cachedBodyPath = null;
    _cachedHighlightPath = null;
    _particles.clear();
    _winParticles.clear();
    _pulsePhase = 0;
    userPath = [generator.startPos];
    hintPath = [];
    mistakeCount = 0;
    onMove(0);
  }
}
