# Session Notes

各自律開発セッションの成果と、次セッションで参照すべき状態を時系列で記録する。
新しい会話を開くときは最新のエントリを読んでから作業を始めるとスムーズ。

## 2026-04-10 — CanvasEditorController 抽出 + Canvas in-memory route registry

### サマリ
`design_canvas_page.dart` (1112 行) から inspector / AST mutation 系ロジックを
`CanvasEditorController` (ChangeNotifier) + `CanvasInspectorClient` (HTTP 抽象) +
`canvas_theme_exporter.dart` に分離。ADR-0007 の controller パターンを Canvas 側にも適用。
`design_canvas_page.dart` は **791 行** となり、全ファイルが 800 行ルールを達成。

### 抽出ファイル
| ファイル | 行数 | 概要 |
|---|---|---|
| `canvas_editor_controller.dart` | 218 | ChangeNotifier — inspector state + 8 AST mutation メソッド + event stream |
| `canvas_inspector_client.dart` | 206 | Abstract interface + HTTP impl — テスト可能 |
| `canvas_theme_exporter.dart` | 73 | テーマ codegen export を free function に分離 |

### テスト
| ファイル | ケース数 |
|---|---|
| `canvas_editor_controller_test.dart` | 17+ ケース |
| `import_payload_controller_test.dart` | 44+ ケース (既存) |

`FakeCanvasInspectorClient` で pure Dart テスト。`flutter test` はローカル SDK が古いため Vercel CI でのみ実行可能。`dart analyze` は全ファイル warning 0。

### Canvas in-memory route registry
`CanvasVirtualPages` (ChangeNotifier) を `ChangeNotifierProvider` で全体に提供。
ImportPage の「キャンバスに取り込む」シートに **「キャンバスに送る」** ボタンを追加。
- `addFromPayload()` で payload → `GeneratedPagePreview` ベースの仮想 `AppRouteDef` を生成
- 同一プロジェクト slug は上書き (idempotent)
- `design_canvas_page.dart` は `context.watch<CanvasVirtualPages>()` でリアクティブに再描画
- テスト: `canvas_virtual_pages_test.dart` 14+ ケース

### localStorage 永続化
- Virtual routes: `canvas_virtual_payloads` キーで payload を保存・復元
- テーマスライダー: `canvas_theme_state` キーで全スライダー値を保存・復元
- `local_storage_stub.dart` / `local_storage_html.dart` の conditional import パターン

### 本日のコミット
| コミット | 内容 |
|---|---|
| `b8fff85` | CanvasEditorController 抽出 (1112→788行) |
| `41bc916` | Canvas in-memory route registry |
| `39a29a8` | Virtual routes を localStorage で永続化 |
| `65a8636` | テーマスライダー状態を localStorage で永続化 |

### 次セッションの最初のタスク候補 (優先順)

1. **Widget 層テスト拡充**
   - `EditableField` タップ → dialog → onChanged の一連
   - `ScreensList` add / remove / reorder の widget test
2. **Flutter SDK upgrade** — ローカルでもテスト実行できるようにする
3. **Canvas ↔ ImportPage 双方向ナビゲーション** — Canvas 上の仮想ルートをタップで ImportPage に戻り再編集

---

## 2026-04-08 〜 2026-04-09 — ImportPage 編集ループ完成 + Canvas 分割

### サマリ
payload-as-truth モデル (ADR-0006) を実装に落とし込み、ImportPage を
React からハンドオフされた payload の **編集可能な真実源** にした。
編集可能性 100% + Undo/Redo + URL 永続化 + Live Preview + JSON I/O。
併せて ADR-0007 で ChangeNotifier controller パターンを正式化し、
`CanvasEditorController` への展開を将来への宿題として位置付け。

### 主要コミット (時系列)

#### ImportPage を編集可能に
- `f514c69` ImportPage を Stateful 化 + tap-to-edit
- `4838e1f` URL 永続化 (base64url を `history.replaceState` で書き戻す)
- `cf026cd` screens / sections の add/remove + 確認ダイアログ
- `38b8211` apis / stack の add/remove
- `e8ca781` userFlow / risks の add/remove
- `66ff89e` meta バッジ (色循環)
- `178b398` icon 絵文字
- `d57d852` from-scratch モード (空 payload テンプレート)
- `36cdbce` screen 複製
- `d2cf378` screen up/down 並び替え
- `228fd98` section up/down 並び替え

