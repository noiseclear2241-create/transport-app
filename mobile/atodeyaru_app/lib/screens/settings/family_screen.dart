import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_repository.dart';

/// 家族管理（プレミアム限定、#24）。
/// 家族を追加すると、契約・端末の登録時にメンバーを選べるようになる。
class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _nameController = TextEditingController();
  String? _relation;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('家族管理')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final m in repo.familyMembers)
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(m.name),
                subtitle: m.relation == null ? null : Text(m.relation!),
              ),
            ),
          const SizedBox(height: 24),
          const Text('家族を追加', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: '名前（例: 妻、長男）'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final r in ['本人', '配偶者', '子供', '両親', 'その他'])
                ChoiceChip(
                  label: Text(r),
                  selected: _relation == r,
                  onSelected: (_) => setState(() => _relation = r),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.trim().isEmpty) return;
              await repo.addFamilyMember(_nameController.text.trim(), _relation);
              _nameController.clear();
              setState(() => _relation = null);
            },
            child: const Text('追加する'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
