import 'package:flutter/material.dart';

/// 「あと○日」表示（#25）。重要な予定を大きく見せるための共通ウィジェット。
class CountdownBadge extends StatelessWidget {
  const CountdownBadge({super.key, required this.daysUntil, required this.color});

  final int daysUntil;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final String label;
    if (daysUntil < 0) {
      label = '${-daysUntil}日超過';
    } else if (daysUntil == 0) {
      label = '今日';
    } else {
      label = 'あと$daysUntil日';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}

class TaskTypeDot extends StatelessWidget {
  const TaskTypeDot({super.key, required this.emoji});
  final String emoji;

  @override
  Widget build(BuildContext context) => Text(emoji, style: const TextStyle(fontSize: 20));
}
