import 'package:uuid/uuid.dart';

import '../models/models.dart';

const _uuid = Uuid();

/// オプション・特典・端末返却から「やること」タスクを自動生成するロジック。
///
/// 生成元（sourceType/sourceId）が変更されたときは、呼び出し側が既存タスクを
/// 洗い替え（削除→再生成）することで、常に最新の日付・金額を反映する。
class TaskGenerator {
  const TaskGenerator._();

  /// オプションの解約確認タスク（#14, #26 🔴）。
  static TaskItem? forOption(ContractOption option, String familyMemberId) {
    final due = option.cancellationCheckDate;
    if (due == null) return null;
    final now = DateTime.now();
    return TaskItem(
      id: _uuid.v4(),
      familyMemberId: familyMemberId,
      title: '${option.name}を確認',
      type: TaskType.cancellation,
      dueDate: due,
      sourceType: 'option',
      sourceId: option.id,
      subtitle: option.monthlyFeeYen != null ? '月額${option.monthlyFeeYen}円' : null,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 特典「申請」タスク（#18, #26 🟡）。申請不要な特典には生成しない。
  static TaskItem? forBenefitApplication(Benefit benefit, String familyMemberId) {
    if (!benefit.applicationRequired) return null;
    final due = benefit.applicationDeadline ?? benefit.applicationStartDate;
    if (due == null) return null;
    final now = DateTime.now();
    return TaskItem(
      id: _uuid.v4(),
      familyMemberId: familyMemberId,
      title: '${benefit.name}を申請',
      type: TaskType.application,
      dueDate: due,
      sourceType: 'benefit_application',
      sourceId: benefit.id,
      subtitle: benefit.amountYen != null ? '${benefit.amountYen}円' : null,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 特典「受取確認」タスク（#18, #26 🟢）。
  static TaskItem? forBenefitReceipt(Benefit benefit, String familyMemberId) {
    final due = benefit.expectedReceiptDate;
    if (due == null) return null;
    final now = DateTime.now();
    return TaskItem(
      id: _uuid.v4(),
      familyMemberId: familyMemberId,
      title: '${benefit.name}受取確認',
      type: TaskType.benefit,
      dueDate: due,
      sourceType: 'benefit_receipt',
      sourceId: benefit.id,
      subtitle: benefit.amountYen != null ? '${benefit.amountYen}円' : null,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 端末返却確認タスク（#20, #26 🟠）。
  static TaskItem? forDeviceReturn(Device device, String familyMemberId) {
    final due = device.returnCheckDate;
    if (due == null) return null;
    final now = DateTime.now();
    return TaskItem(
      id: _uuid.v4(),
      familyMemberId: familyMemberId,
      title: '${device.name}の返却確認',
      type: TaskType.deviceReturn,
      dueDate: due,
      sourceType: 'device_return',
      sourceId: device.id,
      subtitle: '返却目安',
      createdAt: now,
      updatedAt: now,
    );
  }
}
