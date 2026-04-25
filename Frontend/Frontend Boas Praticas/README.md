---
tags: [frontend]
categoria: "Frontend"
---

# Boas Práticas de Frontend — Guia Profissional

**Princípio:** Frontend de qualidade une performance, acessibilidade, manutenibilidade e experiência do usuário. Nenhum aspecto pode ser sacrificado pelos outros.

---

## Core Web Vitals — Metas de Performance

| Métrica | O que mede | Meta (Good) |
|---|---|---|
| **LCP** Largest Contentful Paint | Velocidade de carregamento | < 2.5s |
| **INP** Interaction to Next Paint | Responsividade a interações | < 200ms |
| **CLS** Cumulative Layout Shift | Estabilidade visual | < 0.1 |

### Melhorar LCP

```html
<!-- Preload da imagem hero acima da dobra -->
<link rel="preload" as="image" href="/hero.webp" fetchpriority="high" />

<!-- Imagem hero: eager loading + decoding sync -->
<img
  src="/hero.webp"
  alt="Hero image"
  width="1200" height="600"
  loading="eager"
  decoding="sync"
  fetchpriority="high"
/>

<!-- Preconnect para recursos críticos de terceiros -->
<link rel="preconnect" href="https://fonts.googleapis.com" />
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
```

```css
/* Evitar fontes bloqueando renderização */
@font-face {
  font-family: 'MinhaFonte';
  src: url('/fonts/minha-fonte.woff2') format('woff2');
  font-display: swap;   /* mostra fallback imediatamente */
}
```

### Evitar CLS

```css
/* SEMPRE definir width + height em imagens */
img {
  width: 100%;
  height: auto;
  aspect-ratio: 16 / 9; /* ou o ratio correto */
}

/* Reservar espaço para conteúdo dinâmico (ads, embeds) */
.ad-slot {
  min-height: 250px;
  content-visibility: auto;
}

/* Evitar inserir conteúdo acima do fold após carregamento */
```

---

## Otimização de Imagens

```html
<!-- Sempre: WebP com fallback, tamanhos responsive, lazy em imagens fora do fold -->
<picture>
  <source
    srcset="/img/hero-400.webp 400w, /img/hero-800.webp 800w, /img/hero-1200.webp 1200w"
    sizes="(max-width: 768px) 100vw, (max-width: 1200px) 80vw, 1200px"
    type="image/webp"
  />
  <img
    src="/img/hero-800.jpg"
    alt="Descrição detalhada"
    width="1200" height="600"
    loading="lazy"           <!-- lazy para imagens fora do fold -->
    decoding="async"
  />
</picture>
```

```typescript
// Next.js Image component — automático
import Image from 'next/image'

<Image
  src="/hero.webp"
  alt="Hero"
  width={1200}
  height={600}
  priority          // para imagens acima da dobra (sem lazy)
  quality={85}
  sizes="(max-width: 768px) 100vw, 1200px"
/>
```

---

## Bundle Optimization — JavaScript

```typescript
// Code splitting com dynamic import
const HeavyComponent = lazy(() => import('./HeavyComponent'))
const Chart = lazy(() => import('./Chart'))

// Agrupamento por rota (Vite)
// vite.config.ts
rollupOptions: {
  output: {
    manualChunks: {
      'vendor':    ['react', 'react-dom'],
      'charts':    ['recharts', 'd3'],
      'forms':     ['react-hook-form', 'zod'],
    }
  }
}

// Verificar bundle size
// npx vite-bundle-visualizer
// npx next bundle-analyzer (Next.js)
```

```javascript
// Evitar importar bibliotecas inteiras
// ❌ Importa TUDO do lodash (~70kb)
import _ from 'lodash'
const result = _.debounce(fn, 300)

// ✅ Importar apenas o que precisa
import debounce from 'lodash/debounce'
// Ou usar alternativas nativas:
function debounce(fn, delay) {
  let timer
  return (...args) => { clearTimeout(timer); timer = setTimeout(() => fn(...args), delay) }
}
```

---

## Acessibilidade (WCAG 2.1 AA)

