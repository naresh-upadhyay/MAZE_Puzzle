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
    radius  -= dt * 10;
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
  int  mistakeCount = 0;

  /// 0.0 – 1.0 progress through the solution path
  double get progressPercent {
    final total = generator.solutionPath.length;
    if (total <= 1) return 1.0;
    return (userPath.length / total).clamp(0.0, 1.0);
  }

  // ── Animation state ───────────────────────────────────────────────────────
  double _pulsePhase    = 0.0;
  double _errorTimer    = 0.0;   // seconds remaining of red-flash error state
  bool   _warningState  = false; // finger near wall

  // ── Particles ─────────────────────────────────────────────────────────────
  final List<_GlowParticle> _particles    = [];
  final List<_GlowParticle> _winParticles = [];
  final math.Random _rng = math.Random();
  double _particleTimer = 0;

  // ── Win completion animation ───────────────────────────────────────────────
  bool   _winAnimating    = false;
  double _winAnimTimer    = 0.0;
  double _winWaveProgress = 0.0; // 0→1 energy wave along path

  // ── Touch ─────────────────────────────────────────────────────────────────
  Vector2? currentTouchPos;

  // ── Wall path cache ────────────────────────────────────────────────────────
  Path?  _cachedShadowPath;
  Path?  _cachedBodyPath;
  Path?  _cachedHighlightPath;
  double _cachedSizeX = 0;
  double _cachedSizeY = 0;

  // ── Pre-cached static paints ───────────────────────────────────────────────
  // Floor grid
  final Paint _gridPaint = Paint()
    ..color = const Color(0x0DFFFFFF)
    ..strokeWidth = 0.8
    ..style = PaintingStyle.stroke;

  // Start / Exit markers
  final Paint _startBgPaint = Paint()..color = const Color(0xFF00FF9D).withValues(alpha: 0.10);
  final Paint _exitBgPaint  = Paint()..color = const Color(0xFFFF2A6D).withValues(alpha: 0.12);

  // Hint
  final Paint _hintPaint = Paint()
    ..color = const Color(0xAAFFD700)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // Misc shared paints (mutable per frame, allocated once)
  final Paint _sharedFill   = Paint()..style = PaintingStyle.fill;
  final Paint _sharedStroke = Paint()..style = PaintingStyle.stroke;

  // ── Theme-dependent paints (set in constructor) ────────────────────────────
  // Wall layers
  late final Paint _wallShadow;
  late final Paint _wallBody;
  late final Paint _wallHighlight;

  // Trail layers (Req #2 — 4 layers, thin)
  late final Paint _trailBloom;   // widest, very low alpha
  late final Paint _trailGlow;    // medium neon
  late final Paint _trailBody;    // bright solid
  late final Paint _trailCore;    // white-hot centre

  // Error flash (red trail override)
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
    userPath = [const CellPosition(0, 0)];

    // ── Wall paints ────────────────────────────────────────────────────────
    _wallShadow = Paint()
      ..color = const Color(0xFF010207)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    _wallBody = Paint()
      ..color = const Color(0xFF1A1F55)   // dark navy/indigo body
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    _wallHighlight = Paint()
      ..color = const Color(0xFF2D3490)   // brighter indigo bevel highlight
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    // ── Trail paints (thin, layered) ──────────────────────────────────────
    _trailBloom = Paint()
      ..color = themeColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _trailGlow = Paint()
      ..color = themeColor.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _trailBody = Paint()
      ..color = themeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _trailCore = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ── Orb cursor ────────────────────────────────────────────────────────
    _orbGlow = Paint()..color = themeColor.withValues(alpha: 0.35);
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

    // Finger sparkles while dragging
    if (currentTouchPos != null && !isCompleted) {
      _particleTimer += dt;
      if (_particleTimer >= 0.04) {
        _particleTimer = 0;
        _emitParticles(Offset(currentTouchPos!.x, currentTouchPos!.y), 2);
      }
    }
    _particles.retainWhere((p) => p.update(dt));

    // Win animation
    if (_winAnimating) {
      _winAnimTimer    += dt;
      _winWaveProgress  = (_winAnimTimer / 0.8).clamp(0.0, 1.0);
      _winParticles.retainWhere((p) => p.update(dt));
    }
  }

  // ── Wall cache ────────────────────────────────────────────────────────────
  void _buildWallsIfNeeded(double cw, double ch) {
    if (_cachedShadowPath != null && _cachedSizeX == size.x && _cachedSizeY == size.y) return;
    _cachedSizeX = size.x;
    _cachedSizeY = size.y;

    final shadow = Path(), body = Path(), highlight = Path();
    final cols = generator.cols, rows = generator.rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = generator.grid[r][c];
        final x = c * cw, y = r * ch;

        if (cell.walls.top) {
          _seg(shadow,    x, y,      x + cw, y,      dx: 2.0, dy: 2.0);
          _seg(body,      x, y,      x + cw, y);
          _seg(highlight, x, y,      x + cw, y,      dx: -0.8, dy: -0.8);
        }
        if (cell.walls.left) {
          _seg(shadow,    x, y,      x,      y + ch, dx: 2.0, dy: 2.0);
          _seg(body,      x, y,      x,      y + ch);
          _seg(highlight, x, y,      x,      y + ch, dx: -0.8, dy: -0.8);
        }
        if (c == cols - 1 && cell.walls.right) {
          _seg(shadow,    x + cw, y, x + cw, y + ch, dx: 2.0, dy: 2.0);
          _seg(body,      x + cw, y, x + cw, y + ch);
          _seg(highlight, x + cw, y, x + cw, y + ch, dx: -0.8, dy: -0.8);
        }
        if (r == rows - 1 && cell.walls.bottom) {
          _seg(shadow,    x, y + ch, x + cw, y + ch, dx: 2.0, dy: 2.0);
          _seg(body,      x, y + ch, x + cw, y + ch);
          _seg(highlight, x, y + ch, x + cw, y + ch, dx: -0.8, dy: -0.8);
        }
      }
    }
    _cachedShadowPath = shadow;
    _cachedBodyPath   = body;
    _cachedHighlightPath = highlight;
  }

  void _seg(Path p, double x1, double y1, double x2, double y2,
      {double dx = 0, double dy = 0}) {
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
    final cw   = size.x / cols;
    final ch   = size.y / rows;

    // 1. Subtle floor grid ──────────────────────────────────────────────────
    for (int r = 0; r <= rows; r++) {
      canvas.drawLine(Offset(0, r * ch), Offset(size.x, r * ch), _gridPaint);
    }
    for (int c = 0; c <= cols; c++) {
      canvas.drawLine(Offset(c * cw, 0), Offset(c * cw, size.y), _gridPaint);
    }

    // 2. START cell tint ────────────────────────────────────────────────────
    canvas.drawRect(Rect.fromLTWH(0, 0, cw, ch), _startBgPaint);

    // 3. EXIT cell tint ────────────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH((cols - 1) * cw, (rows - 1) * ch, cw, ch),
      _exitBgPaint,
    );

    // 4. Thick 3D Walls (pre-cached navy/indigo) ────────────────────────────
    _buildWallsIfNeeded(cw, ch);
    final wallThick = (cw * 0.22).clamp(5.0, 16.0);
    _wallShadow.strokeWidth    = wallThick + 3;
    _wallBody.strokeWidth      = wallThick;
    _wallHighlight.strokeWidth = (wallThick * 0.4).clamp(2.0, 6.0);

    if (_cachedShadowPath    != null) canvas.drawPath(_cachedShadowPath!,    _wallShadow);
    if (_cachedBodyPath      != null) canvas.drawPath(_cachedBodyPath!,      _wallBody);
    if (_cachedHighlightPath != null) canvas.drawPath(_cachedHighlightPath!, _wallHighlight);

    // 5. START node (animated) ──────────────────────────────────────────────
    _drawStartNode(canvas, cw, ch);

    // 6. EXIT node (animated, proximity-reactive) ───────────────────────────
    _drawExitNode(canvas, cw, ch, cols, rows);

    // 7. Hint path ──────────────────────────────────────────────────────────
    if (hintPath.isNotEmpty) {
      _hintPaint.strokeWidth = (cw * 0.18).clamp(2.0, 6.0);
      canvas.drawPath(_buildCellPath(hintPath, cw, ch), _hintPaint);
    }

    // 8. Player glow trail ──────────────────────────────────────────────────
    if (userPath.isNotEmpty) {
      _drawTrail(canvas, cw, ch);
    }

    // 9. Energy orb cursor (only while finger is on screen) ─────────────────
    if (currentTouchPos != null && !isCompleted) {
      _drawOrb(canvas, Offset(currentTouchPos!.x, currentTouchPos!.y));
    }

    // 10. Sparkle particles ─────────────────────────────────────────────────
    _drawParticles(canvas, _particles);

    // 11. Win animation wave + win particles ────────────────────────────────
    if (_winAnimating) {
      _drawWinWave(canvas, cw, ch);
      _drawParticles(canvas, _winParticles);
    }
  }

  // ── START node ────────────────────────────────────────────────────────────
  void _drawStartNode(Canvas canvas, double cw, double ch) {
    final pulse  = (math.sin(_pulsePhase) + 1) / 2;
    final center = Offset(cw / 2, ch / 2);
    final r      = (cw * 0.28).clamp(4.0, 14.0);

    // Outer pulsing halo
    _sharedStroke
      ..color = const Color(0xFF00FF9D).withValues(alpha: 0.20 + pulse * 0.25)
      ..strokeWidth = 2.0 + pulse * 1.5;
    canvas.drawCircle(center, r + 4 + pulse * 4, _sharedStroke);

    // Mid ring
    _sharedStroke
      ..color = const Color(0xFF00FF9D).withValues(alpha: 0.75)
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, r, _sharedStroke);

    // Core fill
    _sharedFill.color = const Color(0xFF00FF9D).withValues(alpha: 0.30 + pulse * 0.20);
    canvas.drawCircle(center, r * 0.55, _sharedFill);

    // "START" label
    _drawLabel(canvas, center + Offset(0, r + 8), 'START',
        const Color(0xFF00FF9D), 6.5 + cw * 0.03);
  }

  // ── EXIT node ─────────────────────────────────────────────────────────────
  void _drawExitNode(Canvas canvas, double cw, double ch, int cols, int rows) {
    final pulse  = (math.sin(_pulsePhase + math.pi) + 1) / 2; // opposite phase
    final center = Offset((cols - 0.5) * cw, (rows - 0.5) * ch);
    final r      = (cw * 0.30).clamp(5.0, 16.0);

    // Proximity boost
    double boost = 0.0;
    if (userPath.isNotEmpty) {
      final last = userPath.last;
      final dr = (last.r - (rows - 1)).abs();
      final dc = (last.c - (cols - 1)).abs();
      final dist = dr + dc;
      boost = (1.0 - (dist / 4.0)).clamp(0.0, 1.0);
    }

    // Outer glow ring
    _sharedStroke
      ..color = const Color(0xFFFF2A6D).withValues(alpha: 0.25 + pulse * 0.30 + boost * 0.25)
      ..strokeWidth = 2.5 + pulse * 2.0;
    canvas.drawCircle(center, r + 5 + pulse * 4 + boost * 6, _sharedStroke);

    // Inner ring
    _sharedStroke
      ..color = const Color(0xFFFF2A6D).withValues(alpha: 0.80 + boost * 0.20)
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, r, _sharedStroke);

    // Cross-hair lines
    final arm = r * 0.55;
    _sharedStroke
      ..color = const Color(0xFFFF2A6D).withValues(alpha: 0.70 + boost * 0.30)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(center.dx - arm, center.dy), Offset(center.dx + arm, center.dy), _sharedStroke);
    canvas.drawLine(Offset(center.dx, center.dy - arm), Offset(center.dx, center.dy + arm), _sharedStroke);

    // Dot core
    _sharedFill.color = const Color(0xFFFF2A6D).withValues(alpha: 0.60 + pulse * 0.40 + boost * 0.20);
    canvas.drawCircle(center, r * 0.22, _sharedFill);

    // "EXIT" label
    _drawLabel(canvas, center + Offset(0, r + 9), 'EXIT',
        const Color(0xFFFF2A6D), 6.5 + cw * 0.03);
  }

  // ── Trail ─────────────────────────────────────────────────────────────────
  void _drawTrail(Canvas canvas, double cw, double ch) {
    final lastCell   = userPath.last;
    final lastCenter = _cellCenter(lastCell, cw, ch);
    final headPos    = currentTouchPos != null
        ? Offset(currentTouchPos!.x, currentTouchPos!.y)
        : lastCenter;

    // Build path
    final trailPath = _buildCellPath(userPath, cw, ch);
    if (currentTouchPos != null) {
      if (userPath.length == 1) trailPath.moveTo(lastCenter.dx, lastCenter.dy);
      trailPath.lineTo(headPos.dx, headPos.dy);
    }

    // Stroke widths — thin enough not to hide walls
    final bloomW = (cw * 0.55).clamp(6.0, 18.0);
    final glowW  = (cw * 0.32).clamp(4.0, 12.0);
    final bodyW  = (cw * 0.16).clamp(2.5, 7.0);
    final coreW  = (cw * 0.06).clamp(1.0, 3.0);

    if (_errorTimer > 0.05) {
      // Red flash — single layer
      _trailError.strokeWidth = glowW;
      _trailError.color = Color.lerp(
        const Color(0xFFFF3030),
        themeColor,
        1.0 - _errorTimer / 0.45,
      )!;
      canvas.drawPath(trailPath, _trailError);
    } else {
      // Normal 4-layer glow
      _trailBloom.strokeWidth = bloomW;
      _trailGlow.strokeWidth  = glowW;
      _trailBody.strokeWidth  = bodyW;
      _trailCore.strokeWidth  = coreW;

      canvas.drawPath(trailPath, _trailBloom);
      canvas.drawPath(trailPath, _trailGlow);
      canvas.drawPath(trailPath, _trailBody);
      canvas.drawPath(trailPath, _trailCore);
    }
  }

  // ── Energy orb cursor (small, no large ring) ──────────────────────────────
  void _drawOrb(Canvas canvas, Offset pos) {
    final pulse = (math.sin(_pulsePhase) + 1) / 2;
    // Fixed pixel sizes — stays small on any cell size
    final bloomR = 9.0 + pulse * 3.0;
    final coreR  = 4.0;

    // Warning state tints orb orange
    final orbColor = _warningState
        ? Color.lerp(themeColor, const Color(0xFFFF8C00), 0.7)!
        : themeColor;

    _orbGlow.color = orbColor.withValues(alpha: 0.28 + pulse * 0.18);
    canvas.drawCircle(pos, bloomR, _orbGlow);

    // Mid ring
    _sharedStroke
      ..color = orbColor.withValues(alpha: 0.65)
      ..strokeWidth = 1.5;
    canvas.drawCircle(pos, bloomR * 0.65, _sharedStroke);

    // White core
    _orbCore.color = Colors.white.withValues(alpha: 0.85 + pulse * 0.15);
    canvas.drawCircle(pos, coreR, _orbCore);
  }

  // ── Win wave (energy pulse from start to exit) ────────────────────────────
  void _drawWinWave(Canvas canvas, double cw, double ch) {
    final solution = generator.solutionPath;
    if (solution.length < 2) return;

    final waveEnd = (_winWaveProgress * (solution.length - 1)).round();
    final lit = solution.sublist(0, waveEnd + 1);

    _sharedStroke
      ..color = Colors.white.withValues(alpha: 0.6 * _winWaveProgress)
      ..strokeWidth = (cw * 0.20).clamp(3.0, 8.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (lit.length >= 2) {
      canvas.drawPath(_buildCellPath(lit, cw, ch), _sharedStroke);
    }
  }

  // ── Particles ─────────────────────────────────────────────────────────────
  void _emitParticles(Offset origin, int count) {
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = _rng.nextDouble() * 1.5 + 0.3;
      _particles.add(_GlowParticle(
        position: origin,
        radius:   _rng.nextDouble() * 3.5 + 1.0,
        opacity:  0.80 + _rng.nextDouble() * 0.20,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        color: Color.lerp(themeColor, Colors.white, _rng.nextDouble() * 0.5)!,
      ));
    }
  }

  void _emitWinBurst(Offset origin) {
    for (int i = 0; i < 24; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = _rng.nextDouble() * 3.5 + 1.0;
      _winParticles.add(_GlowParticle(
        position: origin,
        radius:   _rng.nextDouble() * 6.0 + 2.0,
        opacity:  1.0,
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

  // ── Path helpers ──────────────────────────────────────────────────────────
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

  // ── Text helper (tiny labels for START / EXIT) ────────────────────────────
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
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  /* ── Touch gesture handlers ─────────────────────────────────────────────── */

  @override
  void onTapDown(TapDownEvent event) {
    if (isCompleted) return;
    currentTouchPos = event.localPosition;
    _handleTouchInput(event.localPosition, isTap: true);
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (isCompleted) return;
    currentTouchPos = info.eventPosition.widget;
    _handleTouchInput(info.eventPosition.widget, isTap: false);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (isCompleted) return;
    currentTouchPos = info.eventPosition.widget;
    _handleTouchInput(info.eventPosition.widget, isTap: false);
    // Extra sparkles on active drag
    _emitParticles(Offset(currentTouchPos!.x, currentTouchPos!.y), 1);
  }

  @override
  void onPanEnd(DragEndInfo info) {
    currentTouchPos = null;
    _warningState = false;
  }

  @override
  void onPanCancel() {
    currentTouchPos = null;
    _warningState = false;
  }

  void _handleTouchInput(Vector2 widgetPos, {bool isTap = false}) {
    if (size.x <= 0 || size.y <= 0) return;
    final cw  = size.x / generator.cols;
    final ch  = size.y / generator.rows;
    final col = (widgetPos.x / cw).floor().clamp(0, generator.cols - 1);
    final row = (widgetPos.y / ch).floor().clamp(0, generator.rows - 1);

    // Warning zone: finger near cell border (outer 20%)
    final fracX = (widgetPos.x % cw) / cw;
    final fracY = (widgetPos.y % ch) / ch;
    _warningState = fracX < 0.18 || fracX > 0.82 || fracY < 0.18 || fracY > 0.82;

    _moveToTarget(CellPosition(row, col), isTap: isTap);
  }

  void _moveToTarget(CellPosition targetPos, {bool isTap = false}) {
    CellPosition current = userPath.last;
    if (current == targetPos) return;

    bool pathChanged = false;
    int  maxSteps    = generator.cols + generator.rows;

    while (current != targetPos && maxSteps > 0) {
      maxSteps--;

      // Backtrack support
      if (userPath.length > 1 && userPath[userPath.length - 2] == targetPos) {
        userPath.removeLast();
        current = userPath.last;
        pathChanged = true;
        continue;
      }

      CellPosition? nextStep;
      final dr = (targetPos.r - current.r).clamp(-1, 1);
      final dc = (targetPos.c - current.c).clamp(-1, 1);

      if (dr != 0 && generator.canMove(current, CellPosition(current.r + dr, current.c))) {
        nextStep = CellPosition(current.r + dr, current.c);
      } else if (dc != 0 && generator.canMove(current, CellPosition(current.r, current.c + dc))) {
        nextStep = CellPosition(current.r, current.c + dc);
      } else {
        for (final n in [
          CellPosition(current.r - 1, current.c),
          CellPosition(current.r + 1, current.c),
          CellPosition(current.r, current.c - 1),
          CellPosition(current.r, current.c + 1),
        ]) {
          if (generator.canMove(current, n) &&
              (userPath.length < 2 || userPath[userPath.length - 2] != n)) {
            nextStep = n;
            break;
          }
        }
      }

      if (nextStep != null && generator.canMove(current, nextStep)) {
        userPath.add(nextStep);
        current = nextStep;
        pathChanged = true;

        // Win condition
        if (current.r == generator.rows - 1 && current.c == generator.cols - 1) {
          _triggerWin();
          break;
        }
      } else {
        // Wall collision → red flash + callback
        if (_errorTimer <= 0) {
          _errorTimer = 0.45;
          mistakeCount++;
          HapticFeedback.mediumImpact();
          onWrongPath?.call();
        }
        break;
      }
    }

    if (pathChanged) {
      onMove(userPath.length - 1);
      HapticFeedback.lightImpact();
    }
  }

  void _triggerWin() {
    isCompleted    = true;
    _winAnimating  = true;
    _winAnimTimer  = 0;

    // Burst of particles at EXIT
    final cw = size.x / generator.cols;
    final ch = size.y / generator.rows;
    final exitPos = _cellCenter(
        CellPosition(generator.rows - 1, generator.cols - 1), cw, ch);
    _emitWinBurst(exitPos);

    HapticFeedback.mediumImpact();

    // Notify parent after 900ms (time for wave animation)
    Future.delayed(const Duration(milliseconds: 900), onWin);
  }

  // ── Public controls ───────────────────────────────────────────────────────
  void showHint() {
    hintPath = List.from(generator.solutionPath);
    userPath = List.from(generator.solutionPath);
    onMove(userPath.length - 1);
    _triggerWin();
  }

  void undoStep() {
    if (userPath.length > 1) {
      userPath.removeLast();
      onMove(userPath.length - 1);
    }
  }

  void restart() {
    isCompleted      = false;
    currentTouchPos  = null;
    _warningState    = false;
    _errorTimer      = 0;
    _winAnimating    = false;
    _winAnimTimer    = 0;
    _winWaveProgress = 0;
    _cachedShadowPath    = null;
    _cachedBodyPath      = null;
    _cachedHighlightPath = null;
    _particles.clear();
    _winParticles.clear();
    _pulsePhase = 0;
    userPath    = [const CellPosition(0, 0)];
    hintPath    = [];
    mistakeCount = 0;
    onMove(0);
  }
}
