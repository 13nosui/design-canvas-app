// プロジェクトカードを開いた時に表示する右側ドロワー
// 詳細データは親 (App.jsx) が project.detail に部分更新で書き込む

import { useEffect } from 'react'

const SECTION_CLASS = 'border-t border-slate-100 pt-4 mt-4 first:border-t-0 first:pt-0 first:mt-0'
const LABEL_CLASS = 'text-[11px] font-semibold text-slate-400 uppercase tracking-wider'

// VISION のラスボス: React 側で生成した内容を Flutter キャンバスエディタへハンドオフする
const FLUTTER_APP_BASE_URL = 'https://design-canvas-flutter-13nosuis-projects.vercel.app'

function buildHandoffUrl(project) {
  const payload = {
    title: project.title,
    icon: project.icon,
    summary: project.summary,
    prompt: project.prompt,
    meta: project.meta,
    detail: project.detail,
  }
  const json = JSON.stringify(payload)
  // base64url エンコード
  const base64 = btoa(unescape(encodeURIComponent(json)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '')
  return `${FLUTTER_APP_BASE_URL}/import?data=${base64}`
}

export function DetailDrawer({ project, onClose }) {
  // ESC でクローズ
  useEffect(() => {
    if (!project) return undefined
    function onKey(e) {
      if (e.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [project, onClose])

  if (!project) return null

  const detail = project.detail
  const isLoading = project.detailLoading
  const error = project.detailError

  return (
    <>
      {/* 背景オーバーレイ */}
      <div
        className="fixed inset-0 bg-slate-900/30 backdrop-blur-sm z-40 transition-opacity"
        onClick={onClose}
        aria-hidden="true"
      />
      {/* ドロワー本体 */}
      <aside
        className="fixed top-0 right-0 bottom-0 w-full max-w-xl bg-white shadow-2xl z-50 overflow-y-auto"
        role="dialog"
        aria-modal="true"
        aria-labelledby="drawer-title"
      >
        <header className="sticky top-0 bg-white/95 backdrop-blur border-b border-slate-200 px-6 py-4 flex items-start justify-between gap-4 z-10">
          <div className="flex items-start gap-3 min-w-0">
            <span className="text-3xl shrink-0">{project.icon}</span>
            <div className="min-w-0">
              <h2 id="drawer-title" className="text-lg font-semibold text-slate-800 truncate">
                {project.title}
              </h2>
              <p className="text-xs text-slate-500 mt-1 line-clamp-2">{project.summary}</p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="shrink-0 w-8 h-8 rounded-md text-slate-400 hover:bg-slate-100 hover:text-slate-600 transition-colors flex items-center justify-center"
            aria-label="閉じる"
          >
            ✕
          </button>
        </header>

        <div className="px-6 py-6">
          {error ? (
            <div className="text-sm text-red-600">詳細の生成に失敗しました: {error}</div>
          ) : (
            <DetailBody detail={detail} isLoading={isLoading} />
          )}
        </div>

        {/* Flutter キャンバスへのハンドオフ — VISION のクライマックス */}
        {!error && detail && !isLoading && (
          <footer className="sticky bottom-0 bg-white border-t border-slate-200 px-6 py-4 flex items-center justify-between gap-3">
            <span className="text-xs text-slate-500">
              この設計を Flutter キャンバスに渡す
            </span>
            <a
              href={buildHandoffUrl(project)}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-slate-900 text-white text-xs font-semibold hover:bg-slate-700 transition-colors"
            >
              Flutter で開く
              <span aria-hidden="true">↗</span>
            </a>
          </footer>
        )}
      </aside>
    </>
  )
}

function DetailBody({ detail, isLoading }) {
  const screens = Array.isArray(detail?.screens)
    ? detail.screens
        .filter((s) => s && s.name && s.purpose)
        .map((s) => ({
          ...s,
          sections: Array.isArray(s.sections)
            ? s.sections.filter((sec) => sec && sec.label && sec.body)
            : [],
        }))
    : []
  const apis = Array.isArray(detail?.apis)
    ? detail.apis.filter((a) => a && a.name && a.description)
    : []
  const stack = Array.isArray(detail?.stack) ? detail.stack.filter(Boolean) : []
  const risks = Array.isArray(detail?.risks) ? detail.risks.filter(Boolean) : []
  const userFlow = detail?.userFlow

  const empty = !screens.length && !userFlow && !apis.length && !stack.length && !risks.length

  return (
    <div className="space-y-0">
      {empty && isLoading && (
        <div className="text-sm text-slate-400">Claude が詳細を考えています...</div>
      )}

      {screens.length > 0 && (
        <Section label="主要画面">
          <ul className="space-y-4">
            {screens.map((s) => (
              <li key={s.name} className="flex flex-col gap-1">
                <span className="text-sm font-medium text-slate-800">{s.name}</span>
                <span className="text-xs text-slate-500 leading-relaxed">{s.purpose}</span>
                {s.sections.length > 0 && (
                  <ul className="mt-2 space-y-1.5">
                    {s.sections.map((sec) => (
                      <li
                        key={`${s.name}::${sec.label}`}
                        className="rounded-md bg-slate-50 border border-slate-200 px-2.5 py-1.5"
                      >
                        <div className="text-[10px] font-bold text-slate-500 uppercase tracking-wide">
                          {sec.label}
                        </div>
                        <div className="text-xs text-slate-600 leading-relaxed mt-0.5">
                          {sec.body}
                        </div>
                      </li>
                    ))}
                  </ul>
                )}
              </li>
            ))}
          </ul>
        </Section>
      )}

      {userFlow && (
        <Section label="ユーザーフロー">
          <p className="text-sm text-slate-600 leading-relaxed">{userFlow}</p>
        </Section>
      )}

      {apis.length > 0 && (
        <Section label="API / エンドポイント">
          <ul className="space-y-2">
            {apis.map((a) => (
              <li key={a.name} className="flex flex-col gap-0.5">
                <code className="text-xs font-mono text-blue-700 bg-blue-50 px-2 py-0.5 rounded inline-block self-start">
                  {a.name}
                </code>
                <span className="text-xs text-slate-500 leading-relaxed">{a.description}</span>
              </li>
            ))}
          </ul>
        </Section>
      )}

      {stack.length > 0 && (
        <Section label="技術スタック候補">
          <div className="flex flex-wrap gap-1.5">
            {stack.map((s) => (
              <span
                key={s}
                className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-slate-100 text-slate-700"
              >
                {s}
              </span>
            ))}
          </div>
        </Section>
      )}

      {risks.length > 0 && (
        <Section label="リスクと論点">
          <ul className="space-y-1.5">
            {risks.map((r) => (
              <li key={r} className="text-xs text-slate-600 leading-relaxed flex gap-2">
                <span className="text-amber-500">⚠</span>
                <span>{r}</span>
              </li>
            ))}
          </ul>
        </Section>
      )}

      {isLoading && !empty && (
        <div className="mt-6 text-xs text-slate-400 animate-pulse">続きを生成しています...</div>
      )}
    </div>
  )
}

function Section({ label, children }) {
  return (
    <section className={SECTION_CLASS}>
      <div className={LABEL_CLASS}>{label}</div>
      <div className="mt-2">{children}</div>
    </section>
  )
}
