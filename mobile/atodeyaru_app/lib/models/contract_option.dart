import 'enums.dart';

/// デフォルトの解約確認通知タイミング（#16）：30/14/7/3/1/0日前。
const List<int> defaultCancellationNotifyDaysBefore = [30, 14, 7, 3, 1, 0];

/// 契約に紐づくオプション（#14）。
class ContractOption {
  final String id;
  final String contractId;
  final String name;
  final int? monthlyFeeYen;
  final DateTime startDate;
  final PeriodPreset freePeriod;
  final int? freePeriodCustomMonths; // freePeriod == custom のとき使用
  final DateTime? cancellationCheckDate; // 自動計算 or 手動上書き
  final String? memo;
  final List<int> notifyDaysBefore; // 解約確認日の何日前に通知するか
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContractOption({
    required this.id,
    required this.contractId,
    required this.name,
    this.monthlyFeeYen,
    required this.startDate,
    required this.freePeriod,
    this.freePeriodCustomMonths,
    this.cancellationCheckDate,
    this.memo,
    this.notifyDaysBefore = defaultCancellationNotifyDaysBefore,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'contract_id': contractId,
        'name': name,
        'monthly_fee_yen': monthlyFeeYen,
        'start_date': startDate.toIso8601String(),
        'free_period': freePeriod.value,
        'free_period_custom_months': freePeriodCustomMonths,
        'cancellation_check_date': cancellationCheckDate?.toIso8601String(),
        'memo': memo,
        'notify_days_before': notifyDaysBefore.join(','),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory ContractOption.fromMap(Map<String, Object?> map) => ContractOption(
        id: map['id']! as String,
        contractId: map['contract_id']! as String,
        name: map['name']! as String,
        monthlyFeeYen: map['monthly_fee_yen'] as int?,
        startDate: DateTime.parse(map['start_date']! as String),
        freePeriod: PeriodPreset.fromValue(map['free_period']! as String),
        freePeriodCustomMonths: map['free_period_custom_months'] as int?,
        cancellationCheckDate: map['cancellation_check_date'] == null
            ? null
            : DateTime.parse(map['cancellation_check_date']! as String),
        memo: map['memo'] as String?,
        notifyDaysBefore: (map['notify_days_before'] as String?)
                ?.split(',')
                .where((s) => s.isNotEmpty)
                .map(int.parse)
                .toList() ??
            defaultCancellationNotifyDaysBefore,
        createdAt: DateTime.parse(map['created_at']! as String),
        updatedAt: DateTime.parse(map['updated_at']! as String),
      );

  ContractOption copyWith({
    String? name,
    int? monthlyFeeYen,
    DateTime? startDate,
    PeriodPreset? freePeriod,
    int? freePeriodCustomMonths,
    DateTime? cancellationCheckDate,
    String? memo,
    List<int>? notifyDaysBefore,
  }) =>
      ContractOption(
        id: id,
        contractId: contractId,
        name: name ?? this.name,
        monthlyFeeYen: monthlyFeeYen ?? this.monthlyFeeYen,
        startDate: startDate ?? this.startDate,
        freePeriod: freePeriod ?? this.freePeriod,
        freePeriodCustomMonths: freePeriodCustomMonths ?? this.freePeriodCustomMonths,
        cancellationCheckDate: cancellationCheckDate ?? this.cancellationCheckDate,
        memo: memo ?? this.memo,
        notifyDaysBefore: notifyDaysBefore ?? this.notifyDaysBefore,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
