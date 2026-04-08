// /api/* の NDJSON ストリームを async iterator として消費するヘルパー

async function* streamNDJSON(url, body) {
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })

  if (!res.ok) {
    let message = `HTTP ${res.status}`
    try {
      const errBody = await res.json()
      if (errBody?.error) message = errBody.error
    } catch {
      // ignore
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
        const parsed = parseLine(line)
        if (parsed) yield parsed
      }
    }
    const remaining = buffer.trim()
    if (remaining) {
      const parsed = parseLine(remaining)
      if (parsed) yield parsed
    }
  } finally {
    reader.releaseLock()
  }
}

function parseLine(line) {
  if (!line) return null
  let obj
  try {
    obj = JSON.parse(line)
  } catch {
    return null
  }
  if (obj && typeof obj === 'object' && 'error' in obj && typeof obj.error === 'string') {
    throw new Error(obj.error)
  }
  return obj
}

export function generatePrototypeStream(prompt) {
  return streamNDJSON('/api/generate', { prompt })
}

export function elaboratePrototypeStream({ title, summary, prompt }) {
  return streamNDJSON('/api/elaborate', { title, summary, prompt })
}
