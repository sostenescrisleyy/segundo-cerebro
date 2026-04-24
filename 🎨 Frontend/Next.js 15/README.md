---
tags: [frontend]
categoria: "🎨 Frontend"
---

# Next.js 15 — App Router: Guia de Referência

**Versão de referência:** Next.js 15 (App Router)  
**Docs:** https://nextjs.org/docs  
**Runtime padrão:** Node.js (Edge disponível por rota)

---

## Arquitetura Mental: Server First

```
Regra: Todo componente é Server Component por padrão.
Só adicionar "use client" quando precisar de: estado, efeitos, eventos do browser, APIs do browser.
```

| Tipo | Quando usar | Pode usar |
|---|---|---|
| **Server Component** | Fetch de dados, DB, lógica de negócio | async/await, fetch, fs, variáveis de servidor |
| **Client Component** | useState, useEffect, onClick, browser APIs | hooks, eventos, window/document |

**Padrão chave:** Server Components podem *passar* Server Components como `children` para Client Components — o inverso não existe.

```tsx
// ✅ Padrão correto: Server Component como children de Client Component
// Modal.tsx (Client)
'use client'
export default function Modal({ children }: { children: React.ReactNode }) {
  const [open, setOpen] = useState(false)
  return <div>{open && children}</div>
}

// page.tsx (Server) — Cart é Server Component
import Modal from './Modal'
import Cart from './Cart' // Server Component que faz fetch
export default function Page() {
  return <Modal><Cart /></Modal> // Cart roda no servidor ✅
}
```

---

## Estrutura de Projeto

```
src/
├── app/
│   ├── layout.tsx            ← root layout (html + body)
│   ├── page.tsx              ← /
│   ├── loading.tsx           ← Suspense fallback global
│   ├── error.tsx             ← Error boundary global ('use client')
│   ├── not-found.tsx         ← 404
│   ├── globals.css
│   ├── (marketing)/          ← Route Group (não afeta URL)
│   │   ├── layout.tsx        ← layout só para este grupo
│   │   └── about/page.tsx    ← /about
│   ├── dashboard/
│   │   ├── layout.tsx        ← layout persistente do dashboard
│   │   ├── page.tsx          ← /dashboard
│   │   └── [id]/
│   │       └── page.tsx      ← /dashboard/123
│   └── api/
│       └── webhooks/
│           └── route.ts      ← POST /api/webhooks
├── components/
│   ├── ui/                   ← primitivos (Button, Input, Card)
│   └── features/             ← componentes de domínio
├── lib/
│   ├── db.ts                 ← cliente do banco
│   └── auth.ts               ← helpers de auth
└── actions/
    └── user.ts               ← Server Actions
```

---

## Data Fetching em Server Components

```tsx
// app/products/page.tsx
// fetch() é automaticamente memoizado por request na mesma árvore
export default async function ProductsPage() {
  // Cache estático (SSG) — padrão com force-cache
  const featured = await fetch('https://api.example.com/featured', {
    cache: 'force-cache',
    next: { tags: ['products'] }, // para revalidação por tag
  }).then(r => r.json())

  // ISR — revalidar a cada 60s
  const trending = await fetch('https://api.example.com/trending', {
    next: { revalidate: 60 },
  }).then(r => r.json())

  // Dinâmico — sem cache (por request)
  const personalized = await fetch('https://api.example.com/personalized', {
    cache: 'no-store',
  }).then(r => r.json())

  return <ProductList featured={featured} trending={trending} />
}

// Controle de cache em nível de rota:
export const dynamic = 'force-dynamic'  // sempre SSR
export const revalidate = 3600          // ISR de 1 hora
export const runtime = 'edge'           // Edge runtime
```

### React `cache()` para queries reutilizáveis

```tsx
// lib/queries.ts
import { cache } from 'react'
import { db } from './db'

// Chamadas múltiplas ao mesmo getUser(id) no mesmo render são deduplicadas
export const getUser = cache(async (id: string) => {
  return db.user.findUnique({ where: { id }, select: { id: true, name: true, email: true } })
})

// Em qualquer Server Component:
const user = await getUser(params.id)
```

---

## Server Actions

