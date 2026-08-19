import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/onboarding/onboarding_screen.dart';
import 'screens/root/root_scaffold.dart';
import 'services/app_repository.dart';
import 'theme/app_theme.dart';

class AtodeyaruApp extends StatelessWidget {
  const AtodeyaruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'あとでやること',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // 日本語ユーザー向けのアプリのため、ロケールは日本語固定のUI文言を使用する。
      home: const _Launcher(),
    );
  }
}

class _Launcher extends StatelessWidget {
  const _Launcher();

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    if (!repo.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return repo.settings.onboardingCompleted ? const RootScaffold() : const OnboardingScreen();
  }
}
