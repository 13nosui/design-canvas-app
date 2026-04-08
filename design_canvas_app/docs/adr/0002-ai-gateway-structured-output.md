# ADR-0002: LLM 呼び出しに Vercel AI Gateway + `Output.object` を採用

- **Status**: Accepted
- **Date**: 2026-04-08
- **Deciders**: 13nosui

## Context

`prototype_engine` は、ユーザーのプロンプトから **プロジェクトカードを生成** する
機能を中核に置く。この機能の要件:

1. **構造化された出力**: `{title, icon, summary, meta[3]}` の形で返ってこないと
   クライアント側のレンダリングが破綻する
2. **ハルシネーション耐性**: schema を無視した出力が返ってくるとゴーストカードが
   復帰できない (UX 破綻)
3. **ストリーミング**: 体感として "思考が結晶化する" 感覚を出したい (ADR-0003)
4. **観測性**: VISION 原則 2 (Traceable Decisions) は「なぜこのコードになったか」を
   追跡可能であることを要求する。LLM 呼び出しのログ・コスト・レイテンシを見たい
5. **認証管理の負荷最小化**: 個人開発なので API キーのロテーションを手動でやりたくない

候補としてあった選択肢:
- `@anthropic-ai/sdk` 直接
- Vercel AI SDK (`ai` package) + 直接プロバイダ
- Vercel AI SDK + Vercel AI Gateway
- 他社 SDK (OpenAI, Gemini, ...)

## Decision

**Vercel AI SDK v6** の `generateText` (および `streamText`) に **`Output.object(zod schema)`**
を組み合わせ、プロバイダとして **Vercel AI Gateway** (`gateway('anthropic/claude-haiku-4.5')`)
を指定する。

```js
import { streamText, Output, gateway } from 'ai'
import { z } from 'zod'

const cardSchema = z.object({
  title: z.string().min(1).max(20),
  icon: z.string().min(1).max(4),
  summary: z.string().min(20).max(120),
  meta: z.array(z.object({
    label: z.string(),
    color: z.enum(['green', 'blue', 'yellow', 'slate']),
  })).length(3),
})

const { partialOutputStream } = streamText({
  model: gateway('anthropic/claude-haiku-4.5'),
  system: SYSTEM,
  prompt,
  output: Output.object({ schema: cardSchema }),
})
```

- モデルは **Claude Haiku 4.5** を初期選択 (速度・コスト優先、カード生成には十分)
- 将来 Sonnet 4.6 に切り替える場合は `gateway('anthropic/claude-sonnet-4.6')` の 1 行

## Consequences

### Good
- **OIDC 自動認証**: Vercel 本番環境では API キー登録不要。ローテーション管理がゼロ
- **schema 強制**: zod schema が LLM 出力を形式的に保証 → クライアント側の防御コードが不要
- **観測性**: Gateway がリクエスト/レイテンシ/コストを自動で記録
- **プロバイダ抽象化**: モデル切替が文字列変更で済む。将来フォールバック (Claude → GPT) も容易
- **ストリーミング対応**: `partialOutputStream` が v6 ネイティブ API として提供されている
- VISION 原則 2 (Traceable Decisions) と整合
- VISION 原則 3 (Zero Technical Debt) と整合 (schema で壊れた JSON が上がってこない)

### Bad (trade-offs)
- **Vercel プラットフォームロックイン**: 別クラウドへ移行する場合は Gateway の置換が必要
- **レイテンシオーバーヘッド**: 直接呼び出しより数十 ms の Gateway ルーティングが挟まる
- **ローカル開発の手数**: `vercel env pull` で `VERCEL_OIDC_TOKEN` を .env.local に取得する
  手間がかかる (12 時間有効)
- **v6 の新しさ**: `generateObject` は deprecated、`Output.object` ベースの新 API に
  慣れる必要がある

## Alternatives considered

1. **`@anthropic-ai/sdk` 直接**
   - 却下: API キー手動管理、ロテーション、観測性の自作。VISION 原則 2 との乖離
2. **`generateObject` (v5 旧 API)**
   - 却下: v6 で deprecated 扱い。将来の SDK 更新で壊れる
3. **free-form text + `JSON.parse`**
   - 却下: schema 強制なし → ハルシネーション耐性ゼロ → UX 破綻
4. **OpenAI / Gemini**
   - 却下せず保留: Claude の日本語品質と構造化出力の安定性を初期評価で優先。Gateway を
     使っているので将来的にフォールバック先として追加可能
5. **LangChain 系フレームワーク**
   - 却下: 抽象化レイヤが厚すぎる。Vercel プラットフォームと相性の悪い依存を抱える

## Related

- Files
  - `packages/prototype_engine/api/generate.js`
  - `packages/prototype_engine/api/elaborate.js`
  - `packages/prototype_engine/.env.example`
- Commits
  - `199bd6a feat(prototype_engine): プロンプト→Claude生成を実装`
- 外部資料
  - Vercel AI SDK v6 (`node_modules/ai/docs/`)
  - Vercel AI Gateway models: `https://ai-gateway.vercel.sh/v1/models`
