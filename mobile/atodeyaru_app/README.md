# あとでやること

**スマホ契約後のお金と予定を、忘れない。**

スマートフォン・インターネット回線を契約した後に必要な「オプション解約」「無料期間終了」「キャッシュバック申請」「特典受取」「スマホ返却」などを忘れないよう管理する、iOS/Android共通コードのFlutterアプリです。

このアプリは契約書やスクリーンショットを保存する「書類管理アプリ」ではありません。ユーザーが手入力した小容量の構造化データのみを扱い、個人情報・サーバーコストを最小限に抑えることを設計方針としています（詳細は `docs/design_notes.md` を参照）。

## 必要環境

- Flutter SDK 3.27以降（安定版チャンネル推奨）／Dart 3.3以降
- iOS開発: Xcode 15以降・CocoaPods
- Android開発: Android Studio（Android SDK 35, minSdk 26）

このリポジトリには `lib/`・`test/`・`android/`（最小構成）を含みますが、
`ios/` ディレクトリはXcodeプロジェクトファイル（`.pbxproj`）を手書きで
安全に生成できないため含めていません。初回セットアップ時に以下のコマンドで
`ios/` を生成してください（既存の `lib/`・`pubspec.yaml` は上書きされません）。

```bash
cd mobile/atodeyaru_app
flutter create --platforms=ios --org com.atodeyaru .
flutter pub get
```

Android側もお使いのFlutter/AGPバージョンに合わせて差分が出た場合は、
同様に `flutter create --platforms=android --org com.atodeyaru .` で
`android/` を検証・再生成できます（本リポジトリには動作確認用の最小構成を
同梱済みです）。

## セットアップ

```bash
cd mobile/atodeyaru_app
flutter pub get
flutter test        # 日付計算ロジックなどのユニットテスト
flutter run
```

## アーキテクチャ

```
lib/
  models/       # Contract, ContractOption, Benefit, Device, TaskItem, FamilyMember, AppSettings ほか
  services/
    database_service.dart     # sqflite（端末内DB、契約書・画像は保存しない）
    settings_service.dart     # SharedPreferences（設定・課金状態のキャッシュ）
    date_calculator.dart      # 無料期間終了日・返却確認日の暦月計算（Asia/Tokyo）
    task_generator.dart       # オプション/特典/端末からタスクを自動生成
    notification_service.dart # flutter_local_notifications（サーバー常時通知はしない）
    subscription_service.dart # in_app_purchase（App Store / Google Play Billing）
    google_calendar_service.dart # google_sign_in + googleapis（手動同期のみ、プレミアム限定）
    app_repository.dart       # 上記をまとめるアプリ全体の状態（Provider経由でUIに渡す）
  screens/      # onboarding / home / contracts / devices / calendar / history / settings
  widgets/      # TaskCard, CountdownBadge など共通UI
  theme/        # 配色・タイポグラフィ
```

状態管理は `provider` パッケージのみを使用し、UIは `AppRepository`
（`ChangeNotifier`）を経由してのみデータを読み書きします。

## 主要な設計判断

- **無料期間・返却時期の計算はすべて暦月単位。** 30日固定加算ではなく、
  `DateCalculator.addCalendarMonths` で月末クランプまで正しく扱います。
  `test/date_calculator_test.dart` を参照。
- **通知はローカル通知のみ。** サーバーからのプッシュ通知は使用せず、
  契約・オプション・特典・端末が追加/変更されたタイミングでのみ
  `flutter_local_notifications` に予約を登録し直します。
- **Googleカレンダー連携は常時同期しない。** 予定の追加・変更・削除の
  タイミングでのみAPIを呼び出す設計です（`google_calendar_service.dart`）。
- **無料版の制限**は `AppRepository.canAddContract` / `canAddDevice` /
  `canUseGoogleCalendar` で一元管理しています（契約1件・端末1台まで）。

## 未接続の外部サービス（ストア申請前に必須の設定）

このMVPはコード上の実装は用意していますが、実際の値の発行・設定は
ストア/クラウド管理画面側の作業のため、以下は未接続のままです。

| 機能 | 必要な作業 |
| --- | --- |
| App内課金（月額298円/年額2,980円） | App Store Connect / Google Play Consoleで `premium_monthly` / `premium_yearly` の商品を作成し、`lib/services/subscription_service.dart` の商品IDと一致させる |
| Googleカレンダー連携 | Google Cloud ConsoleでOAuthクライアントID発行、`android/app/google-services.json` 相当の設定、iOSの `GIDClientID` / URLスキーム追加 |
| プッシュ通知（将来拡張用） | 本MVPでは未使用（ローカル通知のみ） |
| 簡易管理画面（#49, #50） | サーバー側の実装が必要（`docs/design_notes.md` 参照） |

## テスト

```bash
flutter test
```

`test/date_calculator_test.dart` は仕様書にある

> 契約日 2026-08-19、無料期間2か月 → 解約確認日 2026-10-19

を含む暦月計算の正しさを検証します。

## ライセンス表記・法務ドキュメント

プライバシーポリシー・利用規約・ストア申請情報は `docs/store_listing.md` に
チェックリストとしてまとめています（実際の文書はストア申請前に別途作成してください）。
