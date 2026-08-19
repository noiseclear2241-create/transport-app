import 'enums.dart';

/// ホーム・カレンダー・履歴で表示する「やること」（#40, #41）。
/// オプション/特典/端末返却から自動生成されるほか、汎用タスクとしても使う。
///
/// [sourceType] / [sourceId] で生成元（option / benefit / device）を
/// 追跡し、生成元が編集されたときにタスクを再計算できるようにする。
class TaskItem {
  final String id;
  final String familyMemberId;
  final String title;
  final TaskType type;
  final DateTime dueDate;
  final String? sourceType; // 'option' | 'benefit_application' | 'benefit_receipt' | 'device_return'
  final String? sourceId;
  final String? subtitle; // 金額など補足情報
  final TaskStatus status;
  final DateTime? completedAt;
  final DateTime? snoozedUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskItem({
    required this.id,
    required this.familyMemberId,
    required this.title,
    required this.type,
    required this.dueDate,
    this.sourceType,
    this.sourceId,
    this.subtitle,
    this.status = TaskStatus.pending,
    this.completedAt,
    this.snoozedUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDone => status == TaskStatus.done;

  int daysUntilDue(DateTime today) {
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final base = DateTime(today.year, today.month, today.day);
    return due.difference(base).inDays;
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'family_member_id': familyMemberId,
        'title': title,
        'type': type.value,
        'due_date': dueDate.toIso8601String(),
        'source_type': sourceType,
        'source_id': sourceId,
        'subtitle': subtitle,
        'status': status.value,
        'completed_at': completedAt?.toIso8601String(),
        'snoozed_until': snoozedUntil?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory TaskItem.fromMap(Map<String, Object?> map) => TaskItem(
        id: map['id']! as String,
        familyMemberId: map['family_member_id']! as String,
        title: map['title']! as String,
        type: TaskType.fromValue(map['type']! as String),
        dueDate: DateTime.parse(map['due_date']! as String),
        sourceType: map['source_type'] as String?,
        sourceId: map['source_id'] as String?,
        subtitle: map['subtitle'] as String?,
        status: TaskStatus.fromValue(map['status']! as String),
        completedAt:
            map['completed_at'] == null ? null : DateTime.parse(map['completed_at']! as String),
        snoozedUntil:
            map['snoozed_until'] == null ? null : DateTime.parse(map['snoozed_until']! as String),
        createdAt: DateTime.parse(map['created_at']! as String),
        updatedAt: DateTime.parse(map['updated_at']! as String),
      );

  TaskItem copyWith({
    String? title,
    DateTime? dueDate,
    String? subtitle,
    TaskStatus? status,
    DateTime? completedAt,
    DateTime? snoozedUntil,
    bool clearSnooze = false,
  }) =>
      TaskItem(
        id: id,
        familyMemberId: familyMemberId,
        title: title ?? this.title,
        type: type,
        dueDate: dueDate ?? this.dueDate,
        sourceType: sourceType,
        sourceId: sourceId,
        subtitle: subtitle ?? this.subtitle,
        status: status ?? this.status,
        completedAt: completedAt ?? this.completedAt,
        snoozedUntil: clearSnooze ? null : (snoozedUntil ?? this.snoozedUntil),
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
