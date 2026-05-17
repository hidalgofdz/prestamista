---
name: css-patterns
description: Writes and modifies stylesheets using native CSS with cascade layers, OKLCH design tokens, BEM naming, component-scoped custom properties, and logical properties. Use when adding new components, modifying existing styles, implementing dark mode, or reviewing CSS changes.
---

# Writing CSS

## Architecture

Plain CSS served by Propshaft — no Sass, PostCSS, Tailwind, or build step. Files in `app/assets/stylesheets/` are served directly.

Cascade layers declared in `_global.css`:

```css
@layer reset, base, components, modules, utilities, native, platform;
```

Every rule must live inside an `@layer` block.

## Quick start

New component → new file → wrap in layer:

```css
@layer components {
  .badge {
    background-color: var(--badge-bg, var(--color-ink-lightest));
    color: var(--badge-color, var(--color-ink));
    border-radius: var(--badge-radius, 99rem);
    padding: var(--badge-padding, 0.2em 0.6em);
  }

  .badge--accent {
    --badge-bg: var(--color-link);
    --badge-color: var(--color-ink-inverted);
  }
}
```

## Workflow

1. Read `_global.css` for available tokens
2. Search existing files for similar patterns
3. Identify the correct layer (see [references/layers.md](references/layers.md))
4. Write styles using tokens, logical properties, and native nesting
5. Handle dark mode if semantic variables aren't sufficient
6. Verify no hardcoded values slipped in

## Key patterns

**Tokens** — never hardcode colors, spacing, font sizes, or z-index:

```css
color: var(--color-ink-dark);
padding: var(--block-space) var(--inline-space);
font-size: var(--text-small);
z-index: var(--z-popup);
```

**Logical properties** — use `inline-size`, `block-size`, `margin-block-start`, `padding-inline`, etc. instead of physical equivalents.

**Component customization** — expose `--component-property` variables with defaults. Modifiers override the variables, not the properties.

**Dark mode** — semantic color variables adapt automatically. For component-specific overrides, handle both triggers:

```css
html[data-theme="dark"] & { /* explicit */ }

@media (prefers-color-scheme: dark) {
  html:not([data-theme]) & { /* system fallback */ }
}
```

**BEM naming** — `.block`, `.block__element`, `.block--modifier`. No deep nesting.

**Responsive** — mobile-first with nested `@media (min-width: ...)`. Use `@media (any-hover: hover)` for pointer interactions.

## References

- [references/layers.md](references/layers.md) — layer assignment table and examples
- [references/dark-mode.md](references/dark-mode.md) — dark mode implementation patterns
