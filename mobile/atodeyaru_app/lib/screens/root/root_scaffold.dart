import 'package:flutter/material.dart';

import '../calendar/calendar_screen.dart';
import '../contracts/contracts_tab.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';

/// 下部ナビゲーション5項目（#12）：ホーム・契約・カレンダー・履歴・設定。
/// iOS/Android両方で自然に操作できるよう、標準のNavigationBarを使用する（#53）。
class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    ContractsTab(),
    CalendarScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'ホーム'),
          NavigationDestination(
              icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: '契約'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'カレンダー'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: '履歴'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }
}
