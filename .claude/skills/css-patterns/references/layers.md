# Layer Assignment

| Layer | Purpose | Examples |
|-------|---------|----------|
| `reset` | Browser normalization | Box-sizing, margin removal, reduced-motion |
| `base` | Element defaults, layout scaffold | Body styles, links, grid shell |
| `components` | Reusable UI blocks | Buttons, cards, panels, dialogs |
| `modules` | Page/feature-specific compositions | Feature views, page layouts |
| `utilities` | Single-purpose helpers | Text sizes, flex helpers, visibility |
| `native` | Mobile app overrides | Native shell adjustments |
| `platform` | iOS/Android adjustments | Platform-specific tweaks |

## Examples

```css
/* reset.css */
@layer reset {
  *, *::before, *::after { box-sizing: border-box; }
}

/* base.css */
@layer base {
  body { background: var(--color-canvas); color: var(--color-ink); }
}

/* buttons.css */
@layer components {
  .btn { padding: var(--btn-padding, 0.5em 1.1em); }
  .btn--link { --btn-background: var(--color-link); }
}

/* utilities.css */
@layer utilities {
  .txt-small { font-size: var(--text-small); }
  .flex { display: flex; }
}
```
