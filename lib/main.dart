import 'package:flutter/material.dart';
import 'package:muistipeli/help.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Match',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const GridSelectionPage(),
    );
  }
}

class GridSelectionPage extends StatefulWidget {
  const GridSelectionPage({super.key});

  @override
  State<GridSelectionPage> createState() => _GridSelectionPageState();
}

class _GridSelectionPageState extends State<GridSelectionPage> {
  // Track if the full version is purchased and loading state
  bool _isFullVersion = false;
  bool _isLoading = true;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  // Initialize shared preferences
  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadPurchaseStatus();
    } catch (e) {
      debugPrint('Error initializing preferences: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Load purchase status from shared preferences
  Future<void> _loadPurchaseStatus() async {
    if (_prefs == null) return;

    if (mounted) {
      setState(() {
        _isFullVersion = _prefs!.getBool('isFullVersion') ?? false;
      });
    }
  }

  // Handle purchase of full version
  Future<void> _handlePurchase() async {
    if (_prefs == null) {
      debugPrint('SharedPreferences not initialized yet');
      return;
    }

    try {
      // In a real app, this would connect to your payment processor
      // For now, we'll just simulate a successful purchase
      await _prefs!.setBool('isFullVersion', true);
      if (mounted) {
        setState(() {
          _isFullVersion = true;
        });
        // Close the purchase modal
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error processing purchase: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to process purchase. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startGame(BuildContext context, int rows, int cols) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardMatchingGame(rows: rows, cols: cols),
      ),
    );
  }

  void _showPurchaseModal(BuildContext context) {
    // Get the screen size to make font sizes responsive
    final size = MediaQuery.of(context).size;
    final bool isTablet =
        size.shortestSide >= 600; // Check if device is a tablet

    // Define responsive font sizes
    final double titleSize = isTablet ? 40 : 26;
    final double descriptionSize = isTablet ? 30 : 20;
    final double priceSize = isTablet ? 40 : 26;
    final double iconSize = isTablet ? 48 : 34;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height:
              MediaQuery.of(context).size.height *
              0.5, // Slightly taller to accommodate the dismiss button
          decoration: BoxDecoration(
            color: const Color(0xDEE7EAF6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.only(
            bottom: 40,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dismiss button at the top
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFfefefd),
                      borderRadius: BorderRadius.circular(95),
                      border: Border.all(
                        color: const Color(0xFF9DA2CD),
                        width: 4,
                      ),
                    ),
                    child: Icon(
                      Icons.close,
                      weight: 800,
                      color: const Color(0xFF4E4A73),
                      size: iconSize,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFfefefd),
                  border: Border.all(color: const Color(0xFF9DA2CD), width: 6),
                  borderRadius: BorderRadius.circular(95),
                ),
                padding: const EdgeInsets.all(10),
                child: Text(
                  'Purchase all 4 levels',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4E4A73),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Access all 4 levels by purchasing the full version of the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: descriptionSize,
                    color: const Color(0xFF4E5180),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFfff1ba),
                  borderRadius: BorderRadius.circular(95),
                  border: Border.all(color: const Color(0xFF9DA2CD), width: 6),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : GestureDetector(
                        onTap: _isLoading ? null : _handlePurchase,
                        child: Text(
                          '2€',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF4E4A73),
                            fontSize: priceSize,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    final bool isLandscape = screenWidth > screenHeight;
    const background = Color(0xFF4E4A73);

    // account for system UI insets (status bar, notch, navigation)
    final EdgeInsets padding = MediaQuery.of(context).padding;
    final double safeHeight = screenHeight - padding.top - padding.bottom;

    // Landscape layout: full-width grid with no padding or spacing
    if (isLandscape) {
      // horizontal margin for grid
      final double hPad = screenWidth * 0.05;
      // reserve extra room at top (for help button) and bottom (for labels)
      final double topPad = screenHeight * 0.10;
      final double bottomPad = 0;
      const double gap = 16;
      // compute usable grid area
      final double gridW = screenWidth - 2 * hPad;
      final double gridH = safeHeight - topPad;
      // each cell size (2 columns)
      final double cellW = (gridW - gap) / 2;
      final double cellH = (gridH - gap) / 2;

      return Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              // HELP BUTTON
              Positioned(
                top: screenHeight * 0.02,
                left: screenWidth * 0.04,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.help_outline, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HelpPage()),
                      );
                    },
                  ),
                ),
              ),
              // Landscape grid (no padding/spacing)
              Positioned.fill(
                top: topPad,
                bottom: 0,
                left: hPad,
                right: hPad,
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: gap,
                  crossAxisSpacing: gap,
                  childAspectRatio: cellW / cellH,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildOptionCard(
                      context: context,
                      cols: 2,
                      rows: 4,
                      locked: false,
                    ),
                    _buildOptionCard(
                      context: context,
                      cols: 3,
                      rows: 4,
                      locked: false,
                    ),
                    _buildOptionCard(
                      context: context,
                      cols: 3,
                      rows: 6,
                      locked: true,
                    ),
                    _buildOptionCard(
                      context: context,
                      cols: 4,
                      rows: 6,
                      locked: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Portrait layout: stacked cards
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            // HELP BUTTON
            Positioned(
              top: screenHeight * 0.02,
              left: screenWidth * 0.04,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.white),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => HelpPage(),
                    );
                  },
                ),
              ),
            ),
            // EASY: 2×4
            Positioned(
              top: screenHeight * 0.05,
              right: screenWidth * 0.07,
              child: _buildOptionCard(
                context: context,
                cols: 2,
                rows: 4,
                locked: false,
              ),
            ),
            // MEDIUM: 3×4
            Positioned(
              top: screenHeight * 0.25,
              left: screenWidth * 0.07,
              child: _buildOptionCard(
                context: context,
                cols: 3,
                rows: 4,
                locked: false,
              ),
            ),
            // EXPERT: 3×6 (locked)
            Positioned(
              top: screenHeight * 0.45,
              right: screenWidth * 0.07,
              child: _buildOptionCard(
                context: context,
                cols: 3,
                rows: 6,
                locked: true,
              ),
            ),
            // HARD: 4×6 (locked)
            Positioned(
              top: screenHeight * 0.65,
              left: screenWidth * 0.07,
              child: _buildOptionCard(
                context: context,
                cols: 4,
                rows: 6,
                locked: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required int cols,
    required int rows,
    required bool locked,
  }) {
    // If full version is purchased, no cards are locked
    final bool isLocked = locked && !_isFullVersion;
    final Size screenSize = MediaQuery.of(context).size;
    final bool isLandscape = screenSize.width > screenSize.height;

    // Portrait card size
    final double portraitCardW = screenSize.width * 0.35;
    final double portraitCardH = screenSize.height * 0.25;

    // In landscape, let the card fill its grid cell; in portrait, use fixed size
    final double cardW = isLandscape ? double.infinity : portraitCardW;
    final double cardH = isLandscape ? double.infinity : portraitCardH;

    return GestureDetector(
      onTap: isLocked
          ? () => _showPurchaseModal(context)
          : () => _startGame(context, rows, cols),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: cardW,
                height: cardH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Remove internal vertical padding in landscape
                    final double innerVertPad = isLandscape ? 0 : 24;
                    const double internalSpacing = 4;
                    final double availW = constraints.maxWidth;
                    final double availH = constraints.maxHeight - innerVertPad;
                    final double totalWSpacing = internalSpacing * (cols - 1);
                    final double totalHSpacing = internalSpacing * (rows - 1);
                    final double sqW = (availW - totalWSpacing) / cols;
                    final double sqH = (availH - totalHSpacing) / rows;
                    final double squareSize = min(sqW, sqH);

                    Widget grid = Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int r = 0; r < rows; r++) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (int c = 0; c < cols; c++) ...[
                                Container(
                                  width: squareSize,
                                  height: squareSize / 1.5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEEEEE),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF9DA2CD),
                                      width: 4,
                                    ),
                                  ),
                                ),
                                if (c < cols - 1)
                                  SizedBox(width: internalSpacing),
                              ],
                            ],
                          ),
                          if (r < rows - 1) SizedBox(height: internalSpacing),
                        ],
                      ],
                    );

                    grid = RotatedBox(quarterTurns: 1, child: grid);

                    return Padding(
                      padding: isLandscape
                          ? EdgeInsets.zero
                          : const EdgeInsets.symmetric(vertical: 12),
                      child: grid,
                    );
                  },
                ),
              ),
              if (isLocked)
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Image(
                        image: AssetImage('lib/images/lock.png'),
                        width: 48,
                        height: 48,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F4D9),
                      borderRadius: BorderRadius.circular(95),
                      border: Border.all(
                        color: const Color(0xFF9DA2CD),
                        width: 6,
                      ),
                    ),
                    child: Text(
                      '$cols×$rows',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 32,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4E4A73),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
