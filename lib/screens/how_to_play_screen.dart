import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class HowToPlayScreen extends StatefulWidget {
  final VoidCallback onGotIt;

  const HowToPlayScreen({super.key, required this.onGotIt});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _demoAnimCtrl;

  @override
  void initState() {
    super.initState();
    _demoAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _demoAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // Background Glow Orbs
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGlow.withValues(alpha: 0.12),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentPink.withValues(alpha: 0.10),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // ── Top Header ─────────────────────────────────────────────
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
                        onPressed: widget.onGotIt,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'HOW TO PLAY',
                        style: GoogleFonts.orbitron(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGlow.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryGlow.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'GUIDE',
                          style: GoogleFonts.orbitron(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGlow,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Main Scrollable Body ───────────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          // ── Live Animated Maze Demo Card ───────────────────
                          _buildAnimatedDemoCard(),
                          const SizedBox(height: 16),

                          // ── 3 Instruction Steps ─────────────────────────────
                          _buildInstructionCard(
                            stepNum: '01',
                            title: 'TOUCH START & DRAG',
                            desc: 'Touch the green START node to initiate the beam, then drag your finger through open corridors.',
                            icon: Icons.touch_app_rounded,
                            iconColor: AppTheme.primaryGlow,
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionCard(
                            stepNum: '02',
                            title: 'TRACE NEON PATH',
                            desc: 'A 4-layer glowing neon beam follows your finger smoothly. Avoid touching the thick navy walls!',
                            icon: Icons.auto_awesome_rounded,
                            iconColor: AppTheme.accentGold,
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionCard(
                            stepNum: '03',
                            title: 'REACH THE EXIT PORTAL',
                            desc: 'Navigate through the maze to reach the magenta EXIT node to complete the level and claim 3 stars!',
                            icon: Icons.flag_circle_rounded,
                            iconColor: AppTheme.accentPink,
                          ),
                          const SizedBox(height: 16),

                          // ── Pro Tip Glassmorphic Banner ─────────────────────
                          _buildProTipBanner(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // ── Hero Bottom Button ─────────────────────────────────────
                  _buildGotItButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Animated Mini-Maze Demo Card ──────────────────────────────────────────
  Widget _buildAnimatedDemoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E122B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGlow.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGlow.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIVE PREVIEW',
                style: GoogleFonts.orbitron(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryGlow,
                  letterSpacing: 1.5,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGlow,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'AUTO-DEMO',
                    style: GoogleFonts.orbitron(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mini Maze Canvas
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF060713),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: AnimatedBuilder(
              animation: _demoAnimCtrl,
              builder: (context, child) {
                return CustomPaint(
                  painter: _MiniMazeDemoPainter(progress: _demoAnimCtrl.value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Step Card ─────────────────────────────────────────────────────────────
  Widget _buildInstructionCard({
    required String stepNum,
    required String title,
    required String desc,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E122B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Icon Frame
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Icon(icon, size: 22, color: iconColor),
            ),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.orbitron(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      stepNum,
                      style: GoogleFonts.orbitron(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Pro Tip Banner ────────────────────────────────────────────────────────
  Widget _buildProTipBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_rounded, color: AppTheme.accentGold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'PRO TIP: Hitting a wall causes a short red flash without resetting progress. Use UNDO or HINT if you get stuck!',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.white70,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Bottom Button ────────────────────────────────────────────────────
  Widget _buildGotItButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onGotIt();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00FF9D), Color(0xFF00B36B)],
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGlow.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'READY TO PLAY',
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mini-Maze Demo Custom Painter ────────────────────────────────────────────
class _MiniMazeDemoPainter extends CustomPainter {
  final double progress;

  _MiniMazeDemoPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid cells (4x3)
    final cw = w / 4;
    final ch = h / 3;

    // 1. Grid Background lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.8;
    for (int r = 0; r <= 3; r++) {
      canvas.drawLine(Offset(0, r * ch), Offset(w, r * ch), gridPaint);
    }
    for (int c = 0; c <= 4; c++) {
      canvas.drawLine(Offset(c * cw, 0), Offset(c * cw, h), gridPaint);
    }

    // 2. Thick 3D Navy Walls
    final wallBody = Paint()
      ..color = const Color(0xFF1A1F55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.square;

    final wallHighlight = Paint()
      ..color = const Color(0xFF2D3490)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.square;

    final wallPath = Path();
    // Inner wall segments creating a clean mini corridor
    wallPath.moveTo(cw, 0); wallPath.lineTo(cw, ch * 2);
    wallPath.moveTo(cw * 2, ch); wallPath.lineTo(cw * 2, h);
    wallPath.moveTo(cw * 3, 0); wallPath.lineTo(cw * 3, ch * 2);

    canvas.drawPath(wallPath, wallBody);
    canvas.drawPath(wallPath, wallHighlight);

    // 3. START Node (top-left 0,0)
    final startCenter = Offset(cw / 2, ch / 2);
    final startPaint = Paint()..color = const Color(0xFF00FF9D);
    canvas.drawCircle(startCenter, 10, startPaint..color = const Color(0xFF00FF9D).withValues(alpha: 0.3));
    canvas.drawCircle(startCenter, 6, startPaint..color = const Color(0xFF00FF9D));

    // 4. EXIT Node (bottom-right 3,2)
    final exitCenter = Offset(cw * 3.5, ch * 2.5);
    final exitPaint = Paint()..color = const Color(0xFFFF2A6D);
    canvas.drawCircle(exitCenter, 11, exitPaint..color = const Color(0xFFFF2A6D).withValues(alpha: 0.3));
    canvas.drawCircle(exitCenter, 7, exitPaint..color = const Color(0xFFFF2A6D));

    // 5. Solution Waypoints Path
    final points = [
      Offset(cw / 2, ch / 2),
      Offset(cw / 2, ch * 2.5),
      Offset(cw * 1.5, ch * 2.5),
      Offset(cw * 1.5, ch / 2),
      Offset(cw * 2.5, ch / 2),
      Offset(cw * 2.5, ch * 2.5),
      Offset(cw * 3.5, ch * 2.5),
    ];

    // Compute animated current position along path
    final totalSegs = points.length - 1;
    final currSegFloat = progress * totalSegs;
    final segIdx = currSegFloat.floor().clamp(0, totalSegs - 1);
    final segPct = currSegFloat - segIdx;

    final p1 = points[segIdx];
    final p2 = points[segIdx + 1];
    final currentPos = Offset(
      p1.dx + (p2.dx - p1.dx) * segPct,
      p1.dy + (p2.dy - p1.dy) * segPct,
    );

    // Build partial path up to currentPos
    final tracedPath = Path();
    tracedPath.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i <= segIdx; i++) {
      tracedPath.lineTo(points[i].dx, points[i].dy);
    }
    tracedPath.lineTo(currentPos.dx, currentPos.dy);

    // 6. Layered Neon Trail (Bloom, Glow, Core)
    final trailBloom = Paint()
      ..color = const Color(0xFF00FF9D).withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final trailGlow = Paint()
      ..color = const Color(0xFF00FF9D).withValues(alpha: 0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final trailCore = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(tracedPath, trailBloom);
    canvas.drawPath(tracedPath, trailGlow);
    canvas.drawPath(tracedPath, trailCore);

    // 7. Small Energy Orb Head + Touch Finger Target
    final orbGlow = Paint()..color = const Color(0xFF00FF9D).withValues(alpha: 0.4);
    final orbCore = Paint()..color = Colors.white;
    canvas.drawCircle(currentPos, 12, orbGlow);
    canvas.drawCircle(currentPos, 5, orbCore);

    // Touch ring animation
    final touchRing = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(currentPos, 18 + math.sin(progress * math.pi * 8) * 3, touchRing);
  }

  @override
  bool shouldRepaint(_MiniMazeDemoPainter old) => old.progress != progress;
}
