import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/alarm.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/repositories.dart';

class SubscriptionService implements SubscriptionRepository {
  SubscriptionService(this._userRepository);

  final UserRepository _userRepository;
  final InAppPurchase _iap = InAppPurchase.instance;
  final _tierController = StreamController<SubscriptionTier>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  Future<void> init() async {
    final available = await _iap.isAvailable();
    if (!available) return;

    _purchaseSub = _iap.purchaseStream.listen(_onPurchaseUpdate);
  }

  @override
  Future<bool> isPremiumActive() async {
    final user = await _userRepository.getCurrentUser();
    return user?.isPremium ?? false;
  }

  @override
  Future<void> purchaseMonthly() async {
    await _purchase(AppConstants.premiumMonthlyId);
  }

  @override
  Future<void> purchaseYearly() async {
    await _purchase(AppConstants.premiumYearlyId);
  }

  Future<void> purchaseLifetime() async {
    await _purchase(AppConstants.premiumLifetimeId);
  }

  Future<void> _purchase(String productId) async {
    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isEmpty) return;

    final purchaseParam = PurchaseParam(
      productDetails: response.productDetails.first,
    );
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _activatePremium(
          isTrial: purchase.productID.contains('trial'),
          isLifetime: purchase.productID.contains('lifetime'),
        );
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    }
  }

  Future<void> _activatePremium({
    bool isTrial = false,
    bool isLifetime = false,
  }) async {
    final user = await _userRepository.getCurrentUser();
    if (user == null) return;

    final tier = isLifetime
        ? SubscriptionTier.lifetime
        : isTrial
            ? SubscriptionTier.trial
            : SubscriptionTier.premium;
    final updated = user.copyWith(
      subscriptionTier: tier,
      trialEndsAt: isTrial
          ? DateTime.now().add(const Duration(days: AppConstants.trialDays))
          : null,
    );
    await _userRepository.saveUser(updated);
    _tierController.add(updated.subscriptionTier);
  }

  @override
  Stream<SubscriptionTier> watchSubscriptionTier() async* {
    final user = await _userRepository.getCurrentUser();
    yield user?.subscriptionTier ?? SubscriptionTier.free;
    yield* _tierController.stream;
  }

  Future<bool> shouldShowUpgrade({required bool isPremiumFeature}) async {
    if (!isPremiumFeature) return false;
    return !(await isPremiumActive());
  }

  void dispose() {
    _purchaseSub?.cancel();
    _tierController.close();
  }
}

/// Feature gating — never interrupt active alarms with upgrade prompts.
class PremiumGate {
  PremiumGate(this._subscriptionService, this._getRingState);

  final SubscriptionService _subscriptionService;
  final AlarmRingState Function() _getRingState;

  Future<bool> canAccess({
    required bool isPremiumFeature,
    required Future<void> Function() onUpgradeNeeded,
  }) async {
    if (_isAlarmActive) return !isPremiumFeature;

    final needsUpgrade = await _subscriptionService.shouldShowUpgrade(
      isPremiumFeature: isPremiumFeature,
    );
    if (needsUpgrade) {
      await onUpgradeNeeded();
      return false;
    }
    return true;
  }

  bool get _isAlarmActive {
    final state = _getRingState();
    return state != AlarmRingState.idle && state != AlarmRingState.dismissed;
  }
}
