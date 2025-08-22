import 'package:flutter/material.dart';
import 'package:muistipeli/help.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game.dart';
import 'iap.dart';
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
        fontFamily: GoogleFonts.poppins().fontFamily,
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          // Explicitly define weights for better bold rendering
          titleLarge: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 32,
          ),
          headlineSmall: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
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
  bool _isPurchasing = false;
  bool _hasShownPurchaseSuccessMessage = false; // Track if we've shown the success message
  SharedPreferences? _prefs;
  
  // Payment service for IAP
  final PaymentService _paymentService = PaymentService();
  List<ProductDetails> _products = [];

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _initPaymentService();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  // Initialize payment service
  Future<void> _initPaymentService() async {
    // Set up callbacks
    _paymentService.onPurchaseComplete = (success) {
      if (success && mounted) {
        setState(() {
          _isFullVersion = true;
          _isPurchasing = false;
        });
        // Update SharedPreferences to maintain compatibility
        _prefs?.setBool('isFullVersion', true);
        
        // Only show success message if we haven't shown it before (i.e., it's a new purchase)
        if (!_hasShownPurchaseSuccessMessage) {
          _hasShownPurchaseSuccessMessage = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchase successful! All levels unlocked.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    };

    _paymentService.onPurchaseError = (error) {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
        // Don't show error message for user cancellation
        if (!error.toLowerCase().contains('cancelled')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Purchase failed: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    };

    try {
      // Initialize the service
      await _paymentService.initialize();
      
      // Load products
      await _loadProducts();
    } catch (e) {
      debugPrint('Error initializing payment service: $e');
    }
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _paymentService.loadProducts();
      if (mounted) {
        setState(() {
          _products = products;
          // Use PaymentService state as primary source
          _isFullVersion = _paymentService.isUnlockAllPurchased;
        });
        // Sync with SharedPreferences
        if (_paymentService.isUnlockAllPurchased) {
          _prefs?.setBool('isFullVersion', true);
          // Mark that we've already shown the success message to prevent it on startup
          _hasShownPurchaseSuccessMessage = true;
        }
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
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

  // Load purchase status from shared preferences (fallback)
  Future<void> _loadPurchaseStatus() async {
    if (_prefs == null) return;

    if (mounted) {
      setState(() {
        // Use SharedPreferences as fallback if PaymentService hasn't loaded yet
        _isFullVersion = _prefs!.getBool('isFullVersion') ?? false;
      });
    }
  }

  // Handle purchase of full version using real IAP
  Future<void> _handlePurchase() async {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Products not available. Please check your internet connection.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isPurchasing = true;
    });

    try {
      // Find the unlock all product
      final unlockAllProduct = _products.firstWhere(
        (product) => product.id == 'unlock_all',
        orElse: () => throw Exception('Unlock all product not found'),
      );

      // Initiate purchase with timeout
      await _paymentService.purchaseProduct(unlockAllProduct)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              // Reset purchasing state on timeout
              if (mounted) {
                setState(() {
                  _isPurchasing = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Purchase timed out. Please try again.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              return false;
            },
          );

    } catch (e) {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Handle restore purchases
  Future<void> _handleRestorePurchases() async {
    setState(() {
      _isPurchasing = true;
    });

    try {
      await _paymentService.restorePurchases()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              if (mounted) {
                setState(() {
                  _isPurchasing = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Restore timed out. Please try again.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
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

    // Check if products are loaded
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Products not available. Please check your internet connection.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get the unlock all product
    final unlockAllProduct = _products.firstWhere(
      (product) => product.id == 'unlock_all',
      orElse: () => throw Exception('Product not found'),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height:
                  MediaQuery.of(context).size.height *
                  0.6, // Slightly taller to accommodate restore button
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
                      child: Image(
                        image: AssetImage('lib/icons/close.png'),
                        width: iconSize,
                        height: iconSize,
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
                  // Purchase button
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
                    child: _isPurchasing
                        ? const CircularProgressIndicator()
                        : GestureDetector(
                            onTap: _isPurchasing ? null : () async {
                              setModalState(() {});
                              await _handlePurchase();
                              setModalState(() {});
                            },
                            child: Text(
                              unlockAllProduct.price,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF4E4A73),
                                fontSize: priceSize,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  // Restore purchases button
                  TextButton(
                    onPressed: _isPurchasing ? null : () async {
                      setModalState(() {});
                      await _handleRestorePurchases();
                      setModalState(() {});
                    },
                    child: Text(
                      'Restore Purchases',
                      style: TextStyle(
                        color: const Color(0xFF4E4A73),
                        fontSize: descriptionSize * 0.8,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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

    // Show loading spinner while initializing
    if (_isLoading) {
      return Scaffold(
        backgroundColor: background,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // account for system UI insets (status bar, notch, navigation)
    final EdgeInsets padding = MediaQuery.of(context).padding;
    final double safeHeight = screenHeight - padding.top - padding.bottom;

    // Landscape layout: single horizontal row with all 4 cards
    if (isLandscape) {
      // minimal horizontal margin for row
      final double hPad = screenWidth * 0.02;
      // reserve room at top for help button
      final double topPad = screenHeight * 0.08;
      const double gap = 8; // Gap between cards
      // compute usable area
      final double availableWidth = screenWidth - 2 * hPad;
      final double availableHeight = safeHeight - topPad - 20; // Add bottom margin
      
      // Calculate card dimensions with proper aspect ratio
      double cardW = (availableWidth - 3 * gap) / 4;
      double cardH = cardW; // Start with square cards
      
      // If cards would be too tall for available height, scale down
      if (cardH > availableHeight * 0.8) {
        cardH = availableHeight * 0.8;
        cardW = cardH; // Keep square aspect ratio
      }
      
      // Recalculate if cards are too wide after height adjustment
      final double totalRequiredWidth = (cardW * 4) + (gap * 3);
      if (totalRequiredWidth > availableWidth) {
        cardW = (availableWidth - 3 * gap) / 4;
        cardH = cardW; // Maintain square aspect ratio
      }

      return Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              // HELP BUTTON
              Positioned(
                top: screenHeight * 0.02,
                left: screenWidth * 0.04,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HelpPage()),
                    );
                  },
                  child: const Image(
                    image: AssetImage('lib/icons/Q-mark.png'),
                    width: 40,
                    height: 40,
                  ),
                ),
              ),
              // Horizontal row of cards - centered in available space
              Positioned(
                top: topPad + (availableHeight - cardH) / 2, // Center vertically in remaining space
                left: hPad,
                right: hPad,
                child: Center(
                  child: SizedBox(
                    width: (cardW * 4) + (gap * 3), // Exact width needed for all cards
                    height: cardH,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: cardW,
                        height: cardH,
                        child: _buildOptionCard(
                          context: context,
                          cols: 2,
                          rows: 4,
                          locked: false,
                        ),
                      ),
                      SizedBox(
                        width: cardW,
                        height: cardH,
                        child: _buildOptionCard(
                          context: context,
                          cols: 3,
                          rows: 4,
                          locked: false,
                        ),
                      ),
                      SizedBox(
                        width: cardW,
                        height: cardH,
                        child: _buildOptionCard(
                          context: context,
                          cols: 3,
                          rows: 6,
                          locked: true,
                        ),
                      ),
                      SizedBox(
                        width: cardW,
                        height: cardH,
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
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Portrait layout: 4 equal quadrants
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            // HELP BUTTON
            Positioned(
              top: screenHeight * 0.02,
              left: screenWidth * 0.04,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => HelpPage(),
                  );
                },
                child: const Image(
                  image: AssetImage('lib/icons/Q-mark.png'),
                  width: 40,
                  height: 40,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                children: [
                  // Top row (2 quadrants)
                  Expanded(
                    child: Row(
                      children: [
                        // 2x4
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: _buildOptionCard(
                              context: context,
                              cols: 3,
                              rows: 4,
                              locked: false,
                            ),
                          ),
                        ),
                        // 3x4
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: _buildOptionCard(
                              context: context,
                              cols: 2,
                              rows: 4,
                              locked: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bottom row (2 quadrants)
                  Expanded(
                    child: Row(
                      children: [
                          // 3×6
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: _buildOptionCard(
                              context: context,
                              cols: 4,
                              rows: 6,
                              locked: true,
                            ),
                          ),
                        ),
                        // 4x6
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: _buildOptionCard(
                              context: context,
                              cols: 3,
                              rows: 6,
                              locked: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

    // More responsive card sizing based on device size and layout
    final bool isTablet = screenSize.shortestSide >= 600;
    final bool isLargePhone = screenSize.shortestSide >= 400;
    
    // In portrait quadrant layout, size cards to fit well in each quadrant
    // In landscape, use the provided constraints from the row layout
    double cardW, cardH;
    if (isLandscape) {
      // Landscape: use provided constraints
      cardW = double.infinity;
      cardH = double.infinity;
    } else {
      // Portrait quadrant: size based on available quadrant space
      if (isTablet) {
        cardW = screenSize.width * 0.35; // Smaller since we have 2 per row
        cardH = screenSize.height * 0.25; // Fit well in each quadrant
      } else if (isLargePhone) {
        cardW = screenSize.width * 0.38;
        cardH = screenSize.height * 0.28;
      } else {
        cardW = screenSize.width * 0.40;
        cardH = screenSize.height * 0.30;
      }
    }

    return GestureDetector(
      onTap: isLocked
          ? () => _showPurchaseModal(context)
          : () => _startGame(context, rows, cols),
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
                    final bool isTablet = screenSize.shortestSide >= 600;
                    final bool isLargePhone = screenSize.shortestSide >= 400;
                    
                    final double sizeTagHeight = 60;
                    final double innerVertPad = isLandscape ? 0 : 24;
                    
                    final double gridComplexity = (cols * rows).toDouble();
                    final double baseInternalSpacing = isTablet ? 4.0 : 3.5; // Reduce base spacing on tablets
                    
                    double spacingScale;
                    if (gridComplexity == 12) { // 3x4
                      spacingScale = 0.7; 
                    } else if (gridComplexity == 18) { // 3x6
                      spacingScale = 0.65; 
                    } else if (gridComplexity == 24) { // 4x6
                      spacingScale = 0.65;
                    } else {
                      spacingScale = gridComplexity > 12 ? 0.4 : (gridComplexity > 8 ? 0.6 : 1.0); 
                    }
                    
                    final double internalSpacing = baseInternalSpacing * spacingScale;
                    
                    final double availW = constraints.maxWidth;
                    final double availH = constraints.maxHeight - innerVertPad - sizeTagHeight;
                    final double totalWSpacing = internalSpacing * (cols - 1);
                    final double totalHSpacing = internalSpacing * (rows - 1);
                    final double sqW = (availW - totalWSpacing) / cols;
                    final double sqH = (availH - totalHSpacing) / rows;
                    
                    // Make card size proportional to container size AND grid complexity with improved scaling
                    final double deviceScale = isTablet ? 1.4 : (isLargePhone ? 1.2 : 1.3); // Bigger scale for tablets
                    final double baseContainerPercentage = isLandscape ? 
                      (isTablet ? 0.22 : 0.25) : // Landscape: bigger on tablets too
                      (isTablet ? 0.20 : 0.22); // Portrait: bigger base percentages
                    final double containerBasedSize = min(availW, availH) * baseContainerPercentage * deviceScale;
                    
                    // Adjust complexity factor to make all difficulties more similar in size
                    double complexityFactor;
                    if (gridComplexity == 12) { // 3x4
                      complexityFactor = 0.90; // Increase from 0.88 to make cards bigger
                    } else if (gridComplexity == 18) { // 3x6
                      complexityFactor = 0.94; // Make 3x6 cards bigger too
                    } else if (gridComplexity == 24) { // 4x6 - hardest difficulty
                      complexityFactor = 0.93; // Make hardest difficulty cards even bigger and more consistent
                    } else {
                      complexityFactor = 1.0 - (gridComplexity - 8) * 0.035; // Original calculation for other layouts
                    }
                    
                    final double adjustedContainerSize = containerBasedSize * complexityFactor.clamp(0.4, 1.0);
                    final double squareSize = min(min(sqW, sqH), adjustedContainerSize);
                    
                    // Scale border radius and border width proportionally to card size with device-aware scaling
                    final double baseBorderRadius = isTablet ? 12.0 : 8.0; // Higher base values for tablets
                    final double baseBorderWidth = isTablet ? 5.0 : 3.0; // Higher base values for tablets
                    final double baseReference = containerBasedSize * 0.75; // More appropriate reference size
                    final double scaleFactor = (squareSize / baseReference).clamp(0.4, 1.5); // Allow more range
                    
                    // Adjust border styling to be more consistent between all difficulties
                    double borderStyleReduction;
                    if (gridComplexity == 12) { // 3x4
                      borderStyleReduction = 0.9; // Slight reduction
                    } else if (gridComplexity == 18) { // 3x6
                      borderStyleReduction = 0.87; // Similar to 3x4, instead of the previous 0.6-0.8
                    } else if (gridComplexity == 24) { // 4x6 - hardest difficulty
                      borderStyleReduction = 0.83; // Bigger borders and rounding for hardest difficulty
                    } else {
                      borderStyleReduction = gridComplexity > 12 ? (isTablet ? 0.8 : 0.6) : 1.0; // Original logic for other layouts
                    }
                    
                    final double borderRadius = (baseBorderRadius * scaleFactor * borderStyleReduction).clamp(2.0, 15.0);
                    final double borderWidth = (baseBorderWidth * scaleFactor * borderStyleReduction).clamp(1.5, 6.0);

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
                                  height: squareSize * 1.25, // Slightly taller cards for better proportion
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEEEEE),
                                    borderRadius: BorderRadius.circular(borderRadius),
                                    border: Border.all(
                                      color: const Color(0xFF9DA2CD),
                                      width: borderWidth,
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

                    return Padding(
                      padding: isLandscape
                          ? EdgeInsets.zero
                          : const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          // Main grid area that takes available space minus tag area
                          Expanded(
                            child: Center(child: grid),
                          ),
                          // Size tag fixed at bottom
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFfff1ba),
                              borderRadius: BorderRadius.circular(95),
                              border: Border.all(
                                color: const Color(0xFF9DA2CD),
                                width: 6,
                              ),
                            ),
                            child: Text(
                              '$cols×$rows',
                              style: GoogleFonts.poppins(
                                fontSize: 36,
                                letterSpacing: 3,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4E4A73),
                              ),
                            ),
                          ),
                        ],
                      ),
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
            ],
          ),
    );
  }
}
