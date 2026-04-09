import { useEffect, useState } from 'react'
import { AppShell, LandingHero, InformationGrid } from './components/prototypes'
import { ProjectMeta } from './components/Badge'
import { CommandBar } from './components/CommandBar'
import { DetailDrawer } from './components/DetailDrawer'
import { INITIAL_PROJECTS } from './data/projects'
import { generatePrototypeStream, elaboratePrototypeStream } from './lib/generate'

const STORAGE_KEY = 'design-canvas.projects.v1'

/**
 * Load persisted projects from localStorage. Falls back to the sample
 * INITIAL_PROJECTS on first visit, on parse error, or on a missing entry.
 * We drop any entry with `generating: true` since an in-progress stream
 * cannot be resumed across reloads.
 */
function loadPersistedProjects() {
  try {
    const raw = typeof window !== 'undefined'
      ? window.localStorage.getItem(STORAGE_KEY)
      : null
    if (!raw) return INITIAL_PROJECTS
    const parsed = JSON.parse(raw)
    if (!Array.isArray(parsed)) return INITIAL_PROJECTS
    return parsed
      .filter((p) => p && typeof p === 'object' && p.id && !p.generating)
      .map((p) => ({ ...p, generating: false, detailLoading: false }))
  } catch {
    return INITIAL_PROJECTS
  }
}

function savePersistedProjects(projects) {
  try {
    if (typeof window === 'undefined') return
    // Avoid persisting transient states
    const sanitized = projects
      .filter((p) => !p.generating && !p.error)
      .map(({ detailLoading, ...rest }) => rest)
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(sanitized))
  } catch {
    // storage full / private mode → ignore
  }
}

const NAV_ITEMS = [
  { label: 'Projects', href: '#', active: true },
  { label: 'Components', href: '#' },
  { label: 'Team Assets', href: '#' },
  { label: 'Docs', href: '#' },
]

const BASE_CARD =
  'rounded-xl border border-slate-200 bg-white p-5 shadow-sm hover:shadow-md transition-shadow cursor-pointer card-enter'
const GHOST_CARD =
  'rounded-xl border border-dashed border-blue-300 bg-blue-50/50 p-5 animate-pulse'
const ERROR_CARD =
  'rounded-xl border border-red-200 bg-red-50 p-5 shadow-sm card-enter'

function cardClassFn(item) {
  if (item.generating) return GHOST_CARD
  if (item.error) return ERROR_CARD
  return BASE_CARD
}

// 不完全な meta 要素を除外 (ストリーミング途中の partial 対応)
function validMeta(meta) {
  return Array.isArray(meta) ? meta.filter((m) => m && m.label && m.color) : []
}

// projects → InformationGrid の items 形式に変換
function toGridItems(projects) {
  return projects.map((p) => {
    const safeMeta = validMeta(p.meta)
    const hasContent = Boolean(p.summary)
    return {
      id: p.id,
      icon: <span className="text-2xl">{p.icon}</span>,
      title: p.title,
      generating: p.generating ?? false,
      error: p.error ?? false,
      description: p.error ? (
        <span className="block text-red-600 text-sm leading-relaxed">{p.summary}</span>
      ) : hasContent ? (
        <>
          <span className="block text-slate-500 leading-relaxed">{p.summary}</span>
          {safeMeta.length > 0 && <ProjectMeta roles={safeMeta} />}
        </>
      ) : (
        <span className="block text-slate-400 text-sm">Claude が生成しています...</span>
      ),
    }
  })
}

