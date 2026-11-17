import 'dart:async';

import 'package:admob_kit/admob_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'storage_service.dart';

/// Build with `--dart-define=IAP_DEBUG=true` to log what Google Play returns.
const bool _iapDebug = bool.fromEnvironment('IAP_DEBUG');

/// Store product IDs for "Remove ads". These must exactly match the products
/// in Google Play Console: subscriptions `monthly` and `yearly`, plus the
/// one-time product `lifetime`.
class SubscriptionIds {
  SubscriptionIds._();

  static const String monthly = 'monthly';
  static const String yearly = 'yearly';
  static const String lifetime = 'lifetime';
  static const List<String> order = [monthly, yearly, lifetime];
  static const Set<String> all = {monthly, yearly, lifetime};
}

/// Wraps `in_app_purchase` to sell "Remove ads" (subscriptions and a
/// lifetime product). Mirrors [AdService]'s singleton pattern.
///
/// [isPro] is cached on the phone so ads stay off when the store can't be
/// reached, and re-checked against Google Play on every start, so a
/// cancelled subscription brings ads back once it runs out.
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

  /// Fired whenever [isPro] actually changes value (purchase, restore or an
  /// expired subscription) — used to flip ad-gating immediately.
  ValueChanged<bool>? onProStatusChanged;

  /// Fired after every purchase-stream update is processed (success,
  /// failure, or cancel) so the UI can stop showing a loading spinner.
  VoidCallback? onPurchaseUpdate;

  Future<void> init() async {
    try {
      _isAvailable = await _iap.isAvailable();
    } catch (_) {
      _isAvailable = false;
    }
    if (!_isAvailable) return;
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (_) {},
    );
    await Future.wait([loadProducts(), syncOwned()]);
  }

  Future<void> loadProducts() async {
    _isLoadingProducts = true;
    try {
      final response = await _iap
          .queryProductDetails(SubscriptionIds.all)
          .timeout(const Duration(seconds: 20));
      if (_iapDebug) _logResponse(response);
      // A subscription comes back once per base plan / offer. Keep the plain
      // base plan (no offer id) so the paywall shows the same price that the
      // Play purchase sheet charges.
      final byId = <String, ProductDetails>{};
      for (final p in response.productDetails) {
        final current = byId[p.id];
        if (current == null || (!_isBasePlan(current) && _isBasePlan(p))) {
          byId[p.id] = p;
        }
      }
      _products = [
        for (final id in SubscriptionIds.order)
          if (byId[id] != null) byId[id]!,
      ];
    } catch (_) {
      _products = [];
    }
    _isLoadingProducts = false;
  }

  /// True for a one-time product, or for a subscription entry that is the
  /// base plan itself rather than an offer on it.
  static bool _isBasePlan(ProductDetails p) {
    if (p is! GooglePlayProductDetails) return true;
    final index = p.subscriptionIndex;
    final offers = p.productDetails.subscriptionOfferDetails;
    if (index == null || offers == null) return true;
    return offers[index].offerId == null;
  }

  void _logResponse(ProductDetailsResponse response) {
    debugPrint(
      '[IAP] error=${response.error} notFound=${response.notFoundIDs}',
    );
    for (final p in response.productDetails) {
      debugPrint('[IAP] id=${p.id} price=${p.price} raw=${p.rawPrice}');
      if (p is! GooglePlayProductDetails) continue;
      final w = p.productDetails;
      debugPrint(
        '[IAP]   type=${w.productType} index=${p.subscriptionIndex} '
        'oneTime=${w.oneTimePurchaseOfferDetails?.formattedPrice}',
      );
      final offers = w.subscriptionOfferDetails ?? const [];
      for (var i = 0; i < offers.length; i++) {
        final o = offers[i];
        final phases = o.pricingPhases
            .map(
              (ph) =>
                  '${ph.formattedPrice}/${ph.billingPeriod}'
                  'x${ph.billingCycleCount}',
            )
            .join(', ');
        debugPrint(
          '[IAP]   offer[$i] basePlan=${o.basePlanId} offerId=${o.offerId} '
          'tags=${o.offerTags} token=${o.offerIdToken.substring(0, 12)}... '
          'phases=[$phases]',
        );
      }
    }
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
      _pendingError =
          'This plan is not available right now. Please try again later.';
      onPurchaseUpdate?.call();
      return;
    }
    // Coming back from the Play billing sheet must not land on an App Open
    // ad (or an interstitial) on top of the paywall.
    AdSuppression.suppressFor(const Duration(minutes: 10));
    try {
      // Subscriptions and the lifetime product are all non-consumable.
      final started = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) onPurchaseUpdate?.call();
    } catch (_) {
      _pendingError = 'Purchase failed. Please try again.';
      onPurchaseUpdate?.call();
    }
  }

  /// Re-checks Google Play for what the user owns. Returns [isPro].
  Future<bool> restore() async {
    _pendingError = null;
    await syncOwned();
    onPurchaseUpdate?.call();
    return _isPro;
  }

  /// Asks Google Play what the user owns right now (active subscriptions and
  /// the lifetime product) and updates [isPro] to match. Keeps the cached
  /// state when Play can't answer.
  Future<void> syncOwned() async {
    if (!_isAvailable || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      final addition =
          _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final res = await addition.queryPastPurchases();
      if (res.error != null) return;
      final owned = res.pastPurchases.where(
        (p) =>
            SubscriptionIds.all.contains(p.productID) &&
            p.status != PurchaseStatus.pending &&
            p.status != PurchaseStatus.error,
      );
      for (final p in owned) {
        if (p.pendingCompletePurchase) await _iap.completePurchase(p);
      }
      _setPro(owned.isNotEmpty);
    } catch (_) {
      // Keep the cached state.
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (!SubscriptionIds.all.contains(purchase.productID)) continue;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          continue;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _setPro(true);
          break;
        case PurchaseStatus.error:
          _pendingError =
              purchase.error?.message ?? 'Purchase failed. Please try again.';
          break;
        case PurchaseStatus.canceled:
          break;
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
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
