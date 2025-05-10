import 'package:flutter/material.dart';
import 'dart:math';

class ResultPage extends StatelessWidget {
  final int steps;
  final Offset start;
  final Offset end;
  final double displacement;

  ResultPage({
    required this.steps,
    required this.start,
    required this.end,
    required this.displacement,
  });

  @override
  Widget build(BuildContext context) {
    double dx = end.dx - start.dx;
    double dy = end.dy - start.dy;

    return Scaffold(
      appBar: AppBar(title: Text("Szczegóły obliczeń")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Liczba kroków: $steps"),
            SizedBox(height: 8),
            Text("Punkt początkowy: (${start.dx.toStringAsFixed(2)}, ${start.dy.toStringAsFixed(2)})"),
            Text("Punkt końcowy: (${end.dx.toStringAsFixed(2)}, ${end.dy.toStringAsFixed(2)})"),
            SizedBox(height: 8),
            Text("Δx = ${dx.toStringAsFixed(2)}"),
            Text("Δy = ${dy.toStringAsFixed(2)}"),
            SizedBox(height: 8),
            Text("Obliczenie przemieszczenia:"),
            Text("d = √(Δx² + Δy²)"),
            Text("d = √(${dx.toStringAsFixed(2)}² + ${dy.toStringAsFixed(2)}²)"),
            Text("d = ${displacement.toStringAsFixed(2)}"),
          ],
        ),
      ),
    );
  }
}