export default function App() {
  const [projects, setProjects] = useState(loadPersistedProjects)
  const [selectedId, setSelectedId] = useState(null)

  // Persist to localStorage whenever the project list changes.
  // Skipping transient (generating / errored) entries so reloads land
  // on a clean, resumable state.
  useEffect(() => {
    savePersistedProjects(projects)
  }, [projects])

  async function handleGenerate(prompt) {
    const id = `gen-${Date.now()}`

    // 1. 仮カードを先頭に追加 (アイコンとタイトルはストリームで上書きされる)
    setProjects((prev) => [
      { id, icon: '⏳', title: prompt, summary: '', meta: [], generating: true, prompt },
      ...prev,
    ])

    // 2. ストリームから partial を受け取るたびに上書きする
    try {
      for await (const partial of generatePrototypeStream(prompt)) {
        setProjects((prev) =>
          prev.map((p) =>
            p.id === id
              ? {
                  ...p,
                  icon: partial.icon || p.icon,
                  title: partial.title || p.title,
                  summary: partial.summary || p.summary,
                  meta: validMeta(partial.meta).length > 0 ? partial.meta : p.meta,
                }
              : p
          )
        )
      }
      // 3. ストリーム完了 → ghost を解除
      setProjects((prev) =>
        prev.map((p) => (p.id === id ? { ...p, generating: false } : p))
      )
    } catch (error) {
      setProjects((prev) =>
        prev.map((p) =>
          p.id === id
            ? {
                id,
                icon: '⚠️',
                title: prompt,
                summary: `生成に失敗しました: ${error.message}`,
                meta: [],
                generating: false,
                error: true,
              }
            : p
        )
      )
    }
  }

  async function handleElaborate(project) {
    if (!project || project.detail || project.detailLoading) return

    setProjects((prev) =>
      prev.map((p) =>
        p.id === project.id ? { ...p, detailLoading: true, detailError: null } : p
      )
    )

    try {
      for await (const partial of elaboratePrototypeStream({
        title: project.title,
        summary: project.summary,
        prompt: project.prompt,
      })) {
        setProjects((prev) =>
          prev.map((p) => (p.id === project.id ? { ...p, detail: partial } : p))
        )
      }
      setProjects((prev) =>
        prev.map((p) => (p.id === project.id ? { ...p, detailLoading: false } : p))
      )
    } catch (error) {
      setProjects((prev) =>
        prev.map((p) =>
          p.id === project.id
            ? { ...p, detailLoading: false, detailError: error.message }
            : p
        )
      )
    }
  }

  function handleCardClick(item) {
    const project = projects.find((p) => p.id === item.id)
    if (!project || project.generating || project.error) return
    setSelectedId(project.id)
    handleElaborate(project)
  }

  function handleClearAll() {
    // eslint-disable-next-line no-alert
    if (!window.confirm('生成したプロジェクトを全てクリアし、サンプルに戻します。よろしいですか?')) {
      return
    }
    setProjects(INITIAL_PROJECTS)
    setSelectedId(null)
  }

  const selectedProject = selectedId ? projects.find((p) => p.id === selectedId) : null

  return (
    <AppShell
      header={
        <div className="flex items-center justify-between w-full">
          <div className="flex items-center gap-2">
            <span className="w-5 h-5 rounded bg-blue-600 inline-block" />
            <span className="font-semibold text-slate-800 tracking-tight">Design Canvas</span>
          </div>
          <div className="flex items-center gap-3">
            <span className="text-xs text-slate-400">13nosui</span>
            <div className="w-7 h-7 rounded-full bg-slate-200" />
          </div>
        </div>
      }
      sidebar={
        <nav className="space-y-0.5">
          {NAV_ITEMS.map((item) => (
            <a
              key={item.label}
              href={item.href}
              className={`block px-3 py-2 rounded-md text-sm transition-colors ${
                item.active
                  ? 'bg-blue-50 text-blue-700 font-medium'
                  : 'text-slate-600 hover:bg-slate-100'
              }`}
            >
              {item.label}
            </a>
          ))}
        </nav>
      }
      headerClass="h-14 px-6 flex items-center border-b border-slate-200 bg-white"
      sidebarClass="w-52 shrink-0 border-r border-slate-200 bg-white p-4"
      mainClass="flex-1 overflow-auto bg-slate-50"
    >
      <LandingHero
        headline="Design Canvas / Dashboard"
        subheadline="思考をコードへ。チーム全員が真実を共有する場所。"
        containerClass="pt-12 pb-4 px-6 text-center max-w-2xl mx-auto"
        headlineClass="text-2xl font-bold tracking-tight text-slate-800"
        subheadlineClass="mt-2 text-sm text-slate-500"
      >
        <CommandBar onSubmit={handleGenerate} />
      </LandingHero>

      <div className="px-6 pt-6 max-w-5xl mx-auto flex items-center justify-between">
        <h2 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
          最近のプロジェクト
        </h2>
        <button
          type="button"
          onClick={handleClearAll}
          className="text-xs text-slate-400 hover:text-slate-600 transition-colors"
          title="localStorage に保存されたプロジェクトを全て消してサンプルに戻す"
        >
          Clear All
        </button>
      </div>

      <InformationGrid
        items={toGridItems(projects)}
        columns={3}
        containerClass="pb-12 px-6 max-w-5xl mx-auto"
        cardClassFn={cardClassFn}
        titleClass="text-sm font-semibold text-slate-800 mt-2"
        descClass="mt-1 text-sm"
        onItemClick={handleCardClick}
        isItemDisabled={(item) => item.generating || item.error}
      />
      <DetailDrawer project={selectedProject} onClose={() => setSelectedId(null)} />
    </AppShell>
  )
}
