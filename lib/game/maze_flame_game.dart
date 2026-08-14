import 'dart:math' as math;
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/maze_generator.dart';

// ── Explicit Maze Game States ───────────────────────────────────────────────
enum MazeGameState {
  idle,         // Waiting for player to touch Start Point
  starting,     // Touch down on external Start Point
  entering,     // Dragging from Start Point through Entry Gate
  insideMaze,   // Navigating internal maze corridors
  backtracking, // Reversing / retracting path in corridors
  reachedExit,  // Reached top internal exit cell
  exiting,      // Dragging through Exit Gate towards external Exit Point
  completed,    // Reached external Exit Point!
}

// ── Glow particle ──────────────────────────────────────────────────────────
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

// ── Callbacks ──────────────────────────────────────────────────────────────
typedef OnWrongPath = void Function();

class MazeFlameGame extends FlameGame with PanDetector, TapCallbacks {
  final MazeGenerator generator;
  final Color themeColor;
  final VoidCallback onWin;
  final Function(int moves) onMove;
  final OnWrongPath? onWrongPath;

  // ── Game state machine ────────────────────────────────────────────────────
  MazeGameState gameState = MazeGameState.idle;

  // ── Public state ──────────────────────────────────────────────────────────
  List<CellPosition> userPath = [];
  List<CellPosition> hintPath = [];
  bool isCompleted = false;
  int mistakeCount = 0;

  // Continuous position coordinates
  Offset? _headPos;
  Vector2? currentTouchPos;

  // ── Timers & Animation State ──────────────────────────────────────────────
  double _pulsePhase = 0.0;
  double _errorTimer = 0.0;
  double _collisionTimer = 0.0;
  double _hintTimer = 0.0;

  // Win animation
  bool _winAnimating = false;
  double _winAnimTimer = 0.0;
  double _winWaveProgress = 0.0;

  // Particles
  final List<_GlowParticle> _particles = [];
  final List<_GlowParticle> _winParticles = [];
  final math.Random _rng = math.Random();

  // ── Wall path cache ────────────────────────────────────────────────────────
  Path? _cachedBodyPath;
  double _cachedSizeX = 0;
  double _cachedSizeY = 0;

  // ── Pre-cached paints ─────────────────────────────────────────────────────
  final Paint _gridPaint = Paint()
    ..color = const Color(0x0DFFFFFF)
    ..strokeWidth = 0.8
    ..style = PaintingStyle.stroke;

  final Paint _sharedFill = Paint()..style = PaintingStyle.fill;
  final Paint _sharedStroke = Paint()..style = PaintingStyle.stroke;

  late final Paint _wallShadow;
  late final Paint _wallBody;
  late final Paint _wallHighlight;

  late final Paint _trailBloom;
  late final Paint _trailGlow;
  late final Paint _trailBody;
  late final Paint _trailCore;

  final Paint _trailError = Paint()
    ..color = const Color(0xFFFF3030)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  final Paint _hintPaint = Paint()
    ..color = const Color(0xAAFFD700)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  late final Paint _orbGlow;
  late final Paint _orbCore;
  late final Paint _sparklePaint;

  MazeFlameGame({
    required this.generator,
    required this.themeColor,
    required this.onWin,
    required this.onMove,
    this.onWrongPath,
  }) {
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

    // ── Trail paints ──────────────────────────────────────────────────────
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

    // ── Cursor paints ─────────────────────────────────────────────────────
    _orbGlow = Paint()..color = themeColor.withValues(alpha: 0.38);
    _orbCore = Paint()..color = Colors.white;
    _sparklePaint = Paint()..style = PaintingStyle.fill;
  }

  @override
  Color backgroundColor() => const Color(0xFF060713);

  // ── Progress Percent ───────────────────────────────────────────────────────
  double get progressPercent {
    final total = generator.solutionPath.length;
    if (total <= 1) return 1.0;
    if (gameState == MazeGameState.completed) return 1.0;
    return (userPath.length / total).clamp(0.0, 1.0);
  }

  // ── Geometry Helpers (Internal Grid is inset to make room for external Nodes) ──
  double get _padTop => (size.y * 0.055).clamp(32.0, 52.0);
  double get _padBottom => (size.y * 0.055).clamp(32.0, 52.0);
  double get _padLeft => 10.0;
  double get _padRight => 10.0;

  double get _mazeWidth => size.x - _padLeft - _padRight;
  double get _mazeHeight => size.y - _padTop - _padBottom;

  double get _cw => _mazeWidth / generator.cols;
  double get _ch => _mazeHeight / generator.rows;

