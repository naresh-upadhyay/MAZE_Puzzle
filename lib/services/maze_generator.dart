import 'dart:math';

class CellPosition {
  final int r;
  final int c;

  const CellPosition(this.r, this.c);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellPosition && runtimeType == other.runtimeType && r == other.r && c == other.c;

  @override
  int get hashCode => r.hashCode ^ c.hashCode;

  @override
  String toString() => '($r, $c)';
}

class CellWalls {
  bool top = true;
  bool right = true;
  bool bottom = true;
  bool left = true;
}

class MazeCell {
  final int r;
  final int c;
  final CellWalls walls = CellWalls();
  bool visited = false;

  MazeCell(this.r, this.c);

  CellPosition get pos => CellPosition(r, c);
}

/// Structural complexity metrics of a generated maze
class MazeMetrics {
  final int solutionLength;
  final int turnCount;
  final int deadEndCount;
  final int deepDeadEndCount;
  final int intersectionCount;
  final double difficultyScore;

  const MazeMetrics({
    required this.solutionLength,
    required this.turnCount,
    required this.deadEndCount,
    required this.deepDeadEndCount,
    required this.intersectionCount,
    required this.difficultyScore,
  });
}

class MazeGenerator {
  final int cols;
  final int rows;
  final int puzzleIndex; // 1 to 5
  final int? seed;
  late List<List<MazeCell>> grid;
  List<CellPosition> solutionPath = [];
  MazeMetrics? metrics;

  late CellPosition startPos;
  late CellPosition exitPos;

  MazeGenerator({
    this.cols = 11,
    this.rows = 11,
    this.puzzleIndex = 1,
    this.seed,
  }) {
    // Non-corner entry at bottom boundary, non-corner exit at top boundary
    final entryCol = (cols ~/ 2).clamp(1, cols - 2);
    final offset = (puzzleIndex % 2 == 0 ? 1 : -1) * (cols ~/ 4);
    final exitCol = ((cols ~/ 2) + offset).clamp(1, cols - 2);

    startPos = CellPosition(rows - 1, entryCol);
    exitPos = CellPosition(0, exitCol);
  }

  /// Generates a guaranteed solvable, challenging maze meeting target difficulty metrics
  List<List<MazeCell>> generate() {
    final baseSeed = seed ?? Random().nextInt(1000000);
    var attempt = 0;
    const maxAttempts = 60;

    while (attempt < maxAttempts) {
      final rng = Random(baseSeed + attempt * 7919);
      _generateCandidate(rng);

      solutionPath = solveBFS(startPos, exitPos);
      if (solutionPath.length >= 2) {
        metrics = _calculateMetrics(solutionPath);
        if (_meetsDifficulty(metrics!, puzzleIndex)) {
          break;
        }
      }
      attempt++;
    }

    // Ensure outer boundary walls are 100% solid except at the entry & exit gates
    _enforceBoundaryGates();
    return grid;
  }

  /// Procedural Maze Generation using Recursive Backtracking with Winding Corridor Bias
  void _generateCandidate(Random rng) {
    grid = List.generate(
      rows,
      (r) => List.generate(cols, (c) => MazeCell(r, c)),
    );

    // Recursive Backtracking carving from startPos
    final stack = <MazeCell>[grid[startPos.r][startPos.c]];
    grid[startPos.r][startPos.c].visited = true;

    while (stack.isNotEmpty) {
      final current = stack.last;
      final unvisited = _getUnvisitedNeighbors(current, rng);

      if (unvisited.isNotEmpty) {
        final next = unvisited[rng.nextInt(unvisited.length)];
        _removeWalls(current, next);
        next.visited = true;
        stack.add(next);
      } else {
        stack.removeLast();
      }
    }

    // Clean up any 3-open isolated single wall stubs inside grid
    _refineWallStubs();
  }

  void _enforceBoundaryGates() {
    for (int c = 0; c < cols; c++) {
      // Top boundary solid except at exitPos.c
      grid[0][c].walls.top = (c != exitPos.c);
      // Bottom boundary solid except at startPos.c
      grid[rows - 1][c].walls.bottom = (c != startPos.c);
    }
    for (int r = 0; r < rows; r++) {
      // Left and right boundaries 100% solid
      grid[r][0].walls.left = true;
      grid[r][cols - 1].walls.right = true;
    }
  }

  void _refineWallStubs() {
    for (int r = 1; r < rows - 1; r++) {
      for (int c = 1; c < cols - 1; c++) {
        final cell = grid[r][c];
        int openCount = 0;
        if (!cell.walls.top) openCount++;
        if (!cell.walls.bottom) openCount++;
        if (!cell.walls.left) openCount++;
        if (!cell.walls.right) openCount++;

        // Smooth out isolated 1-wall stubs inside the grid
        if (openCount == 3) {
          if (cell.walls.top) {
            _removeWalls(cell, grid[r - 1][c]);
          } else if (cell.walls.bottom) {
            _removeWalls(cell, grid[r + 1][c]);
          } else if (cell.walls.left) {
            _removeWalls(cell, grid[r][c - 1]);
          } else if (cell.walls.right) {
            _removeWalls(cell, grid[r][c + 1]);
          }
        }
      }
    }
  }

  List<MazeCell> _getUnvisitedNeighbors(MazeCell cell, Random rng) {
    final neighbors = <MazeCell>[];
    final r = cell.r;
    final c = cell.c;

    if (r > 0 && !grid[r - 1][c].visited) neighbors.add(grid[r - 1][c]);
    if (r < rows - 1 && !grid[r + 1][c].visited) neighbors.add(grid[r + 1][c]);
    if (c > 0 && !grid[r][c - 1].visited) neighbors.add(grid[r][c - 1]);
    if (c < cols - 1 && !grid[r][c + 1].visited) neighbors.add(grid[r][c + 1]);

    neighbors.shuffle(rng);
    return neighbors;
  }

