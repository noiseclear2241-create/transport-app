import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_header.dart';

/// 履歴（#41）。過去に完了したタスクを確認できる。
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final completed = repo.completedTasks;

    return Scaffold(
      appBar: AppBar(title: const Text('履歴')),
      body: completed.isEmpty
          ? const Center(
              child: Text('完了したタスクはまだありません。', style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                const SectionHeader(title: '完了したこと'),
                for (final t in completed) _HistoryTile(task: t),
              ],
            ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.task});
  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppRepository>();
    final completedAt = task.completedAt;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: AppColors.success),
        title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          completedAt == null
              ? ''
              : '完了日: ${completedAt.year}/${completedAt.month}/${completedAt.day}',
        ),
        trailing: TextButton(
          onPressed: () => repo.reopenTask(task),
          child: const Text('取り消す'),
        ),
      ),
    );
  }
}
