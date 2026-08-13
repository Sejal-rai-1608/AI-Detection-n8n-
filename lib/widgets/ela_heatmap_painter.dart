import 'dart:math' as math;
import 'package:flutter/material.dart';

class ElaHeatmapPainter extends CustomPainter {
  final List<Offset> hotspots;
  final double manipulationLevel;

  ElaHeatmapPainter({required this.hotspots, required this.manipulationLevel});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw standard faint compression noise (a checkerboard of low opacity dots)
    final random = math.Random(42);
    final noisePaint = Paint()..color = Colors.blueGrey.withOpacity(0.12);
    for (int i = 0; i < size.width; i += 20) {
      for (int j = 0; j < size.height; j += 20) {
        if (random.nextBool()) {
          canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 1.5, noisePaint);
        }
      }
    }

    // Draw manipulation hotspots (where editing happened)
    for (var spot in hotspots) {
      // Scale spots if they were recorded on fixed width
      final x = (spot.dx / 320) * size.width;
      final y = (spot.dy / 200) * size.height;

      // Draw multiple rings representing ELA compression peaks
      final hotspotPaint = Paint()
        ..color = const Color(0xFFFF2E93).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(Offset(x, y), 15, hotspotPaint);
      canvas.drawCircle(Offset(x, y), 30, hotspotPaint..color = const Color(0xFFFF2E93).withOpacity(0.2));

      // Draw pixelated glowing overlay inside the hotspot
      final pixelPaint = Paint()..color = const Color(0xFF00E5FF).withOpacity(0.6);
      canvas.drawRect(Rect.fromLTWH(x - 5, y - 5, 10, 10), pixelPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
