---
tags: [frontend]
categoria: "Frontend"
---

# TypeScript — Guia de Referência Moderno

**Versão:** TypeScript 5.x  
**Princípio:** Tipos como documentação viva. `strict: true` sempre. Preferir `interface` para objetos públicos, `type` para unions e composições.

---

## Tipos Básicos e Boas Práticas

```typescript
// ✅ Sempre tipar parâmetros de funções
function greet(name: string, age: number): string {
  return `Olá ${name}, você tem ${age} anos.`
}

// ✅ Inferência de tipo (não precisar repetir)
const user = { name: 'Ana', age: 30 }  // TypeScript infere o tipo

// ❌ Evitar any — use unknown quando o tipo é desconhecido
function processData(data: unknown) {
  if (typeof data === 'string') {
    console.log(data.toUpperCase())  // seguro após narrowing
  }
}

// ✅ never para casos impossíveis
function assertNever(x: never): never {
  throw new Error(`Caso inesperado: ${x}`)
}
```

---

## Interface vs Type

```typescript
// Interface — para objetos e classes (extensível)
interface User {
  id: string
  name: string
  email?: string            // opcional
  readonly createdAt: Date  // imutável
}

interface Admin extends User {
  role: 'admin' | 'superadmin'
  permissions: string[]
}

// Type — para unions, intersections, tuplas, utilitários
type Status = 'pending' | 'active' | 'inactive'
type ID = string | number
type Point = [number, number]  // tupla

// Intersection (combina tipos)
type AdminUser = User & { role: string }

// Quando usar qual:
// interface → objeto que pode ser extendido (API pública, OOP)
// type      → union, intersection, alias complexo, funções
```

---

## Generics

```typescript
// Generic básico
function identity<T>(value: T): T {
  return value
}

// Generic com constraint
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key]
}

// Generic em interface
interface ApiResponse<T> {
  data: T
  status: number
  message: string
}

type UserResponse = ApiResponse<User>
type ListResponse<T> = ApiResponse<T[]>

// Generic com default
interface PaginatedResult<T, Meta = Record<string, unknown>> {
  items: T[]
  total: number
  meta: Meta
}

// Função genérica com múltiplos tipos
async function fetchData<TInput, TOutput>(
  url: string,
  transform: (input: TInput) => TOutput
): Promise<TOutput> {
  const response = await fetch(url)
  const data: TInput = await response.json()
  return transform(data)
}
```

---

## Utility Types

```typescript
interface Product {
  id: string
  name: string
  price: number
  stock: number
  description: string
}

type CreateProduct = Omit<Product, 'id'>          // sem id
type UpdateProduct = Partial<Omit<Product, 'id'>> // todos opcionais, sem id
type ProductPreview = Pick<Product, 'id' | 'name' | 'price'>
type ReadonlyProduct = Readonly<Product>

// Record — objeto tipado por chave
type Roles = 'admin' | 'user' | 'guest'
type RolePermissions = Record<Roles, string[]>

// Exclude / Extract
type NonNullString = Exclude<string | null | undefined, null | undefined>
type NumberOrString = Extract<string | number | boolean, string | number>

// ReturnType / Parameters
function createUser(name: string, age: number) {
  return { id: crypto.randomUUID(), name, age }
}
type NewUser = ReturnType<typeof createUser>
type CreateUserParams = Parameters<typeof createUser>

// Awaited — tipo do resultado de uma Promise
type UserData = Awaited<ReturnType<typeof fetchUser>>
```

---

## Discriminated Unions (Pattern Essencial)

```typescript
// ✅ Pattern: discriminated union com "type" como discriminante
type Result<T> =
  | { success: true;  data: T }
  | { success: false; error: string }

function parseUser(raw: unknown): Result<User> {
  if (!raw || typeof raw !== 'object') {
    return { success: false, error: 'Dado inválido' }
  }
  return { success: true, data: raw as User }
}

// Uso — TypeScript sabe o tipo em cada branch
const result = parseUser(rawData)
if (result.success) {
  console.log(result.data.name)  // ✅ TypeScript sabe que data existe
} else {
  console.error(result.error)    // ✅ TypeScript sabe que error existe
}

// Outro exemplo — eventos
type AppEvent =
  | { type: 'USER_LOGIN';  userId: string }
  | { type: 'USER_LOGOUT'; sessionId: string }
  | { type: 'PURCHASE';    amount: number; productId: string }

function handleEvent(event: AppEvent) {
  switch (event.type) {
    case 'USER_LOGIN':   return loginUser(event.userId)
    case 'USER_LOGOUT':  return logoutSession(event.sessionId)
    case 'PURCHASE':     return processPurchase(event.amount, event.productId)
    default:             return assertNever(event)  // garante cobertura completa
  }
}
```

---

## Type Guards e Narrowing

```typescript
// Type guard com "is"
function isUser(obj: unknown): obj is User {
  return typeof obj === 'object' && obj !== null && 'id' in obj && 'name' in obj
}

// Type guard com "instanceof"
function handleError(error: unknown): string {
  if (error instanceof Error)   return error.message
  if (typeof error === 'string') return error
  return 'Erro desconhecido'
}

// Assertion function
function assertIsString(val: unknown): asserts val is string {
  if (typeof val !== 'string') throw new TypeError(`Esperado string, recebeu ${typeof val}`)
}
```

---

## satisfies e const

```typescript
// satisfies — valida o tipo mas preserva o tipo literal
const config = {
  port: 3000,
  host: 'localhost',
  db: { url: 'postgres://...' }
} satisfies Record<string, unknown>
// TypeScript ainda sabe que config.port é number (não unknown)

// as const — congela tipos literais
const ROUTES = {
  home:    '/',
  about:   '/sobre',
  contact: '/contato',
} as const
type Route = typeof ROUTES[keyof typeof ROUTES]
// Route = '/' | '/sobre' | '/contato'
```

---

## tsconfig.json Recomendado

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true,
    "skipLibCheck": true,
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist"]
}
```

---

## Referências

→ `references/advanced-types.md` — Conditional types, mapped types, infer, template literals


---

## Relacionado

[[React 19]] | [[Node.js]] | [[Zod Validacao]]


---

## Referencias

- [[Referencias/advanced-types]]
