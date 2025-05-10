import 'dart:math';
import 'package:flutter/material.dart';

class BrownianSimulation {
  final int steps;
  final Random rand = Random();

  BrownianSimulation({required this.steps});

  List<Offset> generate() {
    List<Offset> path = [Offset.zero];

    for (int i = 0; i < steps; i++) {
      double angle = rand.nextDouble() * 2 * pi;
      double dx = cos(angle);
      double dy = sin(angle);
      path.add(path.last + Offset(dx, dy));
    }

    return path;
  }
}

class BrownianPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  BrownianPainter({required this.points, this.color = Colors.blue});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    double minX = points.map((p) => p.dx).reduce(min);
    double maxX = points.map((p) => p.dx).reduce(max);
    double minY = points.map((p) => p.dy).reduce(min);
    double maxY = points.map((p) => p.dy).reduce(max);

    double scaleX = size.width / (maxX - minX + 1);
    double scaleY = size.height / (maxY - minY + 1);
    double scale = min(scaleX, scaleY);

    double offsetX = size.width / 2 - (minX + maxX) / 2 * scale;
    double offsetY = size.height / 2 - (minY + maxY) / 2 * scale;

    final axisPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, offsetY), Offset(size.width, offsetY), axisPaint);
    canvas.drawLine(Offset(offsetX, 0), Offset(offsetX, size.height), axisPaint);

    final pathPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    Offset start = Offset(
      points[0].dx * scale + offsetX,
      points[0].dy * scale + offsetY,
    );
    path.moveTo(start.dx, start.dy);

    for (var i = 1; i < points.length; i++) {
      Offset pt = Offset(
        points[i].dx * scale + offsetX,
        points[i].dy * scale + offsetY,
      );
      path.lineTo(pt.dx, pt.dy);
    }

    canvas.drawPath(path, pathPaint);

    Offset end = Offset(
      points.last.dx * scale + offsetX,
      points.last.dy * scale + offsetY,
    );

    canvas.drawCircle(start, 6, Paint()..color = Colors.green);
    canvas.drawCircle(end, 6, Paint()..color = Colors.red);

    final displacementPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;
    canvas.drawLine(start, end, displacementPaint);

    double dx = points.last.dx - points[0].dx;
    double dy = points.last.dy - points[0].dy;
    double displacement = sqrt(dx * dx + dy * dy);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'd = ${displacement.toStringAsFixed(2)}',
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    Offset textOffset = Offset(
      (start.dx + end.dx) / 2 + 8,
      (start.dy + end.dy) / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}