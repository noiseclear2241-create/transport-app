/// 家族管理（プレミアム限定・#24）。
/// 無料版でも「自分」1人分のfamily_memberレコードは内部的に自動生成される。
class FamilyMember {
  final String id;
  final String name;
  final String? relation; // 例: 本人, 妻, 子供, 両親
  final DateTime createdAt;

  const FamilyMember({
    required this.id,
    required this.name,
    this.relation,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'relation': relation,
        'created_at': createdAt.toIso8601String(),
      };

  factory FamilyMember.fromMap(Map<String, Object?> map) => FamilyMember(
        id: map['id']! as String,
        name: map['name']! as String,
        relation: map['relation'] as String?,
        createdAt: DateTime.parse(map['created_at']! as String),
      );

  FamilyMember copyWith({String? name, String? relation}) => FamilyMember(
        id: id,
        name: name ?? this.name,
        relation: relation ?? this.relation,
        createdAt: createdAt,
      );
}
