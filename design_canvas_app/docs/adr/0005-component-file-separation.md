# ADR-0005: Flutter コンポーネントの `.dart` + `.styles.dart` 分離

- **Status**: Accepted
- **Date**: 2026-04-08 (規約自体はそれ以前から存在、今回 ADR 化)
- **Deciders**: 13nosui

## Context

`apps/mobile` はただの Flutter アプリではなく、**デザインキャンバスエディタを内蔵する
Flutter アプリ** である。キャンバスエディタは以下のような操作を行う:

- 画面上のコンポーネントを選択
- プロパティインスペクタで色、余白、radius、border 幅などを GUI 編集
- **編集結果を実際のソースコードファイルに書き戻す** (AST ベース)

この "コードを書き戻す" 操作の **対象を安全に限定** する必要がある。Widget tree
の骨格 (Row/Column 構造) や Provider 購読ロジックを AST で書き換えるのはリスクが
高すぎる。一方で、色や余白の `static const` を書き換えるのは安全かつ決定的。

したがって **書き換えて良い領域と、そうでない領域を物理的に分離** する規約が必要になった。

## Decision

`apps/mobile/` 内のすべてのコンポーネント / ページは **2 ファイルに分割** する:

| ファイル | 役割 | 許可 | 禁止 |
|---|---|---|---|
| **`{name}.dart`** | レイアウト骨格 | Row/Column 構造、Provider 購読、イベントハンドラ | スタイル値のハードコード |
| **`{name}.styles.dart`** | 視覚定数 | `static const` / `static final` のみ | Provider/ビジネスロジック依存 |

### キャンバスの書き換え境界
- キャンバスエディタは `.styles.dart` **のみ** を書き換える
- `.dart` ファイルはキャンバスから **読み取り専用** として扱う

### トークン参照のルール
`.styles.dart` 内の値は `AppTokens` (`lib/core/design_system/tokens.dart`) の定数を
参照することが推奨される。対応トークンが存在しない生の値を使う場合は、行末に
**`// TODO: New Token Candidate - {descriptiveName}`** コメントを付与する。

```dart
// Good: 既存トークン参照
static const padding = EdgeInsets.symmetric(
  horizontal: AppTokens.spaceM,
  vertical: AppTokens.spaceS,
);

// Good: 未マッピング値 + TODO
static final headerColor = Color(0xFFF3F4F6); // TODO: New Token Candidate - colorHeaderBg
```

## Consequences

### Good
- **書き換え対象の局所化**: AST リライトが狙うファイルが小さく、リスクが閉じる
- **トークン昇格の可視化**: `// TODO: New Token Candidate` が将来のデザインシステム拡充の
  バックログになる
- **責務の明快さ**: レビューで「ロジック変更か見た目変更か」が一目で分かる
- **AI との相性**: Claude や他の AI にレイアウト編集を依頼するときも、書き換え対象を
  明示しやすい。"`.styles.dart` だけを編集して" と言えば済む
- **VISION 原則 1 (AI-Native Structure) との整合**: 疎結合で透明性の高いアーキテクチャを
  コード構造レベルで保証する

### Bad (trade-offs)
- **ファイル数が 2 倍** になる
- **小さなコンポーネントにも 2 ファイル作る手間**
- 初見のコントリビュータは慣れるまで混乱する
- `import` が冗長 (`import 'foo.dart'` + `import 'foo.styles.dart'`)
- `.styles.dart` 側で `AppTokens` を import する忘れで生値が混入する可能性

## Alternatives considered

1. **単一ファイル内に `class Styles` を持つ**
   - 却下: 同じファイル内で AST 書き換え対象を切り出すことになり、誤爆リスクが残る。
     例: レイアウト変更の diff に紛れてスタイル定数の位置が動き、キャンバスが参照を失う
2. **Theme Extension だけで対応する**
   - 却下: グローバルな theme には、個別コンポーネント固有の値 (例: `ImportPage` の
     ヒーローアイコンサイズ) を載せる粒度が合わない
3. **CSS-in-Dart 的なランタイム生成**
   - 却下: `const` 性を失う、パフォーマンス低下、そもそも AST 書き換えが不可能になる
4. **GUI 編集を諦めてコード直接編集**
   - 却下: プロダクトの中核価値を否定する

## Related

- Files
  - `apps/mobile/lib/core/design_system/tokens.dart` (`AppTokens`)
  - `apps/mobile/lib/presentation/pages/import_page.dart` + `import_page.styles.dart` (最新の規約準拠例)
  - `apps/mobile/lib/presentation/pages/design_canvas_page.dart` (書き換えを実行するエンジン)
- Documentation
  - `CLAUDE.md` — "Component File Separation (Flutter 強制規約)" セクション
  - `CLAUDE.md` — "Design Token Rules (Flutter)" セクション
- Commits (規約への準拠を示す例)
  - `be79f43 feat: React で生成した設計を Flutter キャンバスへハンドオフ` (ImportPage で規約適用)

## Future considerations

- **Lint 化**: `.dart` ファイル内にスタイルっぽい値 (`Color(0x`, `EdgeInsets.`, `BorderRadius.`
  等) が直書きされていないか、custom lint で検出する
- **スキャフォールディング**: 新規ページを作るときに 2 ファイルを同時生成する CLI を用意する
- **`New Token Candidate` 集約**: TODO コメントを週次でスキャンして、Token 昇格候補をまとめる
