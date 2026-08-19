import 'enums.dart';

/// 契約特典（#17, #18）。申請と受取を分離してステータス管理する。
class Benefit {
  final String id;
  final String contractId;
  final String name;
  final int? amountYen;
  final BenefitType type;
  final bool applicationRequired;
  final DateTime? applicationStartDate;
  final DateTime? applicationDeadline;
  final DateTime? expectedReceiptDate;
  final String? condition;
  final String? memo;
  final BenefitStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Benefit({
    required this.id,
    required this.contractId,
    required this.name,
    this.amountYen,
    required this.type,
    required this.applicationRequired,
    this.applicationStartDate,
    this.applicationDeadline,
    this.expectedReceiptDate,
    this.condition,
    this.memo,
    this.status = BenefitStatus.notApplied,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'contract_id': contractId,
        'name': name,
        'amount_yen': amountYen,
        'type': type.value,
        'application_required': applicationRequired ? 1 : 0,
        'application_start_date': applicationStartDate?.toIso8601String(),
        'application_deadline': applicationDeadline?.toIso8601String(),
        'expected_receipt_date': expectedReceiptDate?.toIso8601String(),
        'condition': condition,
        'memo': memo,
        'status': status.value,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Benefit.fromMap(Map<String, Object?> map) => Benefit(
        id: map['id']! as String,
        contractId: map['contract_id']! as String,
        name: map['name']! as String,
        amountYen: map['amount_yen'] as int?,
        type: BenefitType.fromValue(map['type']! as String),
        applicationRequired: (map['application_required'] as int) == 1,
        applicationStartDate: map['application_start_date'] == null
            ? null
            : DateTime.parse(map['application_start_date']! as String),
        applicationDeadline: map['application_deadline'] == null
            ? null
            : DateTime.parse(map['application_deadline']! as String),
        expectedReceiptDate: map['expected_receipt_date'] == null
            ? null
            : DateTime.parse(map['expected_receipt_date']! as String),
        condition: map['condition'] as String?,
        memo: map['memo'] as String?,
        status: BenefitStatus.fromValue(map['status']! as String),
        createdAt: DateTime.parse(map['created_at']! as String),
        updatedAt: DateTime.parse(map['updated_at']! as String),
      );

  Benefit copyWith({
    String? name,
    int? amountYen,
    BenefitType? type,
    bool? applicationRequired,
    DateTime? applicationStartDate,
    DateTime? applicationDeadline,
    DateTime? expectedReceiptDate,
    String? condition,
    String? memo,
    BenefitStatus? status,
  }) =>
      Benefit(
        id: id,
        contractId: contractId,
        name: name ?? this.name,
        amountYen: amountYen ?? this.amountYen,
        type: type ?? this.type,
        applicationRequired: applicationRequired ?? this.applicationRequired,
        applicationStartDate: applicationStartDate ?? this.applicationStartDate,
        applicationDeadline: applicationDeadline ?? this.applicationDeadline,
        expectedReceiptDate: expectedReceiptDate ?? this.expectedReceiptDate,
        condition: condition ?? this.condition,
        memo: memo ?? this.memo,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
