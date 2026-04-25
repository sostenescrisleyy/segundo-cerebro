---
tags: [frontend]
categoria: "Frontend"
---

# React 19 — Guia de Referência Moderno

**Versão de referência:** React 19 (estável)  
**Docs:** https://react.dev  
**Princípio:** Componentes funcionais + hooks. Class components são legado.

---

## Novidades React 19 que Mudam o Jogo

| Feature | O que é | Substitui |
|---|---|---|
| **React Compiler** | Memoização automática | useMemo / useCallback manuais |
| **useActionState** | Estado de formulários/actions | useFormState + estados manuais |
| **useOptimistic** | UI otimista | Estados booleanos de loading |
| **use()** | Leitura de Promises e Context em render | useContext + Suspense verboso |
| **Server Components** | Render no servidor sem JS no cliente | getServerSideProps / API routes |
| **Actions** | Funções async diretamente em forms | onSubmit + fetch + useState |

---

## Componentes: Regras Fundamentais

```tsx
// ✅ Componente funcional moderno — TypeScript always
interface ButtonProps {
  label: string
  onClick?: () => void
  variant?: 'primary' | 'secondary' | 'ghost'
  disabled?: boolean
  children?: React.ReactNode
}

export function Button({
  label,
  onClick,
  variant = 'primary',
  disabled = false,
  children
}: ButtonProps) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={cn(buttonVariants({ variant }), disabled && 'opacity-50')}
      type="button"
    >
      {children ?? label}
    </button>
  )
}

// Regras de naming:
// - Componente: PascalCase  (Button, UserCard, ProfileForm)
// - Hook:        camelCase com use  (useUser, useDebounce)
// - Arquivo:     mesmo nome do componente (Button.tsx, UserCard.tsx)
```

---

## Hooks Essenciais com Boas Práticas

### useState — quando e como

```tsx
// ✅ Estado relacionado → objeto único
const [form, setForm] = useState({ name: '', email: '', age: 0 })
// Atualizar parcialmente:
setForm(prev => ({ ...prev, name: 'João' }))

// ✅ Estado independente → useState separados
const [isOpen, setIsOpen] = useState(false)
const [selectedId, setSelectedId] = useState<string | null>(null)

// ✅ Lazy initialization para computações pesadas
const [data] = useState(() => computeExpensiveInitialValue())
```

### useEffect — apenas efeitos externos

```tsx
// ✅ Correto: sincronia com sistema externo
useEffect(() => {
  const subscription = subscribe(userId)
  return () => subscription.unsubscribe() // cleanup SEMPRE
}, [userId])

// ✅ Correto: listener de evento
useEffect(() => {
  window.addEventListener('resize', handleResize)
  return () => window.removeEventListener('resize', handleResize)
}, [handleResize])

// ❌ Errado: transformação de dados → faça no render
useEffect(() => {
  setFullName(`${firstName} ${lastName}`) // desnecessário
}, [firstName, lastName])
// ✅ Correto:
const fullName = `${firstName} ${lastName}` // derivar no render

// ❌ Errado: fetch sem cleanup/abort
useEffect(() => {
  fetch('/api/data').then(r => r.json()).then(setData)
}, [])
// ✅ Correto:
useEffect(() => {
  const abortController = new AbortController()
  fetch('/api/data', { signal: abortController.signal })
    .then(r => r.json()).then(setData)
    .catch(err => { if (err.name !== 'AbortError') setError(err) })
  return () => abortController.abort()
}, [])
```

### useRef — DOM e valores mutáveis

```tsx
// Acesso ao DOM
const inputRef = useRef<HTMLInputElement>(null)
useEffect(() => { inputRef.current?.focus() }, [])

// Valor que não dispara re-render (ex: setTimeout ID, contadores)
const timerRef = useRef<ReturnType<typeof setTimeout>>()
const startTimer = () => {
  timerRef.current = setTimeout(() => doSomething(), 1000)
}
const stopTimer = () => clearTimeout(timerRef.current)

// Valor anterior (react pattern)
const prevCountRef = useRef(count)
useEffect(() => { prevCountRef.current = count })
const prevCount = prevCountRef.current
```

---

## React 19: Formulários com Actions

```tsx
// Sem Server Actions — client-side action
async function submitForm(formData: FormData) {
  const name = formData.get('name') as string
  await fetch('/api/profile', {
    method: 'POST',
    body: JSON.stringify({ name }),
  })
}

export function ProfileForm() {
  const [state, action, isPending] = useActionState(
    async (prev: any, formData: FormData) => {
      try {
        await submitForm(formData)
        return { success: true }
      } catch (e) {
        return { error: 'Erro ao salvar' }
      }
    },
    null
  )

  return (
    <form action={action}>
      <input name="name" required />
      {state?.error && <p className="text-red-500">{state.error}</p>}
      {state?.success && <p className="text-green-500">Salvo!</p>}
      <button disabled={isPending}>
        {isPending ? 'Salvando...' : 'Salvar'}
      </button>
    </form>
  )
}
```

---

## Performance: O que Otimizar (e o que não)

### React Compiler (React 19+) — memoização automática

