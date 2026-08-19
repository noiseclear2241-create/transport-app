import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import 'family_screen.dart';
import 'premium_screen.dart';

/// 設定タブ（#12, #24, #27, #37, #64）。
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final settings = repo.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.workspace_premium, color: AppColors.primary),
            title: Text(settings.isPremium ? 'プレミアム利用中' : '無料版'),
            subtitle: Text(settings.subscriptionState.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumScreen())),
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('通知'),
            subtitle: const Text('解約確認・特典申請・返却時期などのお知らせ（#36, #37）'),
            value: settings.notificationsEnabled,
            onChanged: (v) async {
              if (v) await NotificationService.instance.requestPermission();
              await repo.setNotificationsEnabled(v);
            },
          ),
          ListTile(
            leading: const Icon(Icons.family_restroom_outlined),
            title: const Text('家族管理'),
            subtitle: Text(settings.isPremium ? '${repo.familyMembers.length}人登録済み' : 'プレミアム限定機能'),
            trailing: settings.isPremium ? const Icon(Icons.chevron_right) : const Icon(Icons.lock_outline),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => settings.isPremium ? const FamilyScreen() : const PremiumScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.event_available_outlined),
            title: const Text('Googleカレンダー連携'),
            subtitle: Text(
              !settings.isPremium
                  ? 'プレミアム限定機能'
                  : settings.googleCalendarConnected
                      ? '連携中'
                      : '未連携',
            ),
            trailing: settings.isPremium ? const Icon(Icons.chevron_right) : const Icon(Icons.lock_outline),
            onTap: () {
              if (!settings.isPremium) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumScreen()));
                return;
              }
              _showGoogleCalendarSheet(context, repo);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('このアプリについて', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
          ),
          const ListTile(leading: Icon(Icons.info_outline), title: Text('あとでやること'), subtitle: Text('スマホ契約後のお金と予定を、忘れない。')),
          const ListTile(leading: Icon(Icons.privacy_tip_outlined), title: Text('プライバシーポリシー')),
          const ListTile(leading: Icon(Icons.description_outlined), title: Text('利用規約')),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: AppColors.danger),
            title: const Text('アカウントを削除', style: TextStyle(color: AppColors.danger)),
            subtitle: const Text('契約・端末・オプション・特典・タスクなど、すべてのデータを削除します（#64）'),
            onTap: () => _confirmDeleteAccount(context, repo),
          ),
        ],
      ),
    );
  }

  void _showGoogleCalendarSheet(BuildContext context, AppRepository repo) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Googleカレンダー連携', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              '解約確認・特典申請・返却確認などの予定が追加/変更/削除されたタイミングでのみ同期します。'
              '常時同期は行わないため、通信量やサーバー負荷を抑えられます（#28）。\n'
              'Googleアカウントのパスワードは保存されません。',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            if (repo.settings.googleCalendarConnected)
              ElevatedButton(
                onPressed: () async {
                  await repo.setGoogleCalendarConnected(false);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                child: const Text('連携を解除する'),
              )
            else
              ElevatedButton(
                onPressed: () async {
                  // TODO: GoogleCalendarService.instance.connect() を呼び出し、
                  // 成功したらカレンダーIDを保存する。
                  await repo.setGoogleCalendarConnected(true, calendarId: 'primary');
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                child: const Text('Googleアカウントで連携する'),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, AppRepository repo) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('アカウントを削除しますか？'),
        content: const Text('この操作は取り消せません。契約・端末・オプション・特典・タスクなど、すべてのデータが削除されます。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('キャンセル')),
          TextButton(
            onPressed: () async {
              await repo.deleteAllData();
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            },
            child: const Text('削除する', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
