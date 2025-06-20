import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: BirthdayPage(),
  ));
}

class BirthdayPage extends StatefulWidget {
  const BirthdayPage({super.key});

  @override
  State<BirthdayPage> createState() => _BirthdayPageState();
}

class _BirthdayPageState extends State<BirthdayPage> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 5));
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      body: Stack(
        alignment: Alignment.center,
        children: [
          ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 30,
            emissionFrequency: 0.1,
            gravity: 0.3,
            colors: const [Colors.pink, Colors.red, Colors.orange, Colors.yellow],
            createParticlePath: _drawFlowerShape,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                '🎉 Happy Birthday 🎂',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                  shadows: [
                    Shadow(color: Colors.purpleAccent, blurRadius: 10),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                'Wishing you a day filled with love and joy!',
                style: TextStyle(fontSize: 18, color: Colors.black54),
                textAlign: TextAlign.center,
              )
            ],
          )
        ],
      ),
    );
  }

  Path _drawFlowerShape(Size size) {
    final path = Path();
    final rnd = Random();
    final petals = 6;
    final radius = 6.0;

    for (int i = 0; i < petals; i++) {
      final angle = (2 * pi / petals) * i;
      final x = radius * cos(angle);
      final y = radius * sin(angle);
      path.addOval(Rect.fromCircle(center: Offset(x, y), radius: 2));
    }
    return path;
  }
}
