import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_repository.dart';
import '../services/date_calculator.dart';
import '../theme/app_theme.dart';
import 'countdown_badge.dart';

/// ホーム・カレンダー詳細で使う共通タスクカード（#11, #25, #54）。
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onComplete,
    this.onTap,
    this.showDate = false,
  });

  final TaskItem task;
  final VoidCallback onComplete;
  final VoidCallback? onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final color = task.type.value.taskTypeColor;
    final days = DateCalculator.daysUntil(task.dueDate, DateTime.now());
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TaskTypeDot(emoji: task.type.emoji),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    if (task.subtitle != null)
                      Text(
                        task.subtitle!,
                        style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                      ),
                    if (showDate)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${task.dueDate.month}月${task.dueDate.day}日',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                    const SizedBox(height: 8),
                    CountdownBadge(daysUntil: days, color: color),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              if (task.status != TaskStatus.done) ...[
                Column(
                  children: [
                    OutlinedButton(
                      onPressed: onComplete,
                      style: OutlinedButton.styleFrom(minimumSize: const Size(72, 40)),
                      child: const Text('完了'),
                    ),
                    TextButton(
                      onPressed: () => _showSnoozeSheet(context),
                      style: TextButton.styleFrom(minimumSize: const Size(72, 32), padding: EdgeInsets.zero),
                      child: const Text('あとで', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ] else
                const Icon(Icons.check_circle, color: AppColors.success),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnoozeSheet(BuildContext context) {
    final repo = context.read<AppRepository>();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text('あとで通知する', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            for (final option in SnoozeOption.values)
              ListTile(
                title: Text(option.label),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final until = await _resolveSnoozeDate(context, option);
                  if (until != null) await repo.snoozeTask(task, until);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _resolveSnoozeDate(BuildContext context, SnoozeOption option) async {
    final now = DateTime.now();
    switch (option) {
      case SnoozeOption.oneHour:
        return now.add(const Duration(hours: 1));
      case SnoozeOption.tonight:
        final tonight = DateTime(now.year, now.month, now.day, 20);
        return tonight.isBefore(now) ? tonight.add(const Duration(days: 1)) : tonight;
      case SnoozeOption.tomorrow:
        return DateTime(now.year, now.month, now.day, 9).add(const Duration(days: 1));
      case SnoozeOption.threeDays:
        return DateTime(now.year, now.month, now.day, 9).add(const Duration(days: 3));
      case SnoozeOption.custom:
        if (!context.mounted) return null;
        final date = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date == null) return null;
        return DateTime(date.year, date.month, date.day, 9);
    }
  }
}
