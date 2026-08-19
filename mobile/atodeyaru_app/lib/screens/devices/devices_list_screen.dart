import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../services/date_calculator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/countdown_badge.dart';
import '../../widgets/section_header.dart';
import '../settings/premium_screen.dart';
import 'device_form_screen.dart';
import 'return_checklist_screen.dart';

/// 端末一覧の中身（#19〜#23）。無料版は端末1台まで。
/// FAB/AppBarは呼び出し側（ContractsTab）が持つため、本体のみのウィジェット。
class DevicesListView extends StatelessWidget {
  const DevicesListView({super.key});

  static void onAddPressed(BuildContext context, AppRepository repo) {
    if (!repo.canAddDevice) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumScreen()));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DeviceFormScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    return repo.devices.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'まだ端末が登録されていません。\n右下の「端末を登録」から返却時期を管理できます。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              if (!repo.settings.isPremium) const SectionHeader(title: '端末（無料版：1台まで）'),
              for (final d in repo.devices) _DeviceTile(device: d),
            ],
          );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device});
  final Device device;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppRepository>();
    final due = device.returnCheckDate;
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: due == null
                ? const Text('返却時期: わからない')
                : Text('返却確認日の目安: ${due.year}/${due.month}/${due.day}'),
            trailing: due == null
                ? null
                : CountdownBadge(daysUntil: DateCalculator.daysUntil(due, DateTime.now()), color: AppColors.warning),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DeviceFormScreen(existing: device)),
            ),
            onLongPress: () => _confirmDelete(context, repo),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.checklist),
                label: const Text('返却前チェックリスト'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ReturnChecklistScreen(device: device)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppRepository repo) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('「${device.name}」を削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('キャンセル')),
          TextButton(
            onPressed: () {
              repo.deleteDevice(device.id);
              Navigator.pop(dialogContext);
            },
            child: const Text('削除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
