# ADR-0001: モノレポによる React + Flutter の dual-stack 採用

- **Status**: Accepted
- **Date**: 2026-04-08
- **Deciders**: 13nosui

## Context

プロダクトビジョン (VISION.md) は「プロンプト → プロトタイプ → コードが真実」の
一筆書きな体験を目指している。この体験は性質の異なる 2 つの体験から成る:

1. **生成体験**: PdM / デザイナーが言葉でアイデアを書き、即座に視覚化される
   - 必要なのは: 軽量な Web UI、速い HMR、LLM ストリーミング、広い配布性
2. **編集体験**: デザイナーがキャンバス上でコンポーネントを直接触り、AST 経由で
   コードファイルが書き換わる
   - 必要なのは: リッチな GUI、分析容易なコード構造、ネイティブ品質の描画、
     ローカルファイル I/O

この 2 つの要件は 1 つのスタックで両立しにくい。React に全振りするとキャンバス編集の
"コードと視覚の一体感" を作りにくく、Flutter に全振りすると Web ホスティングの軽さと
Tailwind 的な即時 UI 組成を失う。

## Decision

**モノレポ (npm workspaces) 上に 2 つのスタックを並置する**:

```
design_canvas_app/
├── packages/
│   └── prototype_engine/   # React + Vite + Tailwind
└── apps/
    └── mobile/             # Flutter (Web/iOS/Android/macOS)
```

- デプロイは Vercel 上の **2 プロジェクト** に分離
  - `design-canvas-project` ← prototype_engine
  - `design-canvas-flutter` ← apps/mobile
- GitHub 連携は **同一リポジトリ** (`13nosui/design-canvas-app`)、Root Directory で分離
- 両者の連携は URL 経由のデータハンドオフで行う (ADR-0004)

## Consequences

### Good
- 各スタックの長所を活かせる。React は生成 UI と LLM 連携、Flutter はキャンバス編集
- デザイナーが「モバイル含む多デバイスでキャンバスを触れる」Flutter Web のメリットを得る
- 2 つの Vercel プロジェクトが独立してスケール・デプロイされる
- 片側のビルド失敗が他側に波及しない
- 両者の実装差分が VISION の 2 体験の差を可視化している

### Bad (trade-offs)
- デザイントークンを 2 回定義する必要がある (Tailwind 側と `AppTokens` 側)
  - 将来的に SSoT の JSON からコード生成する余地あり
- 2 言語・2 ビルド体系 (Node / Dart) を扱う認識負荷
- Flutter Web ビルドが遅い (初回 ~5 分、Flutter SDK clone 含む)
- クロスプロジェクトの型共有ができない (スキーマは二重定義 or 慣習)

## Alternatives considered

1. **React 単一**
   - 却下: Flutter の AST ベース編集エンジンと同等のものを Web で作るのは巨大な工数。
     `analyzer` パッケージ相当の Dart の静的解析を JS で再実装する必要がある
2. **Flutter 単一**
   - 却下: 生成 UI の即時性 (Vite HMR, Tailwind) と、Web 配布の軽さを失う。
     LLM ストリーミング + React 風 UI 組成の手軽さも諦めることになる
3. **Next.js Turborepo 統合**
   - 却下: Flutter のネイティブ描画・AST 編集を活かせない
4. **別リポジトリに分離**
   - 却下: 両側にまたがる変更 (e.g. ハンドオフ仕様変更) のコストが跳ね上がり、
     VISION の「思考の直結」が分断される

## Related

- Files
  - `package.json` (npm workspaces ルート)
  - `packages/prototype_engine/`
  - `apps/mobile/`
  - `CLAUDE.md` (モノレポ構造セクション)
- Commits
  - `815470a feat: Initialize AI-driven monorepo for world-wide development platform`
- Vercel Projects
  - `design-canvas-project` (prototype_engine)
  - `design-canvas-flutter` (apps/mobile)
