import 'package:flutter_test/flutter_test.dart';
import 'package:maze_glow_path/services/maze_generator.dart';

void main() {
  group('Maze Generator & Difficulty Verification Tests', () {
    test('Verify all 5 puzzle tiers generate solvable, complex mazes', () {
      final configs = [
        {'tier': 1, 'cols': 9, 'rows': 9, 'minLen': 12, 'minTurns': 4},
        {'tier': 2, 'cols': 9, 'rows': 9, 'minLen': 15, 'minTurns': 6},
        {'tier': 3, 'cols': 11, 'rows': 11, 'minLen': 18, 'minTurns': 8},
        {'tier': 4, 'cols': 13, 'rows': 13, 'minLen': 22, 'minTurns': 10},
        {'tier': 5, 'cols': 15, 'rows': 15, 'minLen': 26, 'minTurns': 12},
      ];

      for (final cfg in configs) {
        final tier = cfg['tier'] as int;
        final cols = cfg['cols'] as int;
        final rows = cfg['rows'] as int;
        final minLen = cfg['minLen'] as int;
        final minTurns = cfg['minTurns'] as int;

        final generator = MazeGenerator(
          cols: cols,
          rows: rows,
          puzzleIndex: tier,
          seed: 42000 + tier,
        );

        generator.generate();

        // 1. Solvability
        expect(generator.solutionPath.isNotEmpty, true, reason: 'Puzzle tier $tier must have a solution');
        expect(generator.solutionPath.first, generator.startPos);
        expect(generator.solutionPath.last, generator.exitPos);

        // 2. Non-corner gate positions
        expect(generator.startPos.r, rows - 1);
        expect(generator.startPos.c > 0 && generator.startPos.c < cols - 1, true,
            reason: 'Entry gate must not be in corner');
        expect(generator.exitPos.r, 0);
        expect(generator.exitPos.c > 0 && generator.exitPos.c < cols - 1, true,
            reason: 'Exit gate must not be in corner');

        // 3. Boundary walls: open only at entry and exit
        for (int c = 0; c < cols; c++) {
          expect(generator.grid[0][c].walls.top, c != generator.exitPos.c,
              reason: 'Top boundary open only at exit');
          expect(generator.grid[rows - 1][c].walls.bottom, c != generator.startPos.c,
              reason: 'Bottom boundary open only at entry');
        }
        for (int r = 0; r < rows; r++) {
          expect(generator.grid[r][0].walls.left, true, reason: 'Left boundary solid');
          expect(generator.grid[r][cols - 1].walls.right, true, reason: 'Right boundary solid');
        }

        // 4. Metrics & Complexity
        final m = generator.metrics;
        expect(m != null, true);
        expect(m!.solutionLength >= minLen, true,
            reason: 'Tier $tier solution length (${m.solutionLength}) should meet min ($minLen)');
        expect(m.turnCount >= minTurns, true,
            reason: 'Tier $tier turn count (${m.turnCount}) should meet min ($minTurns)');
        expect(m.deadEndCount > 0, true);
      }
    });
  });
}
