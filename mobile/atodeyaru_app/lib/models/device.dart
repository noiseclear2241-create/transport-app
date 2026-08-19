import 'enums.dart';

/// 返却前通知のデフォルト（#21）：90/60/30/14/7/3/1日前。
const List<int> defaultReturnNotifyDaysBefore = [90, 60, 30, 14, 7, 3, 1];

/// スマートフォン等の端末情報（#19, #20）。
/// 返却条件は会社・プログラムによって異なるため、アプリ側では断定せず
/// 「返却確認日」「返却目安」という表現に統一する（#20）。
class Device {
  final String id;
  final String familyMemberId;
  final String? contractId;
  final String name;
  final String? maker;
  final DateTime? purchaseDate;
  final DateTime? useStartDate;
  final DevicePurchaseMethod purchaseMethod;
  final int? priceYen;
  final int? installmentCount;
  final int? monthlyPaymentYen;
  final String? returnProgramName;
  final ReturnPeriodPreset returnPeriod;
  final int? returnPeriodCustomMonths;
  final DateTime? returnCheckDate; // 返却確認日（自動計算 or 手動上書き）
  final DateTime? returnDeadline; // 返却期限（分かる場合のみ）
  final String? memo;
  final List<int> notifyDaysBefore;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Device({
    required this.id,
    required this.familyMemberId,
    this.contractId,
    required this.name,
    this.maker,
    this.purchaseDate,
    this.useStartDate,
    required this.purchaseMethod,
    this.priceYen,
    this.installmentCount,
    this.monthlyPaymentYen,
    this.returnProgramName,
    required this.returnPeriod,
    this.returnPeriodCustomMonths,
    this.returnCheckDate,
    this.returnDeadline,
    this.memo,
    this.notifyDaysBefore = defaultReturnNotifyDaysBefore,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasReturnProgram => returnPeriod != ReturnPeriodPreset.unknown || returnCheckDate != null;

  Map<String, Object?> toMap() => {
        'id': id,
        'family_member_id': familyMemberId,
        'contract_id': contractId,
        'name': name,
        'maker': maker,
        'purchase_date': purchaseDate?.toIso8601String(),
        'use_start_date': useStartDate?.toIso8601String(),
        'purchase_method': purchaseMethod.value,
        'price_yen': priceYen,
        'installment_count': installmentCount,
        'monthly_payment_yen': monthlyPaymentYen,
        'return_program_name': returnProgramName,
        'return_period': returnPeriod.value,
        'return_period_custom_months': returnPeriodCustomMonths,
        'return_check_date': returnCheckDate?.toIso8601String(),
        'return_deadline': returnDeadline?.toIso8601String(),
        'memo': memo,
        'notify_days_before': notifyDaysBefore.join(','),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Device.fromMap(Map<String, Object?> map) => Device(
        id: map['id']! as String,
        familyMemberId: map['family_member_id']! as String,
        contractId: map['contract_id'] as String?,
        name: map['name']! as String,
        maker: map['maker'] as String?,
        purchaseDate:
            map['purchase_date'] == null ? null : DateTime.parse(map['purchase_date']! as String),
        useStartDate: map['use_start_date'] == null
            ? null
            : DateTime.parse(map['use_start_date']! as String),
        purchaseMethod: DevicePurchaseMethod.fromValue(map['purchase_method']! as String),
        priceYen: map['price_yen'] as int?,
        installmentCount: map['installment_count'] as int?,
        monthlyPaymentYen: map['monthly_payment_yen'] as int?,
        returnProgramName: map['return_program_name'] as String?,
        returnPeriod: ReturnPeriodPreset.fromValue(map['return_period']! as String),
        returnPeriodCustomMonths: map['return_period_custom_months'] as int?,
        returnCheckDate: map['return_check_date'] == null
            ? null
            : DateTime.parse(map['return_check_date']! as String),
        returnDeadline: map['return_deadline'] == null
            ? null
            : DateTime.parse(map['return_deadline']! as String),
        memo: map['memo'] as String?,
        notifyDaysBefore: (map['notify_days_before'] as String?)
                ?.split(',')
                .where((s) => s.isNotEmpty)
                .map(int.parse)
                .toList() ??
            defaultReturnNotifyDaysBefore,
        createdAt: DateTime.parse(map['created_at']! as String),
        updatedAt: DateTime.parse(map['updated_at']! as String),
      );

  Device copyWith({
    String? name,
    String? maker,
    DateTime? purchaseDate,
    DateTime? useStartDate,
    DevicePurchaseMethod? purchaseMethod,
    int? priceYen,
    int? installmentCount,
    int? monthlyPaymentYen,
    String? returnProgramName,
    ReturnPeriodPreset? returnPeriod,
    int? returnPeriodCustomMonths,
    DateTime? returnCheckDate,
    DateTime? returnDeadline,
    String? memo,
    List<int>? notifyDaysBefore,
  }) =>
      Device(
        id: id,
        familyMemberId: familyMemberId,
        contractId: contractId,
        name: name ?? this.name,
        maker: maker ?? this.maker,
        purchaseDate: purchaseDate ?? this.purchaseDate,
        useStartDate: useStartDate ?? this.useStartDate,
        purchaseMethod: purchaseMethod ?? this.purchaseMethod,
        priceYen: priceYen ?? this.priceYen,
        installmentCount: installmentCount ?? this.installmentCount,
        monthlyPaymentYen: monthlyPaymentYen ?? this.monthlyPaymentYen,
        returnProgramName: returnProgramName ?? this.returnProgramName,
        returnPeriod: returnPeriod ?? this.returnPeriod,
        returnPeriodCustomMonths: returnPeriodCustomMonths ?? this.returnPeriodCustomMonths,
        returnCheckDate: returnCheckDate ?? this.returnCheckDate,
        returnDeadline: returnDeadline ?? this.returnDeadline,
        memo: memo ?? this.memo,
        notifyDaysBefore: notifyDaysBefore ?? this.notifyDaysBefore,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}

/// 返却前チェックリストの1項目（#22）。
class ChecklistItem {
  final String id;
  final String deviceId;
  final String label;
  final bool checked;
  final int sortOrder;

  const ChecklistItem({
    required this.id,
    required this.deviceId,
    required this.label,
    required this.checked,
    required this.sortOrder,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'device_id': deviceId,
        'label': label,
        'checked': checked ? 1 : 0,
        'sort_order': sortOrder,
      };

  factory ChecklistItem.fromMap(Map<String, Object?> map) => ChecklistItem(
        id: map['id']! as String,
        deviceId: map['device_id']! as String,
        label: map['label']! as String,
        checked: (map['checked'] as int) == 1,
        sortOrder: map['sort_order']! as int,
      );

  ChecklistItem copyWith({bool? checked}) => ChecklistItem(
        id: id,
        deviceId: deviceId,
        label: label,
        checked: checked ?? this.checked,
        sortOrder: sortOrder,
      );
}

/// 返却前チェックリストのデフォルト項目（#22）。
/// 契約先によって必要な作業が異なるため、末尾で案内文を必ず表示する。
const List<String> defaultChecklistLabels = [
  'データをバックアップした',
  '写真・動画を移行した',
  'Apple ID / Googleアカウントを確認した',
  '端末検索機能を確認した',
  '初期化した',
  'SIM / eSIMを確認した',
  '返却方法を確認した',
  '返却した',
];
