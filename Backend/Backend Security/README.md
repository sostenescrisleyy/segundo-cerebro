---
tags: [backend]
categoria: "Backend"
---

# Backend Security — Zero Trust por Padrão

## A Filosofia Central

> **O frontend é um campo de batalha público. Qualquer dado que chega ao servidor pode ter sido forjado.**  
> Um usuário mal-intencionado pode: modificar requests com DevTools, interceptar com Burp Suite, escrever scripts curl, replay attacks em webhooks, e fazer tudo que quiser com seus dados — exceto o que você barrar no servidor.

**Regra de ouro:** Segurança que existe apenas no frontend não é segurança.

---

## Lei 1 — Segredos Nunca Tocam o Frontend

### O problema

```bash
# Isto parece "seguro" mas NÃO É:
REACT_APP_STRIPE_SECRET=sk_live_abc123   # ← bundle público no JS
NEXT_PUBLIC_OPENAI_KEY=sk-xyz789         # ← NEXT_PUBLIC = visível para todos
VITE_GOOGLE_API_KEY=AIzaSy...            # ← todo VITE_ vai pro bundle
```

Durante o build, essas variáveis são literalmente substituídas nos arquivos `.js` que qualquer um pode ler com `curl https://seusite.com/assets/index.js | grep "sk_live"`.

### A solução: BFF (Backend for Frontend)

```
Browser ──→ SEU SERVIDOR (guarda segredos) ──→ API externa
              ↑ nunca passa o secret key    ↑ aqui sim usa o key
```

```typescript
// ✅ Correto — chave fica no servidor
// pages/api/payment.ts (Next.js) ou routes/payment.ts (Express)
export async function POST(req: Request) {
  // STRIPE_SECRET nunca vai pro browser — fica só aqui
  const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!)

  const session = await stripe.checkout.sessions.create({ /* ... */ })
  return Response.json({ url: session.url }) // só retorna o necessário
}

// ❌ Errado — chama Stripe direto do browser
// No componente React:
const stripe = new Stripe(process.env.REACT_APP_STRIPE_KEY) // EXPOSTO
```

### Classificação de variáveis

| Tipo | Exemplo | Onde fica |
|---|---|---|
| **Segredo** | `DATABASE_URL`, `JWT_SECRET`, `STRIPE_SECRET`, `OPENAI_KEY` | Servidor APENAS — nunca `NEXT_PUBLIC_` |
| **ID público** | `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` | Pode ser público — é feito para isso |
| **Config pública** | `NEXT_PUBLIC_API_URL`, `NEXT_PUBLIC_APP_NAME` | OK no frontend |

### Gestão de segredos em produção

```bash
# ❌ Nunca commitar .env com valores reais
# .gitignore DEVE ter:
.env
.env.local
.env.production

# ✅ Commitar apenas o template:
# .env.example (sem valores reais):
DATABASE_URL=postgresql://user:password@host:5432/db
JWT_SECRET=gere-com-openssl-rand-hex-32
STRIPE_SECRET_KEY=sk_live_...
```

Para produção, use um gerenciador de segredos (não apenas env vars):
- **AWS Secrets Manager** — rotação automática + auditoria
- **HashiCorp Vault** — auto-hospedado, controle total
- **Doppler / Infisical** — developer-friendly, fácil integração

---

## Lei 2 — Nunca Confie no Input do Usuário

### Validação dupla — sempre no servidor

```typescript
// ❌ Errado — só valida no frontend, backend aceita qualquer coisa
// Frontend: campo com maxLength="100"
// Backend: await db.insert({ bio: req.body.bio }) // sem validar

// ✅ Correto — validação no servidor com Zod
import { z } from 'zod'

const CreateUserSchema = z.object({
  name:  z.string().min(2).max(100).trim(),
  email: z.string().email().toLowerCase(),
  age:   z.number().int().min(18).max(120),
  bio:   z.string().max(500).optional(),
  role:  z.enum(['user', 'editor']),  // nunca aceitar 'admin' de input externo!
})

export async function createUser(req: Request) {
  // Parse lança erro automático em input inválido
  const data = CreateUserSchema.parse(req.body)
  // Daqui para frente, data é tipado e validado
  await db.users.create({ data })
}
```

### Sanitização de HTML (XSS prevention)

```typescript
// Se precisar aceitar HTML do usuário:
import DOMPurify from 'isomorphic-dompurify'

// ❌ Errado
const bio = req.body.bio  // pode conter <script>alert(1)</script>
await db.update({ bio })

// ✅ Correto
const bio = DOMPurify.sanitize(req.body.bio, {
  ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a'],
  ALLOWED_ATTR: ['href']
})
await db.update({ bio })
```

