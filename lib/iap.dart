import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:get/get.dart';

class InAppPurchaseUtils extends GetxController {
  InAppPurchaseUtils._();

  static final InAppPurchaseUtils _instance = InAppPurchaseUtils._();

  static InAppPurchaseUtils get inAppPurchaseUtilsInstance => _instance;

  final InAppPurchase _iap = InAppPurchase.instance;

  void purchaseProduct(ProductDetails productDetails) {
    final purchaseParam = PurchaseParam(productDetails: productDetails);

    _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }
}
