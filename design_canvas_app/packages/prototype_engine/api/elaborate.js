// Vercel Function: 既存のプロジェクトカードを Claude が深堀りする
// 入力: title, summary, prompt (元の生成プロンプト) → 構造化詳細を NDJSON でストリーミング
import { streamText, Output, gateway } from 'ai'
import { z } from 'zod'

const detailSchema = z.object({
  screens: z
    .array(
      z.object({
        name: z.string().describe('画面名 (短く具体的に)'),
        purpose: z.string().describe('その画面が果たす役割 (1 文)'),
      })
    )
    .min(3)
    .max(5)
    .describe('主要画面 3〜5 件'),
  userFlow: z
    .string()
    .min(40)
    .max(280)
    .describe('代表的なユーザーフローを 1 段落で描写'),
  apis: z
    .array(
      z.object({
        name: z.string().describe('API/エンドポイント名 (例: GET /users/:id)'),
        description: z.string().describe('そのエンドポイントが返すもの / やること'),
      })
    )
    .min(3)
    .max(5)
    .describe('必要な API/エンドポイント 3〜5 件'),
  stack: z
    .array(z.string())
    .min(3)
    .max(6)
    .describe('技術スタック候補 3〜6 件 (フロント / バック / インフラ)'),
  risks: z
    .array(z.string())
    .min(2)
    .max(4)
    .describe('プロダクト特有の主要リスクや論点 2〜4 件'),
})

const SYSTEM = `あなたはプロダクトデザイナー兼テックリードです。
ユーザーが既に生成したプロジェクトカード (タイトル・概要・元プロンプト) を読み取り、
そのプロダクトを実装するための詳細を構造化された形で生成してください。

各セクションは現実味のある具体性を持たせてください:
- screens: 実際にチームが画面リストを書くときに使えるレベル
- userFlow: 「ユーザーは X して、Y して、Z する」のようにアクションが見える描写
- apis: REST 風の表記を推奨。ドメインに合わせて命名
- stack: モダンで現実的な選択肢。理由は不要
- risks: 技術負債・倫理・スケール・ユーザー体験など、観点を散らす`

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST')
    res.status(405).json({ error: 'Method not allowed' })
    return
  }

  const { title, summary, prompt } = req.body || {}
  if (typeof title !== 'string' || typeof summary !== 'string') {
    res.status(400).json({ error: 'title and summary (string) are required' })
    return
  }

  res.setHeader('Content-Type', 'application/x-ndjson; charset=utf-8')
  res.setHeader('Cache-Control', 'no-cache, no-transform')
  res.setHeader('X-Accel-Buffering', 'no')

  const userMessage = [
    `元のプロンプト: ${prompt || '(不明)'}`,
    `タイトル: ${title}`,
    `概要: ${summary}`,
    '',
    'このプロダクトを実装するための詳細を生成してください。',
  ].join('\n')

  try {
    const { partialOutputStream } = streamText({
      model: gateway('anthropic/claude-haiku-4.5'),
      system: SYSTEM,
      prompt: userMessage,
      output: Output.object({ schema: detailSchema }),
    })

    for await (const partial of partialOutputStream) {
      res.write(JSON.stringify(partial) + '\n')
    }
    res.end()
  } catch (error) {
    console.error('[api/elaborate] failure', error)
    const message = error instanceof Error ? error.message : 'Generation failed'
    if (!res.headersSent) {
      res.status(500).json({ error: message })
    } else {
      res.write(JSON.stringify({ error: message }) + '\n')
      res.end()
    }
  }
}
