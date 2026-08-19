import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../theme/app_theme.dart';
import '../contracts/benefit_form_screen.dart';
import '../contracts/contract_detail_screen.dart';
import '../contracts/option_form_screen.dart';
import '../devices/device_form_screen.dart';

/// 初回登録ウィザード（#44）：STEP1〜6。
class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final _pageController = PageController();
  int _step = 0;

  ContractType _type = ContractType.smartphone;
  Carrier _carrier = Carrier.docomo;
  DateTime _contractDate = DateTime.now();
  bool? _hasOptions;
  bool? _hasBenefits;
  bool? _hasDeviceReturn;

  static const _totalSteps = 6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('契約の登録 (${_step + 1}/$_totalSteps)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == 0) {
              Navigator.of(context).pop();
            } else {
              _goTo(_step - 1);
            }
          },
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _StepScaffold(
            question: '何を契約しましたか？',
            child: Wrap(
              spacing: 12,
              children: [
                for (final t in [ContractType.smartphone, ContractType.internet, ContractType.other])
                  ChoiceChip(
                    label: Text(t.label),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            onNext: () => _goTo(1),
          ),
          _StepScaffold(
            question: 'どこの会社ですか？',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final c in Carrier.values)
                  ChoiceChip(
                    label: Text(c.label),
                    selected: _carrier == c,
                    onSelected: (_) => setState(() => _carrier = c),
                  ),
              ],
            ),
            onNext: () => _goTo(2),
          ),
          _StepScaffold(
            question: '契約日は？',
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text('${_contractDate.year}年${_contractDate.month}月${_contractDate.day}日'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _contractDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _contractDate = picked);
              },
            ),
            onNext: () => _goTo(3),
          ),
          _YesNoStep(
            question: 'オプションはありますか？',
            description: '解約し忘れると損をしやすい、無料期間付きのオプションを登録できます。',
            value: _hasOptions,
            onChanged: (v) => setState(() => _hasOptions = v),
            onNext: () => _goTo(4),
          ),
          _YesNoStep(
            question: '特典はありますか？',
            description: 'キャッシュバックやポイントなど、申請・受取が必要な特典を登録できます。',
            value: _hasBenefits,
            onChanged: (v) => setState(() => _hasBenefits = v),
            onNext: () => _goTo(5),
          ),
          _YesNoStep(
            question: 'スマホの返却予定はありますか？',
            description: '返却プログラムを利用している場合、返却確認の時期をお知らせします。',
            value: _hasDeviceReturn,
            onChanged: (v) => setState(() => _hasDeviceReturn = v),
            onNext: _finish,
            isLast: true,
          ),
        ],
      ),
    );
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(step, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Future<void> _finish() async {
    final repo = context.read<AppRepository>();
    final contract = await repo.addContract(
      familyMemberId: repo.defaultFamilyMemberId,
      type: _type,
      carrier: _carrier,
      contractDate: _contractDate,
    );
    await repo.completeOnboarding();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ContractDetailScreen(contractId: contract.id)),
    );

    if (_hasOptions == true) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OptionFormScreen(contractId: contract.id)),
      );
    }
    if (_hasBenefits == true) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BenefitFormScreen(contractId: contract.id)),
      );
    }
    if (_hasDeviceReturn == true) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DeviceFormScreen(contractId: contract.id)),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.question, required this.child, required this.onNext});

  final String question;
  final Widget child;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          child,
          const Spacer(),
          ElevatedButton(onPressed: onNext, child: const Text('次へ')),
        ],
      ),
    );
  }
}

class _YesNoStep extends StatelessWidget {
  const _YesNoStep({
    required this.question,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.onNext,
    this.isLast = false,
  });

  final String question;
  final String description;
  final bool? value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onNext;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: value == true ? AppColors.primary.withValues(alpha: 0.1) : null,
                  ),
                  onPressed: () => onChanged(true),
                  child: const Text('ある'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: value == false ? AppColors.primary.withValues(alpha: 0.1) : null,
                  ),
                  onPressed: () => onChanged(false),
                  child: const Text('ない'),
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: value == null ? null : onNext,
            child: Text(isLast ? '登録完了' : '次へ'),
          ),
        ],
      ),
    );
  }
}
