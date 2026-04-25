---
tags: [agentes]
categoria: "Agentes"
---


# Otimizador de Performance Web — Core Web Vitals

**Regra de Ouro:** Medir antes de otimizar. Nunca assumir onde está o gargalo.

---

## Core Web Vitals — Metas 2025

| Métrica | Bom | Precisa Melhorar | Ruim |
|---|---|---|---|
| **LCP** — Largest Contentful Paint | ≤ 2.5s | 2.5s – 4s | > 4s |
| **INP** — Interaction to Next Paint | ≤ 200ms | 200ms – 500ms | > 500ms |
| **CLS** — Cumulative Layout Shift | ≤ 0.1 | 0.1 – 0.25 | > 0.25 |
| **TTFB** — Time to First Byte | ≤ 800ms | 800ms – 1.8s | > 1.8s |
| **FCP** — First Contentful Paint | ≤ 1.8s | 1.8s – 3s | > 3s |

---

## Fluxo de Otimização

### Passo 1: Medir

```bash
# Lighthouse local
npx lighthouse http://localhost:3000 --output=html --output-path=./perf.html
npx lighthouse http://localhost:3000 --view   # abre resultado no browser

# Bundle analysis
npx @next/bundle-analyzer  # Next.js
npx vite-bundle-visualizer  # Vite

# Web Vitals no código
npm install web-vitals
```

```typescript
// Monitorar Web Vitals em produção
import { onCLS, onINP, onLCP, onFCP, onTTFB } from 'web-vitals'

function reportMetric(metric: any) {
  // Enviar para seu analytics
  fetch('/api/vitals', {
    method: 'POST',
    body: JSON.stringify(metric),
  })
  console.log(metric)
}

onCLS(reportMetric)
onINP(reportMetric)
onLCP(reportMetric)
onFCP(reportMetric)
onTTFB(reportMetric)
```

---

## Otimizar LCP

### 1. Preload da imagem hero

```html
<!-- Preload da maior imagem acima da dobra -->
<link
  rel="preload"
  as="image"
  href="/hero.webp"
  imageSrcset="/hero-400.webp 400w, /hero-800.webp 800w, /hero-1200.webp 1200w"
  imageSizes="100vw"
  fetchpriority="high"
/>
```

```tsx
// Next.js Image com priority
<Image
  src="/hero.webp"
  alt="Hero"
  width={1200}
  height={600}
  priority        // ← remove lazy load, adiciona preload automático
  quality={85}
  sizes="(max-width: 768px) 100vw, 1200px"
/>
```

### 2. Fontes sem bloqueio

```css
@font-face {
  font-family: 'MinhaFonte';
  src: url('/fonts/fonte.woff2') format('woff2');
  font-display: optional;  /* não causa layout shift — mais agressivo */
  /* ou: font-display: swap; — usa fallback enquanto carrega */
}
```

```tsx
// Next.js — fontes com preload automático
import { Inter } from 'next/font/google'

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
  preload: true,
})
```

---

## Otimizar CLS

```css
/* SEMPRE definir dimensões em imagens */
img {
  width: 100%;
  height: auto;
  aspect-ratio: 16 / 9;  /* reserva espaço antes de carregar */
}

/* Reservar espaço para conteúdo dinâmico */
.ad-container {
  min-height: 250px;
  width: 300px;
}

/* Evitar inserir conteúdo acima de conteúdo existente */
.notification-bar {
  position: fixed;    /* ou usar padding-top no body */
  top: 0;
}
```

---

## Otimizar INP (Interatividade)

```typescript
// ❌ Tarefa longa bloqueando main thread
function processarDadosGigantes(dados: number[]) {
  return dados.reduce((acc, val) => {
    // operação pesada — bloqueia UI por centenas de ms
    return acc + Math.sqrt(val) * Math.PI
  }, 0)
}

// ✅ Quebrar em chunks com yield
async function processarEmChunks(dados: number[]): Promise<number> {
  let resultado = 0
  const CHUNK_SIZE = 1000

  for (let i = 0; i < dados.length; i += CHUNK_SIZE) {
    const chunk = dados.slice(i, i + CHUNK_SIZE)
    resultado += chunk.reduce((acc, val) => acc + Math.sqrt(val) * Math.PI, 0)

    // Ceder controle ao browser entre chunks
    await new Promise(resolve => setTimeout(resolve, 0))
    // ou: await scheduler.yield()  (mais moderno, se disponível)
  }

  return resultado
}

// ✅ useTransition para updates não-urgentes no React
const [isPending, startTransition] = useTransition()

function handleSearch(query: string) {
  // Update urgente (imediato)
  setSearchQuery(query)

  // Update não-urgente (pode ser adiado)
  startTransition(() => {
    setFilteredResults(filtrarResultados(query))
  })
}
```

