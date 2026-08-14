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

  // ── Dual-puzzle state ──────────────────────────────────────────────────────
  int  _currentPuzzleIndex = 1;
  bool _showPhaseOverlay   = false;
  bool _isPaused           = false;

  // ── Timer & stats ──────────────────────────────────────────────────────────
  int    _moves         = 0;
  int    _seconds       = 0;
  Timer? _timer;
  bool   _hintUsed      = false;
  int    _totalMistakes = 0;

  // ── Wrong-path toast ───────────────────────────────────────────────────────
  bool _showWrongTurn = false;
  Timer? _wrongTurnTimer;

  // ── Progress ───────────────────────────────────────────────────────────────
  double _progress = 0.0;

  // ── Progress bar animation ─────────────────────────────────────────────────
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
    _progress = 0.0;
    _isPaused = false;
    _loadPuzzle(1);
    _startTimer();
  }

  void _loadPuzzle(int puzzleIndex) {
    final state = Provider.of<GameState>(context, listen: false);

    final level = state.currentLevel;
    final isComplicated = puzzleIndex == 2;
    final cols = isComplicated
        ? (14 + (level * 0.08).floor()).clamp(14, 18)
        : (10 + (level * 0.05).floor()).clamp(10, 12);
    final rows = cols;

    final levelSeed = state.currentLevel * 100 + puzzleIndex;

    _generator = MazeGenerator(
      cols: cols,
      rows: rows,
      isComplicated: isComplicated,
      seed: levelSeed,
    );
    _generator.generate();

    final equippedColor = AppTheme.themeColors[state.equippedTheme] ?? AppTheme.primaryGlow;
    final themeColor = isComplicated ? AppTheme.accentPink : equippedColor;

    _flameGame = MazeFlameGame(
      generator: _generator,
      themeColor: themeColor,
      onWin: _handlePuzzleWin,
      onMove: (moveCount) {
        setState(() {
          _moves    = moveCount;
          _progress = _flameGame.progressPercent;
        });
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

    if (_currentPuzzleIndex == 1) {
      setState(() => _showPhaseOverlay = true);
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (!mounted) return;
        setState(() {
          _currentPuzzleIndex = 2;
          _showPhaseOverlay   = false;
          _moves              = 0;
          _progress           = 0.0;
        });
        _loadPuzzle(2);
      });
    } else {
      // Both puzzles cleared — wait 900ms for win animation then report
      Future.delayed(const Duration(milliseconds: 950), () {
        if (!mounted) return;
        _stopTimer();
        final state = Provider.of<GameState>(context, listen: false);

        int stars = 3;
        if (_seconds > 45 || _hintUsed || _totalMistakes > 3) stars = 2;
        if (_seconds > 90 || _totalMistakes > 7) stars = 1;

        final coinsEarned = stars * 30;
        final gemsEarned  = stars > 2 ? 4 : 2;
        final isPerfect   = stars == 3 && !_hintUsed && _totalMistakes == 0;

        state.saveLevelResult(
          'simple',
          state.currentLevel,
          stars,
          _seconds.toDouble(),
          isPerfect,
          coinsEarned: coinsEarned,
          gemsEarned: gemsEarned,
        );

        widget.onWinPayload(stars, _formattedTime, _moves, coinsEarned, gemsEarned);
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
    final state      = Provider.of<GameState>(context);
    final isP2       = _currentPuzzleIndex == 2;
    final puzzleColor = isP2 ? AppTheme.accentPink : AppTheme.primaryGlow;

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

                  // ── PATH PROGRESS bar ──────────────────────────────────────────
                  _buildProgressBar(puzzleColor),
                  const SizedBox(height: 8),

                  // ── Maze Canvas ────────────────────────────────────────────────
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
                'PUZZLE $_currentPuzzleIndex / 2',
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: puzzleColor,
                  letterSpacing: 2,
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
                  Text('$_moves',
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

  // ── Progress bar ──────────────────────────────────────────────────────────
  Widget _buildProgressBar(Color color) {
    return Row(
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
              minHeight: 4,
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
    );
  }

  // ── Maze area with overlays ───────────────────────────────────────────────
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
                          'WRONG TURN',
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

          // Puzzle 1 cleared transition overlay
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
                        size: 64, color: AppTheme.primaryGlow),
                    const SizedBox(height: 14),
                    Text(
                      'PUZZLE 1 CLEARED!',
                      style: GoogleFonts.orbitron(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryGlow,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PUZZLE 2  —  MULTI-PATH MAZE',
                      style: GoogleFonts.orbitron(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentPink),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Multiple routes — find the EXIT',
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: AppTheme.textMuted),
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
                _moves    = 0;
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
                'GAME PAUSED',
                style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'LEVEL ${state.currentLevel} • PUZZLE $_currentPuzzleIndex / 2',
                style: GoogleFonts.orbitron(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: puzzleColor,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),

              // Resume Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _togglePause,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: puzzleColor,
                    foregroundColor: Colors.black,
                    elevation: 8,
                    shadowColor: puzzleColor.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded, size: 22, color: Colors.black),
                      const SizedBox(width: 8),
                      Text(
                        'RESUME',
                        style: GoogleFonts.orbitron(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Restart Level Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () {
                    _togglePause();
                    _flameGame.restart();
                    setState(() {
                      _moves = 0;
                      _progress = 0.0;
                    });
                    _startTimer();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.refresh_rounded, size: 18, color: Colors.white70),
                      const SizedBox(width: 8),
                      Text(
                        'RESTART PUZZLE',
                        style: GoogleFonts.orbitron(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Quit to Menu Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () {
                    _stopTimer();
                    widget.onBack();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF4060),
                    side: BorderSide(color: const Color(0xFFFF4060).withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.home_rounded, size: 18, color: Color(0xFFFF4060)),
                      const SizedBox(width: 8),
                      Text(
                        'EXIT TO MENU',
                        style: GoogleFonts.orbitron(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── HUD icon button ───────────────────────────────────────────────────────────
class _HudIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HudIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ── Control button ────────────────────────────────────────────────────────────
class _ControlBtn extends StatefulWidget {
  final IconData icon;
  final Color?   iconColor;
  final String   label;
  final String?  badge;
  final Color?   badgeColor;
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
  State<_ControlBtn> createState() => _ControlBtnState();
}

class _ControlBtnState extends State<_ControlBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween(begin: 1.0, end: 0.92).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: ()  => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFF0E122B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon,
                      size: 22, color: widget.iconColor ?? Colors.white),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: GoogleFonts.orbitron(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
              if (widget.badge != null)
                Positioned(
                  top: -8,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.badgeColor ?? AppTheme.accentGold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.badge!,
                      style: GoogleFonts.orbitron(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