  Offset _cellCenter(CellPosition p) => Offset(
        _padLeft + (p.c + 0.5) * _cw,
        _padTop + (p.r + 0.5) * _ch,
      );

  // ── External Node Locations ────────────────────────────────────────────────
  // 1. External START POINT: below the bottom boundary
  Offset get startPointPos => Offset(
        _padLeft + (generator.startPos.c + 0.5) * _cw,
        size.y - (_padBottom * 0.32),
      );

  // 2. ENTRY GATE: on bottom boundary wall
  Offset get entryGatePos => Offset(
        _padLeft + (generator.startPos.c + 0.5) * _cw,
        _padTop + _mazeHeight,
      );

  // 3. EXIT GATE: on top boundary wall
  Offset get exitGatePos => Offset(
        _padLeft + (generator.exitPos.c + 0.5) * _cw,
        _padTop,
      );

  // 4. External EXIT POINT: above the top boundary
  Offset get exitPointPos => Offset(
        _padLeft + (generator.exitPos.c + 0.5) * _cw,
        _padTop * 0.32,
      );

  // ── Update Loop ────────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);

    _pulsePhase = (_pulsePhase + dt * 3.2) % (2 * math.pi);

    if (_errorTimer > 0) _errorTimer = (_errorTimer - dt).clamp(0.0, 1.0);
    if (_collisionTimer > 0) _collisionTimer = (_collisionTimer - dt).clamp(0.0, 1.0);

    if (_hintTimer > 0) {
      _hintTimer -= dt;
      if (_hintTimer <= 0) hintPath = [];
    }

    // Default head position initialization
    if (_headPos == null && size.x > 0 && size.y > 0) {
      _headPos = startPointPos;
    }

    // Idle return when touch released
    if (currentTouchPos == null && _headPos != null && !isCompleted) {
      final target = userPath.isEmpty ? startPointPos : _cellCenter(userPath.last);
      final diff = target - _headPos!;
      if (diff.distance > 1.0) {
        _headPos = Offset.lerp(_headPos!, target, (18.0 * dt).clamp(0.0, 1.0))!;
      } else {
        _headPos = target;
      }
    }

    // Particles update
    _particles.retainWhere((p) => p.update(dt));

