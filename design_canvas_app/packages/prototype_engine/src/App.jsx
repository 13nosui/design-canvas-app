import { useState } from 'react'
import { AppShell, LandingHero, InformationGrid } from './components/prototypes'
import { Badge, ProjectMeta } from './components/Badge'
import { CommandBar } from './components/CommandBar'
import { INITIAL_PROJECTS, ICONS, pickRandom, randomMeta } from './data/projects'

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

// projects → InformationGrid の items 形式に変換
function toGridItems(projects) {
  return projects.map((p) => ({
    id: p.id,
    icon: <span className="text-2xl">{p.icon}</span>,
    title: p.title,
    generating: p.generating ?? false,
    description: p.generating ? (
      <span className="block text-slate-400 text-sm">生成しています...</span>
    ) : (
      <>
        <span className="block text-slate-500 leading-relaxed">{p.summary}</span>
        <ProjectMeta roles={p.meta} />
      </>
    ),
  }))
}

export default function App() {
  const [projects, setProjects] = useState(INITIAL_PROJECTS)

  function handleGenerate(prompt) {
    const id = `gen-${Date.now()}`

    // 1. 仮カードをリスト先頭に追加
    setProjects((prev) => [
      { id, icon: '⏳', title: prompt, summary: '', meta: [], generating: true },
      ...prev,
    ])

    // 2. 1.5秒後に本番カードへ差し替え
    setTimeout(() => {
      setProjects((prev) =>
        prev.map((p) =>
          p.id === id
            ? {
                id,
                icon: pickRandom(ICONS),
                title: prompt,
                summary: `「${prompt}」から生成されたプロトタイプ。ここに自動生成されたサービス概要が入ります。`,
                meta: randomMeta(),
                generating: false,
              }
            : p
        )
      )
    }, 1500)
  }

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

      <div className="px-6 pt-6 max-w-5xl mx-auto">
        <h2 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
          最近のプロジェクト
        </h2>
      </div>

      <InformationGrid
        items={toGridItems(projects)}
        columns={3}
        containerClass="pb-12 px-6 max-w-5xl mx-auto"
        cardClassFn={(item) => (item.generating ? GHOST_CARD : BASE_CARD)}
        titleClass="text-sm font-semibold text-slate-800 mt-2"
        descClass="mt-1 text-sm"
      />
    </AppShell>
  )
}
