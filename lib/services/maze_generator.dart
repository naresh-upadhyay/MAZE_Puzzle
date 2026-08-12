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

class MazeGenerator {
  final int cols;
  final int rows;
  final bool isComplicated;
  final int? seed;
  late List<List<MazeCell>> grid;
  List<CellPosition> solutionPath = [];

  MazeGenerator({
    this.cols = 12,
    this.rows = 12,
    this.isComplicated = false,
    this.seed,
  });

  List<List<MazeCell>> generate() {
    grid = List.generate(
      rows,
      (r) => List.generate(cols, (c) => MazeCell(r, c)),
    );

    final rng = seed != null ? Random(seed) : Random();

    // Serpentine DFS with Direction Bias to create complex winding mazes
    final stack = <MazeCell>[];
    final startCell = grid[0][0];
    startCell.visited = true;
    stack.add(startCell);

    while (stack.isNotEmpty) {
      final current = stack.last;
      final neighbors = _getUnvisitedNeighbors(current, rng);

      if (neighbors.isNotEmpty) {
        final next = neighbors[rng.nextInt(neighbors.length)];
        _removeWalls(current, next);
        next.visited = true;
        stack.add(next);
      } else {
        stack.removeLast();
      }
    }

    if (isComplicated) {
      _makeMultiPathBraidMaze(rng);
    } else {
      // Add subtle extra branches for simple mazes so they aren't just 1 linear hallway
      _addMinorBranches(rng);
    }

    solutionPath = solveBFS(const CellPosition(0, 0), CellPosition(rows - 1, cols - 1));
    return grid;
  }

  void _addMinorBranches(Random rng) {
    final extraLoops = (rows * cols * 0.08).round();
    int added = 0;
    int safety = 200;
    while (added < extraLoops && safety > 0) {
      safety--;
      final r = rng.nextInt(rows);
      final c = rng.nextInt(cols);
      final cell = grid[r][c];

      final candidates = <MazeCell>[];
      if (r > 0 && cell.walls.top) candidates.add(grid[r - 1][c]);
      if (r < rows - 1 && cell.walls.bottom) candidates.add(grid[r + 1][c]);
      if (c > 0 && cell.walls.left) candidates.add(grid[r][c - 1]);
      if (c < cols - 1 && cell.walls.right) candidates.add(grid[r][c + 1]);

      if (candidates.isNotEmpty) {
        final target = candidates[rng.nextInt(candidates.length)];
        _removeWalls(cell, target);
        added++;
      }
    }
  }

  void _makeMultiPathBraidMaze(Random rng) {
    // 1. Remove 60% of dead ends to turn single-path dead ends into tricky loops
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = grid[r][c];
        int wallCount = 0;
        if (cell.walls.top) wallCount++;
        if (cell.walls.bottom) wallCount++;
        if (cell.walls.left) wallCount++;
        if (cell.walls.right) wallCount++;

        if (wallCount >= 3 && rng.nextDouble() < 0.70) {
          final candidates = <MazeCell>[];
          if (r > 0 && cell.walls.top) candidates.add(grid[r - 1][c]);
          if (r < rows - 1 && cell.walls.bottom) candidates.add(grid[r + 1][c]);
          if (c > 0 && cell.walls.left) candidates.add(grid[r][c - 1]);
          if (c < cols - 1 && cell.walls.right) candidates.add(grid[r][c + 1]);

          if (candidates.isNotEmpty) {
            final target = candidates[rng.nextInt(candidates.length)];
            _removeWalls(cell, target);
          }
        }
      }
    }

    // 2. Knock down extra internal walls to create multiple alternative routes to exit
    final extraLoops = (rows * cols * 0.22).round();
    int added = 0;
    int safety = 600;
    while (added < extraLoops && safety > 0) {
      safety--;
      final r = rng.nextInt(rows);
      final c = rng.nextInt(cols);
      final cell = grid[r][c];

      final candidates = <MazeCell>[];
      if (r > 0 && cell.walls.top) candidates.add(grid[r - 1][c]);
      if (r < rows - 1 && cell.walls.bottom) candidates.add(grid[r + 1][c]);
      if (c > 0 && cell.walls.left) candidates.add(grid[r][c - 1]);
      if (c < cols - 1 && cell.walls.right) candidates.add(grid[r][c + 1]);

      if (candidates.isNotEmpty) {
        final target = candidates[rng.nextInt(candidates.length)];
        _removeWalls(cell, target);
        added++;
      }
    }
  }

  List<MazeCell> _getUnvisitedNeighbors(MazeCell cell, Random rng) {
    final neighbors = <MazeCell>[];
    final r = cell.r;
    final c = cell.c;

    if (r > 0 && !grid[r - 1][c].visited) neighbors.add(grid[r - 1][c]);
    if (c < cols - 1 && !grid[r][c + 1].visited) neighbors.add(grid[r][c + 1]);
    if (r < rows - 1 && !grid[r + 1][c].visited) neighbors.add(grid[r + 1][c]);
    if (c > 0 && !grid[r][c - 1].visited) neighbors.add(grid[r][c - 1]);

    // Shuffle neighbors to avoid simple bias
    neighbors.shuffle(rng);
    return neighbors;
  }

  void _removeWalls(MazeCell a, MazeCell b) {
    final dr = b.r - a.r;
    final dc = b.c - a.c;

    if (dr == -1) { a.walls.top = false; b.walls.bottom = false; }
    else if (dr == 1) { a.walls.bottom = false; b.walls.top = false; }

    if (dc == 1) { a.walls.right = false; b.walls.left = false; }
    else if (dc == -1) { a.walls.left = false; b.walls.right = false; }
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
}