    // Win animation: Shortest path energy sweep wave
    if (_winAnimating) {
      _winAnimTimer += dt;
      _winWaveProgress = (_winAnimTimer / 1.15).clamp(0.0, 1.0);

      final solution = generator.solutionPath;
      if (solution.isNotEmpty && size.x > 0 && size.y > 0) {
        final currIndex = (_winWaveProgress * (solution.length - 1)).floor().clamp(0, solution.length - 1);
        final pt = _cellCenter(solution[currIndex]);
        _emitParticles(pt, 2);
      }
      _winParticles.retainWhere((p) => p.update(dt));
    }
  }

  // ── Render Loop ────────────────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.x <= 0 || size.y <= 0) return;

    final cw = _cw;
    final ch = _ch;
    final cols = generator.cols;
    final rows = generator.rows;

    // 1. Draw Subtle Floor Grid
    _drawFloorGrid(canvas, cw, ch, cols, rows);

    // 2. Draw 3D Maze Walls
    _buildWallsIfNeeded(cw, ch);
    if (_cachedBodyPath != null) {
      // 3D Shadow
      canvas.save();
      canvas.translate(0, 2.2);
      canvas.drawPath(_cachedBodyPath!, _wallShadow);
      canvas.restore();

      // Wall Body
      canvas.drawPath(_cachedBodyPath!, _wallBody);

      // 3D Bevel Highlight
      canvas.save();
      canvas.translate(0, -0.9);
      canvas.drawPath(_cachedBodyPath!, _wallHighlight);
      canvas.restore();
    }

    // 3. Draw External Nodes & Boundary Gates
    _drawStartPoint(canvas, cw);
    _drawEntryGate(canvas, cw);
    _drawExitGate(canvas, cw);
    _drawExitPoint(canvas, cw);

    // 4. Draw Hint Guide (if active)
    if (_hintTimer > 0 && hintPath.isNotEmpty) {
      _drawHintGuide(canvas, cw, ch);
    }

    // 5. Draw Player Laser Trail
    _drawTrail(canvas, cw, ch);

    // 6. Draw Finger / Head Cursor
    if (_headPos != null && !isCompleted && gameState != MazeGameState.idle) {
      _drawOrb(canvas, _headPos!);
    }

    // 7. Draw Active Particles
    _drawParticles(canvas, _particles);

    // 8. Draw Win Wave & Victory Particles
    if (_winAnimating) {
      _drawWinWave(canvas, cw, ch);
      _drawParticles(canvas, _winParticles);
    }
  }

  // ── Floor Grid ─────────────────────────────────────────────────────────────
  void _drawFloorGrid(Canvas canvas, double cw, double ch, int cols, int rows) {
    for (int r = 0; r <= rows; r++) {
      final y = _padTop + r * ch;
      canvas.drawLine(Offset(_padLeft, y), Offset(_padLeft + _mazeWidth, y), _gridPaint);
    }
    for (int c = 0; c <= cols; c++) {
      final x = _padLeft + c * cw;
      canvas.drawLine(Offset(x, _padTop), Offset(x, _padTop + _mazeHeight), _gridPaint);
    }
  }

  // ── 3D Wall Generation Cache ───────────────────────────────────────────────
  void _buildWallsIfNeeded(double cw, double ch) {
    if (_cachedBodyPath != null && _cachedSizeX == size.x && _cachedSizeY == size.y) {
      return;
    }
    _cachedSizeX = size.x;
    _cachedSizeY = size.y;

    final wallW = (cw * 0.18).clamp(3.0, 9.0);
    _wallShadow.strokeWidth = wallW + 2.5;
    _wallBody.strokeWidth = wallW;
    _wallHighlight.strokeWidth = (wallW * 0.35).clamp(1.0, 3.0);

    final rawPath = Path();
    final cols = generator.cols;
    final rows = generator.rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = generator.grid[r][c];
        final x = _padLeft + c * cw;
        final y = _padTop + r * ch;

        // Top wall
        if (cell.walls.top) {
          rawPath.moveTo(x, y);
          rawPath.lineTo(x + cw, y);
        }
        // Left wall
        if (cell.walls.left) {
          rawPath.moveTo(x, y);
          rawPath.lineTo(x, y + ch);
        }
        // Right wall
        if (c == cols - 1 && cell.walls.right) {
          rawPath.moveTo(x + cw, y);
          rawPath.lineTo(x + cw, y + ch);
        }
        // Bottom wall
        if (r == rows - 1 && cell.walls.bottom) {
          rawPath.moveTo(x, y + ch);
          rawPath.lineTo(x + cw, y + ch);
        }
      }
    }

    _cachedBodyPath = rawPath;
  }

  // ── START POINT (External Bottom Node) ─────────────────────────────────────
  void _drawStartPoint(Canvas canvas, double cw) {
    final pulse = (math.sin(_pulsePhase * 2.0) + 1) / 2;
    final pos = startPointPos;
    final r = (cw * 0.28).clamp(7.0, 16.0);
    const pink = Color(0xFFFF2A6D);

    // Outer beacon ripple
    _sharedStroke
      ..color = pink.withValues(alpha: 0.35 + pulse * 0.35)
      ..strokeWidth = 2.0;
    canvas.drawCircle(pos, r * 1.6 + pulse * 4.0, _sharedStroke);

    // Outer glow ring
    _sharedStroke
      ..color = pink.withValues(alpha: 0.85)
      ..strokeWidth = 2.4;
    canvas.drawCircle(pos, r, _sharedStroke);

    // Inner bright core
    _sharedFill.color = pink.withValues(alpha: 0.70 + pulse * 0.30);
    canvas.drawCircle(pos, r * 0.45, _sharedFill);
    _sharedFill.color = Colors.white;
    canvas.drawCircle(pos, r * 0.22, _sharedFill);

    _drawLabel(canvas, pos + Offset(0, r + 9), 'START POINT', pink, 7.5);
  }

  // ── ENTRY GATE (Bottom Boundary Opening) ───────────────────────────────────
  void _drawEntryGate(Canvas canvas, double cw) {
    final gatePos = entryGatePos;
    final gateW = _cw;
    const pink = Color(0xFFFF2A6D);
    final pulse = (math.sin(_pulsePhase) + 1) / 2;

    final x1 = gatePos.dx - gateW / 2;
    final x2 = gatePos.dx + gateW / 2;
    final y = gatePos.dy;

    // Glowing gate pillar brackets on bottom boundary wall
    _sharedStroke
      ..color = pink.withValues(alpha: 0.90 + pulse * 0.10)
      ..strokeWidth = 3.2;
    canvas.drawLine(Offset(x1, y - 6), Offset(x1, y + 10), _sharedStroke);
    canvas.drawLine(Offset(x2, y - 6), Offset(x2, y + 10), _sharedStroke);

    // Threshold indicator line
    _sharedStroke
      ..color = pink.withValues(alpha: 0.50 + pulse * 0.40)
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset(x1 + 3, y), Offset(x2 - 3, y), _sharedStroke);

    _drawLabel(canvas, gatePos - Offset(0, 10), 'ENTRY GATE', pink, 6.8);
  }

  // ── EXIT GATE (Top Boundary Opening) ───────────────────────────────────────
  void _drawExitGate(Canvas canvas, double cw) {
    final gatePos = exitGatePos;
    final gateW = _cw;
    const green = Color(0xFF00FF9D);
    final pulse = (math.sin(_pulsePhase + math.pi) + 1) / 2;

    final x1 = gatePos.dx - gateW / 2;
    final x2 = gatePos.dx + gateW / 2;
    final y = gatePos.dy;

    // Gate pillar brackets
    _sharedStroke
      ..color = green.withValues(alpha: 0.90 + pulse * 0.10)
      ..strokeWidth = 3.2;
    canvas.drawLine(Offset(x1, y - 10), Offset(x1, y + 6), _sharedStroke);
    canvas.drawLine(Offset(x2, y - 10), Offset(x2, y + 6), _sharedStroke);

    // Threshold indicator line
    _sharedStroke
      ..color = green.withValues(alpha: 0.50 + pulse * 0.40)
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset(x1 + 3, y), Offset(x2 - 3, y), _sharedStroke);

    _drawLabel(canvas, gatePos + Offset(0, 10), 'EXIT GATE', green, 6.8);
  }

  // ── EXIT POINT (External Top Node) ─────────────────────────────────────────
  void _drawExitPoint(Canvas canvas, double cw) {
    final pulse = (math.sin(_pulsePhase * 2.0 + math.pi) + 1) / 2;
    final pos = exitPointPos;
    final r = (cw * 0.30).clamp(8.0, 18.0);
    const green = Color(0xFF00FF9D);

    // Outer pulse beacon
    _sharedStroke
      ..color = green.withValues(alpha: 0.35 + pulse * 0.35)
      ..strokeWidth = 2.0;
    canvas.drawCircle(pos, r * 1.6 + pulse * 4.0, _sharedStroke);

    // Outer ring
    _sharedStroke
      ..color = green.withValues(alpha: 0.85)
      ..strokeWidth = 2.4;
    canvas.drawCircle(pos, r, _sharedStroke);

    // Crosshairs
    final arm = r * 0.65;
    canvas.drawLine(Offset(pos.dx - arm, pos.dy), Offset(pos.dx + arm, pos.dy), _sharedStroke);
    canvas.drawLine(Offset(pos.dx, pos.dy - arm), Offset(pos.dx, pos.dy + arm), _sharedStroke);

    // Inner bright core
    _sharedFill.color = green.withValues(alpha: 0.70 + pulse * 0.30);
    canvas.drawCircle(pos, r * 0.40, _sharedFill);
    _sharedFill.color = Colors.white;
    canvas.drawCircle(pos, r * 0.20, _sharedFill);

    _drawLabel(canvas, pos - Offset(0, r + 9), 'EXIT POINT', green, 7.5);
  }

  // ── Hint Guide (Golden Pulsing Breadcrumb Beam) ─────────────────────────────
  void _drawHintGuide(Canvas canvas, double cw, double ch) {
    final p = Path();
    p.moveTo(startPointPos.dx, startPointPos.dy);
    p.lineTo(entryGatePos.dx, entryGatePos.dy);

    for (final c in hintPath) {
      final center = _cellCenter(c);
      p.lineTo(center.dx, center.dy);
    }
    p.lineTo(exitGatePos.dx, exitGatePos.dy);
    p.lineTo(exitPointPos.dx, exitPointPos.dy);

    final pulse = (math.sin(_pulsePhase * 4) + 1) / 2;

    _sharedStroke
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.20 + pulse * 0.20)
      ..strokeWidth = (cw * 0.35).clamp(6.0, 16.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(p, _sharedStroke);

    _hintPaint.strokeWidth = (cw * 0.16).clamp(3.0, 6.0);
    canvas.drawPath(p, _hintPaint);
  }

  // ── Multi-Tier Player Trail (Start Point -> Entry Gate -> Maze -> Exit Gate -> Exit Point) ──
  void _drawTrail(Canvas canvas, double cw, double ch) {
    if (gameState == MazeGameState.idle || (userPath.isEmpty && _headPos == startPointPos)) {
      return;
    }

    final trailPath = Path();

    // 1. Originate laser trail from external START POINT
    trailPath.moveTo(startPointPos.dx, startPointPos.dy);

    // 2. If entering or inside maze, connect through ENTRY GATE
    if (gameState != MazeGameState.idle && gameState != MazeGameState.starting) {
      trailPath.lineTo(entryGatePos.dx, entryGatePos.dy);
    }

    // 3. Connect through internal cells
    for (int i = 0; i < userPath.length; i++) {
      final c = _cellCenter(userPath[i]);
      trailPath.lineTo(c.dx, c.dy);
    }

    // 4. If exiting or completed, connect through EXIT GATE and to EXIT POINT
    if (gameState == MazeGameState.exiting || gameState == MazeGameState.completed) {
      trailPath.lineTo(exitGatePos.dx, exitGatePos.dy);
      if (gameState == MazeGameState.completed) {
        trailPath.lineTo(exitPointPos.dx, exitPointPos.dy);
      }
    }

    // 5. Connect to continuous cursor head position
    if (_headPos != null && gameState != MazeGameState.completed) {
      trailPath.lineTo(_headPos!.dx, _headPos!.dy);
    }

    final bloomW = (cw * 0.55).clamp(6.0, 18.0);
    final glowW = (cw * 0.32).clamp(4.0, 12.0);
    final bodyW = (cw * 0.16).clamp(2.5, 7.0);
    final coreW = (cw * 0.06).clamp(1.0, 3.0);

    if (_errorTimer > 0.05 || _collisionTimer > 0.05) {
      _trailError.strokeWidth = glowW;
      _trailError.color = Color.lerp(
        const Color(0xFFFF3030),
        themeColor,
        1.0 - (_errorTimer > 0 ? _errorTimer : _collisionTimer) / 0.45,
      )!;
      canvas.drawPath(trailPath, _trailError);
    } else {
      _trailBloom.strokeWidth = bloomW;
      _trailGlow.strokeWidth = glowW;
      _trailBody.strokeWidth = bodyW;
      _trailCore.strokeWidth = coreW;

      // Multi-tier glow rendering
      canvas.drawPath(trailPath, _trailBloom);
      canvas.drawPath(trailPath, _trailGlow);
      canvas.drawPath(trailPath, _trailBody);
      canvas.drawPath(trailPath, _trailCore);
    }
  }

  // ── Finger Gesture Cursor Orb with Concentric Shockwave Ripples ─────────────
  void _drawOrb(Canvas canvas, Offset pos) {
    final pulse = (math.sin(_pulsePhase * 2.0) + 1) / 2;
    final r = 9.0 + pulse * 3.0;

    final isError = _errorTimer > 0.05 || _collisionTimer > 0.05;
    final cursorColor = isError ? const Color(0xFFFF3030) : themeColor;

    // 1. Concentric shockwave ripple 1
    final rip1 = (_pulsePhase % math.pi) / math.pi;
    _sharedStroke
      ..color = cursorColor.withValues(alpha: (1.0 - rip1) * 0.40)
      ..strokeWidth = 1.8;
    canvas.drawCircle(pos, 8.0 + rip1 * 18.0, _sharedStroke);

    // 2. Concentric shockwave ripple 2
    final rip2 = ((_pulsePhase + math.pi / 2) % math.pi) / math.pi;
    _sharedStroke
      ..color = cursorColor.withValues(alpha: (1.0 - rip2) * 0.30)
      ..strokeWidth = 1.5;
    canvas.drawCircle(pos, 8.0 + rip2 * 14.0, _sharedStroke);

    // 3. Outer soft bloom halo
    _orbGlow.color = cursorColor.withValues(alpha: 0.28 + pulse * 0.22);
    canvas.drawCircle(pos, r * 2.5, _orbGlow);

    // 4. Bright aura ring
    _sharedStroke
      ..color = cursorColor.withValues(alpha: 0.85)
      ..strokeWidth = 2.2;
    canvas.drawCircle(pos, r * 1.1, _sharedStroke);

    // 5. White Hot Core
    _orbCore.color = isError ? const Color(0xFFFF7070) : Colors.white;
    canvas.drawCircle(pos, r * 0.55, _orbCore);
  }

  // ── Shortest Path Win Wave (Radiant Golden Sweep on Exit) ───────────────────
  void _drawWinWave(Canvas canvas, double cw, double ch) {
    final solution = generator.solutionPath;
    if (solution.length < 2) return;

    final p = Path();
    p.moveTo(startPointPos.dx, startPointPos.dy);
    p.lineTo(entryGatePos.dx, entryGatePos.dy);

    final waveEnd = (_winWaveProgress * (solution.length - 1)).round().clamp(0, solution.length - 1);
    final litPath = solution.sublist(0, waveEnd + 1);

    for (final c in litPath) {
      final center = _cellCenter(c);
      p.lineTo(center.dx, center.dy);
    }

    if (_winWaveProgress >= 0.92) {
      p.lineTo(exitGatePos.dx, exitGatePos.dy);
      p.lineTo(exitPointPos.dx, exitPointPos.dy);
    }

    // Outer Golden Glow
    _sharedStroke
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.45)
      ..strokeWidth = (cw * 0.45).clamp(8.0, 22.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(p, _sharedStroke);

    // Mid Neon Cyan/Gold Beam
    _sharedStroke
      ..color = const Color(0xFF00FFD0).withValues(alpha: 0.90)
      ..strokeWidth = (cw * 0.22).clamp(4.0, 10.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(p, _sharedStroke);

    // Bright White Core
    _sharedStroke
      ..color = Colors.white
      ..strokeWidth = (cw * 0.10).clamp(2.0, 5.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(p, _sharedStroke);

    // Wave Leader Orb
    final leadPos = _cellCenter(litPath.last);
    final pulse = (math.sin(_pulsePhase * 3) + 1) / 2;
    _sharedFill.color = const Color(0xFFFFD700).withValues(alpha: 0.6);
    canvas.drawCircle(leadPos, (cw * 0.38).clamp(6.0, 18.0) + pulse * 4, _sharedFill);
    _sharedFill.color = Colors.white;
    canvas.drawCircle(leadPos, (cw * 0.18).clamp(3.0, 8.0), _sharedFill);
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
    for (int i = 0; i < 54; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = _rng.nextDouble() * 140.0 + 40.0;
      _winParticles.add(_GlowParticle(
        position: origin,
        radius: _rng.nextDouble() * 6.0 + 2.0,
        opacity: 1.0,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        color: [themeColor, Colors.white, const Color(0xFFFFD700), const Color(0xFF00FF9D)][_rng.nextInt(4)],
      ));
    }
  }

  void _drawParticles(Canvas canvas, List<_GlowParticle> list) {
    for (final p in list) {
      _sparklePaint.color = p.color.withValues(alpha: p.opacity.clamp(0.0, 1.0));
      canvas.drawCircle(p.position, p.radius.clamp(0.0, 12.0), _sparklePaint);
    }
  }

  void _drawLabel(Canvas canvas, Offset pos, String text, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: 0.90),
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  // ── Touch Gesture Handlers (Continuous Physical Collision Navigation) ───────
  @override
  void onTapDown(TapDownEvent event) {
    if (isCompleted) return;
    _handleTouchStart(event.localPosition.toOffset());
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (isCompleted) return;
    _handleTouchStart(info.eventPosition.widget.toOffset());
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (isCompleted) return;
    _handleTouchMove(info.eventPosition.widget.toOffset());
  }

  @override
  void onPanEnd(DragEndInfo info) {
    currentTouchPos = null;
  }

  @override
  void onPanCancel() {
    currentTouchPos = null;
  }

  // ── Touch Start ────────────────────────────────────────────────────────────
  void _handleTouchStart(Offset touchPos) {
    currentTouchPos = Vector2(touchPos.dx, touchPos.dy);

    // 1. If at Start Point
    final distToStart = (touchPos - startPointPos).distance;
    if (gameState == MazeGameState.idle || userPath.isEmpty) {
      if (distToStart < _cw * 1.5 || touchPos.dy >= startPointPos.dy - _ch) {
        gameState = MazeGameState.starting;
        _headPos = startPointPos;
        HapticFeedback.selectionClick();
      }
    }
  }

  // ── Touch Move (Physical Corridor Navigation & Collision) ───────────────────
  void _handleTouchMove(Offset touchPos) {
    currentTouchPos = Vector2(touchPos.dx, touchPos.dy);
    final cw = _cw;
    final ch = _ch;

    // ── PHASE 1: START POINT -> ENTRY GATE ──────────────────────────────────
    if (gameState == MazeGameState.idle || gameState == MazeGameState.starting) {
      final distToStart = (touchPos - startPointPos).distance;
      if (distToStart < cw * 1.6 || touchPos.dy >= startPointPos.dy - ch) {
        gameState = MazeGameState.starting;
      }
    }

    if (gameState == MazeGameState.starting || gameState == MazeGameState.entering) {
      // Dragging upward from startPointPos to entryGatePos
      final dy = touchPos.dy - startPointPos.dy;
      if (dy < 0) {
        final totalDist = (startPointPos.dy - entryGatePos.dy).abs();
        final progress = ((-dy) / totalDist).clamp(0.0, 1.0);
        _headPos = Offset(startPointPos.dx, startPointPos.dy - totalDist * progress);

        if (progress >= 0.85) {
          // Crossed ENTRY GATE! Enter maze at startPos
          gameState = MazeGameState.insideMaze;
          userPath = [generator.startPos];
          _headPos = _cellCenter(generator.startPos);
          HapticFeedback.mediumImpact();
          onMove(0);
        }
      }
      return;
    }

    // ── PHASE 2: INSIDE MAZE NAVIGATION & PHYSICAL CORRIDOR CONSTRAINTS ─────
    if (gameState == MazeGameState.insideMaze || gameState == MazeGameState.backtracking || gameState == MazeGameState.reachedExit) {
      var maxIterations = 8;
      var changed = false;

      while (maxIterations > 0) {
        maxIterations--;
        final curr = userPath.last;
        final currCenter = _cellCenter(curr);

        // Check Backtracking First
        if (userPath.length > 1) {
          final prev = userPath[userPath.length - 2];
          final prevCenter = _cellCenter(prev);
          final toPrev = prevCenter - currCenter;
          final dx = touchPos.dx - currCenter.dx;
          final dy = touchPos.dy - currCenter.dy;

          if (toPrev.dx != 0 && (dx * toPrev.dx > 0)) {
            final progress = (dx / toPrev.dx).clamp(0.0, 1.0);
            _headPos = Offset(currCenter.dx + toPrev.dx * progress, currCenter.dy);
            if (progress >= 0.65) {
              userPath.removeLast();
              gameState = MazeGameState.backtracking;
              changed = true;
              HapticFeedback.selectionClick();
              continue;
            }
            break;
          } else if (toPrev.dy != 0 && (dy * toPrev.dy > 0)) {
            final progress = (dy / toPrev.dy).clamp(0.0, 1.0);
            _headPos = Offset(currCenter.dx, currCenter.dy + toPrev.dy * progress);
            if (progress >= 0.65) {
              userPath.removeLast();
              gameState = MazeGameState.backtracking;
              changed = true;
              HapticFeedback.selectionClick();
              continue;
            }
            break;
          }
        }

        // Forward Movement Along Open Corridors
        final canUp = generator.canMove(curr, CellPosition(curr.r - 1, curr.c));
        final canDown = generator.canMove(curr, CellPosition(curr.r + 1, curr.c));
        final canLeft = generator.canMove(curr, CellPosition(curr.r, curr.c - 1));
        final canRight = generator.canMove(curr, CellPosition(curr.r, curr.c + 1));

        final dx = touchPos.dx - currCenter.dx;
        final dy = touchPos.dy - currCenter.dy;
        final absDx = dx.abs();
        final absDy = dy.abs();

        if (absDx < 2.0 && absDy < 2.0) {
          _headPos = currCenter;
          break;
        }

        var advanced = false;

        // Dominant horizontal intent
        if (absDx >= absDy) {
          if (dx > 0 && canRight) {
            final advance = dx.clamp(0.0, cw);
            _headPos = Offset(currCenter.dx + advance, currCenter.dy);
            if (advance >= cw * 0.65) {
              _advanceTo(CellPosition(curr.r, curr.c + 1));
              changed = true;
              advanced = true;
            }
          } else if (dx < 0 && canLeft) {
            final advance = (-dx).clamp(0.0, cw);
            _headPos = Offset(currCenter.dx - advance, currCenter.dy);
            if (advance >= cw * 0.65) {
              _advanceTo(CellPosition(curr.r, curr.c - 1));
              changed = true;
              advanced = true;
            }
          } else if (absDy > 6.0) {
            // Secondary vertical fallback
            if (dy > 0 && canDown) {
              final advance = dy.clamp(0.0, ch);
              _headPos = Offset(currCenter.dx, currCenter.dy + advance);
              if (advance >= ch * 0.65) {
                _advanceTo(CellPosition(curr.r + 1, curr.c));
                changed = true;
                advanced = true;
              }
            } else if (dy < 0 && canUp) {
              final advance = (-dy).clamp(0.0, ch);
              _headPos = Offset(currCenter.dx, currCenter.dy - advance);
              if (advance >= ch * 0.65) {
                _advanceTo(CellPosition(curr.r - 1, curr.c));
                changed = true;
                advanced = true;
              }
            } else {
              _triggerWallCollision(currCenter);
            }
          } else {
            _triggerWallCollision(currCenter);
          }
        } else {
          // Dominant vertical intent
          if (dy > 0 && canDown) {
            final advance = dy.clamp(0.0, ch);
            _headPos = Offset(currCenter.dx, currCenter.dy + advance);
            if (advance >= ch * 0.65) {
              _advanceTo(CellPosition(curr.r + 1, curr.c));
              changed = true;
              advanced = true;
            }
          } else if (dy < 0 && canUp) {
            final advance = (-dy).clamp(0.0, ch);
            _headPos = Offset(currCenter.dx, currCenter.dy - advance);
            if (advance >= ch * 0.65) {
              _advanceTo(CellPosition(curr.r - 1, curr.c));
              changed = true;
              advanced = true;
            }
          } else if (absDx > 6.0) {
            // Secondary horizontal fallback
            if (dx > 0 && canRight) {
              final advance = dx.clamp(0.0, cw);
              _headPos = Offset(currCenter.dx + advance, currCenter.dy);
              if (advance >= cw * 0.65) {
                _advanceTo(CellPosition(curr.r, curr.c + 1));
                changed = true;
                advanced = true;
              }
            } else if (dx < 0 && canLeft) {
              final advance = (-dx).clamp(0.0, cw);
              _headPos = Offset(currCenter.dx - advance, currCenter.dy);
              if (advance >= cw * 0.65) {
                _advanceTo(CellPosition(curr.r, curr.c - 1));
                changed = true;
                advanced = true;
              }
            } else {
              _triggerWallCollision(currCenter);
            }
          } else {
            _triggerWallCollision(currCenter);
          }
        }

        if (!advanced) break;
      }

      if (changed) {
        onMove(userPath.length - 1);
      }
    }

    // ── PHASE 3: EXIT GATE -> EXIT POINT ────────────────────────────────────
    if (gameState == MazeGameState.reachedExit || gameState == MazeGameState.exiting) {
      final exitCellCenter = _cellCenter(generator.exitPos);
      final dy = touchPos.dy - exitCellCenter.dy;

      if (dy < 0) {
        // Dragging upward beyond top boundary towards exitPointPos
        gameState = MazeGameState.exiting;
        final totalDist = (exitCellCenter.dy - exitPointPos.dy).abs();
        final progress = ((-dy) / totalDist).clamp(0.0, 1.0);
        _headPos = Offset(exitCellCenter.dx, exitCellCenter.dy - totalDist * progress);

        if (progress >= 0.85 || touchPos.dy <= exitPointPos.dy + 8.0) {
          // Reached external EXIT POINT! Puzzle Complete!
          _headPos = exitPointPos;
          _triggerWin();
        }
      }
    }
  }

  void _triggerWallCollision(Offset currCenter) {
    if (_collisionTimer <= 0) {
      _collisionTimer = 0.35;
      HapticFeedback.heavyImpact();
    }
  }

  void _advanceTo(CellPosition next) {
    userPath.add(next);
    gameState = MazeGameState.insideMaze;
    HapticFeedback.selectionClick();

    // Check if reached internal exit cell
    if (next == generator.exitPos) {
      gameState = MazeGameState.reachedExit;
      HapticFeedback.mediumImpact();
      return;
    }

    // Dead-end detection
    final cell = generator.grid[next.r][next.c];
    var openCount = 0;
    if (!cell.walls.top) openCount++;
    if (!cell.walls.bottom) openCount++;
    if (!cell.walls.left) openCount++;
    if (!cell.walls.right) openCount++;

    if (openCount == 1 && next != generator.startPos) {
      mistakeCount++;
      _errorTimer = 0.45;
      HapticFeedback.heavyImpact();
      onWrongPath?.call();
    }
  }

  // ── Win Trigger (External Exit Point Reached) ──────────────────────────────
  void _triggerWin() {
    if (isCompleted) return;
    isCompleted = true;
    gameState = MazeGameState.completed;
    _winAnimating = true;
    _winAnimTimer = 0;

    _headPos = exitPointPos;
    _emitWinBurst(exitPointPos);

    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 1400), onWin);
  }

  // ── Public controls ───────────────────────────────────────────────────────
  void showHint() {
    hintPath = List.from(generator.solutionPath);
    _hintTimer = 5.0; // 5-second golden guide beam
    HapticFeedback.mediumImpact();
  }

  void undoStep() {
    if (userPath.length > 1) {
      userPath.removeLast();
      _headPos = _cellCenter(userPath.last);
      onMove(userPath.length - 1);
    }
  }

  void restart() {
    isCompleted = false;
    gameState = MazeGameState.idle;
    currentTouchPos = null;
    _headPos = startPointPos;
    _errorTimer = 0;
    _collisionTimer = 0;
    _winAnimating = false;
    _winAnimTimer = 0;
    _winWaveProgress = 0;
    _particles.clear();
    _winParticles.clear();
    _pulsePhase = 0;
    userPath = [];
    hintPath = [];
    mistakeCount = 0;
    onMove(0);
  }
}
