# Design Canvas

> **Prompt your idea. See it live. Edit the truth.**
> A universal development platform where any team — anywhere in the world — can go from concept to working code using only natural language.

---

## The Problem

Building software today still means translating the same idea three times:
**words → wireframes → code.**

Each translation loses fidelity, momentum, and meaning.
Complex challenges — mental health, education, accessibility — deserve faster iteration than the current toolchain allows.

## The Vision

**Design Canvas** collapses the gap between intention and implementation.

A PdM types a prompt. A working layout appears.
A designer refines it with words, not pixels.
An engineer ships it — clean, tested, and traceable.

No Figma handoff. No boilerplate. No translation cost.

---

## The Loop (as of 2026-04-09)

```
┌─────────────────┐      ┌──────────────┐      ┌──────────────────┐
│  React          │      │  Flutter     │      │  Generated code  │
│  Prototype      │─────▶│  ImportPage  │─────▶│  .dart + .styles │
│  Engine         │ URL  │  (editable)  │ live │  .dart pair      │
└─────────────────┘      └──────────────┘      └──────────────────┘
         ▲                       │
         │                       │
         └── payload is the truth ┘
         (reload-safe, URL-shareable, undo/redo)
```

**プロンプト → プロトタイプ → コードが真実** の一筆書き。

Web でも desktop でも、編集ループが閉じます。

---

## Live Demos

- **React Prototype Engine**: https://design-canvas-project-13nosuis-projects.vercel.app/
- **Flutter Canvas + ImportPage**: https://design-canvas-flutter-13nosuis-projects.vercel.app/

---

## Feature Matrix

### React prototype_engine

- [x] プロンプト → Claude Haiku 4.5 でカード生成 (Vercel AI Gateway, NDJSON stream)
- [x] カードクリックで詳細生成 (screens, userFlow, apis, stack, risks)
- [x] 各 screen に固有の `sections[]` (Claude が画面ごとに異なる構造を返す)
- [x] DetailDrawer でハンドオフ先 URL 生成 (base64url payload)

### Flutter ImportPage (編集の真実)

- [x] base64url URL を読み取り payload 復元
- [x] **全フィールド編集可能**: title / icon / summary / screens / sections / apis / stack / userFlow / risks / meta
- [x] meta バッジは palette アイコンで色を 4 色循環 (green / blue / yellow / slate)
- [x] structural edits: add/remove screens / sections / apis / stack / risks / meta
- [x] **Undo / Redo** (30 ステップ履歴、AppBar ボタン)
- [x] **URL に自動永続化** — reload しても編集保持、URL コピーで共有可能
- [x] **Live Preview** panel — 編集中に PhoneFrame で live 更新
- [x] **from-scratch mode** — URL なしでアクセスすると「新規作成」ボタン
- [x] 編集 → `.dart` + `.styles.dart` pair を bottom sheet で preview / コピー
- [x] Desktop 実ファイル書き込み (`lib/presentation/generated/...`)

### Flutter Canvas Editor

- [x] Multi-device preview (iPhone 15 / Pixel 7 / all)
- [x] `analyzer` ベースの AST 書き換え (Wrap / Unwrap / Insert / Duplicate)
- [x] Property inspector → `.styles.dart` 定数を live 書き換え
- [x] `AppTokens` トークンシステム + `Promote to Token` UX
- [x] 生成テーマファイルのエクスポート (Web: クリップボード、desktop: 直接書き込み)

---

## Architecture Highlights

### Payload as Truth (ADR-0006)

ImportPage は **payload (Map) を編集の単一真実源** とし、`.dart` + `.styles.dart`
はそこから決定論的に derive されます。

```
payload (Map) ── editAtPath ──▶ setState + URL 永続化
    │
    ├─▶ generatePagesFromPayload() ──▶ .dart + .styles.dart 文字列
    │
    └─▶ GeneratedPagePreview() ──▶ Live Flutter Widget
                                     (codegen と lockstep)
```

この設計で:
- Flutter Web で完全に動く (ファイルシステム不要)
- Undo/Redo は payload のスナップショットだけで済む
- URL 共有 = 編集済み状態の共有

### Component File Separation (ADR-0005)

Flutter の全コンポーネントは `{name}.dart` (骨格) + `{name}.styles.dart` (視覚定数)
の 2 ファイルに分割。Canvas editor はスタイルのみを AST 書き換えるので、
レイアウト構造を壊さず安全に視覚を編集できます。

### Full ADR index

`docs/adr/` に 6 本:

| # | Title |
|---|---|
| [0001](./docs/adr/0001-monorepo-dual-stack.md) | React + Flutter のモノレポ dual-stack |
| [0002](./docs/adr/0002-ai-gateway-structured-output.md) | LLM = Vercel AI Gateway + `Output.object` |
| [0003](./docs/adr/0003-ndjson-streaming.md) | NDJSON ストリーミング契約 |
| [0004](./docs/adr/0004-handoff-base64url.md) | base64url URL ハンドオフ |
| [0005](./docs/adr/0005-component-file-separation.md) | `.dart` + `.styles.dart` 分離 |
| [0006](./docs/adr/0006-payload-as-truth.md) | Payload を編集の真実源に |

