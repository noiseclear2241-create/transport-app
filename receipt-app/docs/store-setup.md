# ストア公開・課金セットアップ手順

このアプリ（`receipt-app`）は Capacitor でラップした Web アプリを iOS / Android の
ネイティブアプリとしてビルドする構成になっています。コード側の実装（フォーム・
PDF生成・課金ゲート）はこのリポジトリに揃っていますが、**以下の手順はあなた自身の
アカウントで行う必要があります**（この開発環境からは実行できません）。

## 前提

- macOS + Xcode（iOS ビルド用。Windows/Linux では iOS のビルドはできません）
- Android Studio（Android ビルド用。こちらは Windows/Linux/macOS どこでも可）
- Apple Developer Program（年額 $99）※ iOS を出す場合
- Google Play Developer アカウント（登録費 $25、初回のみ）※ Android を出す場合
- RevenueCat アカウント（無料枠あり。月間売上 $2,500 までは無料）

## 1. アプリIDの変更

`capacitor.config.ts` の `appId` は現在プレースホルダー
（`com.example.receiptapp`）です。ストアに登録する一意の Bundle ID / Application ID
に変更してから、`npm run cap:sync` を実行してください。

```ts
// capacitor.config.ts
appId: 'com.yourcompany.receiptapp', // ← 変更する
```

## 2. RevenueCat のセットアップ

1. https://app.revenuecat.com でプロジェクトを作成
2. 「Apps」で iOS アプリ・Android アプリをそれぞれ追加し、Bundle ID / Package name
   を上記のアプリIDと一致させる
3. 各アプリの **Public API Key** を控える
4. プロジェクトルートに `.env` ファイルを作成（`.env.example` をコピー）し、
   キーを設定する：
   ```
   VITE_REVENUECAT_IOS_KEY=appl_xxxxxxxxxxxx
   VITE_REVENUECAT_ANDROID_KEY=goog_xxxxxxxxxxxx
   ```
5. RevenueCat の「Products」で、各ストア側で作成した消費型（consumable）商品を
   紐付ける
6. 「Offerings」で Offering を作成し、Package を追加する。**Package の
   identifier に `credits_5` のように末尾へ枚数を含めてください**
   （例：`credits_1` = 1枚分, `credits_5` = 5枚パック）。
   このアプリの `src/lib/purchases.ts` はこの命名規則から付与するクレジット数を
   読み取ります。

## 3. App Store Connect（iOS）

1. App Store Connect でアプリを新規作成（Bundle ID は手順1と一致させる）
2. 「App内課金」で消費型（Consumable）商品を必要な枚数パック分だけ作成
   （例：1枚パック、5枚パック）
3. 価格・商品名・説明文を設定し、審査に提出する準備をする
4. Xcode で `npm run cap:ios` を実行してプロジェクトを開き、署名設定
   （Team / Bundle Identifier）を行ってからビルド・アーカイブ

## 4. Google Play Console（Android）

1. Play Console でアプリを新規作成
2. 「収益化」→「アプリ内アイテム」で管理対象商品（消費型）を作成
3. `npm run cap:android` で Android Studio を開き、署名済み AAB をビルド
   （Play Console の「App Bundle explorer」の指示に従う）
4. 内部テスト → クローズドテスト → 本番リリースの順に提出

## 5. 動作確認

- ブラウザ（`npm run dev`）ではストア課金は動作しません（Paywall にその旨の
  注記が表示されます）。実機・実ビルドでのみ購入フローを確認できます。
- Sandbox（iOS）/ ライセンステスター（Android）アカウントで購入テストを
  行ってから本番公開してください。

## 6. 審査時の注意点

- 領収書アプリは「デジタルコンテンツの購入」に該当するため、Apple/Google の
  規約上、決済は各ストアの IAP を使う必要があります（Stripe 等の外部決済を
  ネイティブアプリ内で使うと審査に通りません）。
- 印影スペースは実際の印鑑画像ではなく枠のみです。実印/角印の画像を追加したい
  場合は、ユーザーが自分の印影画像をアップロードできる機能を別途検討してください
  （このリポジトリには未実装です）。