```tsx
// actions/user.ts
'use server'
import { revalidatePath, revalidateTag } from 'next/cache'
import { z } from 'zod'

const UpdateProfileSchema = z.object({
  name: z.string().min(2).max(100),
  bio:  z.string().max(500).optional(),
})

export async function updateProfile(formData: FormData) {
  // 1. Auth — verificar sessão no servidor
  const session = await getServerSession()
  if (!session) throw new Error('Unauthorized')

  // 2. Validação
  const parsed = UpdateProfileSchema.safeParse({
    name: formData.get('name'),
    bio:  formData.get('bio'),
  })
  if (!parsed.success) return { error: parsed.error.flatten() }

  // 3. Mutação
  await db.user.update({ where: { id: session.user.id }, data: parsed.data })

  // 4. Revalidação
  revalidatePath('/profile')
  revalidateTag('user-' + session.user.id)
  return { success: true }
}
```

```tsx
// components/ProfileForm.tsx
'use client'
import { useActionState } from 'react'  // React 19 — substitui useFormState
import { updateProfile } from '@/actions/user'

export function ProfileForm() {
  const [state, action, isPending] = useActionState(updateProfile, null)

  return (
    <form action={action}>
      <input name="name" required />
      <textarea name="bio" />
      {state?.error && <p>{state.error.fieldErrors.name?.[0]}</p>}
      <button disabled={isPending}>
        {isPending ? 'Salvando...' : 'Salvar'}
      </button>
    </form>
  )
}
```

---

## Route Handlers (API Routes)

```ts
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server'

// GET /api/users
export async function GET(req: NextRequest) {
  const { searchParams } = req.nextUrl
  const page = Number(searchParams.get('page') ?? 1)
  const users = await db.user.findMany({ skip: (page - 1) * 20, take: 20 })
  return NextResponse.json({ users, page })
}

// POST /api/users
export async function POST(req: NextRequest) {
  const body = await req.json()
  // validar, criar, retornar
  return NextResponse.json({ user }, { status: 201 })
}

// Para rotas dinâmicas: app/api/users/[id]/route.ts
export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }  // Next.js 15: params é Promise
) {
  const { id } = await params
  const user = await db.user.findUnique({ where: { id } })
  if (!user) return NextResponse.json({ error: 'Not found' }, { status: 404 })
  return NextResponse.json(user)
}
```

---

## Middleware

```ts
// middleware.ts (raiz do projeto)
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  const token = request.cookies.get('token')?.value

  // Proteger rotas do dashboard
  if (request.nextUrl.pathname.startsWith('/dashboard')) {
    if (!token) {
      return NextResponse.redirect(new URL('/login', request.url))
    }
  }

  // Headers customizados
  const response = NextResponse.next()
  response.headers.set('x-pathname', request.nextUrl.pathname)
  return response
}

export const config = {
  // Rodar middleware apenas nestas rotas (melhor performance)
  matcher: ['/dashboard/:path*', '/api/:path*'],
}
```

---

## Streaming com Suspense

```tsx
// app/dashboard/page.tsx
import { Suspense } from 'react'
import { UserStats, RecentOrders, Notifications } from '@/components'
import { StatsSkeleton, OrdersSkeleton } from '@/components/skeletons'

export default function DashboardPage() {
  return (
    <div>
      <h1>Dashboard</h1>
      {/* Cada Suspense faz streaming independente */}
      <Suspense fallback={<StatsSkeleton />}>
        <UserStats />       {/* Server Component com fetch lento */}
      </Suspense>

      <Suspense fallback={<OrdersSkeleton />}>
        <RecentOrders />    {/* Outro fetch independente */}
      </Suspense>

      <Suspense fallback={<p>Carregando notificações...</p>}>
        <Notifications />
      </Suspense>
    </div>
  )
}
```

---

## Metadata e SEO

```tsx
// app/products/[slug]/page.tsx
import type { Metadata } from 'next'

// Metadata estática
export const metadata: Metadata = {
  title: 'Produtos | MinhaLoja',
  description: 'Os melhores produtos',
}

// Metadata dinâmica
export async function generateMetadata(
  { params }: { params: Promise<{ slug: string }> }
): Promise<Metadata> {
  const { slug } = await params
  const product = await getProduct(slug)

  return {
    title: `${product.name} | MinhaLoja`,
    description: product.description,
    openGraph: {
      title: product.name,
      images: [{ url: product.image }],
    },
  }
}
```

---

## Referências

→ `references/caching.md` — sistema de cache completo (Data Cache, Router Cache, Full Route Cache)  
→ `references/patterns.md` — auth, uploads, internacionalização, optimistic UI  
→ `references/performance.md` — bundle splitting, next/image, next/font, Core Web Vitals


---

## Relacionado

[[React 19]] | [[Tailwind CSS v4]] | [[Supabase]] | [[TypeScript]]


---

## Referencias

- [[Referencias/caching]]
- [[Referencias/patterns]]
