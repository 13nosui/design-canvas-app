# ADR-0007: ImportPage の state 管理を `ChangeNotifier` controller で分離

- **Status**: Accepted
- **Date**: 2026-04-09
- **Deciders**: 13nosui

## Context

ADR-0006 で payload-as-truth を採択し、ImportPage が編集可能な「真実源」を
抱える役割を持った。最初は `_ImportPageState` の中に直接フィールドを並べて
実装したが、以下の症状が出た:

1. **ファイル肥大化**: `import_page.dart` が 862 行を超え、ルール違反 (>800)
2. **責務の混線**: UI 組み立て (build) と mutation ロジック (editAtPath /
   addScreen / removeScreen ...) が同居
3. **テスト困難性**: 全ての mutation が `setState()` 呼び出し + Flutter
   bindings に依存するため、widget test でないと実行できない
4. **Undo/Redo の追加が重い**: snapshot / history stack / notifier が
   State の雑多なフィールドに埋もれる

本プロジェクトは既存の canvas editor (`design_canvas_page.dart`) も
巨大な StatefulWidget で同じ症状を抱えている (1944 行)。同じ轍を踏まない
ために、ImportPage の段階で明確な分離パターンを定めたい。

候補:

### A. 現状のまま (StatefulWidget に全部を詰める)
Flutter の入門的アプローチ。シンプルだが、上記 4 症状が再発する。

### B. `ChangeNotifier` controller を別ファイルに切り出す (本 ADR の選択)
`ImportPayloadController extends ChangeNotifier` に state と mutation を
移し、Widget 側は `addListener(() => setState(() {}))` で rebuild する
だけの薄い層にする。CLAUDE.md の dart/patterns.md にも記載されている
Provider + ChangeNotifier 方式の控えめ版。

### C. Riverpod / Bloc / Provider 本格導入
より大きな依存と学習コスト。現時点では過剰。

### D. `setState` + InheritedWidget + 手書き Notifier
Flutter 低レベル API だけで実装。学習価値はあるがメリットが薄い。

## Decision

**Option B — `ChangeNotifier` ベースの controller を採用する**。

具体的には `apps/mobile/lib/presentation/pages/import_payload_controller.dart`
に `ImportPayloadController extends ChangeNotifier` を配置し、以下を所有
させる:

- `Map<String, dynamic>? payload` (所有)
- `bool dirty` (派生状態)
- `List<Map<String, dynamic>> _undoStack / _redoStack` (bounded 30)
- `bool canUndo / canRedo` (派生状態)

提供するメソッド:
- `editAtPath(List<Object> path, String newValue)` — path-based ネスト編集
- `addScreen / removeScreen / addSection / removeSection`
- `addApi / removeApi / addStack / removeStack / addRisk / removeRisk`
- `addMeta / removeMeta / cycleMetaColor`
- `startBlank()` — テンプレートからの新規作成
- `undo() / redo()`
- `exportAsJson() / importFromJson(String)`
- 内部: `_pushHistory()`, `_persistToUrl()`, `_deepClone()`

ImportPage (`_ImportPageState`) 側は:

```dart
class _ImportPageState extends State<ImportPage> {
  late final ImportPayloadController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ImportPayloadController(_decodePayload(...));
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }
}
```

UI 層は `_controller.payload`, `_controller.canUndo`, `_controller.editAtPath`
... を参照するだけ。mutation は全て controller 側で実装され、
widget は「表示 + callback 配線」の責務だけを持つ。

## Consequences

### Good
- **import_page.dart が 862 → 553 行に削減** (約 36%)。
  ルール違反解消に加え、build 関数の可読性が大幅に改善
- **pure Dart で controller を unit test できる**: `flutter_test` で
  widget を起こさず、`Map<String, dynamic>` 操作だけを検証。
  `import_payload_controller_test.dart` が 38 ケースで網羅
- **Undo/Redo が「加えるだけ」で成立**: 各 mutation の先頭で
  `_pushHistory()` を呼べば済む統一パス
- **ADR-0006 の「payload is truth」の実装に適合**: controller が payload を
  所有し、外部は editAtPath 経由でしか触れない → 一貫した mutation パス
- **URL 永続化が controller 内で閉じる**: `_persistToUrl()` が全ての
  mutation 経路の末端で呼ばれる。Widget 側は永続化を気にしなくて良い
- **将来 Provider / Riverpod に昇格するときも移行容易**: すでに
  ChangeNotifier インターフェースなので `ChangeNotifierProvider` に
  包むだけ

### Bad (trade-offs)
- **setState の二重発火リスク**: controller が `notifyListeners()` し、
  そのリスナーが `setState()` する。現状は冗長だが危険ではない
  (Flutter 側がフレームをまとめる)。将来的には ListenableBuilder
  で更に薄くできる
- **dispose 順序の注意点**: `removeListener` → `dispose` の順を守る
  必要あり (片方忘れると leak)
- **widget に controller を渡す境界が 1 箇所増えた**: 学習コスト
- **既存の canvas editor とは不統一**: `design_canvas_page.dart` は
  依然として StatefulWidget 直書きパターン。統一するには大きな refactor

## Alternatives considered

1. **A. StatefulWidget に直書き**
   - 却下: 本 ADR の動機そのもの
2. **C. Riverpod / Bloc 導入**
   - 却下: MVP に過剰。依存を増やさず ChangeNotifier で足りる
3. **D. InheritedWidget で生書き**
   - 却下: ボイラープレートが ChangeNotifier より多い
4. **E. `ValueNotifier<Map>`**
   - 却下: map 単位の置換しか notify できず、undo/redo や
     `_pushHistory` のような副次処理を重ねにくい
5. **Immer 風の immutable state + copyWith**
   - 保留: freezed 導入が必要。将来の選択肢としては残す。現状は
     deep-clone via JSON round-trip で十分速い (payload は小さい)

## Related

- Files
  - `apps/mobile/lib/presentation/pages/import_payload_controller.dart`
    (398 行 — 本 ADR の実装)
  - `apps/mobile/lib/presentation/pages/import_page.dart`
    (753 行 — Widget 層、controller を購読)
  - `apps/mobile/test/presentation/import_payload_controller_test.dart`
    (38 ケース)
- ADRs
  - [ADR-0006](./0006-payload-as-truth.md) — 本 ADR の動機
  - [ADR-0005](./0005-component-file-separation.md) — `.dart` / `.styles.dart`
    分離との相補関係
- Commits
  - `c0ddb8f feat(mobile): Undo/Redo + ImportPayloadController の State/UI 分離`
  - `54f5094 test(mobile): ImportPayloadController の unit tests (26 ケース)`
  - `57d9e20 test(mobile): meta 編集 + JSON export/import のテスト 12 ケース`

## Future considerations

- **Canvas editor (`design_canvas_page.dart`) への同じパターン適用**:
  現在 1944 行を単一 State に詰め込んでいる。AST 編集・inspector 状態・
  canvas transform を個別の controller に分けることを検討
- **`ListenableBuilder` / `AnimatedBuilder` で更に薄く**: 現状の
  `addListener(() => setState(() {}))` は冗長。Flutter 3.x 以降の
  `ListenableBuilder` で Widget 階層を直接 rebuild 範囲に限定できる
- **Record / sealed event pattern**: 将来 mutation を history として
  時系列記録したいなら、sealed class `PayloadEvent` を追加して
  controller を event sourcing 化できる
