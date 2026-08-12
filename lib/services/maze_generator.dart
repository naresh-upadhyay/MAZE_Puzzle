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
  late List<List<MazeCell>> grid;
  List<CellPosition> solutionPath = [];

  MazeGenerator({this.cols = 10, this.rows = 10});

  List<List<MazeCell>> generate() {
    grid = List.generate(
      rows,
      (r) => List.generate(cols, (c) => MazeCell(r, c)),
    );

    final stack = <MazeCell>[];
    final startCell = grid[0][0];
    startCell.visited = true;
    stack.add(startCell);

    final rng = Random();

    while (stack.isNotEmpty) {
      final current = stack.last;
      final neighbors = _getUnvisitedNeighbors(current);

      if (neighbors.isNotEmpty) {
        final next = neighbors[rng.nextInt(neighbors.length)];
        _removeWalls(current, next);
        next.visited = true;
        stack.add(next);
      } else {
        stack.removeLast();
      }
    }

    solutionPath = solveBFS(const CellPosition(0, 0), CellPosition(rows - 1, cols - 1));
    return grid;
  }

  List<MazeCell> _getUnvisitedNeighbors(MazeCell cell) {
    final neighbors = <MazeCell>[];
    final r = cell.r;
    final c = cell.c;

    if (r > 0 && !grid[r - 1][c].visited) neighbors.add(grid[r - 1][c]);
    if (c < cols - 1 && !grid[r][c + 1].visited) neighbors.add(grid[r][c + 1]);
    if (r < rows - 1 && !grid[r + 1][c].visited) neighbors.add(grid[r + 1][c]);
    if (c > 0 && !grid[r][c - 1].visited) neighbors.add(grid[r][c - 1]);

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
    final queue = <List<CellPosition>>[
      [start]
    ];
    final visited = <CellPosition>{start};

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final curr = path.last;

      if (curr == end) {
        return path;
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
            queue.add([...path, next]);
          }
        }
      }
    }
    return [];
  }
}
