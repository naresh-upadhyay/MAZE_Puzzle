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
  final Function(int stars, String formattedTime, int coinsEarned, int gemsEarned) onWinPayload;

  const GameplayScreen({super.key, required this.onBack, required this.onWinPayload});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  late MazeGenerator _generator;
  late MazeFlameGame _flameGame;

  int _moves = 0;
  int _seconds = 0;
  Timer? _timer;
  bool _hintUsed = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    final state = Provider.of<GameState>(context, listen: false);
    final cols = state.selectedMode == 'simple' ? 8 : 14;
    final rows = state.selectedMode == 'simple' ? 8 : 14;

    _generator = MazeGenerator(cols: cols, rows: rows);
    _generator.generate();

    final themeColor = AppTheme.themeColors[state.equippedTheme] ?? AppTheme.primaryGlow;

    _flameGame = MazeFlameGame(
      generator: _generator,
      themeColor: state.selectedMode == 'complicated' ? AppTheme.accentPink : themeColor,
      onWin: _handleWin,
      onMove: (moveCount) {
        setState(() {
          _moves = moveCount;
        });
      },
    );

    _startTimer();
  }

  void _handleWin() {
    _stopTimer();
    final state = Provider.of<GameState>(context, listen: false);

    // Calculate stars: 3 stars <= 25s & no hints; 2 stars <= 45s; 1 star otherwise
    int stars = 3;
    if (_seconds > 25 || _hintUsed || _flameGame.mistakeCount > 2) {
      stars = 2;
    }
    if (_seconds > 50 || _flameGame.mistakeCount > 5) {
      stars = 1;
    }

    final coinsEarned = stars * 25;
    final gemsEarned = stars > 2 ? 3 : 1;
    final isPerfect = stars == 3 && !_hintUsed && _flameGame.mistakeCount == 0;

    state.saveLevelResult(
      state.selectedMode,
      state.currentLevel,
      stars,
      _seconds.toDouble(),
      isPerfect,
      coinsEarned: coinsEarned,
      gemsEarned: gemsEarned,
    );

    widget.onWinPayload(stars, _formattedTime, coinsEarned, gemsEarned);
  }

  void _startTimer() {
    _stopTimer();
    _seconds = 0;
    _hintUsed = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  String get _formattedTime {
    final mins = (_seconds / 60).floor();
    final secs = _seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Gameplay Header HUD
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.pause, color: Colors.white, size: 24),
                    onPressed: widget.onBack,
                  ),
                  Column(
                    children: [
                      Text(
                        'LEVEL ${state.currentLevel} - ${state.selectedMode.toUpperCase()}',
                        style: GoogleFonts.orbitron(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGlow,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 12, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            _formattedTime,
                            style: GoogleFonts.orbitron(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.directions_walk, size: 12, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            'MOVES: $_moves',
                            style: GoogleFonts.orbitron(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPink.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accentPink.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite, size: 14, color: AppTheme.accentPink),
                        const SizedBox(width: 4),
                        Text(
                          '3',
                          style: GoogleFonts.orbitron(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentPink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // FLAME GAME CANVAS WIDGET
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF04050D),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 2),
                  ),
                  child: Stack(
                    children: [
                      // GAME CANVAS ENGINE
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: GameWidget(game: _flameGame),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Gameplay Controls Footer (UNDO, HINT, RESTART)
              Row(
                children: [
                  Expanded(
                    child: _ControlBtn(
                      icon: Icons.undo,
                      label: 'UNDO',
                      badge: '${state.undoCount}',
                      onTap: () {
                        if (state.undoCount > 0) {
                          state.useUndo();
                          _flameGame.undoStep();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ControlBtn(
                      icon: Icons.lightbulb,
                      iconColor: AppTheme.accentGold,
                      label: 'HINT',
                      badge: '${state.hintCount}',
                      onTap: () {
                        if (state.hintCount > 0) {
                          state.useHint();
                          _hintUsed = true;
                          _flameGame.showHint();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ControlBtn(
                      icon: Icons.refresh,
                      label: 'RESTART',
                      onTap: () {
                        _flameGame.restart();
                        _startTimer();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _ControlBtn({
    required this.icon,
    this.iconColor,
    required this.label,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: AppTheme.glassCardDecoration(),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                Icon(icon, size: 20, color: iconColor ?? Colors.white),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: -6,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.accentGold,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge!,
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
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
