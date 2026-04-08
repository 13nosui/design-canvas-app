# ADR-0004: React → Flutter ハンドオフに base64url URL パラメータを採用

- **Status**: Accepted
- **Date**: 2026-04-08
- **Deciders**: 13nosui

## Context

VISION のクライマックス体験は「プロンプト → プロトタイプ (React) → コードが真実
(Flutter キャンバス)」の一筆書きである。この一筆書きを成立させるには、React 側で
生成したプロジェクトカード + 詳細 (画面構成、ユーザーフロー、API、技術スタック、
リスク) を Flutter 側のページへ **受け渡す** 必要がある。

制約:
- React と Flutter は **独立した Vercel プロジェクト** (ADR-0001)。同一ドメインではない
- ペイロードサイズは 1〜4 KB 程度 (JSON stringify 後)
- ハンドオフ頻度は「カードクリック」単位
- 現段階ではユーザー認証もバックエンド DB もない
- 共有できる URL になると、誰かに送って同じ詳細を見せられる副次メリットがある

候補:
1. **base64url エンコードで URL クエリに詰める**
2. **Vercel Blob / KV に保存して短縮 ID を URL に渡す**
3. **postMessage (iframe 経由)**
4. **LocalStorage / BroadcastChannel**

## Decision

**ペイロードを JSON → base64url エンコード → `?data=<...>` で Flutter URL を開く**。

### React 側 (`DetailDrawer.jsx`)

```js
function buildHandoffUrl(project) {
  const payload = {
    title: project.title,
    icon: project.icon,
    summary: project.summary,
    prompt: project.prompt,
    meta: project.meta,
    detail: project.detail,
  }
  const json = JSON.stringify(payload)
  const base64 = btoa(unescape(encodeURIComponent(json)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '')
  return `${FLUTTER_APP_BASE_URL}/import?data=${base64}`
}
```

### Flutter 側 (`ImportPage`)

```dart
final encoded = Uri.base.queryParameters['data'];
final normalized = base64Url.normalize(encoded);
final jsonStr = utf8.decode(base64Url.decode(normalized));
final payload = json.decode(jsonStr) as Map<String, dynamic>;
```

### 運用上の要件
- Flutter Web の GoRouter を **path-style** URL で動かすため、Vercel に SPA fallback
  rewrite (`/(.*)` → `/index.html`) が必要 (ADR では独立項目化せず、実装上の必須設定として記録)
- Flutter 側の初期画面ディスパッチは `_HomeDispatcher` (main.dart) で `Uri.base.path` を
  見て手動振り分け。将来 `MaterialApp.router` へ移行予定

## Consequences

### Good
- **ステートレス**: バックエンド永続化ゼロ。サーバー側の追加コスト・課金なし
- **即時動作**: 外部リソース待ちゼロ、レイテンシ最小
- **共有可能**: URL をコピペすれば誰でも同じページを開ける。ブラウザブックマーク、
  Slack 投稿、メール添付なんでも OK
- **監査可能**: URL 自体にデータが含まれるので、ログを見れば何が渡ったか分かる
- **Vercel プロジェクトをまたいで動く**: CORS もトークン共有も不要、単なる URL 遷移

### Bad (trade-offs)
- **URL 長の上限** (実用上 ~8 KB)。詳細セクションが膨らむと限界に近づく
  - 実測: 典型的な詳細付きカードで 1387 文字 ≈ 1.4 KB、上限の 17%
- **機密情報は絶対に載せられない**: URL は HTTPS でも中間のログ (CDN、proxy、
  ブラウザ履歴) に残る前提で扱う必要がある
- **スキーマ変更の互換性**: 現状の実装はペイロード形状がハードコード。将来変更する
  場合は `version` フィールドを追加して両側で解釈を分岐する必要がある
- **URL が長い**: コピペはできるが視認性は低い

## Alternatives considered

1. **Vercel Blob / KV + 短縮 URL (`?id=abc`)**
   - 却下 (現段階): 永続化でリソース管理と課金が発生し、MVP には過剰。
     **ただし将来 URL 長が問題になれば切り替える** (昇格候補)
2. **postMessage (React 側で Flutter を iframe 化)**
   - 却下: Vercel プロジェクトが別々 (ADR-0001) で独立デプロイを尊重したい。
     iframe 化すると Flutter の URL 直接共有ができなくなる
3. **LocalStorage / BroadcastChannel**
   - 却下: Vercel サブドメインが異なるため origin が分離され、共有ストレージが使えない
4. **カスタムプロトコルスキーム** (`designcanvas://import?...`)
   - 却下: Web アプリから起動できない、デスクトップだけ。OS ネイティブ依存
5. **クエリを複数の小さなパラメータに分解する** (`?title=&summary=&...`)
   - 却下: detail.screens など配列構造の表現が煩雑、エンコード/デコードが複雑

## Related

- Files
  - `packages/prototype_engine/src/components/DetailDrawer.jsx` (`buildHandoffUrl`)
  - `apps/mobile/lib/presentation/pages/import_page.dart` (`_decodePayload`, `_readEncodedFromUrl`)
  - `apps/mobile/lib/main.dart` (`_HomeDispatcher` による URL 振り分け)
  - `apps/mobile/vercel.json` (SPA fallback rewrite)
- Commits
  - `be79f43 feat: React で生成した設計を Flutter キャンバスへハンドオフ`
  - `eb7351a fix(mobile): Flutter Web の SPA fallback rewrite を追加`
  - `d54ba8c fix(mobile): /import URL を実際に ImportPage に振り分ける`

## Future considerations

- **スキーマ versioning**: 次回ペイロード変更時に `version: 1` フィールドを追加する
- **Blob 移行**: URL が 4 KB を超えたり、機密寄りの情報を載せる必要が出たら、
  Vercel Blob + 短縮 URL の方式に切り替える
- **Flutter 側の router 正式化**: `_HomeDispatcher` を廃し、`MaterialApp.router(routerConfig: appRouter)`
  へ移行する (別 ADR 候補)
