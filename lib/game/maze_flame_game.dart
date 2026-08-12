import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../services/maze_generator.dart';

class MazeFlameGame extends FlameGame with PanDetector, TapCallbacks {
  final MazeGenerator generator;
  final Color themeColor;
  final VoidCallback onWin;
  final Function(int moves) onMove;

  List<CellPosition> userPath = [];
  List<CellPosition> hintPath = [];
  bool isCompleted = false;
  int mistakeCount = 0;

  MazeFlameGame({
    required this.generator,
    required this.themeColor,
    required this.onWin,
    required this.onMove,
  }) {
    userPath = [const CellPosition(0, 0)];
  }

  @override
  Color backgroundColor() => const Color(0xFF04050D);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final cols = generator.cols;
    final rows = generator.rows;

    final cellWidth = size.x / cols;
    final cellHeight = size.y / rows;

    // Draw Subtle Floor Grid Lines
    final gridPaint = Paint()
      ..color = const Color(0x0FFFFFFF)
      ..strokeWidth = 1.0;

    for (int r = 0; r <= rows; r++) {
      canvas.drawLine(Offset(0, r * cellHeight), Offset(size.x, r * cellHeight), gridPaint);
    }
    for (int c = 0; c <= cols; c++) {
      canvas.drawLine(Offset(c * cellWidth, 0), Offset(c * cellWidth, size.y), gridPaint);
    }

    // 1. Draw Start & Exit Portal Cell Backgrounds
    final startBgPaint = Paint()..color = const Color(0xFF00FF9D).withValues(alpha: 0.15);
    final exitBgPaint = Paint()..color = const Color(0xFFFF3366).withValues(alpha: 0.2);

    canvas.drawRect(Rect.fromLTWH(0, 0, cellWidth, cellHeight), startBgPaint);
    canvas.drawRect(
      Rect.fromLTWH((cols - 1) * cellWidth, (rows - 1) * cellHeight, cellWidth, cellHeight),
      exitBgPaint,
    );

    // Draw Start Node Ring (0,0)
    final startCenter = Offset(cellWidth / 2, cellHeight / 2);
    final startRingPaint = Paint()
      ..color = const Color(0xFF00FF9D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);
    canvas.drawCircle(startCenter, (cellWidth * 0.35).clamp(4.0, 18.0), startRingPaint);

