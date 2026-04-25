---
tags: [frontend]
categoria: "Frontend"
---

# Vue 3 — Composition API

**Versão:** Vue 3.5+ | **Meta-framework:** Nuxt 3  
**Princípio:** Composition API com `<script setup>` é o padrão moderno. Pinia para estado global.

---

## Componente — Estrutura Básica

```vue
<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'

// Props com TypeScript
const props = defineProps<{
  title: string
  count?: number       // opcional
  items: string[]
}>()

// Emits tipados
const emit = defineEmits<{
  update: [value: string]   // nome: [parâmetros]
  close: []
}>()

// Estado reativo
const name  = ref('')
const count = ref(props.count ?? 0)

// Computed
const doubled = computed(() => count.value * 2)
const isEmpty  = computed(() => name.value.trim().length === 0)

// Métodos
function increment() {
  count.value++
  emit('update', String(count.value))
}

// Lifecycle
onMounted(() => console.log('montado'))
</script>

<template>
  <div class="card">
    <h2>{{ title }}</h2>
    <p>Dobro: {{ doubled }}</p>

    <input v-model="name" placeholder="Nome" />

    <button :disabled="isEmpty" @click="increment">
      Incrementar ({{ count }})
    </button>

    <!-- v-for sempre com :key -->
    <ul>
      <li v-for="item in items" :key="item">{{ item }}</li>
    </ul>

    <!-- v-if / v-else -->
    <span v-if="count > 10">Alto</span>
    <span v-else>Baixo</span>
  </div>
</template>
```

---

## Reactivity em Profundidade

```typescript
import { ref, reactive, computed, watch, watchEffect, toRefs } from 'vue'

// ref → primitivos e objetos (acesso via .value no script)
const count = ref(0)
const user  = ref<User | null>(null)
count.value++

// reactive → objetos (sem .value, mas não funciona com primitivos)
const state = reactive({
  loading: false,
  error: null as string | null,
  data: [] as User[],
})
state.loading = true  // direto, sem .value

// watch — reage a mudanças específicas
watch(count, (newVal, oldVal) => {
  console.log(`${oldVal} → ${newVal}`)
})

// watch deep para objetos
watch(() => state.data, (data) => {
  console.log('data mudou', data)
}, { deep: true, immediate: true })

// watchEffect — executa quando qualquer dependência muda
watchEffect(() => {
  document.title = `Contagem: ${count.value}`
})
```

---

## Composables — Lógica Reutilizável

```typescript
// composables/useFetch.ts
import { ref, onMounted } from 'vue'

export function useFetch<T>(url: string) {
  const data    = ref<T | null>(null)
  const loading = ref(false)
  const error   = ref<string | null>(null)

  async function fetch() {
    loading.value = true
    error.value   = null
    try {
      const res  = await globalThis.fetch(url)
      data.value = await res.json() as T
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Erro desconhecido'
    } finally {
      loading.value = false
    }
  }

  onMounted(fetch)
  return { data, loading, error, refresh: fetch }
}

// Uso no componente:
const { data: users, loading } = useFetch<User[]>('/api/users')
```

---

## Pinia — Estado Global

```typescript
// stores/auth.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useAuthStore = defineStore('auth', () => {
  // state
  const user  = ref<User | null>(null)
  const token = ref<string | null>(localStorage.getItem('token'))

  // getters
  const isLoggedIn  = computed(() => !!token.value)
  const displayName = computed(() => user.value?.name ?? 'Visitante')

  // actions
  async function login(email: string, password: string) {
    const res = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    })
    const data = await res.json()
    token.value = data.token
    user.value  = data.user
    localStorage.setItem('token', data.token)
  }

  function logout() {
    user.value  = null
    token.value = null
    localStorage.removeItem('token')
  }

  return { user, token, isLoggedIn, displayName, login, logout }
})
```

---

## Vue Router 4

```typescript
// router/index.ts
import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/',        component: () => import('@/pages/Home.vue') },
    { path: '/login',   component: () => import('@/pages/Login.vue') },
    {
      path: '/dashboard',
      component: () => import('@/pages/Dashboard.vue'),
      meta: { requiresAuth: true },
      children: [
        { path: 'users',    component: () => import('@/pages/Users.vue') },
        { path: 'settings', component: () => import('@/pages/Settings.vue') },
      ]
    },
    { path: '/:pathMatch(.*)*', component: () => import('@/pages/NotFound.vue') },
  ],
})

// Navigation guard
router.beforeEach((to, from) => {
  const auth = useAuthStore()
  if (to.meta.requiresAuth && !auth.isLoggedIn) {
    return { path: '/login', query: { redirect: to.fullPath } }
  }
})

export default router
```

---

## Referências

→ `references/nuxt.md` — Nuxt 3: SSR, SSG, server routes, useFetch, useAsyncData


---

## Relacionado

[[Tailwind CSS v4]] | [[TypeScript]] | [[Vite]]


---

## Referencias

- [[Referencias/nuxt]]
