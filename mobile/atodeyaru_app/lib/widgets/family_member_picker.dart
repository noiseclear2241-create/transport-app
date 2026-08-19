import 'package:flutter/material.dart';

import '../models/models.dart';

/// 家族が複数登録されている場合にのみ表示する選択UI（#24）。
/// 電話番号を登録しておくと、同姓同名の家族でも区別しやすくなる。
class FamilyMemberPicker extends StatelessWidget {
  const FamilyMemberPicker({
    super.key,
    required this.members,
    required this.selectedId,
    required this.onChanged,
  });

  final List<FamilyMember> members;
  final String selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (members.length <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('誰の契約・端末ですか？', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: members.any((m) => m.id == selectedId) ? selectedId : members.first.id,
            items: [
              for (final m in members)
                DropdownMenuItem(
                  value: m.id,
                  child: Text(_label(m)),
                ),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  String _label(FamilyMember m) {
    final relation = m.relation;
    final phone = m.phoneNumber;
    final parts = <String>[m.name];
    if (relation != null && relation.isNotEmpty) parts.add('($relation)');
    if (phone != null && phone.isNotEmpty) parts.add(phone);
    return parts.join(' ');
  }
}
