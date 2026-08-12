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

    // 2. Draw Maze Walls (Single pass: Top and Left per cell + Right for last col + Bottom for last row)
    final wallPaint = Paint()
      ..color = themeColor
      ..strokeWidth = (cellWidth * 0.12).clamp(3.0, 10.0)
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = generator.grid[r][c];
        final x = c * cellWidth;
        final y = r * cellHeight;

        if (cell.walls.top) {
          canvas.drawLine(Offset(x, y), Offset(x + cellWidth, y), wallPaint);
        }
        if (cell.walls.left) {
          canvas.drawLine(Offset(x, y), Offset(x, y + cellHeight), wallPaint);
        }
        if (c == cols - 1 && cell.walls.right) {
          canvas.drawLine(Offset(x + cellWidth, y), Offset(x + cellWidth, y + cellHeight), wallPaint);
        }
        if (r == rows - 1 && cell.walls.bottom) {
          canvas.drawLine(Offset(x, y + cellHeight), Offset(x + cellWidth, y + cellHeight), wallPaint);
        }
      }
    }

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

    // 4. Draw User Glowing Traced Path
    if (userPath.isNotEmpty) {
      final pathPaint = Paint()
        ..color = themeColor
        ..strokeWidth = cellWidth * 0.35
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8.0);

      for (int i = 0; i < userPath.length - 1; i++) {
        final p1 = userPath[i];
        final p2 = userPath[i + 1];
        final c1 = Offset(p1.c * cellWidth + cellWidth / 2, p1.r * cellHeight + cellHeight / 2);
        final c2 = Offset(p2.c * cellWidth + cellWidth / 2, p2.r * cellHeight + cellHeight / 2);
        canvas.drawLine(c1, c2, pathPaint);
      }

      // Draw Cursor Endpoint Node
      final last = userPath.last;
      final headCenter = Offset(last.c * cellWidth + cellWidth / 2, last.r * cellHeight + cellHeight / 2);
      final headPaint = Paint()..color = Colors.white;
      final headGlowPaint = Paint()
        ..color = themeColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);

      canvas.drawCircle(headCenter, cellWidth * 0.28, headGlowPaint);
      canvas.drawCircle(headCenter, cellWidth * 0.20, headPaint);
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
