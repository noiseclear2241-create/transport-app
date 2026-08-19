import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/app_repository.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();

  final repo = AppRepository();
  unawaited(repo.load());

  runApp(
    ChangeNotifierProvider.value(
      value: repo,
      child: const AtodeyaruApp(),
    ),
  );
}
