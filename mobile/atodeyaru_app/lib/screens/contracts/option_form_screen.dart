import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../services/date_calculator.dart';
import '../../theme/app_theme.dart';

/// オプション登録・編集（#14, #15, #16, #42）。
class OptionFormScreen extends StatefulWidget {
  const OptionFormScreen({super.key, required this.contractId, this.existing});

  final String contractId;
  final ContractOption? existing;

  @override
  State<OptionFormScreen> createState() => _OptionFormScreenState();
}

class _OptionFormScreenState extends State<OptionFormScreen> {
  final _nameController = TextEditingController();
  final _feeController = TextEditingController();
  final _customMonthsController = TextEditingController();
  final _memoController = TextEditingController();
  DateTime _startDate = DateTime.now();
  PeriodPreset _freePeriod = PeriodPreset.m2;
  DateTime? _manualCancellationDate;
  late Set<int> _notifyDays;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController.text = e?.name ?? '';
    _feeController.text = e?.monthlyFeeYen?.toString() ?? '';
    _memoController.text = e?.memo ?? '';
    _startDate = e?.startDate ?? DateTime.now();
    _freePeriod = e?.freePeriod ?? PeriodPreset.m2;
    _customMonthsController.text = e?.freePeriodCustomMonths?.toString() ?? '';
    _manualCancellationDate = e?.cancellationCheckDate;
    _notifyDays = (e?.notifyDaysBefore ?? defaultCancellationNotifyDaysBefore).toSet();
  }

  DateTime? get _autoDate => DateCalculator.calculateFreePeriodEndDate(
        startDate: _startDate,
        freePeriod: _freePeriod,
        customMonths: int.tryParse(_customMonthsController.text),
      );

  @override
  Widget build(BuildContext context) {
    final auto = _autoDate;
    final displayDate = _manualCancellationDate ?? auto;

    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'オプションを追加' : 'オプションを編集')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'オプション名'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _feeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '月額料金（任意・円）'),
          ),
          const SizedBox(height: 20),
          const Text('契約開始日', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text('${_startDate.year}年${_startDate.month}月${_startDate.day}日'),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _startDate = picked);
            },
          ),
          const SizedBox(height: 20),
          const Text('無料期間', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in PeriodPreset.values)
                ChoiceChip(
                  label: Text(p.label),
                  selected: _freePeriod == p,
                  onSelected: (_) => setState(() {
                    _freePeriod = p;
                    _manualCancellationDate = null;
                  }),
                ),
            ],
          ),
          if (_freePeriod == PeriodPreset.custom) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customMonthsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'カスタム月数'),
              onChanged: (_) => setState(() {}),
            ),
          ],
          if (_freePeriod == PeriodPreset.unknown) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '契約書や契約時のメールを確認してみましょう。（#42）\n'
                'わかったら日付を直接指定することもできます。',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.edit_calendar_outlined),
              label: Text(_manualCancellationDate == null
                  ? '解約確認日を直接指定する'
                  : '解約確認日: ${_manualCancellationDate!.year}/${_manualCancellationDate!.month}/${_manualCancellationDate!.day}'),
              onPressed: _pickManualDate,
            ),
          ],
          const SizedBox(height: 16),
          if (displayDate != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('解約確認日（自動計算）', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${displayDate.year}年${displayDate.month}月${displayDate.day}日',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  TextButton(onPressed: _pickManualDate, child: const Text('日付を修正する')),
                ],
              ),
            ),
          const SizedBox(height: 20),
          const Text('通知タイミング', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final d in defaultCancellationNotifyDaysBefore)
                FilterChip(
                  label: Text(d == 0 ? '当日' : '$d日前'),
                  selected: _notifyDays.contains(d),
                  onSelected: (v) => setState(() => v ? _notifyDays.add(d) : _notifyDays.remove(d)),
                ),
            ],
          ),
          const SizedBox(height: 20),
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

  Future<void> _pickManualDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _manualCancellationDate ?? _autoDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _manualCancellationDate = picked);
  }

  Future<void> _save() async {
    final repo = context.read<AppRepository>();
    await repo.upsertOption(
      contractId: widget.contractId,
      id: widget.existing?.id,
      name: _nameController.text.trim().isEmpty ? 'オプション' : _nameController.text.trim(),
      monthlyFeeYen: int.tryParse(_feeController.text.trim()),
      startDate: _startDate,
      freePeriod: _freePeriod,
      freePeriodCustomMonths: int.tryParse(_customMonthsController.text.trim()),
      manualCancellationCheckDate: _manualCancellationDate,
      memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
      notifyDaysBefore: _notifyDays.toList()..sort((a, b) => b.compareTo(a)),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _feeController.dispose();
    _customMonthsController.dispose();
    _memoController.dispose();
    super.dispose();
  }
}
