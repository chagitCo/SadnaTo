# src/frontend — React web app

Loaded on demand when Claude works under `src/frontend/`. Rules live in the standards; this file
gives local context, layout and commands only.

## Must read before changing code here

- [frontend-react](../../docs/standards/frontend-react.md) — FE rules (TypeScript, state, forms, i18n/RTL, a11y)
- [security](../../docs/standards/security.md) — browser-side items (tokens, CSP, CSRF)
- [testing](../../docs/standards/testing.md) — Vitest, Testing Library, Playwright, axe-core

Most-cited IDs during review: FE-02 (feature folders), FE-04 (server state), FE-07/08 (RTL and
strings), FE-10 (accessibility), SEC-09 (no tokens in browser storage).

## Layout

```
src/frontend/
  package.json  tsconfig.json (strict)  vite.config.ts  eslint.config.js  index.html
  src/app/                    shell, router, providers (QueryClient, i18n), error boundary
  src/features/<feature>/     api/ (query + mutation hooks), components/, schemas/ (Zod), routes/
  src/shared/                 design-system components, BFF HTTP client, a11y helpers
  src/i18n/{he,en}/*.json     translations; Hebrew is the default locale (RTL)
  tests/e2e/                  Playwright specs with axe-core checks
```

The app talks only to the BFF on the same origin (`/bff/*`); the BFF lives in
`src/backend/services/web-bff/` (ADR-0005). Hosting is S3 + CloudFront (`infra/`).

## Commands (run from `src/frontend/`)

| Purpose | Command |
|---|---|
| Install | `npm ci` |
| Dev server | `npm run dev` |
| Lint + typecheck | `npm run lint && npm run typecheck` |
| Unit/component tests | `npm test` |
| E2E + accessibility | `npm run test:e2e` |
| Production build | `npm run build` |

Status: the app is scaffolded in Phase 4. Node.js is not yet installed on the current dev machine.

## Typical flow here

1. Zod schema for the API shape, then a TanStack Query hook in `features/<f>/api/`.
2. Components with translated strings in `he` and `en`, logical CSS properties.
3. Component tests by role/label, then a Playwright flow with an axe check.
4. Self-review with `test-reviewer` and `security-reviewer`.
