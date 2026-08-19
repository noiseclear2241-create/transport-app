import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_repository.dart';
import '../devices/devices_list_screen.dart';
import 'contracts_list_screen.dart';

/// 下部ナビゲーションの「契約」タブ（#12）。
/// 契約とスマートフォン端末（返却時期管理 #19〜#23）を切り替えて表示する。
class ContractsTab extends StatefulWidget {
  const ContractsTab({super.key});

  @override
  State<ContractsTab> createState() => _ContractsTabState();
}

class _ContractsTabState extends State<ContractsTab> with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final isContractsTab = _controller.index == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('契約'),
        bottom: TabBar(controller: _controller, tabs: const [Tab(text: '契約'), Tab(text: '端末')]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => isContractsTab
            ? ContractsListView.onAddPressed(context, repo)
            : DevicesListView.onAddPressed(context, repo),
        icon: const Icon(Icons.add),
        label: Text(isContractsTab ? '契約を追加' : '端末を登録'),
      ),
      body: TabBarView(
        controller: _controller,
        children: const [ContractsListView(), DevicesListView()],
      ),
    );
  }
}
