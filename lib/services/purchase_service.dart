import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'storage_service.dart';

/// Store product IDs for the Pro subscription. These must exactly match
/// the subscription products configured in Google Play Console / App
/// Store Connect.
class SubscriptionIds {
  SubscriptionIds._();

  static const String monthly = 'monthly';
  static const String yearly = 'yearly';
  static const Set<String> all = {monthly, yearly};
}

/// Wraps `in_app_purchase` to sell the ad-free Pro subscription. Mirrors
/// [AdService]'s singleton pattern.
class PurchaseService {
  static final PurchaseService _instance = PurchaseService._();
  static PurchaseService get instance => _instance;
  PurchaseService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isPro = StorageService.isPro();
  bool _isAvailable = false;
  bool _isLoadingProducts = false;
  List<ProductDetails> _products = [];
  String? _pendingError;

  bool get isPro => _isPro;
  bool get isAvailable => _isAvailable;
  bool get isLoadingProducts => _isLoadingProducts;
  List<ProductDetails> get products => _products;
  String? get pendingError => _pendingError;

  /// Fired whenever [isPro] actually changes value (first purchase or
  /// restore) — used to flip ad-gating on immediately.
  ValueChanged<bool>? onProStatusChanged;

  /// Fired after every purchase-stream update is processed (success,
  /// failure, or cancel) so the UI can stop showing a loading spinner.
  VoidCallback? onPurchaseUpdate;

  Future<void> init() async {
    _isAvailable = await _iap.isAvailable();
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (_) {},
    );
    if (_isAvailable) {
      await loadProducts();
    }
  }

  Future<void> loadProducts() async {
    _isLoadingProducts = true;
    try {
      final response = await _iap.queryProductDetails(SubscriptionIds.all);
      _products = response.productDetails;
    } catch (_) {
      _products = [];
    }
    _isLoadingProducts = false;
  }

  ProductDetails? productFor(String id) {
    for (final product in _products) {
      if (product.id == id) return product;
    }
    return null;
  }

  Future<void> buy(String productId) async {
    _pendingError = null;
    final product = productFor(productId);
    if (product == null) {
      _pendingError = 'This plan is not available right now. Please try again later.';
      onPurchaseUpdate?.call();
      return;
    }
    await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  Future<void> restore() async {
    _pendingError = null;
    await _iap.restorePurchases();
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          continue;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _setPro(true);
          break;
        case PurchaseStatus.error:
          _pendingError = purchase.error?.message ?? 'Purchase failed. Please try again.';
          break;
        case PurchaseStatus.canceled:
          break;
      }
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
    onPurchaseUpdate?.call();
  }

  void _setPro(bool value) {
    if (_isPro == value) return;
    _isPro = value;
    StorageService.setPro(value);
    onProStatusChanged?.call(value);
  }

  void dispose() {
    _subscription?.cancel();
  }
}
