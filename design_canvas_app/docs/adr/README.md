# Architecture Decision Records

このディレクトリはプロジェクトの **非自明な設計判断** を記録する場所。
VISION.md の原則 2 「Traceable Decisions」の実装である。

> すべての実装に、その背景 (ADR: Architecture Decision Record) がドキュメントとして
> 紐付いている状態を保つ。なぜそのコードになったのかが常に追跡可能であること。
> — VISION.md

## ルール

- **1 つの判断 = 1 つのファイル**
- ファイル名: `NNNN-short-kebab-case-title.md` (4 桁連番)
- 新しい ADR を書いたら連番をインクリメント
- 一度 **Accepted** にした ADR は **書き換えない**。取り消すときは新しい ADR で Supersedes する
- 判断の "What / When / How" ではなく **"Why"** を書く。今の状態はコードが記述している
- 却下した選択肢 (Alternatives considered) こそ価値がある情報

## 構造

各 ADR は次の見出しを持つ:

1. **Status** — Proposed / Accepted / Deprecated / Superseded by NNNN
2. **Context** — なぜこの判断が必要だったか、制約は何か
3. **Decision** — 何を選んだか、どう実装したか
4. **Consequences** — Good / Bad のトレードオフを正直に
5. **Alternatives considered** — 却下した選択肢と理由
6. **Related** — 関連ファイル・コミット・外部資料

## 一覧

| # | タイトル | Status |
|---|---|---|
| [0001](./0001-monorepo-dual-stack.md) | モノレポによる React + Flutter の dual-stack | Accepted |
| [0002](./0002-ai-gateway-structured-output.md) | LLM 呼び出しに Vercel AI Gateway + `Output.object` | Accepted |
| [0003](./0003-ndjson-streaming.md) | React ↔ Vercel Functions 間の NDJSON ストリーミング契約 | Accepted |
| [0004](./0004-handoff-base64url.md) | React → Flutter ハンドオフに base64url URL パラメータ | Accepted |
| [0005](./0005-component-file-separation.md) | Flutter コンポーネントの `.dart` + `.styles.dart` 分離 | Accepted |
| [0006](./0006-payload-as-truth.md) | Handoff payload を "編集の真実" とし、生成コードを derive する | Accepted |
| [0007](./0007-controller-pattern.md) | ImportPage の state を `ChangeNotifier` controller で分離 | Accepted |

## 新しい ADR を書くタイミング

次のいずれかに該当する判断は ADR にする:

- 複数の妥当な選択肢から 1 つを選んだ
- トレードオフを許容する判断 (何かを諦めて何かを得た)
- 将来の開発者が「なぜこうなっているのか」と疑問を持ちそう
- プロジェクト全体のアーキテクチャに影響する
- 外部依存の選定 (フレームワーク、SDK、API プロバイダ)
- セキュリティやプライバシーに関わる判断

次のものは ADR **不要**:

- コーディングスタイル (linter / formatter の責務)
- 一時的なハック (コメントで十分)
- 明らかに "これ以外なかった" 選択
