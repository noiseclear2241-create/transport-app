import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../theme/app_theme.dart';

/// プレミアム案内・課金画面（#29〜#35）。
///
/// 価格はストア（App Store Connect / Google Play Console）側の商品設定から
/// 取得する構成が前提のため、ここでの「月額298円」「年額2,980円」は
/// ストアから商品情報を取得できるまでの表示用フォールバックとして扱う。
/// 実際の購入処理は SubscriptionService（in_app_purchase）を通じて行う。
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final settings = repo.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('プレミアム')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.workspace_premium, size: 56, color: AppColors.primary),
          const SizedBox(height: 12),
          const Text('スマホ契約後のお金と予定を、忘れない。',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          const _FeatureRow(text: '契約数・端末数が無制限'),
          const _FeatureRow(text: '家族の契約もまとめて管理'),
          const _FeatureRow(text: 'Googleカレンダー連携'),
          const _FeatureRow(text: '高度な通知設定・通知数拡張'),
          const _FeatureRow(text: '広告なし'),
          const SizedBox(height: 24),
          if (settings.subscriptionState == SubscriptionState.free) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Text('まずは7日間、無料でお試しください', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('無料期間終了後は月額298円です。いつでも解約できます。', textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => repo.startFreeTrial(),
              child: const Text('7日間無料体験を始める'),
            ),
          ] else if (settings.subscriptionState == SubscriptionState.trial) ...[
            _TrialStatusCard(daysRemaining: settings.trialDaysRemaining(DateTime.now())),
            const SizedBox(height: 16),
            const _PlanButtons(),
          ] else if (settings.isPremium) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('すでにプレミアムをご利用中です。ありがとうございます！',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ] else ...[
            const _PlanButtons(),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              // TODO: SubscriptionService.instance.restorePurchases() を呼び出し、
              // AppRepository.applySubscriptionState でストアの状態を反映する（#35）。
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('購入を復元しました（ストア設定後に有効になります）')),
              );
            },
            child: const Text('購入を復元する'),
          ),
          const SizedBox(height: 8),
          const Text(
            '買い切りプランはありません。月額298円または年額2,980円のサブスクリプションです。'
            'iOSではApp Store、AndroidではGoogle Playの設定からいつでも解約できます。',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}

class _TrialStatusCard extends StatelessWidget {
  const _TrialStatusCard({required this.daysRemaining});
  final int daysRemaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text('無料体験はあと$daysRemaining日です。', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('無料期間終了後は月額298円です。次回の料金発生日は体験終了日の翌日です。', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _PlanButtons extends StatelessWidget {
  const _PlanButtons();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppRepository>();
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _purchase(context, repo),
          child: const Text('月額298円で始める'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => _purchase(context, repo),
          child: const Text('年額2,980円で始める（お得）'),
        ),
      ],
    );
  }

  void _purchase(BuildContext context, AppRepository repo) {
    // TODO: SubscriptionService.instance.buy(product) を呼び出す。
    // StoreKit / Google Play Billing の購入完了コールバックで
    // repo.applySubscriptionState(SubscriptionState.premium, ...) を呼ぶ。
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ストアの商品設定が完了すると購入できるようになります')),
    );
  }
}
