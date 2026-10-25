# Frontend standard — React + TypeScript (FE)

Scope: everything under `src/frontend/`. Sources: MISSION (Frontend), ADR-0005 (BFF), reference
service NFR-8/NFR-9.

## Rules

- **FE-01** TypeScript runs in `strict` mode with `noUncheckedIndexedAccess`; `any` and non-null assertions (`!`) need an inline justification comment.
- **FE-02** Code is organized by feature (`src/features/<feature>/{api,components,schemas,routes}`); a feature imports another feature only through that feature's `index.ts`.
- **FE-03** The app calls only same-origin `/bff/*` endpoints through the shared HTTP client, which sends the CSRF header and handles Problem Details responses.
- **FE-04** Server state is managed with TanStack Query (query keys per feature, invalidation after mutations); a global client-state store needs an ADR.
- **FE-05** Every API response is parsed with a Zod schema before use, and forms use React Hook Form with the same Zod schemas for validation.
- **FE-06** Hebrew (`he`) is the default locale with `dir="rtl"`; English (`en`) is supported, and switching language updates `lang` and `dir` without a reload.
- **FE-07** Layout uses CSS logical properties (`margin-inline-start`, `inset-inline-end`, `text-align: start`) so RTL and LTR render correctly without per-direction overrides.
- **FE-08** User-visible text comes from translation files; hard-coded UI strings fail lint.
- **FE-09** Dates, numbers and currencies are formatted with `Intl` APIs for the active locale.
- **FE-10** Pages meet WCAG 2.2 AA: semantic elements first, every control has an accessible name, visible focus, keyboard operability, and form errors announced via `aria-live`.
- **FE-11** `dangerouslySetInnerHTML`, `eval` and inline event-handler strings are not used.
- **FE-12** Components stay presentational where possible; data fetching lives in hooks under `api/`, not inside deeply nested components.
- **FE-13** Loading, empty and error states are designed and implemented for every data view.

## Tooling (reference)

| Concern | Tool |
|---|---|
| Build/dev | Vite |
| Lint | ESLint (typescript-eslint strict, jsx-a11y, i18next/no-literal-string) |
| Format | Prettier (run by the PostToolUse hook when installed) |
| Unit/component tests | Vitest + Testing Library |
| E2E + accessibility | Playwright + @axe-core/playwright |
| i18n | i18next + react-i18next |

Testing expectations for the frontend are in [testing.md](testing.md) (TEST-08, TEST-09).
