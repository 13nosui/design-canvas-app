# ADR-0003: React ↔ Vercel Functions 間の NDJSON ストリーミング契約

- **Status**: Accepted
- **Date**: 2026-04-08
- **Deciders**: 13nosui

## Context

LLM 生成は数秒かかる。VISION が掲げる「思考の結晶化」体感を出すには、
**部分結果を逐次クライアントに届ける** 必要がある。具体的には AI SDK v6 の
`partialOutputStream` (AsyncIterable<PartialObject>) をクライアントまで届ける。

候補:
1. **SSE (Server-Sent Events)** — `text/event-stream`、ブラウザに `EventSource` がある
2. **WebSocket** — 双方向ストリーム
3. **NDJSON** (改行区切り JSON) — プレーンな HTTP レスポンス
4. **単発レスポンス (非ストリーミング)** — 全部生成し終わってから返す

Vercel Functions は Node.js ランタイムで `res.write` によるチャンク送信をサポート
しており、上記どれも理論上可能。

## Decision

**NDJSON** (`application/x-ndjson`) でストリーミングする。

### サーバー側

```js
res.setHeader('Content-Type', 'application/x-ndjson; charset=utf-8')
res.setHeader('Cache-Control', 'no-cache, no-transform')
res.setHeader('X-Accel-Buffering', 'no')  // プロキシバッファリング回避

const { partialOutputStream } = streamText({...})
for await (const partial of partialOutputStream) {
  res.write(JSON.stringify(partial) + '\n')
}
res.end()
```

### クライアント側

`streamNDJSON` ヘルパーを `src/lib/generate.js` に共通化:

```js
async function* streamNDJSON(url, body) {
  const res = await fetch(url, { method: 'POST', body: JSON.stringify(body), ... })
  const reader = res.body.getReader()
  const decoder = new TextDecoder()
  let buffer = ''
  while (true) {
    const { done, value } = await reader.read()
    if (done) break
    buffer += decoder.decode(value, { stream: true })
    let newlineIndex
    while ((newlineIndex = buffer.indexOf('\n')) !== -1) {
      const line = buffer.slice(0, newlineIndex).trim()
      buffer = buffer.slice(newlineIndex + 1)
      const parsed = parseLine(line)
      if (parsed) yield parsed
    }
  }
  // ...残バッファ処理
}
```

- **エラー伝搬**: ヘッダ送信後に失敗したら `{"error": "..."}` の行を stream に
  書き込んでから `res.end()`。クライアント側の `parseLine` は `error` キーを
  検出したら `throw`

## Consequences

### Good
- **実装シンプル**: SSE の `event: / data: / id:` のような framing が不要
- **各行が完全な JSON** → `tail`、`jq`、`curl -N` で人間が目視デバッグ可能
- **AI SDK の partialObject がそのままネットワーク上に流れる** (1 行 = 1 partial state)
- **プロキシ/CDN との相性**: HTTP 標準の範囲内なので変な処理を挟まれにくい
- **エラーを同じストリームで伝搬できる** (専用チャネル不要)

### Bad (trade-offs)
- **ブラウザの `EventSource` API が使えない** → カスタム fetch + reader 実装が必要
- **ヘッダ送信後のエラーはステータスコードで伝えられない** (body 内の error 行のみ)
- **進捗メタデータ (パーセント、estimated time) は構造化の追加設計が必要**
- **1 行が長すぎると、JSON parse がチャンク境界で失敗するリスク** (バッファ運用で回避済み)

## Alternatives considered

1. **SSE (`text/event-stream`)**
   - 却下: framing のオーバーヘッドと、Vercel の buffering 回避の追加設定が面倒。
     `EventSource` がブラウザネイティブで使える利点はあるが、POST body が送れない欠点もある
2. **WebSocket**
   - 却下: ステートフル接続は Vercel Functions (FaaS) と相性が悪い。コネクション維持の
     コストが発生し、冷起動と合わさって不安定
3. **長時間ポーリング**
   - 却下: 部分結果のリアルタイム性を失う
4. **非ストリーミング (単発レスポンス)**
   - 却下: 数秒待たされる体験が悪化し、VISION の "思考の結晶化" が成立しない

## Related

- Files
  - `packages/prototype_engine/api/generate.js` (送信側)
  - `packages/prototype_engine/api/elaborate.js` (送信側)
  - `packages/prototype_engine/src/lib/generate.js` (`streamNDJSON` 共通ヘルパー)
  - `packages/prototype_engine/src/App.jsx` (`for await` による partial 消費)
- Commits
  - `d23d156 feat(prototype_engine): Claude生成をストリーミング対応`
  - `c2ad838 feat(prototype_engine): カードクリックで詳細を深堀り生成`
