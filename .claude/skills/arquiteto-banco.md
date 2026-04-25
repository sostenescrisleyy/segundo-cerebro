---
name: arquiteto-banco
description: >
  Use para design de schema, otimização de queries, migrações e seleção de banco de dados.
  Especialista em PostgreSQL, SQLite, Neon, Turso, Prisma e Drizzle. Ative para: "design de
  banco", "schema", "migração", "query lenta", "N+1", "índice", "prisma schema", "drizzle",
  "normalização", "relacionamento", "foreign key", "EXPLAIN ANALYZE", "query SQL", "ORM",
  "banco serverless", "performance banco", "zero downtime migration", "soft delete",
  "auditoria banco", "histórico de alterações", "particionamento", "JSONB".
---

# Arquiteto de Banco de Dados

Especialista em design de schema, otimização de queries e soluções de banco modernas.

---

## Framework de Decisão

### Seleção de Banco

| Necessidade | Banco Recomendado | Por quê |
|---|---|---|
| Relações complexas + ACID | **PostgreSQL** | Mais robusto, recursos avançados (JSONB, arrays, full-text) |
| Serverless + Edge | **Neon / Turso / PlanetScale** | HTTP-based, sem cold start de conexão |
| Embedded / Desktop | **SQLite** | Zero infraestrutura, arquivo único |
| Tempo-real + sync | **Supabase (PostgreSQL)** | Realtime via WebSockets nativo |
| Time-series | **TimescaleDB** | Extensão PostgreSQL para séries temporais |
| Documentos flexíveis | **MongoDB** | Schema-less para dados dinâmicos |

### Seleção de ORM

| ORM | Use Quando | Pontos Fortes | Pontos Fracos |
|---|---|---|---|
| **Prisma** | DX prioridade, type-safety, migrations automáticas | IntelliSense excepcional, migrations versionadas | Bundle maior, queries raw menos ergonômicas |
| **Drizzle** | Edge/serverless, SQL-like, peso mínimo | Leve, funciona no edge, SQL familiar | Ecossistema menor |
| **TypeORM** | Enterprise, decorators, OOP forte | Maduro, muito recurso | Verboso, configuração complexa |
| **Kysely** | Type-safe sem abstração | Controle total, type-safe | Mais verboso que Prisma |
| **SQL Raw** | Queries críticas de performance | Máximo controle | Sem segurança de tipo |

---

## Princípios de Design de Schema

### Convenções de Nomenclatura

```sql
-- Tabelas: snake_case, plural
CREATE TABLE users (...);
CREATE TABLE order_items (...);

-- Colunas: snake_case
user_id, created_at, updated_at, deleted_at

-- Índices: idx_tabela_coluna
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at DESC);
```

### Campos Padrão Sempre Presentes

```prisma
model User {
  // IDs — escolher UNO baseado no contexto
  id         String   @id @default(cuid())     // CUID: legível, sortável, URL-safe
  // id      String   @id @default(uuid())     // UUID: padrão universal
  // id      Int      @id @default(autoincrement()) // Serial: mais simples, menor

  // Auditoria obrigatória
  createdAt  DateTime @default(now())
  updatedAt  DateTime @updatedAt

  // Soft delete (quando necessário)
  deletedAt  DateTime?   // nullable = ativo, preenchido = deletado
}
```

### CUID vs UUID vs Serial — Quando Usar Cada Um

| ID | Use Quando | Exemplo |
|---|---|---|
| **CUID** | Sistemas distribuídos, URLs amigáveis, padrão moderno | `clh3x1y2z0000abc` |
| **UUID** | Interoperabilidade com sistemas externos, padrão universal | `550e8400-e29b-41d4-a716` |
| **Serial/Int** | Sistemas simples, banco único, performance máxima | `1`, `2`, `3` |

---

## Design de Relações

```prisma
// Um-para-muitos (1:N) — caso mais comum
model User {
  id     String  @id @default(cuid())
  orders Order[]
}

model Order {
  id     String  @id @default(cuid())
  userId String
  user   User    @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])  // SEMPRE indexar foreign keys
}

// Muitos-para-muitos (M:N) explícito — mais controle
model Post {
  id   String    @id @default(cuid())
  tags PostTag[]
}

model Tag {
  id    String    @id @default(cuid())
  posts PostTag[]
}

model PostTag {
  postId    String
  tagId     String
  addedAt   DateTime @default(now())  // dado extra na relação
  addedBy   String

  post Post @relation(fields: [postId], references: [id])
  tag  Tag  @relation(fields: [tagId],  references: [id])

  @@id([postId, tagId])  // chave composta
}
```

---

## Índices — Estratégia Completa

