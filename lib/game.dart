import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

// A widget that flips between front and back with a 3D rotation.
class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final bool flipOn;
  final Duration duration;

  const FlipCard({
    Key? key,
    required this.front,
    required this.back,
    required this.flipOn,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  _FlipCardState createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.flipOn) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flipOn != oldWidget.flipOn) {
      if (widget.flipOn) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _controller.value * pi;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);
        // Show back until halfway, then show front flipped 180°
        Widget displayChild = _controller.value <= 0.5
            ? widget.back
            : Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(pi),
                child: widget.front,
              );
        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: displayChild,
        );
      },
    );
  }
}

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
    // Stop the stopwatch and timer so they don’t keep running
    _stopwatch.stop();
    _timer.cancel();

    // Calculate how many stars to award
    final int secs = _stopwatch.elapsed.inSeconds;
    const int threeStarThreshold = 30;
    const int twoStarThreshold = 60;
    final int stars = (secs <= threeStarThreshold)
        ? 3
        : (secs <= twoStarThreshold)
        ? 2
        : 1;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54, // dim background
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        final size = MediaQuery.of(ctx).size;
        return Container(
          width: size.width * 0.9, // 90% of screen width
          height: size.height * 0.7, // 70% of screen height
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.all(32), // Increased padding
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24), // Larger border radius
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Transform.rotate(
                      angle: (i - 1) * 0.2,
                      child: Icon(
                        Icons.star,
                        size: 80, // Larger stars
                        color: i < stars ? Colors.amber : Colors.grey[400],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24), // Increased spacing
                Text(
                  'Time: ${_formatTime(_elapsedTime)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 32, // Larger font size
                  ),
                ),
                const SizedBox(height: 32), // Increased spacing
                Container(
                  padding: const EdgeInsets.all(32), // Increased padding
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF9DA2CD),
                      width: 3, // Thicker border
                    ),
                    borderRadius: BorderRadius.circular(
                      24,
                    ), // Larger border radius
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // close dialog
                      Navigator.of(context).pop(); // exit game screen
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(32), // Increased padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          16,
                        ), // Larger border radius
                      ),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 80,
                    ), // Larger icon
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(scale: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFe7eaf6),
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 60,
        title: Text(
          _formatTime(_elapsedTime),
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final double padding = 16.0;
              final double availableWidth =
                  constraints.maxWidth - (padding * 2);
              final double availableHeight =
                  constraints.maxHeight - kToolbarHeight - (padding * 2);

              bool isLandscape = orientation == Orientation.landscape;
              int displayCols = isLandscape ? widget.rows : widget.cols;
              int displayRows = isLandscape ? widget.cols : widget.rows;

              double cardWidth, cardHeight;
              const double aspectRatio =
                  3 / 4; // Width to height ratio of cards

              // Calculate card size based on available space
              cardWidth =
                  (availableWidth - (8.0 * (displayCols - 1))) / displayCols;
              cardHeight = cardWidth / aspectRatio;

              // If cards are too tall, adjust based on height
              if ((cardHeight * displayRows) + (8.0 * (displayRows - 1)) >
                  availableHeight) {
                cardHeight =
                    (availableHeight - (8.0 * (displayRows - 1))) / displayRows;
                cardWidth = cardHeight * aspectRatio;
              }

              // Calculate total grid dimensions
              final gridWidth =
                  (cardWidth * displayCols) + (8.0 * (displayCols - 1));
              final gridHeight =
                  (cardHeight * displayRows) + (8.0 * (displayRows - 1));

              return Container(
                color: const Color(0xFFe7eaf6),
                padding: EdgeInsets.all(padding),
                child: Center(
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: gridWidth,
                      height: gridHeight,
                      child: GridView.count(
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: displayCols,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: cardWidth / cardHeight,
                        children: isLandscape
                            ? _getLandscapeCardOrder()
                            : List.generate(
                                cards.length,
                                (index) => _buildCard(index),
                              ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _getLandscapeCardOrder() {
    List<Widget> reorderedCards = [];
    int originalCols = widget.cols;
    int originalRows = widget.rows;

    // Transpose the grid by swapping rows and columns
    for (int row = 0; row < originalRows; row++) {
      for (int col = 0; col < originalCols; col++) {
        int originalIndex = row * originalCols + col;
        reorderedCards.add(_buildCard(originalIndex));
      }
    }

    return reorderedCards;
  }

  Widget _buildCard(int index) {
    final card = cards[index];
    final isFaceUp = card.isFaceUp || card.isMatched;

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: FlipCard(
        front: _buildCardFront(card),
        back: _buildCardBack(),
        flipOn: isFaceUp,
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  Widget _buildCardFront(CardModel card) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFffe684),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFF4e5180), width: 6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double halfWidth = constraints.maxWidth * 0.5;
            return Image.asset(
              'lib/images/${card.value + 1}.png',
              width: halfWidth,
              height: halfWidth * 1.33, // maintain aspect ratio
              fit: BoxFit.contain,
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF9da2cd),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFF4e5180), width: 6),
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
          Icons.star_rounded,
          size: 40,
          color: const Color(0xFFfecc4f),
        ),
      ),
    );
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
