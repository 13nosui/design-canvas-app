/**
 * AppShell — SaaSの管理画面向け全体枠
 *
 * Props:
 *   header      ReactNode   ヘッダー内のコンテンツ
 *   sidebar     ReactNode   サイドバー内のコンテンツ
 *   children    ReactNode   メインエリアのコンテンツ
 *   headerClass string      ヘッダーのクラス上書き
 *   sidebarClass string     サイドバーのクラス上書き
 *   mainClass   string      メインエリアのクラス上書き
 */
export default function AppShell({
  header,
  sidebar,
  children,
  headerClass = 'h-14 px-6 flex items-center border-b bg-white',
  sidebarClass = 'w-56 shrink-0 border-r bg-white p-4',
  mainClass = 'flex-1 overflow-auto p-6 bg-gray-50',
}) {
  return (
    <div className="flex flex-col h-screen">
      {header && (
        <header className={headerClass}>
          {header}
        </header>
      )}
      <div className="flex flex-1 overflow-hidden">
        {sidebar && (
          <aside className={sidebarClass}>
            {sidebar}
          </aside>
        )}
        <main className={mainClass}>
          {children}
        </main>
      </div>
    </div>
  )
}
