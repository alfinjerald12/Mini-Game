import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GamePage(),
    );
  }
}

// ### WIDGETS ###

class Bird extends StatelessWidget {
  final double birdY;
  final double birdWidth;
  final double birdHeight;

  const Bird({
    super.key,
    required this.birdY,
    required this.birdWidth,
    required this.birdHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment(0, (2 * birdY + birdHeight) / (2 - birdHeight)),
      child: Image.asset(
        'assets/images/bird.png', // Make sure to add a bird image to your assets
        width: MediaQuery.of(context).size.height * birdWidth / 2,
        height: MediaQuery.of(context).size.height * birdHeight / 2,
        fit: BoxFit.fill,
      ),
    );
  }
}

class Barrier extends StatelessWidget {
  final double barrierX;
  final double barrierWidth;
  final double barrierHeight;
  final bool isTopBarrier;

  const Barrier({
    super.key,
    required this.barrierX,
    required this.barrierWidth,
    required this.barrierHeight,
    required this.isTopBarrier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment((2 * barrierX + barrierWidth) / (2 - barrierWidth), isTopBarrier ? -1 : 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isTopBarrier) const PipeCap(), // Cap at the top for the bottom pipe
          Container(
            width: MediaQuery.of(context).size.width * barrierWidth / 2,
            height: MediaQuery.of(context).size.height * 2 / 3 * barrierHeight / 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.green.shade700,
                  Colors.green.shade800
                ],
                stops: const [
                  0.1,
                  0.9
                ],
              ),
              border: Border.all(width: 3, color: Colors.green.shade900),
            ),
          ),
          if (isTopBarrier) const PipeCap(), // Cap at the bottom for the top pipe
        ],
      ),
    );
  }
}

class PipeCap extends StatelessWidget {
  const PipeCap({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width * 0.5 / 2) * 1.1, // Slightly wider than the pipe
      height: 25,
      decoration: BoxDecoration(
        color: Colors.green.shade800,
        border: Border.all(width: 5, color: Colors.green.shade900),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  // ### GAME SETTINGS ###
  // Using screen heights for physics makes it resolution independent
  static const double gravity = 1.5; // Acceleration in screens per second^2
  static const double jumpStrength = -0.6; // Velocity in screens per second
  static const double barrierMovementSpeed = 0.05; // How fast the pipes move

  // Bird variables
  double birdY = 0;
  double birdVelocity = 0; // Bird's current speed
  final double birdWidth = 0.1;
  final double birdHeight = 0.1;

  // Game loop
  late Ticker _ticker;
  Timer? _barrierTimer;
  Duration _elapsed = Duration.zero;

  // Game state
  bool gameHasStarted = false;
  int score = 0;
  int highScore = 0;

  // Barrier variables
  static List<double> barrierX = [
    2,
    2 + 1.5
  ];
  static double barrierWidth = 0.5; // out of 2
  List<List<double>> barrierHeight = [
    [
      0.6,
      0.4
    ],
    [
      0.4,
      0.6
    ],
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (!gameHasStarted) return;

      final double delta = (elapsed - _elapsed).inMilliseconds / 1000.0;
      _elapsed = elapsed;

      // Apply gravity
      birdVelocity += gravity * delta;
      setState(() {
        birdY += birdVelocity * delta;
      });

      if (birdIsDead()) {
        _ticker.stop();
        _barrierTimer?.cancel();
        _showGameOverDialog();
      }
    });
  }

  void startGame() {
    gameHasStarted = true;
    _ticker.start();
    _elapsed = Duration.zero;

    _barrierTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      setState(() {
        for (int i = 0; i < barrierX.length; i++) {
          barrierX[i] -= barrierMovementSpeed;
          if (barrierX[i] < -barrierWidth && barrierX[i] + barrierMovementSpeed >= -barrierWidth) score++;
          if (barrierX[i] < -1.5) barrierX[i] += 3;
        }
      });
    });
  }

  void jump() {
    setState(() {
      // Give the bird an upward velocity
      birdVelocity = jumpStrength;
    });
  }

  void resetGame() {
    Navigator.pop(context); // Dismiss the dialog
    setState(() {
      birdY = 0;
      birdVelocity = 0;
      gameHasStarted = false;
      _elapsed = Duration.zero;
      score = 0;
      barrierX = [
        2,
        2 + 1.5
      ];
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _barrierTimer?.cancel();
    super.dispose();
  }

  bool birdIsDead() {
    // Check if bird hits top or bottom of screen
    if (birdY < -1.1 || birdY > 1.1) {
      return true;
    }

    // Check if bird hits a barrier
    for (int i = 0; i < barrierX.length; i++) {
      if (barrierX[i] <= birdWidth && barrierX[i] + barrierWidth >= -birdWidth && (birdY <= -1 + barrierHeight[i][0] || birdY + birdHeight >= 1 - barrierHeight[i][1])) {
        return true;
      }
    }
    return false;
  }

  void _showGameOverDialog() {
    if (score > highScore) {
      highScore = score;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.brown,
          title: const Center(
            child: Text(
              "G A M E  O V E R",
              style: TextStyle(color: Colors.white),
            ),
          ),
          content: Text(
            "Score: $score\nHigh Score: $highScore",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            GestureDetector(
              onTap: resetGame,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  color: Colors.white,
                  child: const Text(
                    'PLAY AGAIN',
                    style: TextStyle(color: Colors.brown),
                  ),
                ),
              ),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: gameHasStarted ? jump : startGame,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.blue,
                child: Center(
                  child: Stack(
                    children: [
                      Bird(
                        birdY: birdY,
                        birdWidth: birdWidth,
                        birdHeight: birdHeight,
                      ),
                      Container(
                        alignment: const Alignment(0, -0.5),
                        child: Text(
                          gameHasStarted ? '' : 'T A P  T O  P L A Y',
                          style: const TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ),
                      Barrier(
                        barrierX: barrierX[0],
                        barrierWidth: barrierWidth,
                        barrierHeight: barrierHeight[0][0],
                        isTopBarrier: true,
                      ),
                      Barrier(
                        barrierX: barrierX[0],
                        barrierWidth: barrierWidth,
                        barrierHeight: barrierHeight[0][1],
                        isTopBarrier: false,
                      ),
                      Barrier(
                        barrierX: barrierX[1],
                        barrierWidth: barrierWidth,
                        barrierHeight: barrierHeight[1][0],
                        isTopBarrier: true,
                      ),
                      Barrier(
                        barrierX: barrierX[1],
                        barrierWidth: barrierWidth,
                        barrierHeight: barrierHeight[1][1],
                        isTopBarrier: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              height: 15,
              color: Colors.green,
            ),
            Expanded(
              child: Container(
                color: Colors.brown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'SCORE',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          score.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 35),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'BEST',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          highScore.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 35),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
