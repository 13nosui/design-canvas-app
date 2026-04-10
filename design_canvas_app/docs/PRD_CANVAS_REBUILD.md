# PRD: Design Canvas リビルド

## コンセプト

**「コードを唯一の正しいものとして、自然言語で誰でもアプリがつくれる」**

Figma ライクなキャンバスですべての画面を俯瞰し、導線に矢印が自動的に付き、デザイン調整がコードに直結する。

## 5 フェーズ計画

### Phase 1: Canvas Shell リファクタ + プロジェクト一覧
> **ゴール**: canvas 状態を controller に抽出、プロジェクト一覧バーを表示

| # | タスク | 新規/変更 | リスク |
|---|--------|-----------|--------|
| 1.1 | `CanvasLayoutController` 抽出 (zoom/pan/選択状態) | 新規 | 中 |
| 1.2 | `ProjectListController` (CRUD + localStorage) | 新規 | 低 |
| 1.3 | `ProjectListBar` widget (横スクロール + プロジェクト選択) | 新規 | 低 |
| 1.4 | `design_canvas_page.dart` をシェル化 (~400行) | 変更 | 中 |
| 1.5 | `main.dart` に MultiProvider 追加 | 変更 | 低 |

**成果**: プロジェクト一覧が Canvas 上部に表示。選択でフィルタ。

---

### Phase 2: Widget パレット + ドラッグ & ドロップ
> **ゴール**: 左サイドバーに Widget 一覧、D&D でスクリーンに追加

| # | タスク | 新規/変更 | リスク |
|---|--------|-----------|--------|
| 2.1 | `WidgetPaletteController` (カテゴリ + 検索) | 新規 | 低 |
| 2.2 | `WidgetPaletteSidebar` (~240px 左パネル) | 新規 | 低 |
| 2.3 | `DropTargetOverlay` (D&D 受け入れ + payload 更新) | 新規 | 高 |
| 2.4 | サイドバートグルを toolbar に追加 | 変更 | 低 |

**成果**: 20+ Flutter Widget を D&D で画面に配置可能。

---

### Phase 3: 画面ごとの状態バリエーション
> **ゴール**: 各画面に Loading / Empty / Error ドロップダウン

| # | タスク | 新規/変更 | リスク |
|---|--------|-----------|--------|
| 3.1 | `CanvasLayoutController` に per-screen state 追加 | 変更 | 低 |
| 3.2 | `ScreenCardHeader` (状態ドロップダウン + コードボタン) | 新規 | 低 |
| 3.3 | `MockUIStateProvider` → `GeneratedPagePreview` に反映 | 変更 | 中 |

**成果**: ドロップダウンで状態切替、画面ごとに異なる状態を表示。

---

### Phase 4: Canvas ツールバー刷新
> **ゴール**: Figma 風の 3 セクションツールバー

| # | タスク | 新規/変更 | リスク |
|---|--------|-----------|--------|
| 4.1 | `CanvasToolbar` (左: サイドバー/プロジェクト名、中: デバイス/ズーム、右: テーマ/エクスポート) | 新規 | 低 |
| 4.2 | zoom in/out/fit-all メソッド追加 | 変更 | 低 |
| 4.3 | AppBar → CanvasToolbar に差し替え | 変更 | 低 |

**成果**: 洗練されたツールバー、ズームスライダー、フィットオール。

---

### Phase 5: AI コミット要約 + 仕上げ
> **ゴール**: AI がコミットメッセージを生成、ミニマップ、ショートカットヘルプ

| # | タスク | 新規/変更 | リスク |
|---|--------|-----------|--------|
| 5.1 | `CanvasCommitDialog` に AI 要約追加 | 変更 | 中 |
| 5.2 | `ShortcutHelpOverlay` (? キーで表示) | 新規 | 低 |
| 5.3 | `CanvasMinimap` (右下ミニマップ) | 新規 | 中 |

**成果**: AI コミット、ミニマップ、操作ヘルプ。

---

## 既存コード再利用

### そのまま再利用 (変更なし)
- `inspectable.dart` — Cmd+Click 選択
- `canvas_editor_controller.dart` — AST 操作
- `canvas_inspector_client.dart` — HTTP 抽象
- `page_codegen.dart` — コード生成
- `page_preview.dart` — ライブプレビュー
- `sitemap_painter.dart` — 矢印描画
- `theme_controller.dart` / `theme_persistence.dart` — テーマ管理
- `canvas_device_preview.dart` — デバイスフレーム
- `canvas_live_editor_panel.dart` — プロパティパネル
- `canvas_link.dart` — ルート間リンク

### 拡張して再利用
- `canvas_virtual_pages.dart` — プロジェクトグルーピング追加
- `canvas_commit_dialog.dart` — AI 要約ステップ追加

### 大幅変更
- `design_canvas_page.dart` — シェル化 (800→~400行)
- `main.dart` — MultiProvider 化

---

## 新規ファイル一覧 (全フェーズ)

| ファイル | フェーズ |
|----------|---------|
| `providers/canvas_layout_controller.dart` | 1 |
| `providers/project_list_controller.dart` | 1 |
| `widgets/project_list_bar.dart` + `.styles.dart` | 1 |
| `providers/widget_palette_controller.dart` | 2 |
| `widgets/widget_palette_sidebar.dart` + `.styles.dart` | 2 |
| `widgets/drop_target_overlay.dart` + `.styles.dart` | 2 |
| `widgets/screen_card_header.dart` + `.styles.dart` | 3 |
| `widgets/canvas_toolbar.dart` + `.styles.dart` | 4 |
| `widgets/shortcut_help_overlay.dart` + `.styles.dart` | 5 |
| `widgets/canvas_minimap.dart` + `.styles.dart` | 5 |