```sql
-- Regra: indexar colunas usadas em WHERE, JOIN, ORDER BY frequentes

-- Índice simples (mais comum)
CREATE INDEX idx_orders_status ON orders(status);

-- Índice composto (ordem importa: filtro mais seletivo primeiro)
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
-- Serve para: WHERE user_id = X
-- Serve para: WHERE user_id = X AND status = Y
-- NÃO serve para: WHERE status = Y (só)

-- Índice parcial (indexar só subconjunto)
CREATE INDEX idx_orders_pending ON orders(created_at)
  WHERE status = 'PENDING';

-- Índice para JSONB
CREATE INDEX idx_users_plan ON users ((metadata->>'plan'));
CREATE INDEX idx_users_metadata ON users USING GIN(metadata);

-- Índice para Full-Text Search
CREATE INDEX idx_products_search ON products
  USING GIN(to_tsvector('portuguese', name || ' ' || description));

-- Verificar índices não usados (PostgreSQL)
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY schemaname, tablename;
```

---

## Migrações de Produção — Zero Downtime

### Regra de Ouro
```
NUNCA: DROP COLUMN na mesma migração que uma migração de dados
SEMPRE: 3 fases separadas para mudanças destrutivas
```

### Exemplo: Renomear Coluna (3 fases)

```sql
-- FASE 1: Adicionar nova coluna (deploy)
ALTER TABLE users ADD COLUMN full_name TEXT;

-- Backfill assíncrono (em background, sem lock)
UPDATE users SET full_name = first_name || ' ' || last_name
WHERE full_name IS NULL
LIMIT 1000;  -- em lotes para não travar

-- FASE 2: Adicionar constraint NOT NULL após backfill completo (deploy)
ALTER TABLE users ALTER COLUMN full_name SET NOT NULL;
-- Código novo já usa full_name, código antigo ainda usa first_name/last_name

-- FASE 3: Remover colunas antigas (deploy — semanas depois)
ALTER TABLE users DROP COLUMN first_name;
ALTER TABLE users DROP COLUMN last_name;
```

### Migrações Seguras vs Perigosas

| Operação | Risco | Estratégia |
|---|---|---|
| `ADD COLUMN nullable` | ✅ Seguro | Fazer diretamente |
| `ADD COLUMN NOT NULL` | ⚠️ Perigoso | Adicionar nullable → backfill → add constraint |
| `DROP COLUMN` | ⚠️ Perigoso | Parar uso no código → esperar deploy → dropar |
| `ADD INDEX` | ⚠️ Lento | Usar `CREATE INDEX CONCURRENTLY` (PostgreSQL) |
| `ALTER COLUMN TYPE` | 🔴 Muito perigoso | Nova coluna + migração de dados + swap |
| `DROP TABLE` | 🔴 Irreversível | Soft delete primeiro → backup → drop semanas depois |

---

## EXPLAIN ANALYZE — Diagnosticar Queries Lentas

```sql
-- Sempre usar EXPLAIN ANALYZE para diagnosticar
EXPLAIN ANALYZE
SELECT u.name, COUNT(o.id) as total_orders
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.created_at > '2025-01-01'
GROUP BY u.id, u.name
ORDER BY total_orders DESC;
```

**Sinais de problema no output:**

| Sinal | Problema | Solução |
|---|---|---|
| `Seq Scan` em tabela grande | Falta índice | Criar índice na coluna do WHERE |
| `cost=0..99999` alto | Query pesada | Reescrever query, adicionar índice |
| `rows=1` mas `actual rows=50000` | Estatísticas desatualizadas | `ANALYZE tabela;` |
| `Hash Join` muito lento | JOIN sem índice | Indexar foreign keys |
| Tempo > 100ms em query simples | Problema grave | Investigar com DBA |

```sql
-- Atualizar estatísticas
ANALYZE users;
ANALYZE orders;

-- Ver tabelas com mais slow queries (PostgreSQL)
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 20;
```

---

## N+1 — Detectar e Eliminar

```typescript
// ❌ N+1: 1 query para users + N queries para orders
const users = await prisma.user.findMany()
for (const user of users) {
  const orders = await prisma.order.findMany({  // N queries!
    where: { userId: user.id }
  })
}

// ✅ Solução: include (1 query com JOIN)
const users = await prisma.user.findMany({
  include: { orders: true }
})

// ✅ Solução: select específico (mais performático)
const users = await prisma.user.findMany({
  include: {
    orders: {
      select: { id: true, total: true, status: true },
      where: { status: 'CONFIRMED' },
      orderBy: { createdAt: 'desc' },
      take: 5
    }
  }
})
```

---

## Soft Delete — Implementação Completa

```prisma
model Product {
  id        String    @id @default(cuid())
  name      String
  deletedAt DateTime?            // null = ativo, data = deletado

  @@index([deletedAt])           // para filtrar deletados eficientemente
}
```

```typescript
// Middleware Prisma para filtrar deletados automaticamente
prisma.$use(async (params, next) => {
  const modelsComSoftDelete = ['Product', 'User', 'Order']

  if (modelsComSoftDelete.includes(params.model ?? '')) {
    if (params.action === 'findMany' || params.action === 'findFirst') {
      params.args.where = { ...params.args.where, deletedAt: null }
    }
    if (params.action === 'delete') {
      params.action = 'update'
      params.args.data = { deletedAt: new Date() }
    }
  }

  return next(params)
})
```

---

## Referências

→ `references/postgresql-avancado.md` — JSONB, Full-Text Search, Window Functions, CTEs
→ `references/prisma-patterns.md` — Transações, seed, raw SQL, aggregations avançadas
