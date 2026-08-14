import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../game/maze_flame_game.dart';
import '../models/game_state.dart';
import '../services/maze_generator.dart';
import '../theme/app_theme.dart';

class GameplayScreen extends StatefulWidget {
  final VoidCallback onBack;
  final Function(int stars, String formattedTime, int moves, int coinsEarned, int gemsEarned) onWinPayload;

  const GameplayScreen({super.key, required this.onBack, required this.onWinPayload});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen>
    with TickerProviderStateMixin {
  late MazeGenerator _generator;
  late MazeFlameGame _flameGame;

  // ── 5-Puzzle Level State ──────────────────────────────────────────────────
  int _currentPuzzleIndex = 1;
  static const int _totalPuzzles = 5;
  bool _showPhaseOverlay = false;
  bool _isPaused = false;

  // ── Timer & stats ──────────────────────────────────────────────────────────
  int _moves = 0;
  int _totalMoves = 0;
  int _seconds = 0;
  Timer? _timer;
  bool _hintUsed = false;
  int _totalMistakes = 0;

  // ── Wrong-path toast ───────────────────────────────────────────────────────
  bool _showWrongTurn = false;
  Timer? _wrongTurnTimer;

  // ── Progress ───────────────────────────────────────────────────────────────
  double _progress = 0.0;
  late AnimationController _progressBarAnim;

  @override
  void initState() {
    super.initState();
    _progressBarAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _initGame();
  }

  void _initGame() {
    _currentPuzzleIndex = 1;
    _totalMistakes = 0;
    _totalMoves = 0;
    _moves = 0;
    _progress = 0.0;
    _isPaused = false;
    _loadPuzzle(1);
    _startTimer();
  }

  Color _getPuzzleColor(int puzzleIdx, String equippedTheme) {
    switch (puzzleIdx) {
      case 1:
        return AppTheme.themeColors[equippedTheme] ?? AppTheme.primaryGlow;
      case 2:
        return const Color(0xFF00FFD0); // Neon Turquoise
      case 3:
        return const Color(0xFFFFB800); // Radiant Gold
      case 4:
        return AppTheme.accentPink; // Cyber Pink
      case 5:
      default:
        return const Color(0xFFFF3060); // Crimson Neon
    }
  }

  String _getPuzzleDifficultyName(int puzzleIdx) {
    switch (puzzleIdx) {
      case 1:
        return 'EASY (9×9)';
      case 2:
        return 'EASY+ (9×9)';
      case 3:
        return 'MEDIUM (11×11)';
      case 4:
        return 'MEDIUM+ (13×13)';
      case 5:
      default:
        return 'HARD (15×15)';
    }
  }

  void _loadPuzzle(int puzzleIndex) {
    final state = Provider.of<GameState>(context, listen: false);

    // 5 Progressive Grid Tiers (Capped at 15x15 for mobile touch comfort)
    int cols;
    switch (puzzleIndex) {
      case 1:
        cols = 9;
        break;
      case 2:
        cols = 9;
        break;
      case 3:
        cols = 11;
        break;
      case 4:
        cols = 13;
        break;
      case 5:
      default:
        cols = 15;
        break;
    }
    final rows = cols;

    final levelSeed = state.currentLevel * 1000 + puzzleIndex;

    _generator = MazeGenerator(
      cols: cols,
      rows: rows,
      puzzleIndex: puzzleIndex,
      seed: levelSeed,
    );
    _generator.generate();

    final themeColor = _getPuzzleColor(puzzleIndex, state.equippedTheme);

    _flameGame = MazeFlameGame(
      generator: _generator,
      themeColor: themeColor,
      onWin: _handlePuzzleWin,
      onMove: (moveCount) {
        if (mounted) {
          setState(() {
            _moves = moveCount;
            _progress = _flameGame.progressPercent;
          });
        }
      },
      onWrongPath: _handleWrongPath,
    );
  }

  // ── Wrong-path feedback ───────────────────────────────────────────────────
  void _handleWrongPath() {
    if (!mounted) return;
    setState(() => _showWrongTurn = true);
    _wrongTurnTimer?.cancel();
    _wrongTurnTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _showWrongTurn = false);
    });
  }

  // ── Puzzle win ────────────────────────────────────────────────────────────
  void _handlePuzzleWin() {
    _totalMistakes += _flameGame.mistakeCount;

    if (_currentPuzzleIndex < _totalPuzzles) {
      setState(() => _showPhaseOverlay = true);
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() {
          _totalMoves += _moves;
          _currentPuzzleIndex++;
          _showPhaseOverlay = false;
          _moves = 0;
          _progress = 0.0;
        });
        _loadPuzzle(_currentPuzzleIndex);
      });
    } else {
      // All 5 puzzles cleared — wait 900ms for victory wave celebration then report
      Future.delayed(const Duration(milliseconds: 950), () {
        if (!mounted) return;
        _stopTimer();
        final state = Provider.of<GameState>(context, listen: false);

        int stars = 3;
        if (_seconds > 120 || _hintUsed || _totalMistakes > 5) stars = 2;
        if (_seconds > 240 || _totalMistakes > 12) stars = 1;

        final coinsEarned = stars * 50;
        final gemsEarned = stars > 2 ? 5 : 2;
        final isPerfect = stars == 3 && !_hintUsed && _totalMistakes == 0;
        final cumulativeMoves = _totalMoves + _moves;

        state.saveLevelResult(
          'simple',
          state.currentLevel,
          stars,
          _seconds.toDouble(),
          isPerfect,
          coinsEarned: coinsEarned,
          gemsEarned: gemsEarned,
        );

        widget.onWinPayload(stars, _formattedTime, cumulativeMoves, coinsEarned, gemsEarned);
      });
    }
  }

  // ── Timer ─────────────────────────────────────────────────────────────────
  void _startTimer({bool resume = false}) {
    _stopTimer();
    if (!resume) {
      _seconds = 0;
      _hintUsed = false;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused && !_showPhaseOverlay) {
        setState(() => _seconds++);
      }
    });
  }

  void _stopTimer() => _timer?.cancel();

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  @override
  void dispose() {
    _stopTimer();
    _wrongTurnTimer?.cancel();
    _progressBarAnim.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_seconds / 60).floor();
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);
    final puzzleColor = _getPuzzleColor(_currentPuzzleIndex, state.equippedTheme);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  // ── HUD Row ────────────────────────────────────────────────────
                  _buildHUD(state, puzzleColor),
                  const SizedBox(height: 6),

                  // ── 5-Puzzle Segments & PATH PROGRESS bar ──────────────────────
                  _build5PuzzleProgressBar(puzzleColor),
                  const SizedBox(height: 8),

                  // ── Maze Canvas (Physical Corridor Navigation Area) ────────────
                  Expanded(child: _buildMazeArea(puzzleColor)),
                  const SizedBox(height: 10),

                  // ── Controls ───────────────────────────────────────────────────
                  _buildControls(state),
                ],
              ),
            ),

            // ── In-Game Pause Modal ───────────────────────────────────────────
            if (_isPaused) _buildPauseOverlay(state, puzzleColor),
          ],
        ),
      ),
    );
  }

  // ── HUD ───────────────────────────────────────────────────────────────────
  Widget _buildHUD(GameState state, Color puzzleColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left — Pause Button
        _HudIconBtn(
          icon: Icons.pause_rounded,
          onTap: _togglePause,
        ),

        // Center — Level + Puzzle + Stats
        Expanded(
          child: Column(
            children: [
              Text(
                'LEVEL ${state.currentLevel}',
                style: GoogleFonts.orbitron(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'PUZZLE $_currentPuzzleIndex / $_totalPuzzles  •  ${_getPuzzleDifficultyName(_currentPuzzleIndex)}',
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: puzzleColor,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, size: 11, color: AppTheme.textMuted),
                  const SizedBox(width: 3),
                  Text(_formattedTime,
                      style: GoogleFonts.orbitron(fontSize: 10, color: AppTheme.textMuted)),
                  const SizedBox(width: 14),
                  const Icon(Icons.directions_walk, size: 11, color: AppTheme.textMuted),
                  const SizedBox(width: 3),
                  Text('${_totalMoves + _moves}',
                      style: GoogleFonts.orbitron(fontSize: 10, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
        ),

        // Right — Lives
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.accentPink.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accentPink.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, size: 12, color: AppTheme.accentPink),
              const SizedBox(width: 4),
              Text(
                '${state.energy}',
                style: GoogleFonts.orbitron(
                    fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentPink),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 5-Puzzle Progress Bar with 5 Segments ──────────────────────────────────
  Widget _build5PuzzleProgressBar(Color color) {
    return Column(
      children: [
        // 5-Segment Pills
        Row(
          children: List.generate(_totalPuzzles, (idx) {
            final pNum = idx + 1;
            final isDone = pNum < _currentPuzzleIndex;
            final isCurrent = pNum == _currentPuzzleIndex;

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isDone
                      ? const Color(0xFF00FF9D)
                      : (isCurrent ? color : Colors.white.withValues(alpha: 0.10)),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.6),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Text('PATH',
                style: GoogleFonts.outfit(
                    fontSize: 9, color: AppTheme.textMuted, letterSpacing: 1)),
            const SizedBox(width: 6),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 3.5,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text('${(_progress * 100).round()}%',
                style: GoogleFonts.orbitron(
                    fontSize: 9, color: AppTheme.textMuted)),
          ],
        ),
      ],
    );
  }

  // ── Maze Area (Physical Game Canvas) ───────────────────────────────────────
  Widget _buildMazeArea(Color puzzleColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF060713),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: puzzleColor.withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: puzzleColor.withValues(alpha: 0.06),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Game canvas
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: RepaintBoundary(
              child: GameWidget(game: _flameGame),
            ),
          ),

          // "WRONG TURN" toast
          if (_showWrongTurn)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _showWrongTurn ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3030).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF3030).withValues(alpha: 0.5),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.block_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'WALL / DEAD END',
                          style: GoogleFonts.orbitron(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Interstitial Puzzle Cleared Transition Overlay
          if (_showPhaseOverlay)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 64, color: Color(0xFF00FF9D)),
                    const SizedBox(height: 14),
                    Text(
                      'PUZZLE $_currentPuzzleIndex CLEARED!',
                      style: GoogleFonts.orbitron(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF00FF9D),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'NEXT: PUZZLE ${_currentPuzzleIndex + 1} / $_totalPuzzles',
                      style: GoogleFonts.orbitron(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getPuzzleDifficultyName(_currentPuzzleIndex + 1),
                      style: GoogleFonts.orbitron(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getPuzzleColor(_currentPuzzleIndex + 1, 'neon')),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Controls ──────────────────────────────────────────────────────────────
  Widget _buildControls(GameState state) {
    final remainingHints = state.dailyHintsRemaining;

    return Row(
      children: [
        Expanded(
          child: _ControlBtn(
            icon: Icons.lightbulb_outline_rounded,
            iconColor: remainingHints > 0 ? AppTheme.accentGold : AppTheme.textMuted,
            label: 'HINT',
            badge: '$remainingHints/2',
            badgeColor: remainingHints > 0 ? AppTheme.accentGold : Colors.grey,
            onTap: () {
              if (remainingHints > 0) {
                if (state.useHint()) {
                  _hintUsed = true;
                  _flameGame.showHint();
                }
              } else {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF161B3D),
                    content: Text(
                      'Daily hint limit reached (2/2). Reset tomorrow!',
                      style: GoogleFonts.orbitron(fontSize: 11, color: AppTheme.accentGold),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ControlBtn(
            icon: Icons.refresh_rounded,
            label: 'RESTART',
            onTap: () {
              _flameGame.restart();
              setState(() {
                _moves = 0;
                _progress = 0.0;
              });
              _startTimer();
            },
          ),
        ),
      ],
    );
  }

  // ── In-Game Pause Modal ───────────────────────────────────────────────────
  Widget _buildPauseOverlay(GameState state, Color puzzleColor) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFF0E122B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: puzzleColor.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: puzzleColor.withValues(alpha: 0.20),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: puzzleColor.withValues(alpha: 0.15),
                  border: Border.all(color: puzzleColor, width: 2),
                ),
                child: Icon(Icons.pause_rounded, size: 34, color: puzzleColor),
              ),
              const SizedBox(height: 16),

              Text(
                'PAUSED',
                style: GoogleFonts.orbitron(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'LEVEL ${state.currentLevel} • PUZZLE $_currentPuzzleIndex / $_totalPuzzles',
                style: GoogleFonts.orbitron(
                  fontSize: 11,
                  color: puzzleColor,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 24),

              // Stats Row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatCol(label: 'TIME', val: _formattedTime),
                    _StatCol(label: 'MOVES', val: '$_moves'),
                    _StatCol(label: 'MISTAKES', val: '$_totalMistakes'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Resume Button
              _ModalBtn(
                label: 'RESUME',
                color: puzzleColor,
                textColor: Colors.black,
                onTap: _togglePause,
              ),
              const SizedBox(height: 10),

              // Restart Puzzle
              _ModalBtn(
                label: 'RESTART PUZZLE',
                color: Colors.white.withValues(alpha: 0.08),
                textColor: Colors.white,
                onTap: () {
                  _togglePause();
                  _flameGame.restart();
                  setState(() {
                    _moves = 0;
                    _progress = 0.0;
                  });
                  _startTimer();
                },
              ),
              const SizedBox(height: 10),

              // Exit to Map
              _ModalBtn(
                label: 'QUIT TO MAP',
                color: Colors.transparent,
                textColor: AppTheme.textMuted,
                border: true,
                onTap: () {
                  _stopTimer();
                  widget.onBack();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Supporting Widget Components ────────────────────────────────────────────
class _HudIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HudIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _ControlBtn({
    required this.icon,
    this.iconColor,
    required this.label,
    this.badge,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0E122B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: iconColor ?? Colors.white),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.orbitron(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? AppTheme.primaryGlow).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: (badgeColor ?? AppTheme.primaryGlow).withValues(alpha: 0.5),
                        width: 0.8),
                  ),
                  child: Text(
                    badge!,
                    style: GoogleFonts.orbitron(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: badgeColor ?? AppTheme.primaryGlow,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String val;

  const _StatCol({required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.orbitron(fontSize: 9, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(val, style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}

class _ModalBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final bool border;
  final VoidCallback onTap;

  const _ModalBtn({
    required this.label,
    required this.color,
    required this.textColor,
    this.border = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: border ? Border.all(color: Colors.white.withValues(alpha: 0.15)) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