    // Draw Exit Portal Node (rows-1, cols-1)
    final exitCenter = Offset((cols - 0.5) * cellWidth, (rows - 0.5) * cellHeight);
    final exitRingPaint = Paint()
      ..color = const Color(0xFFFF3366)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6.0);
    canvas.drawCircle(exitCenter, (cellWidth * 0.38).clamp(5.0, 20.0), exitRingPaint);

    final exitCorePaint = Paint()..color = const Color(0xFFFF3366);
    canvas.drawCircle(exitCenter, (cellWidth * 0.18).clamp(3.0, 10.0), exitCorePaint);

    // 2. Draw 3D Beveled Walls (Pass 1: Drop Shadows; Pass 2: Bevel Body; Pass 3: Top Edge Highlights)
    final shadowPaint = Paint()
      ..color = const Color(0xFF03040A)
      ..strokeWidth = (cellWidth * 0.16).clamp(4.0, 12.0)
      ..strokeCap = StrokeCap.square;

    final wallBodyPaint = Paint()
      ..color = themeColor == const Color(0xFFFF3366) || themeColor == const Color(0xFFFF2A6D)
          ? const Color(0xFF2E121B)
          : const Color(0xFF141A3A)
      ..strokeWidth = (cellWidth * 0.14).clamp(3.5, 10.0)
      ..strokeCap = StrokeCap.square;

    final highlightPaint = Paint()
      ..color = themeColor == const Color(0xFFFF3366) || themeColor == const Color(0xFFFF2A6D)
          ? const Color(0xFF5E2737)
          : const Color(0xFF2D3B7A)
      ..strokeWidth = (cellWidth * 0.05).clamp(1.5, 3.5)
      ..strokeCap = StrokeCap.square;

    void drawWallLines(Paint paint, {double dx = 0, double dy = 0}) {
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          final cell = generator.grid[r][c];
          final x = c * cellWidth + dx;
          final y = r * cellHeight + dy;

          if (cell.walls.top) {
            canvas.drawLine(Offset(x, y), Offset(x + cellWidth, y), paint);
          }
          if (cell.walls.left) {
            canvas.drawLine(Offset(x, y), Offset(x, y + cellHeight), paint);
          }
          if (c == cols - 1 && cell.walls.right) {
            canvas.drawLine(Offset(x + cellWidth, y), Offset(x + cellWidth, y + cellHeight), paint);
          }
          if (r == rows - 1 && cell.walls.bottom) {
            canvas.drawLine(Offset(x, y + cellHeight), Offset(x + cellWidth, y + cellHeight), paint);
          }
        }
      }
    }

    // Render 3D Wall Layers
    drawWallLines(shadowPaint, dx: 2.5, dy: 2.5);
    drawWallLines(wallBodyPaint);
    drawWallLines(highlightPaint, dx: -1.0, dy: -1.0);

    // 3. Draw Hint Solution Path (Gold Lines)
    if (hintPath.isNotEmpty) {
      final hintPaint = Paint()
        ..color = const Color(0xAAFFD700)
        ..strokeWidth = cellWidth * 0.25
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6.0);

      for (int i = 0; i < hintPath.length - 1; i++) {
        final p1 = hintPath[i];
        final p2 = hintPath[i + 1];
        final c1 = Offset(p1.c * cellWidth + cellWidth / 2, p1.r * cellHeight + cellHeight / 2);
        final c2 = Offset(p2.c * cellWidth + cellWidth / 2, p2.r * cellHeight + cellHeight / 2);
        canvas.drawLine(c1, c2, hintPaint);
      }
    }

    // 4. Draw Multi-Layer Neon Glowing Path Tube
    if (userPath.isNotEmpty) {
      // Layer A: Soft Radial Blur Aura
      final outerAuraPaint = Paint()
        ..color = themeColor.withValues(alpha: 0.40)
        ..strokeWidth = cellWidth * 0.45
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);

      // Layer B: Solid Primary Neon Body
      final neonBodyPaint = Paint()
        ..color = themeColor
        ..strokeWidth = cellWidth * 0.28
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3.0);

      // Layer C: Bright White-Hot Inner Core Filament
      final coreWhitePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = cellWidth * 0.12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      for (int i = 0; i < userPath.length - 1; i++) {
        final p1 = userPath[i];
        final p2 = userPath[i + 1];
        final c1 = Offset(p1.c * cellWidth + cellWidth / 2, p1.r * cellHeight + cellHeight / 2);
        final c2 = Offset(p2.c * cellWidth + cellWidth / 2, p2.r * cellHeight + cellHeight / 2);
        canvas.drawLine(c1, c2, outerAuraPaint);
        canvas.drawLine(c1, c2, neonBodyPaint);
        canvas.drawLine(c1, c2, coreWhitePaint);
      }

      // Draw Interactive Touch Cursor Node with Outer Pulsing Touch Ring
      final last = userPath.last;
      final headCenter = Offset(last.c * cellWidth + cellWidth / 2, last.r * cellHeight + cellHeight / 2);

      final touchRingPaint = Paint()
        ..color = themeColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6.0);

      final headGlowPaint = Paint()
        ..color = themeColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);

      final headCorePaint = Paint()..color = Colors.white;

      canvas.drawCircle(headCenter, cellWidth * 0.38, touchRingPaint);
      canvas.drawCircle(headCenter, cellWidth * 0.28, headGlowPaint);
      canvas.drawCircle(headCenter, cellWidth * 0.16, headCorePaint);
    }
  }

  /* ------------------------------------------------------------------------
     TOUCH GESTURE INTERACTION HANDLERS (PAN & TAP)
     ------------------------------------------------------------------------ */

  @override
  void onTapDown(TapDownEvent event) {
    if (isCompleted) return;
    _handleTouchInput(event.localPosition);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (isCompleted) return;
    _handleTouchInput(info.eventPosition.widget);
  }

  void _handleTouchInput(Vector2 widgetPos) {
    if (size.x <= 0 || size.y <= 0) return;

    final cellWidth = size.x / generator.cols;
    final cellHeight = size.y / generator.rows;

    final col = (widgetPos.x / cellWidth).floor().clamp(0, generator.cols - 1);
    final row = (widgetPos.y / cellHeight).floor().clamp(0, generator.rows - 1);

    final targetPos = CellPosition(row, col);
    _moveToTarget(targetPos);
  }

  void _moveToTarget(CellPosition targetPos) {
    CellPosition current = userPath.last;
    if (current == targetPos) return;

    // Iterative step towards target cell (handles fast drags & taps across distance)
    int maxSteps = generator.cols + generator.rows;
    while (current != targetPos && maxSteps > 0) {
      maxSteps--;

      // 1. Backtracking Check
      if (userPath.length > 1 && userPath[userPath.length - 2] == targetPos) {
        userPath.removeLast();
        current = userPath.last;
        onMove(userPath.length);
        continue;
      }

      // 2. Direct Neighbor Move
      CellPosition? nextStep;
      final dr = (targetPos.r - current.r).clamp(-1, 1);
      final dc = (targetPos.c - current.c).clamp(-1, 1);

      // Prioritize horizontal or vertical step towards targetPos
      if (dr != 0 && generator.canMove(current, CellPosition(current.r + dr, current.c))) {
        nextStep = CellPosition(current.r + dr, current.c);
      } else if (dc != 0 && generator.canMove(current, CellPosition(current.r, current.c + dc))) {
        nextStep = CellPosition(current.r, current.c + dc);
      } else {
        // Check any valid neighboring step
        final neighbors = [
          CellPosition(current.r - 1, current.c),
          CellPosition(current.r + 1, current.c),
          CellPosition(current.r, current.c - 1),
          CellPosition(current.r, current.c + 1),
        ];
        for (final n in neighbors) {
          if (generator.canMove(current, n) && (userPath.length < 2 || userPath[userPath.length - 2] != n)) {
            nextStep = n;
            break;
          }
        }
      }

      if (nextStep != null && generator.canMove(current, nextStep)) {
        userPath.add(nextStep);
        current = nextStep;
        onMove(userPath.length);

        if (current.r == generator.rows - 1 && current.c == generator.cols - 1) {
          isCompleted = true;
          onWin();
          break;
        }
      } else {
        // Path blocked by wall
        mistakeCount++;
        break;
      }
    }
  }

  void showHint() {
    hintPath = generator.solutionPath;
  }

  void undoStep() {
    if (userPath.length > 1) {
      userPath.removeLast();
      onMove(userPath.length);
    }
  }

  void restart() {
    isCompleted = false;
    userPath = [const CellPosition(0, 0)];
    hintPath = [];
    mistakeCount = 0;
    onMove(1);
  }
}
