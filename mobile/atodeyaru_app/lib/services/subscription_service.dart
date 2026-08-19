import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

/// App Store / Google Play Billing 連携（#32, #33, #34, #35）。
///
/// 価格はコードに直接固定せず、ストア側の商品設定（App Store Connect /
/// Google Play Console）から取得する（#30）。ここでは商品IDのみを定義し、
/// 実際の価格・表示名はストアの管理画面側で管理する。
///
/// 商品ID（各ストアの管理画面で実際に作成し、値を合わせること）:
///   - プレミアム月額: premium_monthly
///   - プレミアム年額: premium_yearly
class SubscriptionService {
  SubscriptionService._internal();
  static final SubscriptionService instance = SubscriptionService._internal();

  static const String monthlyProductId = 'premium_monthly';
  static const String yearlyProductId = 'premium_yearly';
  static const Set<String> productIds = {monthlyProductId, yearlyProductId};

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// 購入更新の通知先。AppRepository.applySubscriptionState を呼び出すことを想定。
  void Function(List<PurchaseDetails> purchases)? onPurchaseUpdated;

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<List<ProductDetails>> loadProducts() async {
    final response = await _iap.queryProductDetails(productIds);
    return response.productDetails;
  }

  void startListening() {
    _subscription ??= _iap.purchaseStream.listen((purchases) {
      onPurchaseUpdated?.call(purchases);
      for (final p in purchases) {
        if (p.pendingCompletePurchase) {
          _iap.completePurchase(p);
        }
      }
    });
  }

  Future<void> buy(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  /// 購入の復元（#35）。iOS: 購入の復元 / Android: 購入情報の再取得。
  Future<void> restorePurchases() => _iap.restorePurchases();

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
