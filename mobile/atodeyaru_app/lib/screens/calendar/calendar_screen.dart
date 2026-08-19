import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/task_card.dart';

/// アプリ内カレンダー（#26）。月表示、種類別カラー、タップで詳細。
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _visibleMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final tasksByDay = <DateTime, List<TaskItem>>{};
    for (final t in repo.tasks) {
      final key = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      tasksByDay.putIfAbsent(key, () => []).add(t);
    }
    final selectedTasks = _selectedDay == null ? <TaskItem>[] : (tasksByDay[_selectedDay] ?? []);

    return Scaffold(
      appBar: AppBar(title: const Text('カレンダー')),
      body: Column(
        children: [
          _MonthHeader(
            month: _visibleMonth,
            onPrev: () => setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1)),
            onNext: () => setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1)),
          ),
          _MonthGrid(
            month: _visibleMonth,
            tasksByDay: tasksByDay,
            selectedDay: _selectedDay,
            onSelect: (d) => setState(() => _selectedDay = d),
          ),
          const _Legend(),
          const Divider(height: 1),
          Expanded(
            child: selectedTasks.isEmpty
                ? const Center(child: Text('この日の予定はありません', style: TextStyle(color: AppColors.textSecondary)))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final t in selectedTasks)
                        TaskCard(task: t, onComplete: () => repo.completeTask(t)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month, required this.onPrev, required this.onNext});
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
          Text('${month.year}年${month.month}月', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.tasksByDay,
    required this.selectedDay,
    required this.onSelect,
  });

  final DateTime month;
  final Map<DateTime, List<TaskItem>> tasksByDay;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    // 月曜始まり。firstOfMonth.weekday: 月=1...日=7
    final leadingBlanks = firstOfMonth.weekday - 1;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final today = DateTime.now();
    final cells = <Widget>[];

    const weekLabels = ['月', '火', '水', '木', '金', '土', '日'];
    for (final w in weekLabels) {
      cells.add(Center(
        child: Text(w, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
      ));
    }
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
      final isSelected = selectedDay != null &&
          date.year == selectedDay!.year && date.month == selectedDay!.month && date.day == selectedDay!.day;
      final dayTasks = tasksByDay[date] ?? [];

      cells.add(GestureDetector(
        onTap: () => onSelect(date),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : null,
            border: isToday ? Border.all(color: AppColors.primary, width: 1.5) : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$day', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Wrap(
                spacing: 2,
                children: [
                  for (final t in dayTasks.take(3))
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: t.type.value.taskTypeColor, shape: BoxShape.circle),
                    ),
                ],
              ),
            ],
          ),
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.1,
        children: cells,
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('🔴', '解約'),
      ('🟡', '申請'),
      ('🟢', '特典'),
      ('🟠', '返却'),
      ('🔵', '確認'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 12,
        children: [
          for (final (emoji, label) in items) Text('$emoji $label', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
