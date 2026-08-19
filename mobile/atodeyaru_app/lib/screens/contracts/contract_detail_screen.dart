import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../services/date_calculator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/countdown_badge.dart';
import '../../widgets/section_header.dart';
import 'benefit_form_screen.dart';
import 'contract_form_screen.dart';
import 'option_form_screen.dart';

/// 契約詳細（オプション・特典の一覧と登録、#14, #17, #18）。
class ContractDetailScreen extends StatelessWidget {
  const ContractDetailScreen({super.key, required this.contractId});

  final String contractId;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final contract = repo.contracts.where((c) => c.id == contractId).firstOrNull;
    if (contract == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('契約が見つかりません')));
    }
    final options = repo.optionsByContract[contractId] ?? [];
    final benefits = repo.benefitsByContract[contractId] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('${contract.carrierLabel} ${contract.type.label}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ContractFormScreen(existing: contract)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, repo, contract),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: '契約日', value:
                      '${contract.contractDate.year}年${contract.contractDate.month}月${contract.contractDate.day}日'),
                  if (contract.contractNumber != null)
                    _InfoRow(label: '契約番号', value: contract.contractNumber!),
                  if (contract.monthlyFeeYen != null)
                    _InfoRow(label: '月額料金', value: '${contract.monthlyFeeYen}円'),
                  if (contract.memo != null && contract.memo!.isNotEmpty)
                    _InfoRow(label: 'メモ', value: contract.memo!),
                ],
              ),
            ),
          ),
          SectionHeader(
            title: 'オプション',
            trailing: TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('追加'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => OptionFormScreen(contractId: contractId)),
              ),
            ),
          ),
          if (options.isEmpty) const EmptyState(message: 'オプションはまだ登録されていません。'),
          for (final o in options) _OptionTile(contractId: contractId, option: o),
          SectionHeader(
            title: '特典',
            trailing: TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('追加'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BenefitFormScreen(contractId: contractId)),
              ),
            ),
          ),
          if (benefits.isEmpty) const EmptyState(message: '特典はまだ登録されていません。'),
          for (final b in benefits) _BenefitTile(contractId: contractId, benefit: b),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppRepository repo, Contract contract) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('契約を削除しますか？'),
        content: const Text('この契約に紐づくオプション・特典・やることも削除されます。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('キャンセル')),
          TextButton(
            onPressed: () async {
              await repo.deleteContract(contract.id);
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('削除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 88, child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.contractId, required this.option});
  final String contractId;
  final ContractOption option;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppRepository>();
    final due = option.cancellationCheckDate;
    return Card(
      child: ListTile(
        title: Text(option.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: due == null
            ? const Text('解約確認日が未設定です')
            : Text('解約確認日: ${due.year}/${due.month}/${due.day}'),
        trailing: due == null
            ? null
            : CountdownBadge(
                daysUntil: DateCalculator.daysUntil(due, DateTime.now()),
                color: AppColors.danger,
              ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OptionFormScreen(contractId: contractId, existing: option),
          ),
        ),
        onLongPress: () => _confirmDeleteOption(context, repo),
      ),
    );
  }

  void _confirmDeleteOption(BuildContext context, AppRepository repo) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('「${option.name}」を削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('キャンセル')),
          TextButton(
            onPressed: () {
              repo.deleteOption(contractId, option.id);
              Navigator.pop(dialogContext);
            },
            child: const Text('削除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({required this.contractId, required this.benefit});
  final String contractId;
  final Benefit benefit;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppRepository>();
    return Card(
      child: ListTile(
        title: Text(benefit.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          [
            if (benefit.amountYen != null) '${benefit.amountYen}円',
            benefit.type.label,
            benefit.status.label,
          ].join(' ・ '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BenefitFormScreen(contractId: contractId, existing: benefit),
          ),
        ),
        onLongPress: () => _confirmDeleteBenefit(context, repo),
      ),
    );
  }

  void _confirmDeleteBenefit(BuildContext context, AppRepository repo) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('「${benefit.name}」を削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('キャンセル')),
          TextButton(
            onPressed: () {
              repo.deleteBenefit(contractId, benefit.id);
              Navigator.pop(dialogContext);
            },
            child: const Text('削除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
