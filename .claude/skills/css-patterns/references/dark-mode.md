# Dark Mode Patterns

## Automatic (preferred)

Use semantic color variables — they adapt without extra code:

```css
.component {
  color: var(--color-ink);
  background: var(--color-canvas);
  border: var(--border);
}
```

## Component-specific overrides

When semantic variables aren't sufficient, handle BOTH triggers:

```css
.component {
  box-shadow: var(--shadow);

  html[data-theme="dark"] & {
    box-shadow: 0 0 0 1px var(--color-ink-lighter);
  }

  @media (prefers-color-scheme: dark) {
    html:not([data-theme]) & {
      box-shadow: 0 0 0 1px var(--color-ink-lighter);
    }
  }
}
```

Never handle only one trigger — users who set an explicit theme and users who rely on system preference must both be covered.

## Available semantic variables

These swap automatically between light and dark:

- `--color-canvas` — page background
- `--color-ink` / `--color-ink-dark` / `--color-ink-medium` / `--color-ink-light` — text and borders
- `--color-ink-inverted` — inverse text (white in light, black in dark)
- `--color-link` — link color
- `--color-negative` / `--color-positive` — status colors
- `--color-selected` / `--color-highlight` — selection and highlights
- `--shadow` — box shadows
