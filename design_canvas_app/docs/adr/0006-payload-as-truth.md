# ADR-0006: Handoff payload を "編集の真実" とし、生成コードを derive する

- **Status**: Accepted
- **Date**: 2026-04-08
- **Deciders**: 13nosui

## Context

ADR-0004 で React → Flutter ハンドオフのペイロードを base64url URL に詰める
方式を採用した。Flutter 側の `ImportPage` は当初「payload を読んで表示するだけ」
の受け取り役だった。

その後、VISION の終盤「**コードが真実**」に到達する最短路を検討したとき、
次のギャップが浮上した:

1. ユーザーは Claude が生成した payload を微調整したい (タイトルを直す、
   画面を 1 枚追加する、セクションの文言を書き換える等)
2. 編集結果が `.dart` + `.styles.dart` (ADR-0005) に即座に反映されてほしい
3. Flutter Web でも動作する必要がある (ファイルシステムには書けない)
4. 編集後の reload や URL 共有でも編集内容が保持されてほしい

候補となるアーキテクチャ:

### A. Code-as-truth (従来の canvas editor 方式)
生成した `.dart` ファイルを最初から書き出し、キャンバスエディタが AST を
直接書き換え、ファイルシステムが唯一の真実。既存の `design_canvas_page.dart`
と同じ方式。

### B. Payload-as-truth (本 ADR)
ハンドオフ payload (Map<String, dynamic>) を編集可能な単一の真実源とし、
`.dart` + `.styles.dart` は payload から決定論的に derive される出力として扱う。
ユーザーが触るのは payload であって生成コードではない。

### C. Dual-source
Payload と生成コードを双方向に同期する。どちらを触っても相手が追従する。

## Decision

**Option B — Payload-as-truth を採用する**。

具体的には:

1. `ImportPage` は StatefulWidget で、`_payload: Map<String, dynamic>` を
   State に保持する
2. すべての編集 UI (`EditableText` / `ScreensList` / add/remove buttons) は
   この payload を path-based mutation で直接書き換える
3. 編集後、`_persistToUrl()` が payload を再エンコードして `history.replaceState`
   で URL に書き戻す (Web のみ、desktop は noop stub)
4. "キャンバスに取り込む" ボタンが押されたタイミングで、現在の payload から
   `generatePagesFromPayload(_payload)` を呼んで .dart + .styles.dart の
   文字列を生成する
5. Bottom sheet の Preview タブと Code タブは同じ payload から derive される
   「2 つの view」として描画される (`page_codegen.dart` と `page_preview.dart`
   が lockstep を維持)

```
          ┌─────────────────────┐
          │   Handoff payload   │ ← 唯一の真実源
          │   (Map / JSON)      │
          └──────────┬──────────┘
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
   [.dart 文字列] [Live Widget] [表示 UI]
    (codegen)    (preview)     (ImportBody)
```

## Consequences

### Good
- **Web で完全に動く**: ファイルシステムが不要。base64url URL と
  `history.replaceState` だけで編集ループが閉じる
- **Flutter と React のスキーマが一致**: payload shape が
  `elaborate.js` (React) の zod schema とそのまま一致するので、
  schema を真実として両側で共有できる
- **reload と URL 共有が両立**: 編集後のユーザーが URL をコピーすれば、
  相手には編集済み payload がそのまま届く。リンクが shareable
- **テストしやすい**: 編集は payload の Map 操作、生成は pure function。
  両方ともテスト容易 (`page_codegen_test.dart` 参照)
- **Undo / Redo への道筋**: payload は immutable にもできるので、
  将来的な履歴機能の実装が直線的
- **ADR-0005 (Component File Separation) と整合**: 生成された
  `.styles.dart` は今後 canvas editor 側で書き戻される可能性があるが、
  その書き戻しは「payload から再度 generate + diff」で実装可能

### Bad (trade-offs)
- **Canvas editor の AST 書き換えパスと別系統**: 既存の
  `design_canvas_page.dart` は AST ベースでソースファイルを直接編集
  する。ImportPage の payload-as-truth とはモデルが違う。将来的に
  両者を統合するなら、ADR-0006 vs code-as-truth のどちらを採用するか
  判断が必要
- **payload のスキーマ変更がコスト**: zod schema (React) と page_codegen
  (Flutter) と page_preview (Flutter) の 3 箇所を同時に更新する必要がある。
  lockstep を守る仕組みは現状人力
- **生成コードをユーザーが直接編集できない**: コードは derive されたものなので、
  bottom sheet でコピーして手で直しても payload には反映されない。逆方向の
  パースは未実装 (C オプション相当)
- **巨大な payload で URL 長が問題**: ADR-0004 で 8KB 上限を警告済み。
  screens や sections を増やすとここに早く到達する

## Alternatives considered

1. **A. Code-as-truth**
   - 却下: Flutter Web で動かない (ファイル書き込み不可)。macOS 限定の
     ツールでは VISION の "AI-Native Structure" の裾野が狭まる
2. **C. Dual-source 双方向同期**
   - 却下 (現段階): コードのパースが必要になり、`analyzer` の出番が増える
     (既存の canvas editor と同じ重さ)。MVP には過剰
3. **Payload を Flutter 側でも zod 風スキーマで検証する**
   - 却下 (現段階): Dart には軽量な schema validator が少なく、
     手書きの `as String?` キャストで当面十分。将来 `package:json_schema`
     等を検討

## Related

- Files
  - `apps/mobile/lib/presentation/pages/import_page.dart`
    (`_ImportPageState._editAtPath`, `_addScreen`, `_removeScreen`,
    `_addSection`, `_removeSection`, `_persistToUrl`)
  - `apps/mobile/lib/presentation/pages/import_page_editors.dart`
    (`EditableText`, `ScreensList`)
  - `apps/mobile/lib/core/design_system/codegen/page_codegen.dart`
    (`generatePagesFromPayload`, `generatePageFromScreen`)
  - `apps/mobile/lib/core/design_system/codegen/page_preview.dart`
    (`GeneratedPagePreview` — lockstep widget preview)
  - `apps/mobile/lib/core/utils/url_updater_html.dart`
    (`updateQueryParameter` via history.replaceState)
  - `packages/prototype_engine/api/elaborate.js` (zod schema with
    screens[].sections)
- Commits
  - `56241ff feat(handoff): Per-screen sections で各ページを固有化`
  - `f514c69 feat(mobile): ImportPage を編集可能に`
  - `4838e1f feat(mobile): ImportPage の編集を URL に永続化 (Web)`
  - `cf026cd feat(mobile): ImportPage で screens/sections を追加・削除`

## Future considerations

- **Payload → .dart の逆方向**: ユーザーが bottom sheet で直接コード編集した
  ときに、差分を payload にフィードバックする機能
- **Canvas editor との統合**: `design_canvas_page.dart` の AST 編集パスと、
  ImportPage の payload 編集パスを統合するか、役割分担で棲み分けるかの決定
- **payload version migration**: schema 変更時の後方互換 (ADR-0004 で予告)
- **collaborative edit**: 複数人で同じ URL を開いて同時編集 (CRDT 相当)
