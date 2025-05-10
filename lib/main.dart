import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

import 'brownian_simulation.dart';
import 'result_page.dart';

void main() {
  runApp(BrownianApp());
}

class BrownianApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Symulacja Browna',
      themeMode: ThemeMode.dark, // 👈 Tryb ciemny jako domyślny
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // 👈 animowany splash
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 2));
    _fade = Tween(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    Future.delayed(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => BrownianHomePage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/splash/branding.png', width: 120),
              SizedBox(height: 20),
              Text(
                "Created by łysyOkrutnik",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class BrownianHomePage extends StatefulWidget {
  @override
  _BrownianHomePageState createState() => _BrownianHomePageState();
}

class _BrownianHomePageState extends State<BrownianHomePage> {
  int steps = 1000;
  List<Offset> _fullPoints = [];
  List<Offset> _animatedPoints = [];
  String _elapsedTime = '';
  double _displacement = 0.0;
  final TextEditingController _controller = TextEditingController(text: "1000");
  final GlobalKey _repaintKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ruchy Browna')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Liczba kroków (> 0)',
                labelStyle: TextStyle(color: Colors.white),
              ),
              style: TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _runSimulation,
                    child: Text('Start symulacji'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showDetails,
                    child: Text('Obliczenia'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveCsv,
                    child: Text('Zapisz CSV'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _exportPng,
                    child: Text('Eksportuj PNG'),
                  ),
                ),
              ],
            ),
            if (_elapsedTime.isNotEmpty || _displacement > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '$_elapsedTime   |   Przemieszczenie: ${_displacement.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            SizedBox(height: 10),
            Expanded(
              child: Container(
                color: Colors.grey.shade900,
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: _animatedPoints.isEmpty
                      ? Center(child: Text('Tutaj będzie wykres'))
                      : CustomPaint(
                    painter: BrownianPainter(points: _animatedPoints),
                    child: Container(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _runSimulation() {
    final input = int.tryParse(_controller.text);
    if (input == null || input <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Podaj liczbę kroków większą niż 0'),
      ));
      return;
    }

    final stopwatch = Stopwatch()..start();
    final simulation = BrownianSimulation(steps: input);
    final generated = simulation.generate();
    stopwatch.stop();

    double dx = generated.last.dx - generated.first.dx;
    double dy = generated.last.dy - generated.first.dy;
    double displacement = sqrt(dx * dx + dy * dy);

    setState(() {
      steps = input;
      _fullPoints = generated;
      _animatedPoints = [generated.first];
      _elapsedTime = 'Czas: ${stopwatch.elapsedMilliseconds} ms';
      _displacement = displacement;
    });

    int index = 1;
    const delay = Duration(milliseconds: 2);
    Future.doWhile(() async {
      await Future.delayed(delay);
      if (index >= _fullPoints.length) return false;

      setState(() {
        _animatedPoints.add(_fullPoints[index]);
      });
      index++;
      return true;
    });
  }

  Future<void> _saveCsv() async {
    if (_fullPoints.isEmpty) return;

    final dir = await getExternalStorageDirectory();
    final file = File('${dir!.path}/trajectory_${DateTime.now().millisecondsSinceEpoch}.csv');
    final buffer = StringBuffer();
    buffer.writeln("x,y");
    for (final p in _fullPoints) {
      buffer.writeln("${p.dx},${p.dy}");
    }
    await file.writeAsString(buffer.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Zapisano do pliku:\n${file.path}')),
    );
  }

  Future<void> _exportPng() async {
    try {
      RenderRepaintBoundary boundary =
      _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final dir = await getExternalStorageDirectory();
      final file = File('${dir!.path}/wykres_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wykres zapisany jako PNG:\n${file.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd eksportu PNG: $e')),
      );
    }
  }

  void _showDetails() {
    if (_fullPoints.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          steps: steps,
          start: _fullPoints.first,
          end: _fullPoints.last,
          displacement: _displacement,
        ),
      ),
    );
  }
}