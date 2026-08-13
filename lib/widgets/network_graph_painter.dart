import 'package:flutter/material.dart';
import 'package:n8ntrial/models/models.dart';

class NetworkGraphPainter extends CustomPainter {
  final List<BacktrackNode> nodes;
  final BacktrackNode? selectedNode;

  NetworkGraphPainter({required this.nodes, required this.selectedNode});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background network grid (Light grey for light mode)
    final gridPaint = Paint()..color = const Color(0xFFE8ECEF);
    for (int i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i.toDouble(), 0), Offset(i.toDouble(), size.height), gridPaint);
    }
    for (int j = 0; j < size.height; j += 30) {
      canvas.drawLine(Offset(0, j.toDouble()), Offset(size.width, j.toDouble()), gridPaint);
    }

    // Connect nodes
    final linePaint = Paint()
      ..color = const Color(0xFFBDC3C7)
      ..strokeWidth = 2.0;

    final originRoutePaint = Paint()
      ..color = const Color(0xFFE63946).withOpacity(0.5)
      ..strokeWidth = 3.0;

    for (var node in nodes) {
      for (var targetId in node.connections) {
        final targetNode = nodes.firstWhere((n) => n.id == targetId);

        // Highlight paths originating from culprit/source
        final isOriginPath = node.isOrigin || (selectedNode != null && (selectedNode!.id == node.id || selectedNode!.id == targetNode.id));

        canvas.drawLine(
          node.position,
          targetNode.position,
          isOriginPath ? originRoutePaint : linePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
