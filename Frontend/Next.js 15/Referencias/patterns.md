# Next.js — Performance e Padrões Comuns

## next/image — Otimização de Imagens

```tsx
import Image from 'next/image'

// Imagem local (tamanho inferido automaticamente)
import heroImg from '@/public/hero.jpg'
<Image src={heroImg} alt="Hero" priority />  // priority para LCP

// Imagem remota (tamanho obrigatório)
<Image
  src="https://cdn.example.com/foto.jpg"
  alt="Produto"
  width={800}
  height={600}
  sizes="(max-width: 768px) 100vw, 50vw"  // obrigatório para responsividade
  loading="lazy"  // padrão — use priority para above-the-fold
/>

// Fill (preenche o container)
<div className="relative h-64 w-full">
  <Image src={product.image} alt={product.name} fill className="object-cover" />
</div>
```

**next.config.ts** — domínios permitidos:
```ts
const nextConfig = {
  images: {
    remotePatterns: [
      { protocol: 'https', hostname: '**.supabase.co' },
      { protocol: 'https', hostname: 'cdn.example.com' },
    ],
  },
}
```

---

## next/font — Zero Layout Shift

```tsx
// app/layout.tsx
import { Geist, Fraunces } from 'next/font/google'
import localFont from 'next/font/local'

const geist = Geist({
  subsets: ['latin'],
  variable: '--font-geist',  // expõe como CSS variable
})

const fraunces = Fraunces({
  subsets: ['latin'],
  variable: '--font-fraunces',
  axes: ['opsz'],  // optical size axis
})

export default function RootLayout({ children }) {
  return (
    <html lang="pt-BR" className={`${geist.variable} ${fraunces.variable}`}>
      <body className="font-sans">{children}</body>
    </html>
  )
}
```

```css
/* globals.css */
:root {
  --font-body: var(--font-geist), sans-serif;
  --font-display: var(--font-fraunces), serif;
}
body { font-family: var(--font-body); }
h1, h2, h3 { font-family: var(--font-display); }
```

---

## Code Splitting com next/dynamic

```tsx
import dynamic from 'next/dynamic'

// Carrega componente só quando necessário (ex: modal pesado)
const HeavyChart = dynamic(() => import('@/components/HeavyChart'), {
  loading: () => <p>Carregando...</p>,
  ssr: false,  // desabilita SSR (para componentes que usam window)
})

// Com named export
const MapComponent = dynamic(
  () => import('@/components/Map').then(mod => mod.MapComponent),
  { ssr: false }
)
```

---

## Parallel Routes (layouts com slots)

```
app/
├── @main/
│   └── page.tsx
├── @sidebar/
│   └── page.tsx
└── layout.tsx

// layout.tsx recebe os slots como props
export default function Layout({ main, sidebar }) {
  return (
    <div className="flex">
      <aside>{sidebar}</aside>
      <main>{main}</main>
    </div>
  )
}
```

---

## Intercepting Routes (modais com URL)

```
app/
├── gallery/
│   ├── page.tsx           ← /gallery (lista)
│   └── [id]/
│       └── page.tsx       ← /gallery/123 (página completa)
└── @modal/
    └── (.)gallery/[id]/
        └── page.tsx       ← abre como modal quando navega da lista
```

---

## Padrão: Auth com Middleware + Session

```ts
// middleware.ts
import { getToken } from 'next-auth/jwt'

export async function middleware(request: NextRequest) {
  const token = await getToken({ req: request })

  if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
    const loginUrl = new URL('/login', request.url)
    loginUrl.searchParams.set('callbackUrl', request.nextUrl.pathname)
    return NextResponse.redirect(loginUrl)
  }

  return NextResponse.next()
}
```

```tsx
// lib/auth.ts — helper reutilizável para Server Components
import { getServerSession } from 'next-auth'
import { redirect } from 'next/navigation'

export async function requireAuth() {
  const session = await getServerSession()
  if (!session) redirect('/login')
  return session
}

// Uso em Server Components:
export default async function DashboardPage() {
  const session = await requireAuth()
  return <div>Olá {session.user.name}</div>
}
```

---

## Padrão: Optimistic UI com useOptimistic

```tsx
'use client'
import { useOptimistic } from 'react'
import { toggleLike } from '@/actions/posts'

export function LikeButton({ postId, initialLiked, initialCount }) {
  const [optimisticState, setOptimistic] = useOptimistic(
    { liked: initialLiked, count: initialCount },
    (state, action: 'toggle') => ({
      liked: !state.liked,
      count: state.liked ? state.count - 1 : state.count + 1,
    })
  )

  async function handleClick() {
    setOptimistic('toggle')  // UI atualiza imediatamente
    await toggleLike(postId) // servidor confirma no fundo
  }

  return (
    <button onClick={handleClick}>
      {optimisticState.liked ? '❤️' : '🤍'} {optimisticState.count}
    </button>
  )
}
```

---

## generateStaticParams — Rotas Estáticas Dinâmicas

```tsx
// app/blog/[slug]/page.tsx

// Gera páginas estáticas em build time
export async function generateStaticParams() {
  const posts = await getAllPosts()
  return posts.map(post => ({ slug: post.slug }))
}

// Comportamento quando slug não está na lista:
export const dynamicParams = true   // gera on-demand (padrão)
export const dynamicParams = false  // retorna 404
```


---

← [[README|Next.js 15]]
