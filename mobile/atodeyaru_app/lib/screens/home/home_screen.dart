import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../services/date_calculator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_header.dart';
import '../../widgets/task_card.dart';
import '../settings/premium_screen.dart';

/// ホーム画面（#11, #54）。
/// アプリを開いた瞬間に「今日、自分が何をすればいいのか」が分かることを最優先する。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final today = DateTime.now();
    final pending = repo.pendingTasks;

    final todayTasks = pending.where((t) => DateCalculator.daysUntil(t.dueDate, today) <= 0).toList();
    final soonTasks = pending
        .where((t) =>
            t.type != TaskType.deviceReturn &&
            DateCalculator.daysUntil(t.dueDate, today) > 0 &&
            DateCalculator.daysUntil(t.dueDate, today) <= 14)
        .toList();
    final returnTasks = pending
        .where((t) => t.type == TaskType.deviceReturn && DateCalculator.daysUntil(t.dueDate, today) > 0)
        .toList();
    final laterTasks = pending
        .where((t) =>
            t.type != TaskType.deviceReturn &&
            DateCalculator.daysUntil(t.dueDate, today) > 14)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('あとでやること', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (!repo.settings.isPremium)
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PremiumScreen()),
              ),
              child: const Text('プレミアム'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: repo.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            if (repo.settings.subscriptionState == SubscriptionState.trial)
              _TrialBanner(daysRemaining: repo.settings.trialDaysRemaining(today)),
            if (pending.isEmpty) ...[
              const SizedBox(height: 40),
              const EmptyState(
                message: '今のところ、やることはありません。\n契約を登録すると自動でお知らせします。',
                icon: Icons.celebration_outlined,
              ),
            ],
            if (todayTasks.isNotEmpty) ...[
              const SectionHeader(title: '今日やること'),
              for (final t in todayTasks)
                TaskCard(task: t, onComplete: () => repo.completeTask(t)),
            ],
            if (soonTasks.isNotEmpty) ...[
              const SectionHeader(title: 'もうすぐ'),
              for (final t in soonTasks)
                TaskCard(task: t, onComplete: () => repo.completeTask(t), showDate: true),
            ],
            if (returnTasks.isNotEmpty) ...[
              const SectionHeader(title: 'スマホ返却'),
              for (final t in returnTasks)
                TaskCard(task: t, onComplete: () => repo.completeTask(t), showDate: true),
            ],
            if (laterTasks.isNotEmpty) ...[
              const SectionHeader(title: '今後'),
              for (final t in laterTasks)
                TaskCard(task: t, onComplete: () => repo.completeTask(t), showDate: true),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrialBanner extends StatelessWidget {
  const _TrialBanner({required this.daysRemaining});
  final int daysRemaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              daysRemaining > 0
                  ? '無料体験はあと$daysRemaining日です。終了後は月額298円になります。'
                  : '無料体験が終了しました。継続するにはプレミアムへご登録ください。',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
