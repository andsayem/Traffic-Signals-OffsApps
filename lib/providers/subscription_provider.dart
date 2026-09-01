import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../ads/ad_service.dart';
import '../services/purchase_service.dart';

/// Exposes Pro-subscription state to the widget tree and drives
/// [AdService]'s ad-gating whenever the status changes.
class SubscriptionProvider with ChangeNotifier {
  final PurchaseService _service = PurchaseService.instance;
  bool _isPurchasing = false;

  SubscriptionProvider() {
    AdService.instance.setProUser(_service.isPro);
    _service.onProStatusChanged = (isPro) {
      AdService.instance.setProUser(isPro);
      notifyListeners();
    };
    _service.onPurchaseUpdate = () {
      _isPurchasing = false;
      notifyListeners();
    };
    _init();
  }

  bool get isPro => _service.isPro;
  bool get isStoreAvailable => _service.isAvailable;
  bool get isLoadingProducts => _service.isLoadingProducts;
  bool get isPurchasing => _isPurchasing;
  String? get error => _service.pendingError;

  ProductDetails? get monthlyProduct => _service.productFor(SubscriptionIds.monthly);
  ProductDetails? get yearlyProduct => _service.productFor(SubscriptionIds.yearly);

  Future<void> _init() async {
    await _service.init();
    notifyListeners();
  }

  Future<void> purchase(String productId) async {
    _isPurchasing = true;
    notifyListeners();
    await _service.buy(productId);
  }

  Future<void> restore() async {
    _isPurchasing = true;
    notifyListeners();
    await _service.restore();
  }
}
