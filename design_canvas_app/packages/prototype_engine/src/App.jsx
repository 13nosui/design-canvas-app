import { AppShell, LandingHero, InformationGrid } from './components/prototypes'

const sampleNavItems = [
  { label: 'Dashboard', href: '#' },
  { label: 'Analytics', href: '#' },
  { label: 'Settings', href: '#' },
]

const sampleFeatures = [
  { title: 'Prompt-driven', description: 'Describe your layout in plain language.' },
  { title: 'Design-token ready', description: 'All styles flow through AppTokens.' },
  { title: 'Zero boilerplate', description: 'Ship clean, testable code from day one.' },
]

export default function App() {
  return (
    <AppShell
      header={<span className="font-semibold text-lg">Prototype Engine</span>}
      sidebar={
        <nav className="space-y-1">
          {sampleNavItems.map((item) => (
            <a key={item.label} href={item.href} className="block px-3 py-2 rounded-md text-sm hover:bg-gray-100">
              {item.label}
            </a>
          ))}
        </nav>
      }
    >
      <LandingHero
        headline="Words become form."
        subheadline="Prompt your layout. Preview it instantly."
        ctaLabel="Get started"
        onCtaClick={() => alert('CTA clicked')}
      />
      <InformationGrid items={sampleFeatures} columns={3} />
    </AppShell>
  )
}
