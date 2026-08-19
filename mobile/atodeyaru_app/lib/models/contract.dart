import 'enums.dart';

/// 契約情報（#13）。「契約書を保存するアプリ」ではないため、
/// PDFや画像は一切保持せず、手入力の構造化データのみを持つ。
class Contract {
  final String id;
  final String familyMemberId;
  final ContractType type;
  final Carrier carrier;
  final String? carrierOther; // carrier == other のときの自由入力
  final DateTime contractDate;
  final String? contractNumber;
  final int? monthlyFeeYen;
  final String? memo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Contract({
    required this.id,
    required this.familyMemberId,
    required this.type,
    required this.carrier,
    this.carrierOther,
    required this.contractDate,
    this.contractNumber,
    this.monthlyFeeYen,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
  });

  String get carrierLabel => carrier == Carrier.other && (carrierOther?.isNotEmpty ?? false)
      ? carrierOther!
      : carrier.label;

  Map<String, Object?> toMap() => {
        'id': id,
        'family_member_id': familyMemberId,
        'type': type.value,
        'carrier': carrier.value,
        'carrier_other': carrierOther,
        'contract_date': contractDate.toIso8601String(),
        'contract_number': contractNumber,
        'monthly_fee_yen': monthlyFeeYen,
        'memo': memo,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Contract.fromMap(Map<String, Object?> map) => Contract(
        id: map['id']! as String,
        familyMemberId: map['family_member_id']! as String,
        type: ContractType.fromValue(map['type']! as String),
        carrier: Carrier.fromValue(map['carrier']! as String),
        carrierOther: map['carrier_other'] as String?,
        contractDate: DateTime.parse(map['contract_date']! as String),
        contractNumber: map['contract_number'] as String?,
        monthlyFeeYen: map['monthly_fee_yen'] as int?,
        memo: map['memo'] as String?,
        createdAt: DateTime.parse(map['created_at']! as String),
        updatedAt: DateTime.parse(map['updated_at']! as String),
      );

  Contract copyWith({
    String? familyMemberId,
    ContractType? type,
    Carrier? carrier,
    String? carrierOther,
    DateTime? contractDate,
    String? contractNumber,
    int? monthlyFeeYen,
    String? memo,
  }) =>
      Contract(
        id: id,
        familyMemberId: familyMemberId ?? this.familyMemberId,
        type: type ?? this.type,
        carrier: carrier ?? this.carrier,
        carrierOther: carrierOther ?? this.carrierOther,
        contractDate: contractDate ?? this.contractDate,
        contractNumber: contractNumber ?? this.contractNumber,
        monthlyFeeYen: monthlyFeeYen ?? this.monthlyFeeYen,
        memo: memo ?? this.memo,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