---

## Bundle — Reduzir Tamanho

### Analisar e identificar problemas

```bash
# Next.js bundle analyzer
ANALYZE=true npm run build

# Ver tamanho das dependências
npx bundlephobia moment     # quanto pesa o moment.js
npx bundlephobia date-fns   # alternativa menor

# Duplicações no bundle
npx webpack-bundle-analyzer dist/
```

### Substituições de bibliotecas pesadas

| Biblioteca Pesada | Alternativa Leve | Redução |
|---|---|---|
| `moment.js` (67kb) | `date-fns` (apenas o que usar) | ~60kb |
| `lodash` (71kb) | `lodash-es` + tree-shaking | ~50kb+ |
| `axios` (32kb) | `fetch` nativo | 32kb |
| `react-icons` (todos) | Importar ícone específico | Enorme |
| `framer-motion` (110kb) | CSS transitions ou GSAP | 60-100kb |

```typescript
// ❌ Importa TUDO do lodash (71kb)
import _ from 'lodash'
const result = _.debounce(fn, 300)

// ✅ Importa só o que precisa (< 1kb)
import debounce from 'lodash/debounce'

// ✅ Ou implementar o necessário diretamente
function debounce<T extends (...args: any[]) => any>(fn: T, delay: number) {
  let timer: ReturnType<typeof setTimeout>
  return (...args: Parameters<T>) => {
    clearTimeout(timer)
    timer = setTimeout(() => fn(...args), delay)
  }
}
```

### Code Splitting com Dynamic Import

```typescript
// ❌ Importa tudo no bundle inicial
import { ChartDashboard } from './ChartDashboard'
import { VideoPlayer } from './VideoPlayer'
import { RichTextEditor } from './RichTextEditor'

// ✅ Carrega só quando necessário
const ChartDashboard = lazy(() => import('./ChartDashboard'))
const VideoPlayer     = lazy(() => import('./VideoPlayer'))
const RichTextEditor  = lazy(() => import('./RichTextEditor'))

// Com Suspense:
<Suspense fallback={<Skeleton />}>
  <ChartDashboard />
</Suspense>

// Vite — chunks manuais
// vite.config.ts
rollupOptions: {
  output: {
    manualChunks: {
      'vendor':   ['react', 'react-dom'],
      'charts':   ['recharts', 'd3'],
      'editor':   ['@tiptap/react', '@tiptap/starter-kit'],
    }
  }
}
```

---

## React — Otimizações de Rendering

```typescript
// memo — evitar re-render quando props não mudam
const UserCard = memo(({ user }: { user: User }) => {
  return <div>{user.name}</div>
}, (prevProps, nextProps) => {
  // retornar true se props são IGUAIS (não re-renderizar)
  return prevProps.user.id === nextProps.user.id
})

// useCallback — estabilizar referência de função
const handleDelete = useCallback((id: string) => {
  deleteUser(id)
}, [])  // ← sem dependências = mesma referência sempre

// useMemo — cálculo pesado
const dadosFiltrados = useMemo(() => {
  return dados
    .filter(d => d.ativo)
    .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
    .slice(0, 100)
}, [dados])  // ← recalcula só quando `dados` muda

// Virtualização para listas longas
import { useVirtual } from '@tanstack/react-virtual'

// ou com react-window:
import { FixedSizeList } from 'react-window'

<FixedSizeList
  height={600}
  itemCount={10000}
  itemSize={60}
  width="100%"
>
  {({ index, style }) => (
    <div style={style}>
      <UserRow user={users[index]} />
    </div>
  )}
</FixedSizeList>
```

---

## Anti-Padrões Comuns

❌ Otimizar sem medir antes (premature optimization)
❌ `will-change: transform` em todos os elementos
❌ Usar `<img>` quando `next/image` está disponível
❌ Carregar scripts de terceiros no `<head>` sem `defer`/`async`
❌ Esquecer `loading="lazy"` em imagens abaixo da dobra
❌ `memo` em tudo — tem custo, usar com critério
❌ Cálculos pesados no render sem `useMemo`

---

## Relacionado

- [[Performance Imagens]]
- [[SEO Specialist]]
- [[Arquiteto de Banco]]
- [[Orquestrador]]
