import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_repository.dart';

/// 特典登録・編集。申請と受取を分離して管理する（#17, #18）。
class BenefitFormScreen extends StatefulWidget {
  const BenefitFormScreen({super.key, required this.contractId, this.existing});

  final String contractId;
  final Benefit? existing;

  @override
  State<BenefitFormScreen> createState() => _BenefitFormScreenState();
}

class _BenefitFormScreenState extends State<BenefitFormScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _conditionController = TextEditingController();
  final _memoController = TextEditingController();
  late BenefitType _type;
  bool _applicationRequired = true;
  DateTime? _applicationStartDate;
  DateTime? _applicationDeadline;
  DateTime? _expectedReceiptDate;
  late BenefitStatus _status;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController.text = e?.name ?? '';
    _amountController.text = e?.amountYen?.toString() ?? '';
    _conditionController.text = e?.condition ?? '';
    _memoController.text = e?.memo ?? '';
    _type = e?.type ?? BenefitType.cashback;
    _applicationRequired = e?.applicationRequired ?? true;
    _applicationStartDate = e?.applicationStartDate;
    _applicationDeadline = e?.applicationDeadline;
    _expectedReceiptDate = e?.expectedReceiptDate;
    _status = e?.status ?? BenefitStatus.notApplied;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? '特典を追加' : '特典を編集')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: '特典名')),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '金額（任意・円）'),
          ),
          const SizedBox(height: 16),
          const Text('特典種類', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in BenefitType.values)
                ChoiceChip(
                  label: Text(t.label),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('申請が必要'),
            value: _applicationRequired,
            onChanged: (v) => setState(() => _applicationRequired = v),
          ),
          if (_applicationRequired) ...[
            _DateField(
              label: '申請開始日',
              date: _applicationStartDate,
              onPick: (d) => setState(() => _applicationStartDate = d),
            ),
            _DateField(
              label: '申請期限',
              date: _applicationDeadline,
              onPick: (d) => setState(() => _applicationDeadline = d),
            ),
          ],
          _DateField(
            label: '受取予定日',
            date: _expectedReceiptDate,
            onPick: (d) => setState(() => _expectedReceiptDate = d),
          ),
          const SizedBox(height: 16),
          const Text('ステータス', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in BenefitStatus.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: _status == s,
                  onSelected: (_) => setState(() => _status = s),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(controller: _conditionController, decoration: const InputDecoration(labelText: '条件')),
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

  Future<void> _save() async {
    final repo = context.read<AppRepository>();
    await repo.upsertBenefit(
      contractId: widget.contractId,
      id: widget.existing?.id,
      name: _nameController.text.trim().isEmpty ? '特典' : _nameController.text.trim(),
      amountYen: int.tryParse(_amountController.text.trim()),
      type: _type,
      applicationRequired: _applicationRequired,
      applicationStartDate: _applicationStartDate,
      applicationDeadline: _applicationDeadline,
      expectedReceiptDate: _expectedReceiptDate,
      condition: _conditionController.text.trim().isEmpty ? null : _conditionController.text.trim(),
      memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
      status: _status,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _conditionController.dispose();
    _memoController.dispose();
    super.dispose();
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.date, required this.onPick});

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              onPick(picked);
            },
            child: Text(date == null ? '未設定' : '${date!.year}/${date!.month}/${date!.day}'),
          ),
          if (date != null)
            IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => onPick(null)),
        ],
      ),
    );
  }
}