```html
<!-- Estrutura semântica correta -->
<main>
  <h1>Título único da página</h1>
  <nav aria-label="Navegação principal">...</nav>
  <article aria-labelledby="article-title">
    <h2 id="article-title">Título do artigo</h2>
  </article>
</main>

<!-- Imagens -->
<img src="produto.jpg" alt="Tênis Nike Air Max branco, tamanho 42" />
<img src="decorativo.svg" alt="" role="presentation" />

<!-- Botões e links claros -->
<button type="button" aria-label="Fechar modal">
  <svg aria-hidden="true">...</svg>
</button>
<a href="/produtos">Ver todos os produtos</a>  <!-- NÃO: "Clique aqui" -->

<!-- Formulários -->
<label for="cpf">CPF <span aria-hidden="true">*</span></label>
<input id="cpf" type="text" inputmode="numeric"
       pattern="[0-9]{3}\.[0-9]{3}\.[0-9]{3}-[0-9]{2}"
       autocomplete="off"
       aria-required="true"
       aria-describedby="cpf-format" />
<span id="cpf-format" class="hint">Formato: 000.000.000-00</span>

<!-- Focus management em modals -->
<dialog aria-modal="true" aria-labelledby="modal-title">
  <h2 id="modal-title">Confirmar ação</h2>
  <button autofocus>Confirmar</button>  <!-- foco automático -->
</dialog>
```

```css
/* Focus visível obrigatório */
:focus-visible {
  outline: 2px solid #005fcc;
  outline-offset: 3px;
  border-radius: 2px;
}

/* Respeitar preferências de movimento */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}

/* Contraste mínimo: 4.5:1 para texto normal, 3:1 para texto grande */
/* Verificar: https://webaim.org/resources/contrastchecker/ */
```

---

## CSS Architecture

```css
/* BEM ou CSS Modules — evitar conflitos de especificidade */

/* BEM */
.card { }
.card__title { }
.card__body { }
.card--featured { }

/* CSS Modules (preferido com React) */
/* Button.module.css */
.button { padding: 0.75rem 1.5rem; }
.button--primary { background: var(--color-primary); }

/* Evitar seletores muito específicos */
/* ❌ */ .header nav ul li a:hover { }
/* ✅ */ .nav-link:hover { }

/* @layer para controle de especificidade */
@layer reset, base, components, utilities;
@layer components {
  .button { /* estilos do componente */ }
}
@layer utilities {
  .mt-4 { margin-top: 1rem; }  /* sempre vence sem !important */
}
```

---

## Convenções de Componentes React

```typescript
// Estrutura de arquivo de componente
// components/ProductCard/
// ├── ProductCard.tsx     ← componente principal
// ├── ProductCard.test.tsx
// ├── ProductCard.module.css
// └── index.ts           ← re-exporta

// Tipagem completa de props
interface ProductCardProps {
  product: Product
  onAddToCart: (id: string) => void
  variant?: 'default' | 'compact' | 'featured'
  className?: string  // sempre aceitar className para extensibilidade
}

// Componente focado e sem side-effects
export function ProductCard({
  product,
  onAddToCart,
  variant = 'default',
  className,
}: ProductCardProps) {
  // Lógica mínima — extrair hooks se ficar complexo
  const { price, discount } = useProductPricing(product)

  return (
    <article className={cn(styles.card, styles[variant], className)}>
      {/* ... */}
    </article>
  )
}

// Regras de ouro de componentes:
// 1. Single responsibility — um componente, uma tarefa
// 2. < 200 linhas — se maior, dividir
// 3. Props tipadas com TypeScript
// 4. Sem lógica de negócio (mover para hooks/services)
// 5. Sempre aceitar className para customização
// 6. Usar forwardRef quando for um elemento HTML wrapeado
```

---

## SEO Técnico

```tsx
// Next.js App Router — metadata
export const metadata: Metadata = {
  title: {
    template: '%s | Nome do Site',
    default: 'Nome do Site',
  },
  description: 'Descrição de 150–160 chars com keyword principal.',
  keywords: ['keyword1', 'keyword2'],
  openGraph: {
    type: 'website',
    locale: 'pt_BR',
    url: 'https://seusite.com',
    title: 'Título para Redes Sociais',
    description: 'Descrição para preview de link',
    images: [{ url: '/og-image.jpg', width: 1200, height: 630, alt: 'Description' }],
  },
  twitter: {
    card: 'summary_large_image',
    creator: '@seuhandle',
  },
  robots: {
    index: true, follow: true,
    googleBot: { index: true, follow: true },
  },
  alternates: {
    canonical: 'https://seusite.com/pagina',
  },
}

// JSON-LD para Rich Results
const jsonLd = {
  '@context': 'https://schema.org',
  '@type': 'Product',
  name: product.name,
  description: product.description,
  offers: {
    '@type': 'Offer',
    price: product.price,
    priceCurrency: 'BRL',
    availability: 'https://schema.org/InStock',
  },
}
// <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
```

---

## Referências

→ `references/performance-checklist.md` — Checklist completo de performance antes de deploy


---

## Relacionado

[[HTML e CSS]] | [[React 19]] | [[Next.js 15]] | [[Frontend Design]]


---

## Referencias

- [[Referencias/performance-checklist]]
