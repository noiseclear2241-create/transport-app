# 領収書PDF作成アプリ（receipt-app）

宛名・金額・但し書きなどを入力して領収書PDFを作成する、Capacitor製のスマホアプリ
（iOS / Android）です。`transport-app`（交通費精算アプリ）とは独立したアプリです。

## 主な機能

- テンプレート3種（① シンプル縦型 / ② ビジネス横型 / ③ インボイス対応）
- インボイス登録番号は未入力なら自動的に欄ごと非表示
- 発行元情報（会社名・住所・電話番号・登録番号）は端末に保存され、次回から自動入力
- PDF作成は1枚目無料、2枚目以降はストア課金（RevenueCat経由のIn-App Purchase）

## 開発

```bash
npm install
npm run dev       # ブラウザでプレビュー（http://localhost:5173）
```

ブラウザプレビューではフォーム・PDF生成・レイアウト確認ができますが、
ストア課金（2枚目以降の購入フロー）は実機ビルドでのみ動作します。

## ネイティブビルド

```bash
npm run cap:android   # Android Studio を開く
npm run cap:ios        # Xcode を開く（macOS のみ）
```

初回のみ `capacitor.config.ts` の `appId` を自分のアプリID（例:
`com.yourcompany.receiptapp`）に変更してください。

## ストア公開・課金設定

RevenueCat / App Store Connect / Google Play Console の設定手順は
[`docs/store-setup.md`](./docs/store-setup.md) を参照してください。

## 技術構成

- Vite + React + TypeScript + Tailwind CSS
- PDF生成: `html2canvas` でテンプレートDOMを高解像度キャンバス化 → `jsPDF` で
  実寸ページに埋め込み（日本語フォントをPDFに直接埋め込む必要がないための方式）
- 課金: `@revenuecat/purchases-capacitor`（消費型クレジットパック）
- 保存・共有: `@capacitor/filesystem` + `@capacitor/share`
