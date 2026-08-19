import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../theme/app_theme.dart';

const _relationOptions = ['本人', '配偶者', '子供', '両親', 'その他'];

/// 家族管理（プレミアム限定、#24）。
/// 家族を追加すると、契約・端末の登録時にメンバーを選べるようになる。
/// 同姓同名の家族を区別できるよう、電話番号を任意で登録・編集できる。
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('家族管理')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditSheet(context, repo, existing: null),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('家族を追加'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          for (final m in repo.familyMembers) _FamilyMemberTile(member: m),
        ],
      ),
    );
  }

  static void _openEditSheet(BuildContext context, AppRepository repo, {required FamilyMember? existing}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: _FamilyMemberEditSheet(existing: existing),
      ),
    );
  }
}

class _FamilyMemberTile extends StatelessWidget {
  const _FamilyMemberTile({required this.member});
  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppRepository>();
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(member.name),
        subtitle: Text([
          if (member.relation != null) member.relation!,
          if (member.phoneNumber != null && member.phoneNumber!.isNotEmpty) member.phoneNumber!,
        ].join(' ・ ')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => FamilyScreen._openEditSheet(context, repo, existing: member),
      ),
    );
  }
}

class _FamilyMemberEditSheet extends StatefulWidget {
  const _FamilyMemberEditSheet({required this.existing});
  final FamilyMember? existing;

  @override
  State<_FamilyMemberEditSheet> createState() => _FamilyMemberEditSheetState();
}

class _FamilyMemberEditSheetState extends State<_FamilyMemberEditSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _relation;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController.text = e?.name ?? '';
    _phoneController.text = e?.phoneNumber ?? '';
    _relation = e?.relation;
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppRepository>();
    final isEdit = widget.existing != null;
    // 最後の1人（自分）は削除できない。
    final canDelete = isEdit && repo.familyMembers.length > 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? '家族を編集' : '家族を追加', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '名前（例: 妻、長男）'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: '電話番号（任意）',
                helperText: '同姓同名の家族を区別するための項目です',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final r in _relationOptions)
                  ChoiceChip(
                    label: Text(r),
                    selected: _relation == r,
                    onSelected: (_) => setState(() => _relation = r),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                if (name.isEmpty) return;
                final phone = _phoneController.text.trim();
                if (widget.existing == null) {
                  await repo.addFamilyMember(name, _relation, phoneNumber: phone.isEmpty ? null : phone);
                } else {
                  await repo.updateFamilyMember(widget.existing!.copyWith(
                    name: name,
                    relation: _relation,
                    phoneNumber: phone.isEmpty ? null : phone,
                  ));
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
            if (canDelete) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  await repo.deleteFamilyMember(widget.existing!.id);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('この家族を削除する', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
