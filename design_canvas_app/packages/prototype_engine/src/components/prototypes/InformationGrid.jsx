/**
 * InformationGrid — 特徴・データ・カードを並べるグリッドセクション
 *
 * Props:
 *   items         Array<{ title, description, icon? }>  表示するアイテム
 *   columns       1 | 2 | 3 | 4   列数（デフォルト 3）
 *   containerClass string          外枠のクラス上書き
 *   cardClass      string          カード1枚のクラス上書き（全カード共通）
 *   cardClassFn    function        (item) => string  カードごとにクラスを返す関数（cardClassより優先）
 *   titleClass     string          タイトルのクラス上書き
 *   descClass      string          説明文のクラス上書き
 */
const COLUMN_CLASSES = {
  1: 'grid-cols-1',
  2: 'grid-cols-1 sm:grid-cols-2',
  3: 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3',
  4: 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-4',
}

export default function InformationGrid({
  items = [],
  columns = 3,
  containerClass = 'py-12 px-6 max-w-5xl mx-auto',
  cardClass = 'rounded-xl border bg-white p-6 shadow-sm',
  cardClassFn,
  titleClass = 'text-base font-semibold text-gray-900',
  descClass = 'mt-2 text-sm text-gray-500',
}) {
  const colClass = COLUMN_CLASSES[columns] ?? COLUMN_CLASSES[3]

  return (
    <section className={containerClass}>
      <ul className={`grid gap-6 ${colClass}`}>
        {items.map((item) => (
          <li key={item.id ?? item.title} className={cardClassFn ? cardClassFn(item) : cardClass}>
            {item.icon && <div className="mb-3 text-indigo-500">{item.icon}</div>}
            <h3 className={titleClass}>{item.title}</h3>
            {item.description && <p className={descClass}>{item.description}</p>}
          </li>
        ))}
      </ul>
    </section>
  )
}
