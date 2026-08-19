import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../widgets/section_header.dart';
import '../settings/premium_screen.dart';
import 'contract_detail_screen.dart';
import 'contract_form_screen.dart';

/// 契約一覧の中身（#12, #13）。無料版は契約1件まで（#23, #29）。
/// FAB/AppBarは呼び出し側（ContractsTab）が持つため、本体のみのウィジェット。
class ContractsListView extends StatelessWidget {
  const ContractsListView({super.key});

  static void onAddPressed(BuildContext context, AppRepository repo) {
    if (!repo.canAddContract) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumScreen()));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContractFormScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();

    return repo.contracts.isEmpty
        ? const _EmptyContracts()
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              if (!repo.settings.isPremium) const SectionHeader(title: '契約（無料版：1件まで）'),
              for (final c in repo.contracts) _ContractTile(contract: c),
            ],
          );
  }
}

class _EmptyContracts extends StatelessWidget {
  const _EmptyContracts();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'まだ契約が登録されていません。\n右下の「契約を追加」から登録しましょう。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractTile extends StatelessWidget {
  const _ContractTile({required this.contract});
  final Contract contract;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppRepository>();
    final optionCount = repo.optionsByContract[contract.id]?.length ?? 0;
    final benefitCount = repo.benefitsByContract[contract.id]?.length ?? 0;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text('${contract.carrierLabel} ${contract.type.label}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '契約日: ${contract.contractDate.year}/${contract.contractDate.month}/${contract.contractDate.day}'
            '　オプション$optionCount件　特典$benefitCount件',
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ContractDetailScreen(contractId: contract.id)),
        ),
      ),
    );
  }
}
