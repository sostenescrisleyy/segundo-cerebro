# Next.js 15 — Sistema de Cache

## Os 4 Camadas de Cache

| Cache | O que armazena | Onde | Duração padrão |
|---|---|---|---|
| **Request Memoization** | Resultado de `fetch()` idênticos no mesmo render | Memória (por request) | Um ciclo de render |
| **Data Cache** | Respostas de `fetch()` | Servidor (persistente) | Indefinida até revalidação |
| **Full Route Cache** | HTML + RSC payload renderizado | Servidor (build/runtime) | Até revalidação |
| **Router Cache** | RSC payload no cliente | Browser (memória) | 30s (dynamic) / 5min (static) |

---

## Controlando o Data Cache

```tsx
// force-cache: salva no Data Cache indefinidamente (SSG comportamento)
fetch(url, { cache: 'force-cache' })

// no-store: nunca cacheia (SSR a cada request)
fetch(url, { cache: 'no-store' })

// revalidate por tempo: ISR
fetch(url, { next: { revalidate: 3600 } })  // revalida após 1h

// revalidate por tag: revalidação sob demanda
fetch(url, { next: { tags: ['posts', 'post-1'] } })
```

## Revalidação sob demanda

```ts
// Em Server Actions ou Route Handlers:
import { revalidatePath, revalidateTag } from 'next/cache'

// Invalida todas as rotas que usam dados com esta tag
revalidateTag('posts')
revalidateTag('post-' + postId)

// Invalida uma rota específica
revalidatePath('/blog')
revalidatePath('/blog/[slug]', 'page')    // somente a página
revalidatePath('/blog', 'layout')         // layout + todas as páginas filhas
```

## Segmentos de Rota vs Fetch

```tsx
// Nível de página (afeta toda a rota)
export const dynamic = 'force-dynamic'    // sem cache (equivale ao getServerSideProps)
export const dynamic = 'force-static'     // força cache mesmo com cookies/headers
export const revalidate = 60              // ISR — revalida após 60s
export const revalidate = false           // nunca revalida (forever cache)

// Fetch individual tem precedência sobre o segmento quando é mais restritivo
// page revalidate=60, mas um fetch com cache:'no-store' ainda é dinâmico
```

## Opt-out de cache no router (Client)

```tsx
import { useRouter } from 'next/navigation'
const router = useRouter()

// Forçar refresh completo (invalida Router Cache)
router.refresh()

// Link sem prefetch
<Link href="/blog" prefetch={false}>Blog</Link>
```

---

## Debugging de Cache em Dev

```bash
# Ver cache hits/misses no terminal durante desenvolvimento
NEXT_TELEMETRY_DEBUG=1 npm run dev

# No log, procure por:
# [Cache] HIT  → servindo do cache
# [Cache] MISS → buscando dado fresco
# [Cache] SKIP → cache desabilitado para esta rota
```


---

← [[README|Next.js 15]]
