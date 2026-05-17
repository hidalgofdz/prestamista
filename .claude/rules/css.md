---
paths:
  - "app/assets/stylesheets/**/*.css"
---

# CSS Rules

## Architecture

- Every rule must live inside an `@layer` block — no top-level styles
- One component per file, named after the component
- Native CSS only — no Sass, Less, PostCSS, or CSS-in-JS

## Tokens

- Never hardcode colors — use `--color-*` or `oklch(var(--lch-*))`
- Never hardcode spacing — use `--inline-space`, `--block-space` (and `half`/`double`)
- Never hardcode font sizes — use `--text-x-small` through `--text-xx-large`
- Never hardcode z-index — use `--z-popup`, `--z-nav`, `--z-flash`, `--z-tooltip`, etc.

## Properties

- Use logical properties: `inline-size` not `width`, `block-size` not `height`, `margin-block-start` not `margin-top`, `padding-inline` not `padding-left`
- No `!important` — cascade layers handle specificity (only exception: `[hidden]`)
- Use native CSS nesting for pseudo-elements, media queries, and state changes

## Components

- BEM naming: `.block`, `.block__element`, `.block--modifier` — no deep nesting
- Customize via internal custom properties with defaults: `var(--component-prop, fallback)`
- Icons use CSS masks: `.icon--name { --svg: url("name.svg"); }`

## Dark mode

- Prefer semantic color variables (they adapt automatically)
- When overrides are needed, handle BOTH `html[data-theme="dark"]` AND `@media (prefers-color-scheme: dark) { html:not([data-theme]) }` — never just one

## Responsive

- Mobile-first with nested `@media (min-width: ...)` inside the component
- Breakpoints: `640px` (tablet), `800px` (desktop), `100ch` (wide content)
- Use `@media (any-hover: hover)` for hover states, `@media (any-hover: none)` for touch

## Accessibility

- Respect `prefers-reduced-motion: reduce` — do not override the reset
- Maintain focus visibility via `--focus-ring-color`, `--focus-ring-size`, `--focus-ring-offset`
