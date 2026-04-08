// /api/generate を呼び出し NDJSON ストリームをパースする async iterator

export async function* generatePrototypeStream(prompt) {
  const res = await fetch('/api/generate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ prompt }),
  })

  if (!res.ok) {
    let message = `HTTP ${res.status}`
    try {
      const body = await res.json()
      if (body?.error) message = body.error
    } catch {
      // ignore parse failures
    }
    throw new Error(message)
  }

  if (!res.body) {
    throw new Error('Response has no body')
  }

  const reader = res.body.getReader()
  const decoder = new TextDecoder()
  let buffer = ''

  try {
    while (true) {
      const { done, value } = await reader.read()
      if (done) break
      buffer += decoder.decode(value, { stream: true })

      let newlineIndex
      while ((newlineIndex = buffer.indexOf('\n')) !== -1) {
        const line = buffer.slice(0, newlineIndex).trim()
        buffer = buffer.slice(newlineIndex + 1)
        if (!line) continue
        const parsed = safeParse(line)
        if (parsed) yield parsed
      }
    }
    const remaining = buffer.trim()
    if (remaining) {
      const parsed = safeParse(remaining)
      if (parsed) yield parsed
    }
  } finally {
    reader.releaseLock()
  }
}

function safeParse(line) {
  try {
    const obj = JSON.parse(line)
    if (obj?.error) throw new Error(obj.error)
    return obj
  } catch (error) {
    if (error instanceof Error && error.message !== 'Unexpected end of JSON input') {
      // 上位ストリームのエラーは投げる
      if (line.includes('"error"')) throw error
    }
    return null
  }
}
