# Design Canvas

> **Prompt your idea. See it live.**
> A universal development platform where any team — anywhere in the world — can go from concept to working prototype using only natural language.

---

## The Problem

Building software today still means translating the same idea three times:
**words → wireframes → code.**

Each translation loses fidelity, momentum, and meaning.
Complex challenges — mental health, education, accessibility — deserve faster iteration than the current toolchain allows.

## The Vision

**Design Canvas** collapses the gap between intention and implementation.

A PdM types a prompt. A working layout appears.
A designer refines it with words, not pixels.
An engineer ships it — clean, tested, and traceable.

No Figma handoff. No boilerplate. No translation cost.

---

## Monorepo Structure

```
design-canvas/
├── apps/
│   └── mobile/              # Flutter canvas editor (real-time component editing)
├── packages/
│   └── prototype_engine/    # React + Tailwind prototype generation engine
├── VISION.md                # Full product vision
└── CLAUDE.md                # AI agent guidance
```

---

## Getting Started

### Prototype Engine (React + Tailwind)

```bash
cd packages/prototype_engine
npm install
npm run dev
```

### Canvas Editor (Flutter)

```bash
cd apps/mobile
flutter pub get
flutter run
```

---

## Core Principles

| Principle | What it means |
|---|---|
| **AI-Native Structure** | Loosely coupled architecture that AI can read and humans can verify |
| **Traceable Decisions** | Every non-obvious choice links to an ADR in `docs/adr/` |
| **Zero Technical Debt** | Tests ship with every implementation, always deployable |

---

## Layout Presets

The prototype engine ships with prompt-ready layout components:

- **`AppShell`** — Full SaaS admin frame: header + sidebar + main
- **`LandingHero`** — Hero section with headline and CTA
- **`InformationGrid`** — Responsive feature/data grid (1–4 columns)

All styles flow through props — no hardcoded Tailwind classes. Designers override via prompts.

---

## Built With

- [Flutter](https://flutter.dev) — Cross-platform canvas editor
- [React](https://react.dev) + [Tailwind CSS](https://tailwindcss.com) — Prototype generation engine
- [Vite](https://vitejs.dev) — Frontend tooling

---

*This project is an open prototype. The goal: become the standard foundation for AI-driven product development worldwide.*
