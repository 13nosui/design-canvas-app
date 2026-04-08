/**
 * LandingHero — ランディングページのヒーローセクション
 *
 * Props:
 *   headline         string      メインのキャッチコピー
 *   subheadline      string      サブコピー
 *   ctaLabel         string      CTAボタンのテキスト（省略するとボタンエリア非表示）
 *   onCtaClick       function    CTAボタンのクリックハンドラ
 *   secondaryLabel   string      サブCTAのテキスト（省略可）
 *   onSecondaryClick function    サブCTAのクリックハンドラ（省略可）
 *   children         ReactNode   見出し・CTAの下に挿入する任意のコンテンツ
 *   containerClass   string      外枠のクラス上書き
 *   headlineClass    string      見出しのクラス上書き
 *   subheadlineClass string      サブ見出しのクラス上書き
 *   ctaClass         string      CTAボタンのクラス上書き
 */
export default function LandingHero({
  headline = 'Your headline here.',
  subheadline = 'Your supporting copy.',
  ctaLabel,
  onCtaClick,
  secondaryLabel,
  onSecondaryClick,
  children,
  containerClass = 'py-20 px-6 text-center max-w-2xl mx-auto',
  headlineClass = 'text-4xl font-bold tracking-tight text-gray-900 sm:text-5xl',
  subheadlineClass = 'mt-4 text-lg text-gray-500',
  ctaClass = 'mt-8 inline-flex items-center px-6 py-3 rounded-lg bg-indigo-600 text-white font-medium hover:bg-indigo-700 transition-colors',
}) {
  return (
    <section className={containerClass}>
      <h1 className={headlineClass}>{headline}</h1>
      {subheadline && <p className={subheadlineClass}>{subheadline}</p>}
      {ctaLabel && (
        <div className="flex flex-wrap justify-center gap-3 mt-8">
          <button className={ctaClass} onClick={onCtaClick}>
            {ctaLabel}
          </button>
          {secondaryLabel && (
            <button
              className="inline-flex items-center px-6 py-3 rounded-lg border border-gray-300 text-gray-700 font-medium hover:bg-gray-50 transition-colors"
              onClick={onSecondaryClick}
            >
              {secondaryLabel}
            </button>
          )}
        </div>
      )}
      {children}
    </section>
  )
}