```tsx
// Com React Compiler ativo, isso NÃO é mais necessário na maioria dos casos:
const memoized = useMemo(() => expensiveCalc(a, b), [a, b])
const stableCallback = useCallback(() => doSomething(id), [id])
const MemoComp = React.memo(MyComponent)

// O Compiler analisa e insere otimizações onde são necessárias.
// Mantenha useMemo/useCallback apenas onde o Profiler confirmar necessidade.
```

### Quando ainda memoizar manualmente

```tsx
// 1. Listas longas com virtualization
import { useVirtualizer } from '@tanstack/react-virtual'

// 2. Cálculo genuinamente pesado (>1ms) em componente que re-renderiza muito
const sortedAndFiltered = useMemo(
  () => items.filter(filterFn).sort(sortFn),
  [items, filterFn, sortFn]
)

// 3. Referência estável para deps de useEffect
const handleEvent = useCallback((event: Event) => {
  processEvent(event, config) // config muda frequentemente
}, [config]) // sem useCallback, useEffect re-executa toda mudança de handleEvent

// Regra: PRIMEIRO profile, DEPOIS otimize. Nunca assuma.
```

### State colocation — estado onde é usado

```tsx
// ❌ Estado hissado desnecessariamente — re-renderiza tudo
function App() {
  const [searchQuery, setSearchQuery] = useState('') // aqui não é necessário
  return <SearchBar query={searchQuery} onChange={setSearchQuery} />
}

// ✅ Estado local onde é usado
function SearchBar() {
  const [query, setQuery] = useState('') // só SearchBar re-renderiza
  return <input value={query} onChange={e => setQuery(e.target.value)} />
}
```

---

## Gerenciamento de Estado: Árvore de Decisão

```
Estado usado por 1 componente?
  → useState / useReducer local

Estado compartilhado entre 2-3 componentes próximos?
  → Elevar ao ancestral comum (prop drilling OK para 1-2 níveis)

Estado global de UI (tema, modal aberto)?
  → Context API + useContext

Estado global de servidor (dados do usuário, cache)?
  → TanStack Query (React Query) — nunca useState para server state

Estado global complexo (múltiplas features, ações relacionadas)?
  → Zustand (simples) ou Jotai (atômico)
  → Evite Redux em novos projetos — muito boilerplate
```

### Zustand — gerenciamento simples e performático

```tsx
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface UserStore {
  user: User | null
  setUser: (user: User | null) => void
  logout: () => void
}

const useUserStore = create<UserStore>()(
  persist(
    (set) => ({
      user: null,
      setUser: (user) => set({ user }),
      logout: () => set({ user: null }),
    }),
    { name: 'user-storage' } // persiste no localStorage
  )
)

// Uso — selecionar só o que precisa (evita re-renders desnecessários)
const user = useUserStore(state => state.user)
const logout = useUserStore(state => state.logout)
```

---

## Padrões de Composição

### Compound Components

```tsx
// Uso: <Select.Root><Select.Option /></Select.Root>
const SelectContext = createContext<SelectContextValue | null>(null)

function Root({ children, value, onChange }) {
  return (
    <SelectContext.Provider value={{ value, onChange }}>
      <div role="listbox">{children}</div>
    </SelectContext.Provider>
  )
}

function Option({ value: optValue, children }) {
  const { value, onChange } = useContext(SelectContext)!
  return (
    <div
      role="option"
      aria-selected={value === optValue}
      onClick={() => onChange(optValue)}
    >
      {children}
    </div>
  )
}

export const Select = { Root, Option }
```

### Render Props com children function

```tsx
// Compartilhar lógica sem HOC
function DataFetcher<T>({
  url,
  children
}: {
  url: string
  children: (data: T | null, loading: boolean) => React.ReactNode
}) {
  const [data, setData] = useState<T | null>(null)
  const [loading, setLoading] = useState(true)
  // fetch...
  return <>{children(data, loading)}</>
}

// Uso:
<DataFetcher<User> url="/api/user">
  {(user, loading) => loading ? <Spinner /> : <UserCard user={user!} />}
</DataFetcher>
```

---

## Custom Hooks: Extraindo Lógica

```tsx
// hooks/useDebounce.ts
export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState(value)
  useEffect(() => {
    const timer = setTimeout(() => setDebouncedValue(value), delay)
    return () => clearTimeout(timer)
  }, [value, delay])
  return debouncedValue
}

// hooks/useLocalStorage.ts
export function useLocalStorage<T>(key: string, initialValue: T) {
  const [stored, setStored] = useState<T>(() => {
    try {
      const item = window.localStorage.getItem(key)
      return item ? JSON.parse(item) : initialValue
    } catch { return initialValue }
  })

  const setValue = (value: T | ((val: T) => T)) => {
    const valueToStore = value instanceof Function ? value(stored) : value
    setStored(valueToStore)
    localStorage.setItem(key, JSON.stringify(valueToStore))
  }

  return [stored, setValue] as const
}
```

---

## Referências

→ `references/data-fetching.md` — TanStack Query, SWR, patterns de server state  
→ `references/error-boundaries.md` — Error Boundaries, Suspense, fallbacks  
→ `references/testing.md` — React Testing Library, mocks, boas práticas de teste


---

## Relacionado

[[Next.js 15]] | [[Tailwind CSS v4]] | [[shadcn ui]] | [[TypeScript]]


---

## Referencias

- [[Referencias/data-fetching]]
