# Theming e Dark Mode

## Estrutura de Tokens com Suporte a Temas

A única forma correta de suportar dark mode é com semantic tokens — nunca hard-code cores diretamente.

```css
/* 1. Primitives (imutáveis) */
:root {
  --zinc-50:  #fafafa;  --zinc-900: #18181b;
  --blue-500: #3b82f6;  --blue-600: #2563eb;
  --green-500: #22c55e; --red-500: #ef4444;
}

/* 2. Light theme (default) */
:root {
  --bg-base:       var(--zinc-50);
  --bg-elevated:   #ffffff;
  --bg-sunken:     var(--zinc-100);
  --text-primary:  var(--zinc-900);
  --text-secondary: var(--zinc-500);
  --border:        var(--zinc-200);
  --action:        var(--blue-600);
  --action-hover:  var(--blue-700);
}

/* 3. Dark theme override */
[data-theme="dark"],
.dark,
@media (prefers-color-scheme: dark) {
  :root {
    --bg-base:       var(--zinc-950);
    --bg-elevated:   var(--zinc-900);
    --bg-sunken:     var(--zinc-800);
    --text-primary:  var(--zinc-50);
    --text-secondary: var(--zinc-400);
    --border:        rgba(255,255,255,0.08);
    --action:        var(--blue-400);     /* mais claro no dark */
    --action-hover:  var(--blue-300);
  }
}
```

## Toggling com JavaScript

```typescript
// Persist em localStorage + respeitar preferência do sistema
function initTheme() {
  const stored = localStorage.getItem('theme')
  const system = window.matchMedia('(prefers-color-scheme: dark)').matches
  const isDark = stored === 'dark' || (!stored && system)
  document.documentElement.dataset.theme = isDark ? 'dark' : 'light'
}

function toggleTheme() {
  const current = document.documentElement.dataset.theme
  const next = current === 'dark' ? 'light' : 'dark'
  document.documentElement.dataset.theme = next
  localStorage.setItem('theme', next)
}

// Executar ANTES do render para evitar flash
// Colocar em <script> inline no <head>
initTheme()
```

## Armadilhas do Dark Mode

```css
/* ❌ Errado — nunca inverter diretamente */
@media (prefers-color-scheme: dark) {
  body { filter: invert(1); }  /* inverte imagens também */
}

/* ❌ Errado — cor hardcoded que quebra no dark */
.card { background: white; color: black; }

/* ✅ Correto — sempre tokens semânticos */
.card {
  background: var(--bg-elevated);
  color: var(--text-primary);
  border: 1px solid var(--border);
}
```

## Imagens no Dark Mode

```css
/* Logos e ícones SVG que precisam adaptar */
.logo { filter: none; }
[data-theme="dark"] .logo {
  filter: brightness(0) invert(1);  /* SVG preto → branco */
}

/* Imagens de foto — levemente escurecer no dark */
[data-theme="dark"] img:not([src$=".svg"]) {
  filter: brightness(0.9);
}
```


---

← [[README|Frontend Design System]]
