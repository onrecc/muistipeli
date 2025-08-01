import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  static const String _unlockAllKey = 'unlock_all_purchased';
  
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // Callbacks for purchase status updates
  Function(bool)? onPurchaseComplete;
  Function(String)? onPurchaseError;
  
  // Track purchase state
  bool _isUnlockAllPurchased = false;
  bool get isUnlockAllPurchased => _isUnlockAllPurchased;

  Future<void> initialize() async {
    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      // Store is not available
      return;
    }

    // Load saved purchase state
    await _loadPurchaseState();

    // Set up the subscription to listen for purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: _updateStreamOnDone,
      onError: _updateStreamOnError,
    );

    // Restore previous purchases on initialization
    await restorePurchases();
  }

  Future<void> _loadPurchaseState() async {
    final prefs = await SharedPreferences.getInstance();
    _isUnlockAllPurchased = prefs.getBool(_unlockAllKey) ?? false;
  }

  Future<void> _savePurchaseState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_unlockAllKey, _isUnlockAllPurchased);
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Handle pending purchases (show loading indicator)
        continue;
      }

      if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle purchase errors
        final error = purchaseDetails.error?.message ?? 'Purchase failed';
        onPurchaseError?.call(error);
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        // Handle purchase cancellation
        onPurchaseError?.call('Purchase was cancelled');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        // Handle successful purchases
        _handleSuccessfulPurchase(purchaseDetails);
      }

      // Complete the purchase transaction
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  void _updateStreamOnDone() {
    _subscription?.cancel();
  }

  void _updateStreamOnError(dynamic error) {
    // Handle errors here
    print('Error in purchase stream: $error');
    onPurchaseError?.call('Purchase stream error: $error');
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    // Verify the purchase (in a real app, you'd want server-side verification)
    if (purchaseDetails.productID == 'unlock_all') {
      _isUnlockAllPurchased = true;
      await _savePurchaseState();
      onPurchaseComplete?.call(true);
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      print('Error restoring purchases: $e');
      onPurchaseError?.call('Failed to restore purchases: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }

  Future<List<ProductDetails>> loadProducts() async {
    // Define your product IDs
    final Set<String> productIds = {'unlock_all'};

    // Query the store for product details
    final ProductDetailsResponse response = await _inAppPurchase
        .queryProductDetails(productIds);

    if (response.error != null) {
      print('Error loading products: ${response.error}');
      return [];
    }

    return response.productDetails;
  }

  Future<bool> purchaseProduct(ProductDetails product) async {
    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

      if (_isConsumable(product.id)) {
        return await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      } else {
        return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      print('Error purchasing product: $e');
      onPurchaseError?.call('Purchase failed: $e');
      return false;
    }
  }

  bool _isConsumable(String productId) {
    // Define which products are consumable
    final consumables = {'coins_100'};
    return consumables.contains(productId);
  }
}
