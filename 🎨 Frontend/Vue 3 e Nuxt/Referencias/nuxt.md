# Nuxt 3 — SSR e Meta-framework

## Estrutura de Pastas

```
nuxt-app/
├── pages/          → roteamento automático baseado em arquivo
├── components/     → auto-importados
├── composables/    → auto-importados (use*)
├── server/
│   ├── api/        → rotas de API (server/api/users.get.ts)
│   └── middleware/ → middleware de servidor
├── middleware/     → middleware de rota (client-side)
├── layouts/        → layouts reutilizáveis
├── plugins/        → plugins Vue
└── nuxt.config.ts
```

## Server Routes (API Backend)

```typescript
// server/api/users.get.ts
export default defineEventHandler(async (event) => {
  const query = getQuery(event)  // query params
  const users = await db.users.findMany()
  return users
})

// server/api/users.post.ts
export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  const user = await db.users.create({ data: body })
  setResponseStatus(event, 201)
  return user
})

// server/api/users/[id].delete.ts
export default defineEventHandler(async (event) => {
  const id = getRouterParam(event, 'id')
  await db.users.delete({ where: { id } })
  return { success: true }
})
```

## Data Fetching

```vue
<script setup lang="ts">
// useFetch — SSR-aware, com cache automático
const { data: users, refresh } = await useFetch<User[]>('/api/users')

// useAsyncData — para lógica customizada
const { data: post } = await useAsyncData('post', () =>
  $fetch(`/api/posts/${route.params.id}`)
)

// Lazy (não bloqueia a navegação)
const { data, pending } = useLazyFetch('/api/heavy-data')
</script>
```

## nuxt.config.ts

```typescript
export default defineNuxtConfig({
  devtools: { enabled: true },
  modules: ['@pinia/nuxt', '@nuxtjs/tailwindcss', 'nuxt-icon'],
  runtimeConfig: {
    // server-only (não exposto ao cliente)
    databaseUrl: process.env.DATABASE_URL,
    // exposto ao cliente (prefixo public)
    public: { apiBase: process.env.API_BASE_URL ?? '/api' }
  },
  routeRules: {
    '/':          { prerender: true },    // SSG
    '/dashboard': { ssr: false },         // SPA
    '/api/**':    { cors: true },
  },
})
```


---

← [[README|Vue 3 e Nuxt]]
