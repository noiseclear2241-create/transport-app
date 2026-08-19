import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../widgets/family_member_picker.dart';
import 'contract_detail_screen.dart';

/// 契約登録・編集（#13）。
class ContractFormScreen extends StatefulWidget {
  const ContractFormScreen({super.key, this.existing});

  final Contract? existing;

  @override
  State<ContractFormScreen> createState() => _ContractFormScreenState();
}

class _ContractFormScreenState extends State<ContractFormScreen> {
  late ContractType _type;
  late Carrier _carrier;
  final _carrierOtherController = TextEditingController();
  DateTime _contractDate = DateTime.now();
  final _numberController = TextEditingController();
  final _feeController = TextEditingController();
  final _memoController = TextEditingController();
  late String _familyMemberId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _familyMemberId = e?.familyMemberId ?? context.read<AppRepository>().defaultFamilyMemberId;
    _type = e?.type ?? ContractType.smartphone;
    _carrier = e?.carrier ?? Carrier.docomo;
    _carrierOtherController.text = e?.carrierOther ?? '';
    _contractDate = e?.contractDate ?? DateTime.now();
    _numberController.text = e?.contractNumber ?? '';
    _feeController.text = e?.monthlyFeeYen?.toString() ?? '';
    _memoController.text = e?.memo ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final repo = context.watch<AppRepository>();
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '契約を編集' : '契約を登録')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FamilyMemberPicker(
            members: repo.familyMembers,
            selectedId: _familyMemberId,
            onChanged: (id) => setState(() => _familyMemberId = id),
          ),
          const Text('何を契約しましたか？', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final t in ContractType.values)
                ChoiceChip(
                  label: Text(t.label),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('どこの会社ですか？', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          DropdownButtonFormField<Carrier>(
            initialValue: _carrier,
            items: [
              for (final c in Carrier.values) DropdownMenuItem(value: c, child: Text(c.label)),
            ],
            onChanged: (v) => setState(() => _carrier = v!),
          ),
          if (_carrier == Carrier.other) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _carrierOtherController,
              decoration: const InputDecoration(labelText: '会社名'),
            ),
          ],
          const SizedBox(height: 20),
          const Text('契約日は？', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text('${_contractDate.year}年${_contractDate.month}月${_contractDate.day}日'),
            onPressed: _pickDate,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _numberController,
            decoration: const InputDecoration(labelText: '契約番号（任意）'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _feeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '月額料金（任意・円）'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _memoController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'メモ'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _contractDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _contractDate = picked);
  }

  Future<void> _save() async {
    final repo = context.read<AppRepository>();
    final fee = int.tryParse(_feeController.text.trim());

    if (widget.existing == null) {
      final contract = await repo.addContract(
        familyMemberId: _familyMemberId,
        type: _type,
        carrier: _carrier,
        carrierOther: _carrierOtherController.text.trim().isEmpty ? null : _carrierOtherController.text.trim(),
        contractDate: _contractDate,
        contractNumber: _numberController.text.trim().isEmpty ? null : _numberController.text.trim(),
        monthlyFeeYen: fee,
        memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ContractDetailScreen(contractId: contract.id)),
      );
    } else {
      final updated = widget.existing!.copyWith(
        familyMemberId: _familyMemberId,
        type: _type,
        carrier: _carrier,
        carrierOther: _carrierOtherController.text.trim().isEmpty ? null : _carrierOtherController.text.trim(),
        contractDate: _contractDate,
        contractNumber: _numberController.text.trim().isEmpty ? null : _numberController.text.trim(),
        monthlyFeeYen: fee,
        memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
      );
      await repo.updateContract(updated);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _carrierOtherController.dispose();
    _numberController.dispose();
    _feeController.dispose();
    _memoController.dispose();
    super.dispose();
  }
}
