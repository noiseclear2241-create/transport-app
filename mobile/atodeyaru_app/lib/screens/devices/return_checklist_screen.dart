import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../theme/app_theme.dart';

/// 返却前チェックリスト（#22）。
/// 契約先によって必要な作業が異なるため、断定はせず案内文を必ず表示する。
class ReturnChecklistScreen extends StatefulWidget {
  const ReturnChecklistScreen({super.key, required this.device});

  final Device device;

  @override
  State<ReturnChecklistScreen> createState() => _ReturnChecklistScreenState();
}

class _ReturnChecklistScreenState extends State<ReturnChecklistScreen> {
  late Future<List<ChecklistItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AppRepository>().getChecklistItems(widget.device.id);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppRepository>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.device.name} 返却前チェック')),
      body: FutureBuilder<List<ChecklistItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  '契約先によって必要な作業が異なります。返却方法の詳細は、契約先（キャリア）の案内を確認してください。',
                ),
              ),
              const SizedBox(height: 12),
              for (final item in items)
                CheckboxListTile(
                  value: item.checked,
                  title: Text(item.label),
                  onChanged: (_) async {
                    await repo.toggleChecklistItem(item);
                    setState(() {
                      _future = repo.getChecklistItems(widget.device.id);
                    });
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
