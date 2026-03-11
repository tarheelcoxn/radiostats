# Frontend Migration: CRA → Vite

## Why

The frontend currently uses **Create React App (CRA) `react-scripts@5.0.1`**, which
has been effectively unmaintained since early 2023. It bundles a large, frozen
dependency tree (webpack, babel, ajv@6, fork-ts-checker, etc.) that grows
increasingly incompatible with newer Node.js LTS releases.

As of March 2026 the `overrides` block in `frontend/package.json` has 19 entries
patching security vulnerabilities and compatibility issues in CRA's transitive
deps. Each fix risks introducing new conflicts. The Dockerfile currently pins
`node:22-alpine` specifically because CRA is incompatible with Node 24+.

**Migrating to Vite** eliminates the entire problem class:

- Replaces ~1600 packages with ~200
- Removes webpack, babel, fork-ts-checker, ajv, schema-utils — the packages
  responsible for the majority of Dependabot alerts and override complexity
- The `overrides` block shrinks to zero or near-zero entries
- The Dockerfile can return to `node:lts-alpine`, tracking the current LTS
  automatically without compatibility concerns
- Vite is actively maintained; security fixes land promptly

## Scope

The frontend is a plain JavaScript React app (no TypeScript, no ejected config).
This is the simplest possible CRA-to-Vite migration case.

## Migration steps

### 1. Update `frontend/package.json`

Remove:
```json
"react-scripts": "^5.0.1"
```

Add:
```json
"vite": "^5.0.0",
"@vitejs/plugin-react": "^4.0.0"
```

Update scripts:
```json
"scripts": {
  "start": "vite",
  "build": "vite build",
  "test": "vitest",
  "preview": "vite preview"
}
```

Remove the entire `overrides` block (verify each entry is no longer needed
after migration — most are webpack/CRA internals).

### 2. Add `frontend/vite.config.js`

```js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
})
```

### 3. Move and update `frontend/public/index.html`

Vite uses `index.html` at the project root (not `public/`). Move it and replace
the CRA `%PUBLIC_URL%` placeholder:

```html
<!-- CRA -->
<link rel="icon" href="%PUBLIC_URL%/favicon.ico" />

<!-- Vite -->
<link rel="icon" href="/favicon.ico" />
```

Add a module script entry point in `<body>`:
```html
<script type="module" src="/src/index.js"></script>
```

### 4. Update environment variable references

CRA uses `process.env.REACT_APP_*`. Vite uses `import.meta.env.VITE_*`.

Audit `frontend/src/` for `process.env.REACT_APP_` and rename variables
accordingly, updating any `.env` files to match.

### 5. Replace test runner (optional but recommended)

CRA uses Jest. Vite pairs with **Vitest**, which shares the same API and is a
near-drop-in replacement:

```js
// vite.config.js
export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: './src/setupTests.js',
  },
})
```

`@testing-library/jest-dom` works unchanged with Vitest.

### 6. Update the Dockerfile

Revert the Node pin and update the build output directory:

```dockerfile
# node:22-alpine was pinned because CRA is incompatible with Node 24+.
# After the Vite migration that constraint is gone.
FROM node:lts-alpine as build
WORKDIR /app
COPY frontend/package.json ./
COPY frontend/package-lock.json ./
RUN npm ci
COPY frontend ./
RUN npm run build
```

Update the nginx `COPY` line (Vite outputs to `dist/`, not `build/`):
```dockerfile
# Before
COPY --from=build /app/build /usr/share/nginx/html

# After
COPY --from=build /app/dist /usr/share/nginx/html
```

Also remove the `COPY frontend/.npmrc ./` line added as a CRA workaround.

### 7. Run and verify

```bash
nerdctl compose up -d --build
curl http://localhost:3000/   # expect 200
```

Run the integration test suite per CONTRIBUTING.md.

## Risk assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| `process.env.REACT_APP_*` references missed | Low | `grep -r REACT_APP frontend/src` |
| `%PUBLIC_URL%` in HTML/assets | Low | `grep -r PUBLIC_URL frontend/public` |
| Jest-specific APIs not in Vitest | Low | Vitest is API-compatible; check `jest.mock()` usage |
| nginx serving wrong build directory | Low | One-line Dockerfile path change |
| CRA webpack aliases (`~` imports) | Low | `grep -r "from '~" frontend/src` |

## What to clean up after migration

- The entire `overrides` block in `package.json` (verify each entry before removing)
- `frontend/.npmrc`
- `frontend/src/serviceWorker.js` (CRA artifact)
- The `node:22-alpine` pin in the Dockerfile (revert to `node:lts-alpine`)

## Reference

- [Vite migration guide](https://vite.dev/guide/)
- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react)
- [Vitest](https://vitest.dev/)
