// プロジェクトカードのモックデータとロール別ステータスプール

export const ICONS = ['🚀', '💡', '🎯', '🌊', '🔮', '🎨', '🏗️', '⚡', '🌱', '🎪']

export const STATUS_POOLS = {
  pdm: [
    { label: 'PdM: 完了', color: 'green' },
    { label: 'PdM: 仕様調整中', color: 'yellow' },
    { label: 'PdM: 未着手', color: 'slate' },
  ],
  design: [
    { label: 'Design: 完了', color: 'green' },
    { label: 'Design: UI実装中', color: 'blue' },
    { label: 'Design: 未着手', color: 'slate' },
  ],
  eng: [
    { label: 'Eng: 完了', color: 'green' },
    { label: 'Eng: 実装中', color: 'blue' },
    { label: 'Eng: API設計中', color: 'yellow' },
    { label: 'Eng: 未着手', color: 'slate' },
  ],
}

export const INITIAL_PROJECTS = [
  {
    id: 'alcotrack',
    icon: '🌿',
    title: 'AlcoTrack',
    summary: 'アルコール依存症の回復支援サービス。毎日の記録と匿名コミュニティ。',
    meta: [
      { label: 'PdM: Spec確定', color: 'green' },
      { label: 'Design: UI実装中', color: 'blue' },
      { label: 'Eng: API設計中', color: 'yellow' },
    ],
  },
  {
    id: 'haiku',
    icon: '✍️',
    title: 'Haiku SNS',
    summary: '5-7-5の俳句だけで投稿できるミニマルSNS。制約がクリエイティビティを生む。',
    meta: [
      { label: 'PdM: 完了', color: 'green' },
      { label: 'Design: 完了', color: 'green' },
      { label: 'Eng: 実装中', color: 'blue' },
    ],
  },
  {
    id: 'voxel',
    icon: '🎲',
    title: 'Voxel Toy Box',
    summary: 'ブラウザで動くボクセルエディタ。子どもでも直感的に3D空間を組み立てられる。',
    meta: [
      { label: 'PdM: 仕様調整中', color: 'yellow' },
      { label: 'Design: 未着手', color: 'slate' },
      { label: 'Eng: PoC完了', color: 'green' },
    ],
  },
]

export function pickRandom(arr) {
  return arr[Math.floor(Math.random() * arr.length)]
}

export function randomMeta() {
  return [
    pickRandom(STATUS_POOLS.pdm),
    pickRandom(STATUS_POOLS.design),
    pickRandom(STATUS_POOLS.eng),
  ]
}
