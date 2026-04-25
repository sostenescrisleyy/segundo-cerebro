---
tags: [devtools]
categoria: "DevTools"
---

# Zod — Validação e Tipagem em Runtime

**Versão:** Zod 3.x  
**Princípio:** Definir o schema uma vez → validação em runtime + tipos TypeScript gerados automaticamente. Single source of truth.

---

## Schemas Básicos

```typescript
import { z } from 'zod'

// Primitivos
const nameSchema  = z.string().min(2).max(100).trim()
const emailSchema = z.string().email('E-mail inválido')
const ageSchema   = z.number().int().min(18, 'Mínimo 18 anos').max(120)
const urlSchema   = z.string().url()
const uuidSchema  = z.string().uuid()
const dateSchema  = z.coerce.date()   // converte string → Date automaticamente

// Enums
const RoleSchema   = z.enum(['admin', 'user', 'guest'])
const StatusSchema = z.enum(['pending', 'active', 'inactive'])

// Arrays e tuplas
const tagsSchema   = z.array(z.string()).min(1).max(10)
const pointSchema  = z.tuple([z.number(), z.number()])

// Objetos
const AddressSchema = z.object({
  street: z.string(),
  number: z.string(),
  city:   z.string(),
  state:  z.string().length(2),
  zip:    z.string().regex(/^\d{5}-?\d{3}$/, 'CEP inválido'),
})
```

---

## Schema Completo — Inferência de Tipos

```typescript
const UserSchema = z.object({
  id:       z.string().cuid(),
  name:     z.string().min(2).max(100).trim(),
  email:    z.string().email().toLowerCase(),
  age:      z.number().int().min(18).optional(),
  role:     z.enum(['admin', 'user']).default('user'),
  tags:     z.array(z.string()).default([]),
  metadata: z.record(z.string(), z.unknown()).optional(),
  address:  AddressSchema.optional(),
  createdAt: z.coerce.date(),
})

// Inferir tipo TypeScript do schema (ZERO duplicação)
type User = z.infer<typeof UserSchema>

// Schema de criação (sem id e timestamps)
const CreateUserSchema = UserSchema.omit({ id: true, createdAt: true })
const UpdateUserSchema = UserSchema.partial().omit({ id: true, createdAt: true })

type CreateUser = z.infer<typeof CreateUserSchema>
type UpdateUser = z.infer<typeof UpdateUserSchema>
```

---

## Parse e SafeParse

```typescript
// .parse() — lança ZodError se inválido
try {
  const user = UserSchema.parse(rawData)
  // user está tipado e validado
} catch (error) {
  if (error instanceof z.ZodError) {
    console.error(error.errors)
    // [{ path: ['email'], message: 'E-mail inválido', code: 'invalid_string' }]
  }
}

// .safeParse() — retorna { success, data } ou { success, error } — preferível
const result = UserSchema.safeParse(rawData)

if (result.success) {
  console.log(result.data.name)  // tipado corretamente
} else {
  const errors = result.error.flatten()
  // errors.fieldErrors → { email: ['E-mail inválido'], name: ['Mínimo 2 chars'] }
  // errors.formErrors  → erros gerais
}

// .parseAsync() para validações assíncronas
const user = await UserSchema.parseAsync(rawData)
```

---

## Refinements — Validações Customizadas

```typescript
const PasswordSchema = z.string()
  .min(8)
  .regex(/[A-Z]/, 'Precisa ter letra maiúscula')
  .regex(/[0-9]/, 'Precisa ter número')
  .regex(/[^A-Za-z0-9]/, 'Precisa ter caractere especial')

// .refine() — validação custom
const ConfirmPasswordSchema = z.object({
  password:        z.string().min(8),
  confirmPassword: z.string(),
}).refine(
  (data) => data.password === data.confirmPassword,
  {
    message: 'Senhas não conferem',
    path:    ['confirmPassword'],   // onde aparece o erro
  }
)

// .superRefine() — múltiplos erros
const AgeRangeSchema = z.object({
  minAge: z.number(),
  maxAge: z.number(),
}).superRefine(({ minAge, maxAge }, ctx) => {
  if (minAge >= maxAge) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'minAge deve ser menor que maxAge',
      path: ['minAge'],
    })
  }
})
```

---

## Transformações

```typescript
// .transform() — transformar após validar
const SlugSchema = z.string()
  .min(1)
  .transform(val => val.toLowerCase().replace(/\s+/g, '-'))

const MoneySchema = z.string()
  .regex(/^\d+([.,]\d{1,2})?$/)
  .transform(val => parseFloat(val.replace(',', '.')))

// .preprocess() — transformar antes de validar (útil para coerce manual)
const FlexibleNumberSchema = z.preprocess(
  (val) => (typeof val === 'string' ? parseFloat(val) : val),
  z.number()
)
```

---

## Discriminated Unions

```typescript
const NotificationSchema = z.discriminatedUnion('type', [
  z.object({
    type:    z.literal('email'),
    to:      z.string().email(),
    subject: z.string(),
    body:    z.string(),
  }),
  z.object({
    type:    z.literal('sms'),
    phone:   z.string().regex(/^\+55\d{11}$/),
    message: z.string().max(160),
  }),
  z.object({
    type:  z.literal('push'),
    token: z.string(),
    title: z.string(),
    data:  z.record(z.string(), z.string()).optional(),
  }),
])

type Notification = z.infer<typeof NotificationSchema>
```

---

## Integração com React Hook Form

```typescript
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'

const LoginSchema = z.object({
  email:    z.string().email('E-mail inválido'),
  password: z.string().min(8, 'Mínimo 8 caracteres'),
})
type LoginForm = z.infer<typeof LoginSchema>

function LoginForm() {
  const { register, handleSubmit, formState: { errors } } =
    useForm<LoginForm>({ resolver: zodResolver(LoginSchema) })

  const onSubmit = (data: LoginForm) => {
    // data está validado e tipado
    console.log(data.email, data.password)
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('email')} />
      {errors.email && <span>{errors.email.message}</span>}

      <input type="password" {...register('password')} />
      {errors.password && <span>{errors.password.message}</span>}

      <button type="submit">Entrar</button>
    </form>
  )
}
```

---

## Validação em Server Actions (Next.js)

```typescript
'use server'
import { z } from 'zod'

const CreatePostSchema = z.object({
  title:   z.string().min(5).max(200),
  content: z.string().min(20),
  tags:    z.array(z.string()).max(5).default([]),
})

export async function createPost(formData: FormData) {
  const result = CreatePostSchema.safeParse({
    title:   formData.get('title'),
    content: formData.get('content'),
    tags:    formData.getAll('tags'),
  })

  if (!result.success) {
    return { error: result.error.flatten().fieldErrors }
  }

  // result.data está totalmente tipado
  const post = await db.post.create({ data: result.data })
  return { data: post }
}
```


---

## Relacionado

[[TypeScript]] | [[React 19]] | [[Node.js]]


---

## Referencias

- [[Referencias/extra]]
