import { useState } from 'react'

// プロンプト入力欄。Enter で送信、Esc でクリア。

export function CommandBar({ onSubmit }) {
  const [value, setValue] = useState('')

  function handleSubmit() {
    const trimmed = value.trim()
    if (!trimmed) return
    onSubmit(trimmed)
    setValue('')
  }

  function handleKeyDown(e) {
    if (e.key === 'Enter') handleSubmit()
    if (e.key === 'Escape') setValue('')
  }

  return (
    <div className="mt-8 w-full max-w-xl mx-auto">
      <div className="flex items-center gap-2 bg-white border border-slate-200 rounded-xl px-4 py-3 shadow-sm focus-within:ring-2 focus-within:ring-blue-400 focus-within:border-blue-400 transition">
        <span className="text-slate-400 text-sm select-none">⌘</span>
        <input
          type="text"
          value={value}
          onChange={(e) => setValue(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder='プロトタイプを説明してください。例：「SaaSの請求管理画面」'
          className="flex-1 bg-transparent text-sm text-slate-700 placeholder-slate-400 outline-none"
        />
        <button
          onClick={handleSubmit}
          disabled={!value.trim()}
          className="shrink-0 px-3 py-1 rounded-lg bg-blue-600 text-white text-xs font-medium hover:bg-blue-700 transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
        >
          生成
        </button>
      </div>
      <p className="mt-2 text-center text-xs text-slate-400">Enter で送信 · Esc でクリア</p>
    </div>
  )
}
