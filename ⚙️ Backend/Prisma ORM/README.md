---
tags: [backend]
categoria: "⚙️ Backend"
---

# Prisma ORM — Guia Completo

**Versão:** Prisma 6+  
**Princípio:** Schema-first. O `schema.prisma` é a fonte da verdade. Migrations versionadas em Git.

---

## Setup

```bash
npm install prisma @prisma/client
npx prisma init --datasource-provider postgresql
```

---

## schema.prisma — Modelos Completos

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String
  password  String
  role      Role     @default(USER)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  // Relações
  posts     Post[]
  profile   Profile?

  @@index([email])
  @@map("users")    // nome real da tabela no banco
}

model Profile {
  id     String  @id @default(cuid())
  bio    String?
  avatar String?

  userId String @unique
  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@map("profiles")
}

model Post {
  id          String   @id @default(cuid())
  title       String
  content     String?
  published   Boolean  @default(false)
  viewCount   Int      @default(0)
  publishedAt DateTime?
  createdAt   DateTime @default(now())

  authorId String
  author   User     @relation(fields: [authorId], references: [id])
  tags     Tag[]    @relation("PostTags")

  @@index([authorId])
  @@map("posts")
}

model Tag {
  id    String @id @default(cuid())
  name  String @unique
  posts Post[] @relation("PostTags")

  @@map("tags")
}

enum Role {
  USER
  ADMIN
  SUPERADMIN
}
```

---

## Migrations

```bash
# Criar migration (dev)
npx prisma migrate dev --name add_users_table

# Aplicar em produção
npx prisma migrate deploy

# Reset completo do banco (dev only!)
npx prisma migrate reset

# Ver status
npx prisma migrate status

# Abrir Prisma Studio
npx prisma studio
```

---

## Prisma Client — Setup Singleton

```typescript
// lib/prisma.ts
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient }

export const prisma = globalForPrisma.prisma ?? new PrismaClient({
  log: process.env.NODE_ENV === 'development'
    ? ['query', 'error', 'warn']
    : ['error'],
})

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
```

---

## Queries CRUD

```typescript
// ── CREATE ────────────────────────────────────────────────────
const user = await prisma.user.create({
  data: {
    email: 'ana@example.com',
    name: 'Ana Lima',
    password: hashedPassword,
    profile: {
      create: { bio: 'Desenvolvedora full-stack' }  // nested create
    }
  },
  include: { profile: true },  // retornar relação
})

// ── READ ─────────────────────────────────────────────────────
// Encontrar único (lança se não existe)
const user = await prisma.user.findUniqueOrThrow({
  where: { email: 'ana@example.com' },
  include: { posts: true, profile: true },
})

// Listar com filtros, ordenação e paginação
const posts = await prisma.post.findMany({
  where: {
    published: true,
    author: { role: 'ADMIN' },           // filtro em relação
    title: { contains: 'Node', mode: 'insensitive' },
    createdAt: { gte: new Date('2025-01-01') },
  },
  orderBy: [{ viewCount: 'desc' }, { createdAt: 'desc' }],
  skip: (page - 1) * pageSize,           // paginação
  take: pageSize,
  select: {                              // apenas campos necessários
    id: true, title: true, publishedAt: true,
    author: { select: { name: true } },
  },
})

// Contar
const total = await prisma.post.count({ where: { published: true } })

// ── UPDATE ────────────────────────────────────────────────────
const updated = await prisma.post.update({
  where: { id: postId },
  data: {
    published: true,
    publishedAt: new Date(),
    viewCount: { increment: 1 },         // operação atômica
  },
})

// updateMany — sem retornar os registros atualizados
await prisma.post.updateMany({
  where: { authorId: userId },
  data: { published: false },
})

// ── UPSERT ────────────────────────────────────────────────────
const profile = await prisma.profile.upsert({
  where:  { userId },
  update: { bio: 'Nova bio' },
  create: { userId, bio: 'Nova bio' },
})

// ── DELETE ────────────────────────────────────────────────────
await prisma.user.delete({ where: { id: userId } })
```

---

## Transações

```typescript
// Transação interativa (recomendada para lógica complexa)
const result = await prisma.$transaction(async (tx) => {
  const order = await tx.order.create({ data: orderData })

  await tx.product.update({
    where: { id: productId },
    data: { stock: { decrement: quantity } },
  })

  await tx.payment.create({
    data: { orderId: order.id, amount: totalAmount }
  })

  return order
})

// Transação batch (simples, sem retorno intermediário)
const [newUser, newProfile] = await prisma.$transaction([
  prisma.user.create({ data: userData }),
  prisma.profile.create({ data: profileData }),
])
```

---

## Seed

```typescript
// prisma/seed.ts
import { prisma } from '../lib/prisma'

async function main() {
  await prisma.user.upsert({
    where: { email: 'admin@site.com' },
    update: {},
    create: {
      email: 'admin@site.com',
      name: 'Admin',
      password: await hashPassword('admin123'),
      role: 'ADMIN',
    },
  })
  console.log('✅ Seed concluído')
}

main().then(() => prisma.$disconnect())

// package.json:
// "prisma": { "seed": "tsx prisma/seed.ts" }
// npx prisma db seed
```

---

## Referências

→ `references/advanced-queries.md` — Raw SQL, aggregations, full-text search, virtual fields


---

## Relacionado

[[PostgreSQL]] | [[Supabase]] | [[Node.js]]


---

## Referencias

- [[Referencias/advanced-queries]]
