// Vercel Function: プロンプトから Claude Haiku でプロジェクトカードをストリーミング生成する
// Vercel 上では AI Gateway の OIDC トークンが自動注入されるため認証設定は不要。
// ローカル開発時は `vercel env pull` で .env.local に VERCEL_OIDC_TOKEN を取得する
// (12 時間有効)。
//
// レスポンスは NDJSON (改行区切り JSON) で、partial object を逐次送信する。
import { streamText, Output, gateway } from 'ai'
import { z } from 'zod'

const cardSchema = z.object({
  title: z.string().min(1).max(20).describe('プロジェクト名 (10 文字程度)'),
  icon: z.string().min(1).max(4).describe('1 つの絵文字'),
  summary: z.string().min(20).max(120).describe('30〜70 文字の日本語のサービス概要'),
  meta: z
    .array(
      z.object({
        label: z.string().describe('「ロール: 状態」の短い日本語 (例: PdM: 仕様調整中)'),
        color: z.enum(['green', 'blue', 'yellow', 'slate']),
      })
    )
    .length(3)
    .describe('PdM / Design / Eng の進捗ステータスを 3 件'),
})

const SYSTEM = `あなたはプロダクトデザイナーの相談相手です。
ユーザーの一行プロンプト (新しいプロダクトのアイデア) を読み取り、
プロジェクトカードのデータを生成してください。

color の意味:
- green: 完了
- blue: 進行中
- yellow: 課題あり / 検討中
- slate: 未着手

プロダクトの性質に応じて 3 ロール (PdM / Design / Eng) の状態の組み合わせを自然に変えてください。
すべて完了状態にする必要はありません。`

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST')
    res.status(405).json({ error: 'Method not allowed' })
    return
  }

  const prompt = req.body?.prompt
  if (typeof prompt !== 'string' || !prompt.trim()) {
    res.status(400).json({ error: 'prompt (string) is required' })
    return
  }

  res.setHeader('Content-Type', 'application/x-ndjson; charset=utf-8')
  res.setHeader('Cache-Control', 'no-cache, no-transform')
  res.setHeader('X-Accel-Buffering', 'no')

  try {
    const { partialOutputStream } = streamText({
      model: gateway('anthropic/claude-haiku-4.5'),
      system: SYSTEM,
      prompt: prompt.trim(),
      output: Output.object({ schema: cardSchema }),
    })

    for await (const partial of partialOutputStream) {
      res.write(JSON.stringify(partial) + '\n')
    }
    res.end()
  } catch (error) {
    console.error('[api/generate] failure', error)
    const message = error instanceof Error ? error.message : 'Generation failed'
    if (!res.headersSent) {
      res.status(500).json({ error: message })
    } else {
      res.write(JSON.stringify({ error: message }) + '\n')
      res.end()
    }
  }
}