### SQL Injection — sempre parameterizado

```typescript
// ❌ CRÍTICO — SQL injection direto
const users = await db.query(
  `SELECT * FROM users WHERE email = '${email}'`
)
// email = "' OR 1=1 --" → retorna TODOS os usuários

// ✅ Correto — parâmetros separados do SQL
const users = await db.query(
  'SELECT * FROM users WHERE email = $1',
  [email]
)
// Com ORM (Prisma, Drizzle) — parametrizado por padrão
const user = await prisma.user.findUnique({ where: { email } })
```

---

## Lei 3 — Autorização no Servidor, Sempre

### BOLA — Broken Object Level Authorization (OWASP #1)

```typescript
// ❌ Crítico — usuário A pode acessar dados do usuário B
app.get('/api/invoices/:id', authenticate, async (req, res) => {
  const invoice = await db.invoices.findById(req.params.id)
  // Nunca verifica se a invoice pertence ao usuário logado!
  res.json(invoice)
})

// ✅ Correto — sempre filtra pelo usuário autenticado
app.get('/api/invoices/:id', authenticate, async (req, res) => {
  const invoice = await db.invoices.findFirst({
    where: {
      id: req.params.id,
      userId: req.user.id  // ← OBRIGATÓRIO: usuário só vê o que é dele
    }
  })
  if (!invoice) return res.status(404).json({ error: 'Not found' })
  res.json(invoice)
})
```

### IDs previsíveis — use UUIDs ou ULIDs

```typescript
// ❌ Problema — IDs sequenciais revelam volume e permitem enumeração
GET /api/orders/1
GET /api/orders/2  // atacante testa todos os números

// ✅ UUIDs ou ULIDs — impossíveis de enumerar
GET /api/orders/01HQ7K3FXNM8Y3BXKJQE7Z5NP2
GET /api/orders/550e8400-e29b-41d4-a716-446655440000

// Prisma com CUID/UUID
model Order {
  id String @id @default(cuid())
}
```

### Role-Based Access Control (RBAC)

```typescript
// Middleware de permissão reutilizável
function requireRole(...roles: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) return res.status(401).json({ error: 'Unauthorized' })
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Forbidden' })
    }
    next()
  }
}

// Uso
app.delete('/api/users/:id', authenticate, requireRole('admin'), deleteUser)
app.get('/api/reports', authenticate, requireRole('admin', 'manager'), getReports)
```

---

## Lei 4 — JWT e Autenticação Segura

```typescript
// ✅ Configuração correta de JWT
import jwt from 'jsonwebtoken'

// NUNCA HS256 com secret fraco — use RS256 ou secret longo
const ACCESS_TOKEN_SECRET = process.env.JWT_SECRET! // 32+ bytes aleatórios
const REFRESH_TOKEN_SECRET = process.env.JWT_REFRESH_SECRET! // diferente!

function generateTokens(userId: string, role: string) {
  const accessToken = jwt.sign(
    { sub: userId, role },
    ACCESS_TOKEN_SECRET,
    {
      expiresIn: '15m',  // ← CURTO — access token expira rápido
      algorithm: 'HS256',
      issuer: 'api.seudominio.com',
      audience: 'app.seudominio.com',
    }
  )

  const refreshToken = jwt.sign(
    { sub: userId },
    REFRESH_TOKEN_SECRET,
    { expiresIn: '7d' }  // refresh pode ser mais longo
  )

  return { accessToken, refreshToken }
}

// Validação — nunca confiar sem verificar
function verifyAccessToken(token: string) {
  return jwt.verify(token, ACCESS_TOKEN_SECRET, {
    algorithms: ['HS256'],  // rejeita outros algoritmos
    issuer: 'api.seudominio.com',
    audience: 'app.seudominio.com',
  })
}
```

### Onde armazenar tokens no browser

```
❌ localStorage → acessível por qualquer JS (XSS rouba o token)
❌ sessionStorage → mesmo problema do localStorage
❌ Cookie sem flags → CSRF vulnerável

✅ Cookie httpOnly + SameSite=Lax + Secure → invisível para JS, protegido de CSRF
```

```typescript
// Setar cookie httpOnly corretamente
res.cookie('accessToken', accessToken, {
  httpOnly: true,    // JS não consegue ler
  secure: true,      // só HTTPS
  sameSite: 'lax',   // protege de CSRF
  maxAge: 15 * 60 * 1000, // 15 min em ms
  path: '/',
})
```

