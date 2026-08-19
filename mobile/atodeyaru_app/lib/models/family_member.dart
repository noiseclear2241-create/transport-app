/// 家族管理（プレミアム限定・#24）。
/// 無料版でも「自分」1人分のfamily_memberレコードは内部的に自動生成される。
///
/// 同じ名前（例:「子供」が複数人）でも区別できるよう、電話番号を任意項目として
/// 持たせている。SMS送信や電話発信には使わず、あくまで本人特定のための
/// 表示・管理用の情報。
class FamilyMember {
  final String id;
  final String name;
  final String? relation; // 例: 本人, 妻, 子供, 両親
  final String? phoneNumber;
  final DateTime createdAt;

  const FamilyMember({
    required this.id,
    required this.name,
    this.relation,
    this.phoneNumber,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'relation': relation,
        'phone_number': phoneNumber,
        'created_at': createdAt.toIso8601String(),
      };

  factory FamilyMember.fromMap(Map<String, Object?> map) => FamilyMember(
        id: map['id']! as String,
        name: map['name']! as String,
        relation: map['relation'] as String?,
        phoneNumber: map['phone_number'] as String?,
        createdAt: DateTime.parse(map['created_at']! as String),
      );

  FamilyMember copyWith({String? name, String? relation, String? phoneNumber}) => FamilyMember(
        id: id,
        name: name ?? this.name,
        relation: relation ?? this.relation,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        createdAt: createdAt,
      );
}
