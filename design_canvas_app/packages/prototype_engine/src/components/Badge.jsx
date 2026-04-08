// 役割ステータスを表示するバッジと、それを束ねる ProjectMeta

const COLOR_CLASSES = {
  green: 'bg-emerald-100 text-emerald-700',
  blue: 'bg-blue-100 text-blue-700',
  yellow: 'bg-yellow-100 text-yellow-700',
  slate: 'bg-slate-100 text-slate-500',
}

export function Badge({ label, color }) {
  return (
    <span
      className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${COLOR_CLASSES[color]}`}
    >
      {label}
    </span>
  )
}

export function ProjectMeta({ roles }) {
  return (
    <div className="mt-3 flex flex-wrap gap-1.5">
      {roles.map((r) => (
        <Badge key={r.label} {...r} />
      ))}
    </div>
  )
}