#### 状態管理
- `c0ddb8f` `ImportPayloadController extends ChangeNotifier` に state 抽出
- `c516f4c` Cmd/Ctrl+Z / Shift+Z キーボードショートカット
- `a6a3b23` JSON export / import

#### テスト
- `54f5094` controller 初期 26 ケース
- `57d9e20` meta + JSON round-trip 12 ケース
- 最終: controller テスト 44+ ケース (pure Dart、flutter test で走る)

#### design_canvas_page.dart 段階的分割
| コミット | 削減 | 抽出先 |
|---|---|---|
| `b3b40a2` (過去) | 2561→1944 | `theme_codegen.dart`, `sitemap_painter.dart` |
| `2a5ef3f` | 1944→1828 | `canvas_inspector_panel.dart` |
| `f758f97` | 1828→1722 | `canvas_commit_dialog.dart`, `canvas_decor.dart` |
| `0611a3b` | 1722→1608 | `canvas_device_preview.dart` |
| `abbd669` | 1608→1112 | `canvas_live_editor_panel.dart` ← 最大抽出 |

### ドキュメント
- `ADR-0006` Payload as truth, code as derivative
- `ADR-0007` ChangeNotifier controller pattern
- README を feature matrix 形式に更新
- CLAUDE.md に ImportPage フロー追記

### 本日の Flutter デプロイ最終状態
`https://design-canvas-flutter-13nosuis-projects.vercel.app/` — 全機能 Ready

### 次セッションの最初のタスク候補 (優先順)

1. **`CanvasEditorController` 抽出** (最推奨)
   - 対象: `_updateCodeText`, `_wrap`, `_unwrap`, `_duplicate`, `_insert`,
     `_loadInspector`, `_updateStyleField`, `_promoteToken`
   - ImportPayloadController と同じ `ChangeNotifier` パターン
   - これで `design_canvas_page.dart` が 800 行ルールを達成予定
   - pure Dart テストを同時に書ける

2. **Canvas in-memory route registry**
   - ImportPage で生成した payload を canvas が直接表示できるように
   - 現状: 手動ファイル書き込み + `scanned_routes` 再生成が必要
   - 設計: `CanvasVirtualPages` (ChangeNotifier) を `design_canvas_page` と
     ImportPage の両方から参照

3. **Widget 層のテスト拡充**
   - 現状 controller は pure 関数テストのみ
   - `EditableField` タップ → dialog → onChanged の一連
   - `ScreensList` の add / remove / reorder の widget test

### 事故防止メモ
- `EditableText` というクラス名は Flutter の built-in と衝突する
  (本セッションで一度ビルドエラー経験済み `8868aa5` で `EditableField`
  にリネーム)
- ローカル Flutter SDK は古くて `google_fonts ^8.0.2` を resolve できない
  ため、`flutter analyze` / `flutter test` は Vercel 側 (newer Flutter)
  でしか実行できない
- 大規模 refactor は context 末尾で走らせない。新セッションで取り組む

### ファイルサイズ snapshot (800 行ルール)
| ファイル | 行数 | 状態 |
|---|---|---|
| `design_canvas_page.dart` | 791 | ✅ |
| `import_page.dart` | 797 | ✅ |
| `import_page_editors.dart` | 675 | ✅ |
| `canvas_live_editor_panel.dart` | 559 | ✅ |
| `import_payload_controller.dart` | 449 | ✅ |
| `import_page_sheet.dart` | 331 | ✅ |
| `canvas_editor_controller.dart` | 218 | ✅ |
| `canvas_inspector_client.dart` | 206 | ✅ |
| `canvas_inspector_panel.dart` | 181 | ✅ |
| `canvas_device_preview.dart` | 159 | ✅ |
| `canvas_commit_dialog.dart` | 128 | ✅ |
| `canvas_theme_exporter.dart` | 73 | ✅ |
| `canvas_decor.dart` | 20 | ✅ |
