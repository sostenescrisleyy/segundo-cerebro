---
tags: [backend]
categoria: "⚙️ Backend"
---

# PostgreSQL — Referência Completa

**Versão:** PostgreSQL 16+  
**Princípio:** SQL é a melhor linguagem para dados relacionais. Entender o plano de execução é fundamental para performance.

---

## Tipos de Dados Essenciais

```sql
-- Texto
TEXT, VARCHAR(n), CHAR(n)

-- Números
INTEGER, BIGINT, NUMERIC(p,s), REAL, DOUBLE PRECISION
SERIAL, BIGSERIAL           -- auto-increment (preferir GENERATED ALWAYS)

-- IDs modernos
id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY
id UUID DEFAULT gen_random_uuid() PRIMARY KEY

-- Data/Hora
DATE, TIME, TIMESTAMP, TIMESTAMPTZ  -- TZ = com timezone (PREFERIR)
INTERVAL

-- Booleano
BOOLEAN

-- JSON
JSON   -- texto validado como JSON
JSONB  -- binário indexável (PREFERIR)

-- Arrays
INTEGER[], TEXT[], JSONB[]

-- Enum
CREATE TYPE status AS ENUM ('pending', 'active', 'inactive');
```

---

## DDL — Criar Tabelas

```sql
CREATE TABLE users (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  email      TEXT    NOT NULL UNIQUE,
  name       TEXT    NOT NULL CHECK (length(name) >= 2),
  role       TEXT    NOT NULL DEFAULT 'user'
             CHECK (role IN ('user', 'admin')),
  metadata   JSONB   DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE posts (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title      TEXT     NOT NULL,
  content    TEXT,
  published  BOOLEAN  DEFAULT FALSE,
  author_id  BIGINT   NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  tags       TEXT[]   DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_posts_author   ON posts(author_id);
CREATE INDEX idx_posts_tags     ON posts USING GIN(tags);      -- para arrays
CREATE INDEX idx_users_metadata ON users USING GIN(metadata);  -- para JSONB
CREATE INDEX idx_posts_search   ON posts USING GIN(
  to_tsvector('portuguese', title || ' ' || coalesce(content, ''))
);
```

---

## Queries Fundamentais

```sql
-- SELECT com JOIN
SELECT
  p.id,
  p.title,
  u.name AS author,
  COUNT(c.id) AS comment_count
FROM posts p
JOIN users u ON u.id = p.author_id
LEFT JOIN comments c ON c.post_id = p.id
WHERE p.published = TRUE
  AND p.created_at > NOW() - INTERVAL '30 days'
GROUP BY p.id, u.name
HAVING COUNT(c.id) > 5
ORDER BY p.created_at DESC
LIMIT 20 OFFSET 0;

-- Upsert
INSERT INTO users (email, name)
VALUES ('ana@email.com', 'Ana Lima')
ON CONFLICT (email)
DO UPDATE SET name = EXCLUDED.name, updated_at = NOW()
RETURNING *;

-- Update com JOIN
UPDATE posts p
SET published = TRUE
FROM users u
WHERE p.author_id = u.id
  AND u.role = 'admin'
  AND p.created_at < NOW() - INTERVAL '7 days';
```

---

## CTEs (Common Table Expressions)

```sql
-- CTE simples
WITH active_users AS (
  SELECT id, email, name
  FROM users
  WHERE last_login > NOW() - INTERVAL '30 days'
),
user_stats AS (
  SELECT
    u.id,
    COUNT(p.id) AS post_count,
    SUM(p.view_count) AS total_views
  FROM active_users u
  LEFT JOIN posts p ON p.author_id = u.id
  GROUP BY u.id
)
SELECT u.*, s.post_count, s.total_views
FROM active_users u
JOIN user_stats s ON s.id = u.id
ORDER BY s.total_views DESC;

-- CTE recursiva (hierarquia)
WITH RECURSIVE category_tree AS (
  -- âncora
  SELECT id, name, parent_id, 0 AS depth
  FROM categories WHERE parent_id IS NULL

  UNION ALL

  -- recursão
  SELECT c.id, c.name, c.parent_id, ct.depth + 1
  FROM categories c
  JOIN category_tree ct ON c.parent_id = ct.id
)
SELECT * FROM category_tree ORDER BY depth, name;
```

---

## Window Functions

```sql
SELECT
  id,
  name,
  salary,
  department,
  AVG(salary)    OVER (PARTITION BY department)          AS dept_avg,
  RANK()         OVER (PARTITION BY department ORDER BY salary DESC) AS rank_in_dept,
  ROW_NUMBER()   OVER (ORDER BY salary DESC)              AS overall_rank,
  LAG(salary)    OVER (ORDER BY created_at)               AS prev_salary,
  SUM(salary)    OVER (ORDER BY created_at ROWS UNBOUNDED PRECEDING) AS running_total
FROM employees;
```

---

## JSONB — Dados Semi-estruturados

```sql
-- Queries em JSONB
SELECT * FROM users
WHERE metadata->>'plan' = 'pro';

SELECT * FROM users
WHERE metadata @> '{"features": ["api_access"]}';

-- Atualizar campo JSONB
UPDATE users
SET metadata = metadata || '{"last_login": "2025-07-01"}'
WHERE id = 1;

-- Indexar campo JSONB específico (mais eficiente que GIN total)
CREATE INDEX idx_users_plan ON users ((metadata->>'plan'));
```

---

## Full-Text Search

```sql
-- Busca em português
SELECT title, ts_rank(search_vector, query) AS rank
FROM posts,
  to_tsquery('portuguese', 'node:* & javascript:*') query
WHERE search_vector @@ query
ORDER BY rank DESC;

-- Coluna gerada para FTS (melhor performance)
ALTER TABLE posts
ADD COLUMN search_vector TSVECTOR
GENERATED ALWAYS AS (
  to_tsvector('portuguese', title || ' ' || coalesce(content, ''))
) STORED;
```

---

## Performance — EXPLAIN ANALYZE

```sql
-- Ver plano de execução
EXPLAIN ANALYZE
SELECT * FROM posts WHERE author_id = 123;

-- Sinais de problema:
-- "Seq Scan" em tabela grande → falta índice
-- "Hash Join" em tabelas pequenas → pode ser Nested Loop
-- "cost=0.00..99999" alto → query pesada
-- "rows=1" com "actual rows=50000" → estatísticas desatualizadas
--   → rodar: ANALYZE posts;
```

---

## Referências

→ `references/pg-admin.md` — Roles, permissões, backup, restore, monitoramento


---

## Relacionado

[[Prisma ORM]] | [[Supabase]] | [[Docker e Compose]]


---

## Referencias

- [[Referencias/extra]]
