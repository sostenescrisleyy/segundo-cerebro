# TypeScript — Tipos Avançados

## Conditional Types

```typescript
type IsArray<T> = T extends any[] ? true : false
type Flatten<T> = T extends Array<infer Item> ? Item : T

// Exemplo: extrair tipo do Promise
type UnwrapPromise<T> = T extends Promise<infer U> ? U : T
type UserData = UnwrapPromise<Promise<User>>  // → User

// DeepPartial
type DeepPartial<T> = T extends object
  ? { [P in keyof T]?: DeepPartial<T[P]> }
  : T
```

## Mapped Types

```typescript
// Tornar todos os campos obrigatórios e readonly
type Immutable<T> = { readonly [K in keyof T]-?: T[K] }

// Adicionar prefixo "get" em métodos
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K]
}

// Filtrar por tipo
type OnlyStrings<T> = {
  [K in keyof T as T[K] extends string ? K : never]: T[K]
}
```

## Template Literal Types

```typescript
type EventName = 'click' | 'focus' | 'blur'
type Handler = `on${Capitalize<EventName>}`
// → 'onClick' | 'onFocus' | 'onBlur'

type CSSProperty = 'margin' | 'padding'
type CSSDirection = 'top' | 'right' | 'bottom' | 'left'
type CSSSpacing = `${CSSProperty}-${CSSDirection}`
// → 'margin-top' | 'margin-right' | ... | 'padding-left'
```

## Padrões com Generics

```typescript
// Builder pattern tipado
class QueryBuilder<T extends object> {
  private filters: Partial<T> = {}

  where<K extends keyof T>(key: K, value: T[K]): this {
    this.filters[key] = value
    return this
  }

  build(): Partial<T> { return this.filters }
}

// Uso:
const query = new QueryBuilder<User>()
  .where('name', 'Ana')   // ✅ TypeScript valida o tipo de 'name'
  .where('age', 30)        // ✅ e de 'age'
  .build()
```


---

← [[README|TypeScript]]
