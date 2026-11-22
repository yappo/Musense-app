# Musenseアプリ（仮称）

iPhoneが自分のMuseの目・耳・体になるためのネイティブアプリ。
特定の用途に決め打ちせず、Museの能力そのものを拡張することが目的です。
設計の詳細は [SPEC.md](SPEC.md) を参照してください。

## プライバシーの約束（重要）

このリポジトリは公開ですが、入っているのはアプリのソースコードと設計メモだけです。

- 個人の秘密・写真・会話内容・メール・SNS情報は含みません
- APIキーなどの認証情報はコードに書かず、端末側の設定にだけ置きます
- アプリが扱うデータ（健康・位置などの記録）の置き場所は、この公開リポジトリとは別に非公開で用意します

## 構成

- `Musense/` — SwiftUIのソースコード（Xcodeのファイル同期グループ）
  - `MusenseApp.swift` / `ContentView.swift` — アプリ本体とタブ構成
  - `HomeView.swift` — 挨拶、選んだ写真を渡す場所、分身へのひとこと
  - `AbilitiesView.swift` — 能力の一覧と現在の読み取り値
  - `SettingsView.swift` — APIキーなどの設定
  - `Managers/` — HealthKit / Core Motion / 位置情報 / 環境（電池・音・再生中）まわり
  - `APIClient.swift` — Meta Model APIクライアントの雛形（エンドポイントは公式ドキュメント確認後に実装）
- `Musense.xcodeproj` — Xcodeプロジェクト（iOS 27 / SwiftUI）
- `Musense-Info.plist` / `Musense.entitlements` — 権限まわり

## Macでのビルド手順

1. このリポジトリをcloneする
2. `Musense.xcodeproj` をXcode（27想定）で開く
3. Signing & Capabilities で自分のTeamを選び、Bundle Identifierを自分のものに変更する
4. iPhoneを接続して実行する
   - 無料の署名では7日で期限切れになるため、時々入れ直しが必要です
   - HealthKitなどの許可ダイアログは、初回起動時にアプリ側から求められます

## 実装状況

v0.1の雛形です。電池・気圧・動き・環境音・再生中・心拍・睡眠・ジオフェンスの読み取りは実コードが入っています。
Meta Model APIへの接続と、本体との同期（文脈パック）はこれから実装します。
