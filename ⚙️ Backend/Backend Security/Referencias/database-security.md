# Segurança de Banco de Dados

## Princípio do Menor Privilégio

```sql
-- ❌ Nunca usar superuser/root para a aplicação
-- CREATE USER app_user SUPERUSER; -- PROIBIDO

-- ✅ Criar usuário com apenas as permissões necessárias
CREATE USER app_user WITH PASSWORD 'senha-forte-aqui';
GRANT CONNECT ON DATABASE mydb TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
-- NÃO conceder: DROP, CREATE, ALTER, TRUNCATE (a menos que necessário)

-- Para read-only (ex: analytics, relatórios):
CREATE USER readonly_user WITH PASSWORD 'outra-senha-forte';
GRANT CONNECT ON DATABASE mydb TO readonly_user;
GRANT USAGE ON SCHEMA public TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;
```

## Prisma — Queries Seguras por Padrão

```typescript
// Prisma usa queries parametrizadas automaticamente ✅
// Mas atenção em raw queries:

// ❌ SQL injection possível com $queryRawUnsafe
const users = await prisma.$queryRawUnsafe(
  `SELECT * FROM users WHERE name = '${name}'`
)

// ✅ Usar $queryRaw com template literals (parametrizado automaticamente)
const users = await prisma.$queryRaw`
  SELECT * FROM users WHERE name = ${name}
`

// ✅ Ou melhor ainda: usar o client ORM
const users = await prisma.user.findMany({
  where: { name }
})
```

## Proteção contra Mass Assignment

```typescript
// ❌ Errado — usuário pode injetar qualquer campo
const user = await prisma.user.update({
  where: { id: userId },
  data: req.body  // NUNCA passar body direto!
})
// Atacante pode enviar: { role: "admin", isVerified: true }

// ✅ Correto — campos explícitos permitidos
const { name, bio, avatarUrl } = UpdateProfileSchema.parse(req.body)
const user = await prisma.user.update({
  where: { id: userId },
  data: { name, bio, avatarUrl }  // apenas os campos seguros
})
```

## Não Expor Dados Sensíveis

```typescript
// Nunca retornar o objeto completo do usuário
const user = await prisma.user.findUnique({ where: { id } })
return user // ❌ retorna passwordHash, refreshToken, etc.

// Usar select explícito ou omitir campos sensíveis
const user = await prisma.user.findUnique({
  where: { id },
  select: {
    id: true,
    name: true,
    email: true,
    role: true,
    createdAt: true,
    // passwordHash: NUNCA
    // refreshToken: NUNCA
  }
})

// Ou omitir campos com helper:
function omitSensitive<T extends Record<string, any>>(obj: T) {
  const { passwordHash, refreshToken, ...safe } = obj
  return safe
}
```

## Soft Delete (evitar perda acidental de dados)

```typescript
// Ao invés de deletar, marcar como deletado
model User {
  id        String    @id @default(cuid())
  deletedAt DateTime? // null = ativo, data = deletado
}

// Sempre filtrar no middleware ou query
const activeUsers = await prisma.user.findMany({
  where: { deletedAt: null }
})

// Hard delete apenas em processos de limpeza programada
```

## Proteção de Dados Sensíveis (Criptografia em repouso)

```typescript
import { createCipheriv, createDecipheriv, randomBytes } from 'crypto'

// Para campos muito sensíveis (CPF, número de cartão, etc.)
function encrypt(text: string): string {
  const iv = randomBytes(16)
  const key = Buffer.from(process.env.ENCRYPTION_KEY!, 'hex') // 32 bytes
  const cipher = createCipheriv('aes-256-gcm', key, iv)

  const encrypted = Buffer.concat([cipher.update(text, 'utf8'), cipher.final()])
  const tag = cipher.getAuthTag()

  return `${iv.toString('hex')}:${tag.toString('hex')}:${encrypted.toString('hex')}`
}

function decrypt(encryptedText: string): string {
  const [ivHex, tagHex, dataHex] = encryptedText.split(':')
  const key = Buffer.from(process.env.ENCRYPTION_KEY!, 'hex')
  const decipher = createDecipheriv('aes-256-gcm', key, Buffer.from(ivHex, 'hex'))
  decipher.setAuthTag(Buffer.from(tagHex, 'hex'))

  return decipher.update(Buffer.from(dataHex, 'hex')) + decipher.final('utf8')
}
```

## Connection Pooling Seguro

```typescript
// DATABASE_URL nunca deve ter senha em texto visível em logs
// Use connection pooling com Prisma Accelerate ou PgBouncer

// No .env:
// DATABASE_URL="postgresql://user:SENHA@host:5432/db?sslmode=require"

// SSL obrigatório em produção
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
  // sslmode=require no URL ou:
  directUrl = env("DIRECT_URL") // para migrations
}
```


---

← [[README|Backend Security]]
