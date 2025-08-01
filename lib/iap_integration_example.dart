// This file shows how to integrate the PaymentService into your main app
// You can copy the relevant parts to your main.dart file

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'iap.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class GridSelectionPageWithIAP extends StatefulWidget {
  const GridSelectionPageWithIAP({super.key});

  @override
  State<GridSelectionPageWithIAP> createState() => _GridSelectionPageWithIAPState();
}

class _GridSelectionPageWithIAPState extends State<GridSelectionPageWithIAP> {
  // Track if the full version is purchased and loading state
  bool _isFullVersion = false;
  bool _isLoading = true;
  bool _isPurchasing = false;
  SharedPreferences? _prefs;
  
  // Add PaymentService
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase successful! Full version unlocked.'),
            backgroundColor: Colors.green,
          ),
        );
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

    // Initialize the service
    await _paymentService.initialize();
    
    // Load products
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _paymentService.loadProducts();
    if (mounted) {
      setState(() {
        _products = products;
        _isFullVersion = _paymentService.isUnlockAllPurchased;
      });
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

  // Load purchase status from shared preferences
  Future<void> _loadPurchaseStatus() async {
    if (_prefs == null) return;

    if (mounted) {
      setState(() {
        _isFullVersion = _prefs!.getBool('isFullVersion') ?? false;
      });
    }
  }

  // Handle purchase of full version using PaymentService
  Future<void> _handlePurchase() async {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Products not loaded yet. Please try again.'),
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
        (product) => product.id == 'unlockall',
        orElse: () => throw Exception('Product not found'),
      );

      // Initiate purchase
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

  // Handle restore purchases
  Future<void> _handleRestorePurchases() async {
    setState(() {
      _isPurchasing = true;
    });

    try {
      await _paymentService.restorePurchases();
    } finally {
      setState(() {
        _isPurchasing = false;
      });
    }
  }

  // Show purchase dialog
  void _showPurchaseDialog() {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Products not available. Please check your internet connection.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final unlockAllProduct = _products.firstWhere(
      (product) => product.id == 'unlockall',
      orElse: () => throw Exception('Product not found'),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unlock Full Version'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Unlock all levels for ${unlockAllProduct.price}'),
              const SizedBox(height: 16),
              if (_isPurchasing)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _handlePurchase,
                      child: Text('Buy for ${unlockAllProduct.price}'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _handleRestorePurchases,
                      child: const Text('Restore Purchases'),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Your existing build method, but add the purchase dialog
    // This is just a simplified example
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Game'),
        actions: [
          if (!_isFullVersion)
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: _showPurchaseDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : const Center(
              child: Text('Your game content here'),
            ),
    );
  }
}
