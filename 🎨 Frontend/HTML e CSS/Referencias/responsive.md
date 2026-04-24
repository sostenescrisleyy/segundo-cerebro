# HTML/CSS — Responsivo e Truques Modernos

## Mobile-First com Media Queries

```css
/* Mobile-first: base sem prefixo, adiciona para telas maiores */
.container {
  width: 100%;
  padding-inline: 1rem;
}

@media (min-width: 640px)  { .container { max-width: 640px;  padding-inline: 1.5rem; } }
@media (min-width: 768px)  { .container { max-width: 768px;  } }
@media (min-width: 1024px) { .container { max-width: 1024px; padding-inline: 2rem; } }
@media (min-width: 1280px) { .container { max-width: 1280px; } }
@media (min-width: 1536px) { .container { max-width: 1536px; } }

/* Utilitário: mostrar/esconder */
@media (max-width: 767px)  { .desktop-only { display: none; } }
@media (min-width: 768px)  { .mobile-only  { display: none; } }
```

## Tipografia Fluida

```css
/* Escala fluida sem media queries */
:root {
  --text-sm:   clamp(0.8rem,  0.7rem  + 0.5vw, 0.9rem);
  --text-base: clamp(1rem,    0.9rem  + 0.5vw, 1.1rem);
  --text-lg:   clamp(1.1rem,  1rem    + 1vw,   1.3rem);
  --text-xl:   clamp(1.25rem, 1rem    + 1.5vw, 1.75rem);
  --text-2xl:  clamp(1.5rem,  1.1rem  + 2vw,   2.5rem);
  --text-3xl:  clamp(2rem,    1.2rem  + 3vw,   3.5rem);
}
```

## Truques CSS Modernos

```css
/* Scroll-driven animations (sem JS) */
@keyframes progress-bar {
  from { transform: scaleX(0); }
  to   { transform: scaleX(1); }
}
.progress {
  animation: progress-bar linear;
  animation-timeline: scroll();
  transform-origin: left;
}

/* Backdrop filter (glassmorphism) */
.glass {
  background: rgb(255 255 255 / 0.1);
  backdrop-filter: blur(12px) saturate(180%);
  border: 1px solid rgb(255 255 255 / 0.2);
}

/* Gradiente de texto */
.gradient-text {
  background: linear-gradient(135deg, #7c3aed, #3b82f6);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

/* Sticky com fallback */
.sticky-header {
  position: sticky;
  top: 0;
  z-index: 100;
  background: rgb(var(--bg) / 0.8);
  backdrop-filter: blur(8px);
}

/* Truncar texto */
.truncate       { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.line-clamp-2   { display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }

/* Espaçamento lógico (multilingual) */
.card { padding-inline: 1.5rem; padding-block: 1rem; }
h2    { margin-block-end: 0.5rem; }
```


---

← [[README|HTML e CSS]]
