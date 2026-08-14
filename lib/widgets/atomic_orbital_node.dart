import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// An atomic orbital location point widget featuring:
/// - 3D-angled elliptical orbital rings
/// - Revolving quantum/electron satellites with 3D depth scaling (front vs back)
/// - Multi-layered pulsating neon glow rings
/// - Holographic center nucleus with level number
/// - Golden stars badge or "NOW" active level badge
class AtomicOrbitalNodeWidget extends StatelessWidget {
  final int level;
  final int currentLevel;
  final int stars;
  final double pulseValue; // 0.0 -> 1.0 animation progress
  final double orbitProgress; // continuous 0.0 -> 1.0 rotation progress
  final VoidCallback? onTap;
  final double size; // overall diameter of the node nucleus (default ~60)

  const AtomicOrbitalNodeWidget({
    super.key,
    required this.level,
    required this.currentLevel,
    this.stars = 0,
    required this.pulseValue,
    required this.orbitProgress,
    this.onTap,
    this.size = 62.0,
  });

  bool get isCompleted => level < currentLevel;
  bool get isActive => level == currentLevel;
  bool get isLocked => level > currentLevel;

  @override
  Widget build(BuildContext context) {
    final actualStars = stars.clamp(0, 3);
    final nucleusSize = isActive ? size * 1.16 : size;
    const totalWidgetSize = 140.0;

    Color primaryColor;
    Color secondaryColor;

    if (isActive) {
      primaryColor = const Color(0xFFFF007F); // Neon Magenta
      secondaryColor = const Color(0xFF00F0FF); // Cyan
    } else if (isCompleted) {
      primaryColor = const Color(0xFF00FF9D); // Neon Emerald
      secondaryColor = const Color(0xFF00E5FF); // Cyan/Turquoise
    } else {
      primaryColor = const Color(0xFF3B4861); // Muted Cyber Slate
      secondaryColor = const Color(0xFF1E293B);
    }

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: totalWidgetSize,
        height: totalWidgetSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Multi-Layer Pulsating Glow Halo
            if (!isLocked)
              _PulseGlowHalo(
                size: totalWidgetSize,
                pulseValue: pulseValue,
                color: primaryColor,
                isActive: isActive,
              ),

            // 2. Orbital Rings & Revolving Satellites (Behind Nucleus Layer)
            CustomPaint(
              size: const Size(totalWidgetSize, totalWidgetSize),
              painter: _AtomicOrbitalsPainter(
                orbitProgress: orbitProgress,
                pulseValue: pulseValue,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                isActive: isActive,
                isCompleted: isCompleted,
                isLocked: isLocked,
                drawFrontLayerOnly: false,
              ),
            ),

            // 3. Central Nucleus Disc
            _buildNucleus(nucleusSize, primaryColor, secondaryColor),

            // 4. Orbital Satellites (Front Layer - Passing in Front of Nucleus)
            CustomPaint(
              size: const Size(totalWidgetSize, totalWidgetSize),
              painter: _AtomicOrbitalsPainter(
                orbitProgress: orbitProgress,
                pulseValue: pulseValue,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                isActive: isActive,
                isCompleted: isCompleted,
                isLocked: isLocked,
                drawFrontLayerOnly: true,
              ),
            ),

            // 5. Stars or Status Badge (Bottom of Nucleus)
            if (isCompleted)
              Positioned(
                bottom: 8,
                child: _buildStarsRow(actualStars),
              )
            else if (isActive)
              Positioned(
                bottom: 6,
                child: _buildActiveBadge(),
              ),
          ],
        ),
      ),
    );
  }

  // ── Central Nucleus Disc ────────────────────────────────────────────────────
  Widget _buildNucleus(double diameter, Color primaryColor, Color secondaryColor) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isActive
            ? const RadialGradient(
                center: Alignment(-0.25, -0.3),
                radius: 0.9,
                colors: [
                  Color(0xFFFF3399),
                  Color(0xFFB000FF),
                  Color(0xFF4A0072),
                ],
              )
            : isCompleted
                ? const RadialGradient(
                    center: Alignment(-0.25, -0.3),
                    radius: 0.9,
                    colors: [
                      Color(0xFF6EFECE),
                      Color(0xFF00FF9D),
                      Color(0xFF006644),
                    ],
                  )
                : const RadialGradient(
                    center: Alignment(-0.2, -0.2),
                    radius: 0.9,
                    colors: [
                      Color(0xFF1E293B),
                      Color(0xFF0F172A),
                      Color(0xFF070B14),
                    ],
                  ),
        border: Border.all(
          color: isActive
              ? Colors.white
              : isCompleted
                  ? Colors.white.withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.20),
          width: isActive ? 3.5 : (isCompleted ? 2.8 : 1.8),
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.95),
                  blurRadius: 28,
                  spreadRadius: 3 + pulseValue * 4,
                ),
                BoxShadow(
                  color: secondaryColor.withValues(alpha: 0.7),
                  blurRadius: 16,
                ),
              ]
            : isCompleted
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.70),
                      blurRadius: 20,
                      spreadRadius: 1 + pulseValue * 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.7),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
      ),
      child: Center(
        child: isLocked
            ? Icon(
                Icons.lock_outline_rounded,
                color: Colors.white.withValues(alpha: 0.35),
                size: diameter * 0.36,
              )
            : Text(
                '$level',
                style: GoogleFonts.orbitron(
                  fontSize: isActive ? diameter * 0.36 : diameter * 0.33,
                  fontWeight: FontWeight.w900,
                  color: isActive
                      ? Colors.white
                      : isCompleted
                          ? Colors.black.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.4),
                  letterSpacing: -0.5,
                  shadows: isActive
                      ? [
                          const Shadow(
                            color: Colors.black87,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
              ),
      ),
    );
  }

  // ── Stars Row for Completed Levels ──────────────────────────────────────────
  Widget _buildStarsRow(int actualStars) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (idx) {
          final isStarEarned = idx < actualStars;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Icon(
              Icons.star_rounded,
              size: 11,
              color: isStarEarned ? AppTheme.accentGold : Colors.white24,
            ),
          );
        }),
      ),
    );
  }

  // ── Active Level "NOW" Glowing Badge ────────────────────────────────────────
  Widget _buildActiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF007F), Color(0xFFB000FF)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF007F).withValues(alpha: 0.7),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        'NOW',
        style: GoogleFonts.orbitron(
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Multi-Layer Pulsating Glow Halo ───────────────────────────────────────────
class _PulseGlowHalo extends StatelessWidget {
  final double size;
  final double pulseValue;
  final Color color;
  final bool isActive;

  const _PulseGlowHalo({
    required this.size,
    required this.pulseValue,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final auraSize = size * (0.62 + pulseValue * 0.38);
    final auraAlpha = (1.0 - pulseValue * 0.75) * (isActive ? 0.50 : 0.32);

    return Container(
      width: auraSize,
      height: auraSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: auraAlpha),
          width: 1.5 + pulseValue * 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: auraAlpha * 0.7),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

// ── Atomic Orbital Rings & Revolving Satellites Custom Painter ───────────────
class _AtomicOrbitalsPainter extends CustomPainter {
  final double orbitProgress;
  final double pulseValue;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isActive;
  final bool isCompleted;
  final bool isLocked;
  final bool drawFrontLayerOnly;

  _AtomicOrbitalsPainter({
    required this.orbitProgress,
    required this.pulseValue,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isActive,
    required this.isCompleted,
    required this.isLocked,
    required this.drawFrontLayerOnly,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final nucleusRadius = size.width * (isActive ? 0.25 : 0.22);

    // Three atomic orbital planes with different inclinations and eccentricities
    final orbitals = [
      _OrbitConfig(
        angle: -math.pi * 0.18, // -32.4 deg
        radiusX: nucleusRadius * 1.70,
        radiusY: nucleusRadius * 0.75,
        speedMultiplier: 1.0,
        phaseOffset: 0.0,
        color: primaryColor,
      ),
      _OrbitConfig(
        angle: math.pi * 0.18, // +32.4 deg
        radiusX: nucleusRadius * 1.70,
        radiusY: nucleusRadius * 0.75,
        speedMultiplier: -1.2,
        phaseOffset: math.pi * 0.6,
        color: secondaryColor,
      ),
      _OrbitConfig(
        angle: math.pi * 0.48, // ~86 deg vertical-ish
        radiusX: nucleusRadius * 1.55,
        radiusY: nucleusRadius * 0.58,
        speedMultiplier: 0.9,
        phaseOffset: math.pi * 1.2,
        color: isActive ? const Color(0xFFFFD700) : primaryColor,
      ),
    ];

    final activeOrbitalsCount = isLocked ? 1 : (isActive ? 3 : 2);

    for (int i = 0; i < activeOrbitalsCount; i++) {
      final config = orbitals[i];
      _drawSingleOrbit(canvas, center, config);
    }
  }

  void _drawSingleOrbit(Canvas canvas, Offset center, _OrbitConfig config) {
    final orbitAngle = config.angle;
    final a = config.radiusX;
    final b = config.radiusY;

    // Calculate current parametric angle t of revolving electron particle
    final speed = isLocked ? 0.2 : (isActive ? 2.0 : 1.0);
    final t = (orbitProgress * speed * config.speedMultiplier * 2 * math.pi + config.phaseOffset) % (2 * math.pi);

    // 3D coordinates in the orbital plane
    final xPrime = a * math.cos(t);
    final yPrime = b * math.sin(t);
    final zPrime = math.sin(t); // z > 0: in front of nucleus, z < 0: behind nucleus

    final isFront = zPrime >= 0;

    // ── 1. Draw Elliptical Orbital Track Line ────────────────────────────────
    if (!drawFrontLayerOnly) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(orbitAngle);

      final trackAlpha = isLocked ? 0.14 : (isActive ? 0.50 : 0.35);

      // Orbital Path Glow
      if (isActive || isCompleted) {
        final glowPaint = Paint()
          ..color = config.color.withValues(alpha: trackAlpha * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: a * 2, height: b * 2), glowPaint);
      }

      // Orbital Track Outline
      final trackPaint = Paint()
        ..color = config.color.withValues(alpha: trackAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isActive ? 1.6 : 1.2;

      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: a * 2, height: b * 2), trackPaint);
      canvas.restore();
    }

    // ── 2. Draw Revolving Quantum/Electron Particle ─────────────────────────
    if ((drawFrontLayerOnly && isFront) || (!drawFrontLayerOnly && !isFront)) {
      // Rotate orbital point by orbitAngle to get canvas coords
      final cosA = math.cos(orbitAngle);
      final sinA = math.sin(orbitAngle);
      final px = center.dx + (xPrime * cosA - yPrime * sinA);
      final py = center.dy + (xPrime * sinA + yPrime * cosA);

      final particleRadius = isFront
          ? (isActive ? 5.2 : 4.2) * (1.0 + (zPrime * 0.25))
          : (isActive ? 3.2 : 2.6) * (0.8 - (zPrime.abs() * 0.2));

      final particleAlpha = isFront
          ? (isLocked ? 0.35 : 1.0)
          : (isLocked ? 0.15 : 0.45);

      // Glowing Halo around Satellite
      if (isFront && !isLocked) {
        canvas.drawCircle(
          Offset(px, py),
          particleRadius * 2.6,
          Paint()
            ..color = config.color.withValues(alpha: isActive ? 0.75 : 0.55)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }

      // Particle Outer Ring
      canvas.drawCircle(
        Offset(px, py),
        particleRadius,
        Paint()..color = config.color.withValues(alpha: particleAlpha),
      );

      // Particle Bright Core
      if (isFront && !isLocked) {
        canvas.drawCircle(
          Offset(px, py),
          particleRadius * 0.45,
          Paint()..color = Colors.white.withValues(alpha: particleAlpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AtomicOrbitalsPainter oldDelegate) => true;
}

class _OrbitConfig {
  final double angle;
  final double radiusX;
  final double radiusY;
  final double speedMultiplier;
  final double phaseOffset;
  final Color color;

  const _OrbitConfig({
    required this.angle,
    required this.radiusX,
    required this.radiusY,
    required this.speedMultiplier,
    required this.phaseOffset,
    required this.color,
  });
}