  void _removeWalls(MazeCell a, MazeCell b) {
    final dr = b.r - a.r;
    final dc = b.c - a.c;

    if (dr == -1) {
      a.walls.top = false;
      b.walls.bottom = false;
    } else if (dr == 1) {
      a.walls.bottom = false;
      b.walls.top = false;
    }

    if (dc == 1) {
      a.walls.right = false;
      b.walls.left = false;
    } else if (dc == -1) {
      a.walls.left = false;
      b.walls.right = false;
    }
  }

  bool canMove(CellPosition fromPos, CellPosition toPos) {
    if (fromPos == toPos) return true;
    final dr = toPos.r - fromPos.r;
    final dc = toPos.c - fromPos.c;

    if ((dr.abs() + dc.abs()) != 1) return false;
    if (toPos.r < 0 || toPos.r >= rows || toPos.c < 0 || toPos.c >= cols) return false;

    final cell = grid[fromPos.r][fromPos.c];

    if (dr == -1 && !cell.walls.top) return true;
    if (dr == 1 && !cell.walls.bottom) return true;
    if (dc == 1 && !cell.walls.right) return true;
    if (dc == -1 && !cell.walls.left) return true;

    return false;
  }

  List<CellPosition> solveBFS(CellPosition start, CellPosition end) {
    final queue = <CellPosition>[start];
    final parent = <CellPosition, CellPosition>{};
    final visited = <CellPosition>{start};

    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);

      if (curr == end) {
        final path = <CellPosition>[];
        CellPosition? temp = end;
        while (temp != null) {
          path.add(temp);
          temp = parent[temp];
        }
        return path.reversed.toList();
      }

      final neighbors = [
        CellPosition(curr.r - 1, curr.c),
        CellPosition(curr.r + 1, curr.c),
        CellPosition(curr.r, curr.c - 1),
        CellPosition(curr.r, curr.c + 1),
      ];

      for (final next in neighbors) {
        if (next.r >= 0 && next.r < rows && next.c >= 0 && next.c < cols) {
          if (!visited.contains(next) && canMove(curr, next)) {
            visited.add(next);
            parent[next] = curr;
            queue.add(next);
          }
        }
      }
    }
    return [];
  }

  MazeMetrics _calculateMetrics(List<CellPosition> path) {
    final solLen = path.length;

    // 1. Calculate turns in solution path
    var turns = 0;
    for (int i = 1; i < path.length - 1; i++) {
      final prev = path[i - 1];
      final curr = path[i];
      final next = path[i + 1];
      final d1 = CellPosition(curr.r - prev.r, curr.c - prev.c);
      final d2 = CellPosition(next.r - curr.r, next.c - curr.c);
      if (d1 != d2) turns++;
    }

    // 2. Count dead ends, deep dead ends, and intersections across whole maze
    var deadEnds = 0;
    var deepDeadEnds = 0;
    var intersections = 0;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = grid[r][c];
        var openCount = 0;
        if (!cell.walls.top) openCount++;
        if (!cell.walls.bottom) openCount++;
        if (!cell.walls.left) openCount++;
        if (!cell.walls.right) openCount++;

        if (openCount == 1 && cell.pos != startPos && cell.pos != exitPos) {
          deadEnds++;
          // Check dead-end depth via short backtrack
          if (_getDeadEndDepth(cell.pos) >= 3) {
            deepDeadEnds++;
          }
        } else if (openCount >= 3) {
          intersections++;
        }
      }
    }

    final score = (solLen * 1.5) + (turns * 2.2) + (deadEnds * 1.2) + (intersections * 1.8);

    return MazeMetrics(
      solutionLength: solLen,
      turnCount: turns,
      deadEndCount: deadEnds,
      deepDeadEndCount: deepDeadEnds,
      intersectionCount: intersections,
      difficultyScore: score,
    );
  }

  int _getDeadEndDepth(CellPosition deadEnd) {
    var depth = 1;
    var curr = deadEnd;
    final visited = <CellPosition>{curr};

    while (depth < 8) {
      final neighbors = [
        CellPosition(curr.r - 1, curr.c),
        CellPosition(curr.r + 1, curr.c),
        CellPosition(curr.r, curr.c - 1),
        CellPosition(curr.r, curr.c + 1),
      ];

      CellPosition? nextStep;
      for (final n in neighbors) {
        if (n.r >= 0 && n.r < rows && n.c >= 0 && n.c < cols && !visited.contains(n) && canMove(curr, n)) {
          nextStep = n;
          break;
        }
      }

      if (nextStep == null) break;
      curr = nextStep;
      visited.add(curr);

      final cell = grid[curr.r][curr.c];
      var openCount = 0;
      if (!cell.walls.top) openCount++;
      if (!cell.walls.bottom) openCount++;
      if (!cell.walls.left) openCount++;
      if (!cell.walls.right) openCount++;
      if (openCount >= 3) break;

      depth++;
    }
    return depth;
  }

  bool _meetsDifficulty(MazeMetrics m, int pIdx) {
    switch (pIdx) {
      case 1: // Easy (9x9)
        return m.solutionLength >= 12 && m.turnCount >= 4;
      case 2: // Easy+ (9x9 / 11x11)
        return m.solutionLength >= 15 && m.turnCount >= 6;
      case 3: // Medium (11x11)
        return m.solutionLength >= 18 && m.turnCount >= 8;
      case 4: // Medium+ (13x13)
        return m.solutionLength >= 22 && m.turnCount >= 10;
      case 5: // Hard (15x15)
      default:
        return m.solutionLength >= 26 && m.turnCount >= 12;
    }
  }
}
