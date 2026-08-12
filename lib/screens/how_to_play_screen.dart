import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class HowToPlayScreen extends StatelessWidget {
  final VoidCallback onGotIt;

  const HowToPlayScreen({super.key, required this.onGotIt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF0F153A), Color(0xFF04050D)],
            radius: 1.2,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header
                Text(
                  'HOW TO PLAY',
                  style: GoogleFonts.orbitron(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),

                // Tutorial Demo Section (Maze Preview + 3 Instructions)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.glassCardDecoration(glowColor: AppTheme.primaryGlow),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Interactive Visual Mini-Maze Canvas Demo
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: const Color(0xFF060713),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Stack(
                            children: [
                              // Grid lines
                              CustomPaint(
                                size: const Size(200, 200),
                                painter: _DemoMazePainter(),
                              ),
                              // Hand pointer icon
                              Positioned(
                                left: 100,
                                top: 90,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.primaryGlow, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.touch_app,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 3 Step Text Instructions
                        _InstructionStep(
                          number: '1.',
                          text: 'Drag your finger on the correct path.',
                        ),
                        const SizedBox(height: 14),
                        _InstructionStep(
                          number: '2.',
                          text: 'The path will glow as you draw.',
                        ),
                        const SizedBox(height: 14),
                        _InstructionStep(
                          number: '3.',
                          text: 'Reach the EXIT to complete the maze.',
                        ),
                      ],
                    ),
                  ),
                ),

                // GOT IT HERO BUTTON
                GestureDetector(
                  onTap: onGotIt,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: AppTheme.primaryButtonDecoration(),
                    child: Center(
                      child: Text(
                        'GOT IT!',
                        style: GoogleFonts.orbitron(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: GoogleFonts.orbitron(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGlow,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _DemoMazePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / 5;
    final cellHeight = size.height / 5;

    // Top & Left Outer Box
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.transparent..style = PaintingStyle.stroke..strokeWidth = 4..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2));

    // Demo Glowing Green Traced Path
    final pathPaint = Paint()
      ..color = const Color(0xFF00FF9D)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);

    final path = Path()
      ..moveTo(cellWidth / 2, cellHeight / 2)
      ..lineTo(cellWidth / 2, cellHeight * 2.5)
      ..lineTo(cellWidth * 2.5, cellHeight * 2.5);

    canvas.drawPath(path, pathPaint);

    // START Badge
    final startBgPaint = Paint()..color = const Color(0xFF00FF9D);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(4, 4, 38, 16), const Radius.circular(4)), startBgPaint);

    // EXIT Badge
    final exitBgPaint = Paint()..color = const Color(0xFFFF3366);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width - 42, size.height - 20, 38, 16), const Radius.circular(4)), exitBgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
