import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../services/date_calculator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/family_member_picker.dart';

/// 端末登録・編集（#19, #20）。
/// 返却条件は会社・プログラムにより異なるため、断定的な表現を避け
/// 「返却確認日」「返却目安」という表現に統一する。
class DeviceFormScreen extends StatefulWidget {
  const DeviceFormScreen({super.key, this.existing, this.contractId});

  final Device? existing;
  final String? contractId;

  @override
  State<DeviceFormScreen> createState() => _DeviceFormScreenState();
}

class _DeviceFormScreenState extends State<DeviceFormScreen> {
  final _nameController = TextEditingController();
  final _makerController = TextEditingController();
  final _priceController = TextEditingController();
  final _installmentCountController = TextEditingController();
  final _monthlyPaymentController = TextEditingController();
  final _returnProgramController = TextEditingController();
  final _customMonthsController = TextEditingController();
  final _memoController = TextEditingController();
  DateTime? _purchaseDate;
  DateTime _useStartDate = DateTime.now();
  DevicePurchaseMethod _purchaseMethod = DevicePurchaseMethod.installment;
  ReturnPeriodPreset _returnPeriod = ReturnPeriodPreset.unknown;
  DateTime? _manualReturnCheckDate;
  late String _familyMemberId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _familyMemberId = e?.familyMemberId ?? context.read<AppRepository>().defaultFamilyMemberId;
    _nameController.text = e?.name ?? '';
    _makerController.text = e?.maker ?? '';
    _priceController.text = e?.priceYen?.toString() ?? '';
    _installmentCountController.text = e?.installmentCount?.toString() ?? '';
    _monthlyPaymentController.text = e?.monthlyPaymentYen?.toString() ?? '';
    _returnProgramController.text = e?.returnProgramName ?? '';
    _memoController.text = e?.memo ?? '';
    _purchaseDate = e?.purchaseDate;
    _useStartDate = e?.useStartDate ?? DateTime.now();
    _purchaseMethod = e?.purchaseMethod ?? DevicePurchaseMethod.installment;
    _returnPeriod = e?.returnPeriod ?? ReturnPeriodPreset.unknown;
    _customMonthsController.text = e?.returnPeriodCustomMonths?.toString() ?? '';
    _manualReturnCheckDate = e?.returnCheckDate;
  }

  DateTime? get _autoDate => DateCalculator.calculateReturnCheckDate(
        baseDate: _useStartDate,
        returnPeriod: _returnPeriod,
        customMonths: int.tryParse(_customMonthsController.text),
      );

  @override
  Widget build(BuildContext context) {
    final displayDate = _manualReturnCheckDate ?? _autoDate;
    final repo = context.watch<AppRepository>();
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? '端末を登録' : '端末を編集')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FamilyMemberPicker(
            members: repo.familyMembers,
            selectedId: _familyMemberId,
            onChanged: (id) => setState(() => _familyMemberId = id),
          ),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: '端末名（例: iPhone 16）')),
          const SizedBox(height: 12),
          TextField(controller: _makerController, decoration: const InputDecoration(labelText: 'メーカー')),
          const SizedBox(height: 16),
          _DateRow(
            label: '利用開始日',
            date: _useStartDate,
            onPick: (d) => setState(() => _useStartDate = d),
          ),
          _DateRowNullable(
            label: '購入日',
            date: _purchaseDate,
            onPick: (d) => setState(() => _purchaseDate = d),
          ),
          const SizedBox(height: 12),
          const Text('購入方法', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final m in DevicePurchaseMethod.values)
                ChoiceChip(
                  label: Text(m.label),
                  selected: _purchaseMethod == m,
                  onSelected: (_) => setState(() => _purchaseMethod = m),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '端末代金（任意・円）'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _installmentCountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '支払回数（任意）'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _monthlyPaymentController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '月々の支払額（任意・円）'),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _returnProgramController,
            decoration: const InputDecoration(labelText: '返却プログラム名（任意）'),
          ),
          const SizedBox(height: 16),
          const Text('返却時期の目安', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in ReturnPeriodPreset.values)
                ChoiceChip(
                  label: Text(r.label),
                  selected: _returnPeriod == r,
                  onSelected: (_) => setState(() {
                    _returnPeriod = r;
                    _manualReturnCheckDate = null;
                  }),
                ),
            ],
          ),
          if (_returnPeriod == ReturnPeriodPreset.custom) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customMonthsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'カスタム月数'),
              onChanged: (_) => setState(() {}),
            ),
          ],
          if (_returnPeriod == ReturnPeriodPreset.unknown) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('契約先の案内を確認してください。（#22）返却条件は会社・プログラムにより異なります。'),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.edit_calendar_outlined),
            label: Text(_manualReturnCheckDate == null ? '返却確認日を直接指定する' : '直接指定: ${_fmt(_manualReturnCheckDate!)}'),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _manualReturnCheckDate ?? _autoDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _manualReturnCheckDate = picked);
            },
          ),
          if (displayDate != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('返却確認日（目安）', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(_fmt(displayDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          TextField(controller: _memoController, maxLines: 3, decoration: const InputDecoration(labelText: 'メモ')),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.year}年${d.month}月${d.day}日';

  Future<void> _save() async {
    final repo = context.read<AppRepository>();
    if (widget.existing == null && !repo.canAddDevice) {
      Navigator.of(context).pop();
      return;
    }
    await repo.upsertDevice(
      id: widget.existing?.id,
      familyMemberId: _familyMemberId,
      contractId: widget.contractId ?? widget.existing?.contractId,
      name: _nameController.text.trim().isEmpty ? '端末' : _nameController.text.trim(),
      maker: _makerController.text.trim().isEmpty ? null : _makerController.text.trim(),
      purchaseDate: _purchaseDate,
      useStartDate: _useStartDate,
      purchaseMethod: _purchaseMethod,
      priceYen: int.tryParse(_priceController.text.trim()),
      installmentCount: int.tryParse(_installmentCountController.text.trim()),
      monthlyPaymentYen: int.tryParse(_monthlyPaymentController.text.trim()),
      returnProgramName:
          _returnProgramController.text.trim().isEmpty ? null : _returnProgramController.text.trim(),
      returnPeriod: _returnPeriod,
      returnPeriodCustomMonths: int.tryParse(_customMonthsController.text.trim()),
      manualReturnCheckDate: _manualReturnCheckDate,
      memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _makerController.dispose();
    _priceController.dispose();
    _installmentCountController.dispose();
    _monthlyPaymentController.dispose();
    _returnProgramController.dispose();
    _customMonthsController.dispose();
    _memoController.dispose();
    super.dispose();
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.date, required this.onPick});
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) onPick(picked);
            },
            child: Text('${date.year}/${date.month}/${date.day}'),
          ),
        ],
      ),
    );
  }
}

class _DateRowNullable extends StatelessWidget {
  const _DateRowNullable({required this.label, required this.date, required this.onPick});
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
        ],
      ),
    );
  }
}