---

## Lei 5 — Rate Limiting e Proteção de Endpoints Sensíveis

```typescript
import rateLimit from 'express-rate-limit'
import slowDown from 'express-slow-down'

// Rate limit global
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 min
  max: 100,
  message: { error: 'Too many requests' },
  standardHeaders: true,
  legacyHeaders: false,
})

// Rate limit AGRESSIVO para login (anti-brute force)
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,   // só 5 tentativas por 15 min por IP
  skipSuccessfulRequests: true, // não conta logins com sucesso
})

// Slow down progressivo (melhor UX que bloquear imediatamente)
const speedLimiter = slowDown({
  windowMs: 15 * 60 * 1000,
  delayAfter: 5,
  delayMs: () => 500, // +500ms por request após o limite
})

app.use(globalLimiter)
app.post('/auth/login', loginLimiter, speedLimiter, loginHandler)
app.post('/auth/forgot-password', loginLimiter, forgotPasswordHandler)
```

---

## Lei 6 — Upload de Arquivos Seguro

```typescript
import { magic } from 'mmmagic' // detecta tipo real pelo conteúdo

// ❌ Errado — confiar no mimetype do browser
app.post('/upload', upload.single('file'), async (req, res) => {
  const mime = req.file.mimetype // usuário pode forjar isto!
  if (mime.startsWith('image/')) processImage(req.file)
})

// ✅ Correto — verificar magic bytes do arquivo
import fileType from 'file-type'

app.post('/upload', upload.single('file'), async (req, res) => {
  const buffer = req.file.buffer
  const detected = await fileType.fromBuffer(buffer)

  const ALLOWED = ['image/jpeg', 'image/png', 'image/webp', 'image/gif']
  if (!detected || !ALLOWED.includes(detected.mime)) {
    return res.status(415).json({ error: 'Tipo de arquivo não permitido' })
  }

  // Limite de tamanho TAMBÉM no servidor (não só no frontend)
  if (buffer.length > 5 * 1024 * 1024) { // 5MB
    return res.status(413).json({ error: 'Arquivo muito grande' })
  }

  // Gerar nome único — nunca usar nome do usuário diretamente
  const ext = detected.ext
  const safeName = `${crypto.randomUUID()}.${ext}`
  await saveFile(buffer, safeName)
})
```

---

## Lei 7 — Headers de Segurança e CORS

```typescript
import helmet from 'helmet'

// Helmet aplica todos os headers de segurança automaticamente
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"], // ajuste se usar CDN
      imgSrc: ["'self'", 'data:', 'https:'],
    },
  },
  hsts: { maxAge: 31536000, includeSubDomains: true }, // 1 ano
}))

// CORS — nunca wildcard em produção
const corsOptions = {
  origin: process.env.NODE_ENV === 'production'
    ? ['https://app.seudominio.com']   // apenas origens conhecidas
    : 'http://localhost:3000',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}
app.use(cors(corsOptions))
```

---

## Lei 8 — Logs Seguros (Nunca Logar Segredos)

```typescript
// ❌ Errado — logar dados sensíveis
console.log('Login attempt:', req.body) // loga senha!
logger.info('JWT generated:', token)     // loga token!
logger.error('DB error:', error.stack)   // pode expor URLs com senhas

// ✅ Correto — logar apenas o que é seguro
logger.info('Login attempt', {
  email: req.body.email, // ok
  ip: req.ip,
  timestamp: new Date().toISOString(),
  // password: NUNCA
})

// Máscara para dados sensíveis
function maskSensitive(obj: Record<string, any>) {
  const SENSITIVE = ['password', 'token', 'secret', 'key', 'authorization']
  return Object.fromEntries(
    Object.entries(obj).map(([k, v]) =>
      SENSITIVE.some(s => k.toLowerCase().includes(s))
        ? [k, '[REDACTED]']
        : [k, v]
    )
  )
}
```

---

## Checklist de Segurança — Antes de Deploy

→ Lista completa em: `references/security-checklist.md`  
→ OWASP Top 10 API detalhado: `references/owasp-api-top10.md`  
→ Autenticação avançada (OAuth, magic links): `references/auth-patterns.md`  
→ Proteção de banco de dados: `references/database-security.md`


---

## Relacionado

[[Supabase]] | [[Next.js 15]] | [[Node.js]]


---

## Referencias

- [[Referencias/auth-patterns]]
- [[Referencias/database-security]]
- [[Referencias/security-checklist]]
