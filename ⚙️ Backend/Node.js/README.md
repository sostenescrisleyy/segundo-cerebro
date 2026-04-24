---
tags: [backend]
categoria: "⚙️ Backend"
---

# Node.js — Backend Moderno

**Runtime:** Node.js 22+ (LTS)  
**Princípios:** async/await nativo, ES Modules, TypeScript, segurança por padrão.

---

## Setup Moderno (ES Modules + TypeScript)

```json
// package.json
{
  "type": "module",
  "scripts": {
    "dev":   "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js"
  }
}
```

```typescript
// src/index.ts — servidor HTTP nativo (sem framework)
import http from 'node:http'

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' })
  res.end(JSON.stringify({ message: 'Hello Node.js' }))
})

server.listen(3000, () => console.log('🚀 http://localhost:3000'))
```

---

## Express — API REST Completa

```typescript
import express, { Request, Response, NextFunction } from 'express'
import cors from 'cors'
import helmet from 'helmet'

const app = express()

// Middlewares globais
app.use(helmet())                       // headers de segurança
app.use(cors({ origin: process.env.FRONTEND_URL }))
app.use(express.json({ limit: '10mb' }))
app.use(express.urlencoded({ extended: true }))

// Router modular
import usersRouter from './routes/users.js'
app.use('/api/users', usersRouter)

// Error handler global (SEMPRE ao final)
app.use((err: Error, req: Request, res: Response, _next: NextFunction) => {
  console.error(err.stack)
  res.status(500).json({ error: err.message })
})

app.listen(Number(process.env.PORT) || 3000)
```

```typescript
// routes/users.ts
import { Router } from 'express'
import { z } from 'zod'

const router = Router()

// Schema de validação
const CreateUserSchema = z.object({
  name:  z.string().min(2).max(100),
  email: z.email(),
  age:   z.number().int().min(18).max(120),
})

router.get('/', async (req, res) => {
  const users = await db.users.findMany()
  res.json(users)
})

router.post('/', async (req, res, next) => {
  try {
    const body = CreateUserSchema.parse(req.body)
    const user = await db.users.create({ data: body })
    res.status(201).json(user)
  } catch (err) {
    next(err)  // repassa para o error handler
  }
})

export default router
```

---

## Fastify — Alta Performance

```typescript
import Fastify from 'fastify'
import { z } from 'zod'

const app = Fastify({ logger: true })

// Plugin de autenticação
await app.register(import('@fastify/jwt'), {
  secret: process.env.JWT_SECRET!
})

// Rota com schema (validação automática + Swagger)
app.post('/users', {
  schema: {
    body: {
      type: 'object',
      required: ['name', 'email'],
      properties: {
        name:  { type: 'string' },
        email: { type: 'string', format: 'email' },
      }
    }
  }
}, async (request, reply) => {
  const user = await createUser(request.body)
  return reply.status(201).send(user)
})

await app.listen({ port: 3000 })
```

---

## Autenticação JWT

```typescript
import jwt from 'jsonwebtoken'
import bcrypt from 'bcrypt'

const JWT_SECRET  = process.env.JWT_SECRET!
const SALT_ROUNDS = 12

// Hash de senha
export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, SALT_ROUNDS)
}

export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash)
}

// Gerar token
export function generateTokens(userId: string) {
  const accessToken = jwt.sign(
    { sub: userId, type: 'access' },
    JWT_SECRET,
    { expiresIn: '15m' }
  )
  const refreshToken = jwt.sign(
    { sub: userId, type: 'refresh' },
    JWT_SECRET,
    { expiresIn: '7d' }
  )
  return { accessToken, refreshToken }
}

// Middleware de autenticação (Express)
export function authenticate(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.split(' ')[1]
  if (!token) return res.status(401).json({ error: 'Token ausente' })

  try {
    const payload = jwt.verify(token, JWT_SECRET) as { sub: string }
    req.userId = payload.sub
    next()
  } catch {
    res.status(401).json({ error: 'Token inválido ou expirado' })
  }
}
```

---

## Variáveis de Ambiente

```typescript
// lib/env.ts — validar ENV no startup
import { z } from 'zod'

const EnvSchema = z.object({
  NODE_ENV:     z.enum(['development', 'production', 'test']).default('development'),
  PORT:         z.coerce.number().default(3000),
  DATABASE_URL: z.url(),
  JWT_SECRET:   z.string().min(32),
  REDIS_URL:    z.url().optional(),
})

// Lança erro no startup se variável obrigatória faltar
export const env = EnvSchema.parse(process.env)
```

---

## Upload de Arquivos com Multer

```typescript
import multer from 'multer'
import path from 'node:path'

const storage = multer.diskStorage({
  destination: 'uploads/',
  filename: (req, file, cb) => {
    const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`
    cb(null, `${unique}${path.extname(file.originalname)}`)
  },
})

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },  // 5MB
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/webp']
    cb(null, allowed.includes(file.mimetype))
  },
})

// Rota de upload
router.post('/avatar', upload.single('file'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'Arquivo obrigatório' })
  res.json({ url: `/uploads/${req.file.filename}` })
})
```

---

## Rate Limiting

```typescript
import rateLimit from 'express-rate-limit'

// Rate limit global
app.use(rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutos
  max: 100,                   // máximo de requisições por janela
  standardHeaders: true,
  legacyHeaders: false,
}))

// Rate limit para auth (mais restritivo)
export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: { error: 'Muitas tentativas. Tente novamente em 15 minutos.' },
})

app.use('/api/auth', authLimiter)
```

---

## Referências

→ `references/patterns.md` — Error handling, logging com Pino, graceful shutdown, clustering


---

## Relacionado

[[TypeScript]] | [[Docker e Compose]] | [[Prisma ORM]]


---

## Referencias

- [[Referencias/extra]]
