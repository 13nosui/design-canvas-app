# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクトビジョン

このプロジェクトは「AI駆動開発の最高の手本」として構築される汎用開発基盤のプロトタイプ。詳細は [VISION.md](./VISION.md) を参照。

**すべての実装はこのビジョンに従う：**
- **思考の直結** — PdMの意図がプロンプトからプロトタイプへ直結する構造を優先する
- **AI-Native Structure** — AIが文脈を理解しやすく、人間が検証しやすい疎結合アーキテクチャを維持する
- **Traceable Decisions** — 非自明な設計判断には `docs/adr/` にADRを作成し、コードにリンクする
- **Zero Technical Debt** — 実装とテストは常にセットで生成し、デプロイ可能な状態を維持する

## モノレポ構造

```
design_canvas_app/
├── apps/
│   └── mobile/              # Flutter アプリ（デザインキャンバスエディタ）
├── packages/
│   └── prototype_engine/    # React + Tailwind（プロトタイプ生成エンジン）
├── CLAUDE.md
├── VISION.md
└── package.json             # npm workspaces ルート
```

## Commands

### prototype_engine（React + Tailwind）
```bash
cd packages/prototype_engine

npm install          # 依存関係のインストール
npm run dev          # 開発サーバー起動（Vite）
npm run build        # プロダクションビルド
npm run lint         # ESLint
```

ルートから実行する場合：
```bash
npm run dev:web      # packages/prototype_engine の dev サーバー
npm run build:web    # packages/prototype_engine のビルド
```

### mobile（Flutter）
```bash
cd apps/mobile

flutter pub get                          # 依存関係のインストール
flutter run                              # アプリ起動
flutter analyze                          # 静的解析
flutter test                             # テスト全実行
flutter test test/vrt_test.dart          # 単一テスト実行
flutter build web --release              # Webビルド（CI/Vercel用）

# pages追加・削除後にroute登録ファイルを再生成
dart scripts/generate_sitemap_widgets.dart
```

## Architecture

### prototype_engine（`packages/prototype_engine/`）

PdMのプロンプトを即座にレイアウトとして具現化するReact製のプロトタイプ生成エンジン。

**コンポーネント設計方針**: Tailwindクラスを直書きせず、各コンポーネントはスタイルを `*Class` props として受け取る。デザイナーがプロンプトから props を渡してスタイルを上書きできる疎結合設計。

**レイアウトプリセット** (`src/components/prototypes/`):
- `AppShell` — ヘッダー・サイドバー・メインエリアを含むSaaS管理画面の全体枠
- `LandingHero` — キャッチコピーとCTAを配置するヒーローセクション
- `InformationGrid` — 特徴・データ・カードを並べる可変列グリッド

### mobile（`apps/mobile/`）

Flutter製のデザインキャンバスエディタ。コンポーネントのリアルタイム視覚編集とASTベースのコード変換を担う。

**State management**: Provider（テーマ・認証・モック状態）。`CanvasSandbox` がコンポーネントプレビュー用の独立プロバイダースコープを提供。

**Routing**: GoRouterを `lib/app/router.dart` で宣言。`canvasRoutes` が全ルートのSingle Source of Truth。`lib/app/scanned_routes.dart` と `lib/core/navigation/sitemap_widgets.g.dart` は生成ファイル。`CanvasVirtualPages` (ChangeNotifier) が ImportPage から送られた仮想ルートを保持し、canvas が `canvasRoutes + virtualPages.routes` をマージ描画する。

**Design tokens**: すべてのスタイル定数は `lib/core/design_system/tokens.dart`（`AppTokens`）に集約。キャンバスエディタは `.styles.dart` ファイルを読み書きしてトークンベースの編集を適用。

**Canvas editor**: `lib/presentation/pages/design_canvas_page.dart` がメイン UI。`CanvasEditorController` (ChangeNotifier) が inspector state と 8 つの AST mutation メソッドを所有し、`CanvasInspectorClient` (abstract interface) 経由でローカル inspector サーバーと通信する (ADR-0007)。テーマ codegen export は `canvas_theme_exporter.dart` に分離。

**Import flow (React → Flutter)**: `lib/presentation/pages/import_page.dart` + `import_page_editors.dart` + `import_page_sheet.dart`。React 側で生成したプロジェクトカードを `?data=<base64url(json)>` で受け取り、payload を **編集可能な真実源** として扱う (ADR-0006)。タップで任意のフィールドを編集、screens/sections を add/remove、編集は URL に自動永続化 (Web)。「キャンバスに取り込む」→「キャンバスに送る」で `CanvasVirtualPages.addFromPayload()` を呼び、ファイル書き出し不要で Design Canvas に即座にライブプレビューを表示。従来通り `page_codegen.dart` 経由での `.dart` + `.styles.dart` ファイル書き出しも可能。

## Component File Separation（Flutter 強制規約）

`apps/mobile/` 内のすべてのコンポーネント／ページは必ず2ファイルに分割する：

- **`{name}.dart`** — レイアウト骨格（Row/Column構造）、Provider購読、イベントハンドラ。スタイル値のハードコード禁止。
- **`{name}.styles.dart`** — すべての視覚定数（`static const` / `static final`）。Provider／ビジネスロジック依存禁止。

キャンバスエディタは `.styles.dart` のみを書き換える。`.dart` ファイルはキャンバスから読み取り専用として扱われる。

## Design Token Rules（Flutter）

`.styles.dart` を書く・更新するとき：
- 対応するトークンが存在する場合は `AppTokens` の定数を参照する。
- 対応トークンがない生の値は使用しつつ、行末に `// TODO: New Token Candidate - {descriptiveName}` を付与する。

```dart
// Good
static const padding = EdgeInsets.symmetric(horizontal: AppTokens.spaceM, vertical: AppTokens.spaceS);

// 未マッピングの値
static final headerColor = Color(0xFFF3F4F6); // TODO: New Token Candidate - colorHeaderBg
```
