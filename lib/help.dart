import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'iap.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFe7eaf6), // Set consistent background color
      body: Container(
        child: SafeArea(
          child: Stack(
            children: [
              // Close button
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF9DA2CD),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 24,
                      color: Color(0xFF4E4A73),
                    ),
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.only(top: 70, left: 16, right: 16, bottom: 24),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          _buildMenuItem(
                            context,
                            icon: Icons.star,
                            title: 'Upgrade to full version',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PurchasePage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildMenuItem(
                            context,
                            icon: Icons.help_outline,
                            title: 'How to play?',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const GuidePage()),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildMenuItem(
                            context,
                            icon: Icons.info_outline,
                            title: 'About us',
                            onTap: () async {
                              const urlString = 'https://digihappy.fi';
                              try {
                                final url = Uri.parse(urlString);
                                
                                // Try different launch modes for better Android compatibility
                                bool launched = false;
                                
                                // First try: external application (default browser)
                                try {
                                  launched = await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } catch (e) {
                                  launched = false;
                                }
                                
                                // Second try: platform default
                                if (!launched) {
                                  try {
                                    launched = await launchUrl(
                                      url,
                                      mode: LaunchMode.platformDefault,
                                    );
                                  } catch (e) {
                                    launched = false;
                                  }
                                }
                                
                                // Third try: in-app web view (last resort)
                                if (!launched) {
                                  try {
                                    launched = await launchUrl(
                                      url,
                                      mode: LaunchMode.inAppWebView,
                                    );
                                  } catch (e) {
                                    launched = false;
                                  }
                                }
                                
                                if (!launched) {
                                  throw Exception('All launch methods failed');
                                }
                                
                              } catch (e) {
                                // Show error and provide manual option
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Could not open website automatically. Please visit digihappy.fi in your browser.'),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 4),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildMenuItem(
                            context,
                            icon: Icons.description,
                            title: 'Terms and Conditions',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const PlaceholderPage(title: 'Terms and Conditions'),
                                ),
                              );
                            },
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
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF9DA2CD),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(64),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: const Color(0xFF4e5180),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 24,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GuidePage extends StatelessWidget {
  const GuidePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFe7eaf6), // Consistent background color
      body: Container(
        child: SafeArea(
          child: Stack(
            children: [
              // Close button
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF9DA2CD),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 24,
                      color: Color(0xFF4E4A73),
                    ),
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.only(top: 70, left: 24, right: 24, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'How to Play',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF4E4A73),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSection('Goal', 'Find all the matching card pairs.'),
                            const SizedBox(height: 32),
                            _buildSection('How', 'Tap any card to turn it over.\nTap another card to find its match.\nKeep matching pairs until all cards are cleared!'),
                            const SizedBox(height: 32),
                            _buildSection('Timer & Stars', 'Each game has a timer.\nAfter you finish, you get:\n\n1 star = Took a bit longer\n2 stars = Pretty quick!\n3 stars = Very fast!'),
                            const SizedBox(height: 32),
                            _buildSection('Levels', 'Level 1 – 2 x 4 cards (FREE)\nLevel 2 – 3 x 4 cards (FREE)\nLevel 3 – 3 x 6 cards (Unlock to play)\nLevel 4 – 4 x 6 cards (Unlock to play)'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF4E4A73),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF4E4A73),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class PurchasePage extends StatefulWidget {
  const PurchasePage({Key? key}) : super(key: key);

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  final PaymentService _paymentService = PaymentService();
  List<ProductDetails> _products = [];
  bool _isLoading = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _initPaymentService();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _initPaymentService() async {
    _paymentService.onPurchaseComplete = (success) {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase successful! All levels unlocked.'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate back to main screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    };

    _paymentService.onPurchaseError = (error) {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    };

    try {
      await _paymentService.initialize();
      final products = await _paymentService.loadProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePurchase() async {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Products not available. Please check your internet connection.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isPurchasing = true;
    });

    try {
      final unlockAllProduct = _products.firstWhere(
        (product) => product.id == 'unlock_all',
        orElse: () => throw Exception('Unlock all product not found'),
      );
      await _paymentService.purchaseProduct(unlockAllProduct);
    } catch (e) {
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

  Future<void> _handleRestorePurchases() async {
    setState(() {
      _isPurchasing = true;
    });

    try {
      await _paymentService.restorePurchases();
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.shortestSide >= 600;
    
    final double titleSize = isTablet ? 32 : 24;
    final double descriptionSize = isTablet ? 20 : 16;
    final double priceSize = isTablet ? 28 : 20;

    return Scaffold(
      backgroundColor: const Color(0xFFe7eaf6),
      body: SafeArea(
        child: Stack(
          children: [
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF9DA2CD),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 24,
                    color: Color(0xFF4E4A73),
                  ),
                ),
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.only(top: 70, left: 24, right: 24, bottom: 24),
              child: Column(
                children: [
                  Text(
                    'Upgrade to Full Version',
                    style: GoogleFonts.poppins(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4E4A73),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (_isLoading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4E4A73),
                        ),
                      ),
                    )
                  else if (_products.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Products not available',
                              style: TextStyle(
                                fontSize: descriptionSize,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please check your internet connection',
                              style: TextStyle(
                                fontSize: descriptionSize - 2,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Column(
                        children: [
                          // Product information
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF9DA2CD),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 64,
                                  color: Colors.amber,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Unlock All Levels',
                                  style: GoogleFonts.poppins(
                                    fontSize: priceSize,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF4E4A73),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Get access to all 4 difficulty levels:\n• Level 3 – 3 x 6 cards\n• Level 4 – 4 x 6 cards',
                                  style: TextStyle(
                                    fontSize: descriptionSize,
                                    color: const Color(0xFF4E4A73),
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (_products.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFfff1ba),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF9da2cd),
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      _products.first.price,
                                      style: TextStyle(
                                        fontSize: priceSize,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF4E4A73),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Purchase button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isPurchasing ? null : _handlePurchase,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4e5180),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                disabledBackgroundColor: Colors.grey[300],
                              ),
                              child: _isPurchasing
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Purchase Now',
                                      style: TextStyle(
                                        fontSize: priceSize,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Restore purchases button
                          TextButton(
                            onPressed: _isPurchasing ? null : _handleRestorePurchases,
                            child: Text(
                              'Restore Purchases',
                              style: TextStyle(
                                fontSize: descriptionSize,
                                color: const Color(0xFF4E4A73),
                                decoration: TextDecoration.underline,
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
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (title == 'Terms and Conditions') {
      return Scaffold(
        backgroundColor: const Color(0xFFe7eaf6),
        body: Container(
          child: SafeArea(
            child: Stack(
              children: [
                // Close button
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF9DA2CD),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 24,
                        color: Color(0xFF4E4A73),
                      ),
                    ),
                  ),
                ),
                // Main content
                Padding(
                  padding: const EdgeInsets.only(top: 70, left: 24, right: 24, bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Terms and Conditions',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF4E4A73),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Last updated 17.7.2025',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4E4A73),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 32),
                              _buildSection('1. App Use', 'This memory game app is designed for users of all ages — kids, adults, and seniors. You may use the app freely for personal, non-commercial purposes.'),
                              const SizedBox(height: 32),
                              _buildSection('2. Privacy & Data Protection', 'No personal data is collected.\nWe do not store, track, or share any information.\nThere is no login, no account, and no external data transmission.\nThe app fully complies with the EU General Data Protection Regulation (GDPR) and other relevant privacy laws.'),
                              const SizedBox(height: 32),
                              _buildSection('3. In-App Purchases', 'The app includes an optional one-time purchase to unlock extra levels.\nThis purchase is handled securely through your device\'s app store (Apple App Store / Google Play Store).\nAll payments are subject to the terms and policies of the app store.'),
                              const SizedBox(height: 32),
                              _buildSection('4. Children\'s Use', 'The app is safe for children and does not contain ads or links.\nThe content is family-friendly and free of inappropriate material.\nParents or guardians should supervise in-app purchases.'),
                              const SizedBox(height: 32),
                              _buildSection('5. Intellectual Property', 'All graphics and content within the app are either original or used under a proper license. These materials may not be copied, modified, or reused outside the app without permission.\nSome graphics, illustrations, or design elements in the app are created using media from Canva, under a valid Canva Teams license. These elements are used within original Digihappy designs and layouts.'),
                              const SizedBox(height: 32),
                              _buildSection('6. Liability', 'We strive to make the app as enjoyable and bug-free as possible. However, we cannot guarantee it will always work perfectly on all devices. We are not liable for any issues or damages that may result from using the app.'),
                              const SizedBox(height: 32),
                              _buildSection('7. Misuse', 'You agree not to use the app in any unlawful or harmful way, or attempt to reverse-engineer or copy its content.'),
                              const SizedBox(height: 32),
                              _buildSection('8. Contact', 'If you have any questions about these Terms or the app, please contact us at:\n\nhappygames@digihappy.fi \n\nhttps://digihappy.fi \n\n© 2025 Digihappy Oy. All rights reserved. \n\nDeveloped in Finland by Digihappy Oy. Lead developer Rene Saarikko.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Default placeholder for other pages
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.build_circle_outlined,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                '$title page coming soon',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This feature will be available in future updates',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF4E4A73),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF4E4A73),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
