import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_repository.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../root/root_scaffold.dart';
import 'setup_wizard_screen.dart';

/// 初回起動画面（#43）。
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.event_available, size: 72, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                '契約後の「忘れちゃった」をなくそう。',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'オプションの解約日、キャッシュバックの申請日、\nスマホの返却時期をお知らせします。',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  await NotificationService.instance.requestPermission();
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SetupWizardScreen()),
                  );
                },
                child: const Text('契約を登録する'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await context.read<AppRepository>().completeOnboarding();
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const RootScaffold()),
                  );
                },
                child: const Text('あとで登録する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
