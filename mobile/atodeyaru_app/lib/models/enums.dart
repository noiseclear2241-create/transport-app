/// アプリ全体で使う列挙型をまとめたファイル。
/// 将来サーバー同期する場合もそのまま文字列として保存できるよう、
/// 各enumに `value`（DB保存用の安定したキー）を持たせている。

enum ContractType {
  smartphone('smartphone', 'スマートフォン'),
  internet('internet', 'インターネット'),
  hikari('hikari', '光回線'),
  other('other', 'その他');

  const ContractType(this.value, this.label);
  final String value;
  final String label;

  static ContractType fromValue(String value) =>
      ContractType.values.firstWhere((e) => e.value == value, orElse: () => ContractType.other);
}

enum Carrier {
  docomo('docomo', 'docomo'),
  au('au', 'au'),
  softbank('softbank', 'SoftBank'),
  rakuten('rakuten', '楽天モバイル'),
  uqMobile('uq_mobile', 'UQ mobile'),
  yMobile('y_mobile', 'Y!mobile'),
  other('other', 'その他');

  const Carrier(this.value, this.label);
  final String value;
  final String label;

  static Carrier fromValue(String value) =>
      Carrier.values.firstWhere((e) => e.value == value, orElse: () => Carrier.other);
}

/// 無料期間・返却時期などで共通して使う「期間プリセット」。
enum PeriodPreset {
  none('none', 'なし'),
  m1('1m', '1か月'),
  m2('2m', '2か月'),
  m3('3m', '3か月'),
  m6('6m', '6か月'),
  m12('12m', '12か月'),
  custom('custom', 'カスタム'),
  unknown('unknown', 'わからない');

  const PeriodPreset(this.value, this.label);
  final String value;
  final String label;

  static PeriodPreset fromValue(String value) =>
      PeriodPreset.values.firstWhere((e) => e.value == value, orElse: () => PeriodPreset.unknown);

  /// nullの場合は「カスタム/わからない」など月数で表せないもの。
  int? get months {
    switch (this) {
      case PeriodPreset.none:
        return 0;
      case PeriodPreset.m1:
        return 1;
      case PeriodPreset.m2:
        return 2;
      case PeriodPreset.m3:
        return 3;
      case PeriodPreset.m6:
        return 6;
      case PeriodPreset.m12:
        return 12;
      case PeriodPreset.custom:
      case PeriodPreset.unknown:
        return null;
    }
  }
}

/// 端末返却プログラムの返却時期プリセット。
enum ReturnPeriodPreset {
  m12('12m', '12か月後'),
  m24('24m', '24か月後'),
  m25('25m', '25か月目'),
  m36('36m', '36か月後'),
  m48('48m', '48か月後'),
  custom('custom', 'カスタム'),
  unknown('unknown', 'わからない');

  const ReturnPeriodPreset(this.value, this.label);
  final String value;
  final String label;

  static ReturnPeriodPreset fromValue(String value) => ReturnPeriodPreset.values
      .firstWhere((e) => e.value == value, orElse: () => ReturnPeriodPreset.unknown);

  int? get months {
    switch (this) {
      case ReturnPeriodPreset.m12:
        return 12;
      case ReturnPeriodPreset.m24:
        return 24;
      case ReturnPeriodPreset.m25:
        return 25;
      case ReturnPeriodPreset.m36:
        return 36;
      case ReturnPeriodPreset.m48:
        return 48;
      case ReturnPeriodPreset.custom:
      case ReturnPeriodPreset.unknown:
        return null;
    }
  }
}

enum BenefitType {
  cashback('cashback', 'キャッシュバック'),
  cash('cash', '現金'),
  point('point', 'ポイント'),
  giftCertificate('gift_certificate', '商品券'),
  amazonGift('amazon_gift', 'Amazonギフト券'),
  other('other', 'その他');

  const BenefitType(this.value, this.label);
  final String value;
  final String label;

  static BenefitType fromValue(String value) =>
      BenefitType.values.firstWhere((e) => e.value == value, orElse: () => BenefitType.other);
}

/// 特典ステータス：申請と受取を分離して管理する。
enum BenefitStatus {
  notApplied('not_applied', '未申請'),
  applied('applied', '申請済み'),
  awaitingReceipt('awaiting_receipt', '受取待ち'),
  received('received', '受取済み'),
  notEligible('not_eligible', '対象外'),
  expired('expired', '期限切れ');

  const BenefitStatus(this.value, this.label);
  final String value;
  final String label;

  static BenefitStatus fromValue(String value) => BenefitStatus.values
      .firstWhere((e) => e.value == value, orElse: () => BenefitStatus.notApplied);
}

enum DevicePurchaseMethod {
  lumpSum('lump_sum', '一括'),
  installment('installment', '分割'),
  returnProgram('return_program', '返却プログラム'),
  other('other', 'その他');

  const DevicePurchaseMethod(this.value, this.label);
  final String value;
  final String label;

  static DevicePurchaseMethod fromValue(String value) => DevicePurchaseMethod.values
      .firstWhere((e) => e.value == value, orElse: () => DevicePurchaseMethod.other);
}

/// タスクの種類。カレンダーの色分け（#26）にも対応する。
enum TaskType {
  cancellation('cancellation', '解約', '🔴'),
  application('application', '申請', '🟡'),
  benefit('benefit', '特典', '🟢'),
  deviceReturn('device_return', '返却', '🟠'),
  confirmation('confirmation', '確認', '🔵');

  const TaskType(this.value, this.label, this.emoji);
  final String value;
  final String label;
  final String emoji;

  static TaskType fromValue(String value) =>
      TaskType.values.firstWhere((e) => e.value == value, orElse: () => TaskType.confirmation);
}

enum TaskStatus {
  pending('pending', '未完了'),
  done('done', '完了'),
  snoozed('snoozed', 'あとで');

  const TaskStatus(this.value, this.label);
  final String value;
  final String label;

  static TaskStatus fromValue(String value) =>
      TaskStatus.values.firstWhere((e) => e.value == value, orElse: () => TaskStatus.pending);
}

/// 課金状態（#34）。
enum SubscriptionState {
  free('free', '無料'),
  trial('trial', '無料体験中'),
  premium('premium', 'プレミアム'),
  cancelling('cancelling', '解約予定'),
  expired('expired', '期限切れ');

  const SubscriptionState(this.value, this.label);
  final String value;
  final String label;

  static SubscriptionState fromValue(String value) => SubscriptionState.values
      .firstWhere((e) => e.value == value, orElse: () => SubscriptionState.free);
}

/// 「あとで」スヌーズの選択肢（#39）。
enum SnoozeOption {
  oneHour('1h', '1時間後'),
  tonight('tonight', '今日の夜'),
  tomorrow('tomorrow', '明日'),
  threeDays('3d', '3日後'),
  custom('custom', '日付指定');

  const SnoozeOption(this.value, this.label);
  final String value;
  final String label;
}