---

## Monorepo Structure

```
design_canvas_app/
├── apps/
│   └── mobile/                  # Flutter canvas + ImportPage
│       └── lib/
│           ├── core/
│           │   ├── design_system/
│           │   │   ├── tokens.dart            # AppTokens
│           │   │   └── codegen/
│           │   │       ├── theme_codegen.dart   # テーマファイル生成
│           │   │       ├── page_codegen.dart    # ページファイル生成
│           │   │       └── page_preview.dart    # lockstep Live Widget
│           │   └── utils/
│           │       ├── page_file_exporter_*.dart  # desktop 書き込み
│           │       └── url_updater_*.dart         # Web URL 永続化
│           └── presentation/
│               ├── pages/
│               │   ├── design_canvas_page.dart    # Canvas editor (AST 書き換え)
│               │   ├── import_page.dart           # ImportPage widget shell
│               │   ├── import_payload_controller.dart  # 状態 + undo/redo
│               │   ├── import_page_editors.dart   # EditableField, ScreensList, ApisList, StackChips
│               │   ├── import_page_sheet.dart     # Bottom sheet (Preview / Code tabs)
│               │   └── import_page_live_preview.dart
│               └── widgets/
│                   ├── property_field_editor.dart
│                   └── sitemap_painter.dart
├── packages/
│   └── prototype_engine/        # React + Tailwind
│       ├── api/
│       │   ├── generate.js      # カード生成 (Claude)
│       │   └── elaborate.js     # 詳細生成 (Claude)
│       └── src/
│           ├── components/
│           │   ├── CommandBar.jsx
│           │   ├── Badge.jsx
│           │   └── DetailDrawer.jsx   # ハンドオフ URL 生成
│           └── lib/
│               └── generate.js        # NDJSON stream helper
├── docs/adr/                    # Architecture Decision Records
├── VISION.md
├── CLAUDE.md
└── README.md
```

---

## Getting Started

### Prototype Engine (React + Tailwind)

```bash
cd packages/prototype_engine
npm install
npm run dev              # Vite dev server

# Production build
npm run build
```

local AI Gateway access requires `vercel env pull` for `VERCEL_OIDC_TOKEN`
(12h valid). 詳細は `packages/prototype_engine/.env.example`.

### Canvas Editor + ImportPage (Flutter)

```bash
cd apps/mobile
flutter pub get
flutter run              # または -d chrome / -d macos

# テスト
flutter test
flutter test test/codegen/page_codegen_test.dart
flutter test test/presentation/import_payload_controller_test.dart

# Web ビルド (Vercel 用)
flutter build web --release

# Canvas で生成コードを書き出した後は scanned_routes を再生成
dart scripts/generate_sitemap_widgets.dart
```

---

## Core Principles

| Principle | What it means |
|---|---|
| **思考の直結 / AI-Native Structure** | Loosely coupled architecture that AI can read and humans can verify |
| **Traceable Decisions** | Every non-obvious choice links to an ADR in `docs/adr/` |
| **Zero Technical Debt** | Tests ship with every implementation, always deployable |

---

## Test Coverage (relevant to recent work)

- `test/codegen/page_codegen_test.dart` — 27+ ケース
  - slugify / pascalCase / screen generation / rich content
  - sections / meta / apis / stack 各セクション
- `test/presentation/import_payload_controller_test.dart` — 26 ケース
  - editAtPath (ネスト path)
  - undo / redo (bounded 30, deep-clone 独立性)
  - structural mutations (add/remove)
  - startBlank, dispose

---

## Built With

- [Flutter](https://flutter.dev) — Cross-platform canvas editor + ImportPage
- [React](https://react.dev) + [Tailwind CSS](https://tailwindcss.com) — Prototype generation engine
- [Vercel AI SDK v6](https://sdk.vercel.ai) — `streamText` + `Output.object` + `gateway()`
- [Vercel AI Gateway](https://vercel.com/docs/ai-gateway) — OIDC 認証で Claude Haiku 4.5 に接続
- [Vite](https://vitejs.dev) — React 側のビルド

---

## Next Milestones

- [ ] Canvas editor が ImportPage の生成ページを in-memory で直接表示 (現在は手動ファイル書き込み + scanned_routes 再生成が必要)
- [ ] Flutter → React 逆方向ハンドオフ (canvas の状態を React へ返す)
- [ ] `design_canvas_page.dart` のさらなる分割 (1944 行 → < 800)
- [ ] Widget test の拡充 (ImportPage UI、bottom sheet 含む)
- [ ] Flutter Web の CSP と SPA fallback の強化

---

*This project is an open prototype. The goal: become the standard foundation for AI-driven product development worldwide.*
