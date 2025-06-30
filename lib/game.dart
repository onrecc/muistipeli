import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class CardMatchingGame extends StatefulWidget {
  final int rows;
  final int cols;

  const CardMatchingGame({super.key, required this.rows, required this.cols});

  @override
  State<CardMatchingGame> createState() => _CardMatchingGameState();
}

class _CardMatchingGameState extends State<CardMatchingGame> {
  late List<CardModel> cards;
  int? selectedIndex;
  int? previouslySelectedIndex;
  int matchedPairs = 0;
  int moves = 0;
  bool isProcessing = false;
  late Stopwatch _stopwatch;
  late Timer _timer;
  Duration _elapsedTime = Duration.zero;

  void _initializeGame() {
    setState(() {
      _stopwatch.reset();
      _elapsedTime = Duration.zero;
      final totalPairs = (widget.rows * widget.cols) ~/ 2;
      final cardValues = List.generate(totalPairs, (index) => index);
      cards = [
        ...cardValues,
        ...cardValues,
      ].map((value) => CardModel(value: value)).toList()..shuffle(Random());
      selectedIndex = null;
      previouslySelectedIndex = null;
      matchedPairs = 0;
      moves = 0;
      isProcessing = false;
    });
    _stopwatch.start();
  }

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _initializeGame();
    _startTimer();
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = _stopwatch.elapsed;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _onCardTap(int index) {
    if (isProcessing || cards[index].isMatched || cards[index].isFaceUp) {
      return;
    }

    setState(() {
      cards[index] = cards[index].copyWith(isFaceUp: true);

      if (selectedIndex == null) {
        // First card selected
        selectedIndex = index;
      } else {
        // Second card selected
        isProcessing = true;
        moves++;

        if (cards[selectedIndex!].value == cards[index].value) {
          // Match found
          cards[selectedIndex!] = cards[selectedIndex!].copyWith(
            isMatched: true,
          );
          cards[index] = cards[index].copyWith(isMatched: true);
          matchedPairs++;

          // Check if game is won
          if (matchedPairs == (widget.rows * widget.cols) ~/ 2) {
            _showGameWonDialog();
          }

          selectedIndex = null;
          isProcessing = false;
        } else {
          // No match
          previouslySelectedIndex = selectedIndex;
          selectedIndex = index;

          // Flip cards back after delay (slightly longer than the flip animation)
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              setState(() {
                cards[previouslySelectedIndex!] =
                    cards[previouslySelectedIndex!].copyWith(isFaceUp: false);
                cards[selectedIndex!] = cards[selectedIndex!].copyWith(
                  isFaceUp: false,
                );
                selectedIndex = null;
                isProcessing = false;
              });
            }
          });
        }
      }
    });
  }

  void _showGameWonDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Congratulations!'),
        content: Text('You won in ${_formatTime(_elapsedTime)}!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4E4A73),
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 60,
        title: Text(
          _formatTime(_elapsedTime),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate available space accounting for app bar and system UI
          final padding = 16.0 * 2;
          final availableHeight = constraints.maxHeight - padding;

          // Calculate card size based on both width and height constraints
          final maxCardWidth =
              (constraints.maxWidth - 32.0 - (8.0 * (widget.cols - 1))) /
              widget.cols;
          final maxCardHeight =
              (availableHeight - (8.0 * (widget.rows - 1))) / widget.rows;

          // Choose the smaller card size to ensure it fits both dimensions
          final cardSize = min(maxCardWidth, maxCardHeight * 0.8);
          final cardWidth = cardSize;
          final cardHeight = cardSize / 0.8;

          // Calculate total grid dimensions
          final gridWidth =
              (cardWidth * widget.cols) + (8.0 * (widget.cols - 1));
          final gridHeight =
              (cardHeight * widget.rows) + (8.0 * (widget.rows - 1));

          return Container(
            color: const Color(0xFF4E4A73),
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: SizedBox(
                width: gridWidth,
                height: gridHeight,
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: widget.cols,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 0.8,
                  children: List.generate(
                    cards.length,
                    (index) => _buildCard(index),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(int index) {
    final card = cards[index];
    final isFaceUp = card.isFaceUp || card.isMatched;

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final rotateAnim = Tween(begin: pi / 2, end: 0.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          );

          return AnimatedBuilder(
            animation: rotateAnim,
            child: child,
            builder: (context, child) {
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(rotateAnim.value),
                alignment: Alignment.center,
                child: child,
              );
            },
          );
        },
        child: Container(
          key: ValueKey<bool>(isFaceUp), // Important: Unique key for animation
          child: isFaceUp ? _buildCardFront(card) : _buildCardBack(),
        ),
      ),
    );
  }

  Widget _buildCardFront(CardModel card) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(Icons.star, size: 40, color: _getCardColor(card.value)),
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[800],
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.question_mark,
          size: 40,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  Color _getCardColor(int value) {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];
    return colors[value % colors.length];
  }
}

@immutable
class CardModel {
  final int value;
  final bool isFaceUp;
  final bool isMatched;

  const CardModel({
    required this.value,
    this.isFaceUp = false,
    this.isMatched = false,
  });

  CardModel copyWith({bool? isFaceUp, bool? isMatched}) {
    return CardModel(
      value: value,
      isFaceUp: isFaceUp ?? this.isFaceUp,
      isMatched: isMatched ?? this.isMatched,
    );
  }
}
