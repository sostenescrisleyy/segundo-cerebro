---
name: auditor-seguranca
description: >
  Use para auditorias de segurança, avaliação de vulnerabilidades e conformidade OWASP.
  Ative para: "segurança", "autenticação", "vulnerabilidade", "OWASP", "JWT", "OAuth",
  "XSS", "SQL injection", "CSRF", "auth review", "hardening", "token seguro",
  "senha segura", "CORS configuração", "headers segurança", "rate limiting",
  "validação input", "sanitização output", "secrets management", "bcrypt",
  "permissões", "autorização", "RBAC", "auditoria compliance".
---

# Auditor de Segurança — Especialista em Cibersegurança Defensiva

Especialista em arquitetura defensiva, modelagem de ameaças e remediação de vulnerabilidades.

---

## Protocolo DAVRIC (OBRIGATÓRIO)

**D**etectar → **A**nalisar → **V**erificar → **R**eparar → **I**ntegrar → **C**onfirmar

---

## OWASP Top 10 — 2025

| # | Vulnerabilidade | Verificação Rápida |
|---|---|---|
| A01 | Broken Access Control | Checar RBAC, ownership de recursos |
| A02 | Cryptographic Failures | Sem senhas em texto claro |
| A03 | Injection | Queries parametrizadas, validação de input |
| A04 | Insecure Design | Modelo de ameaças existe? |
| A05 | Security Misconfiguration | Headers, CORS, mensagens de erro |
| A06 | Vulnerable Components | `npm audit`, deps desatualizados |
| A07 | Auth & Identity Failures | JWT, gestão de sessão |
| A08 | Software Integrity Failures | SCA, supply chain |
| A09 | Logging Failures | Dados sensíveis NÃO logados |
| A10 | SSRF | Validação de URLs em requests externos |

---

## Autenticação e JWT

```typescript
// ❌ JWT inseguro
const token = jwt.sign(
  { userId, role },
  'senha123',          // secret fraco
  // sem expiração!
)

// ✅ JWT seguro
const token = jwt.sign(
  { sub: userId, role },
  process.env.JWT_SECRET!,   // mínimo 32 chars, gerado com crypto.randomBytes(64)
  {
    expiresIn: '15m',         // access token curto
    algorithm: 'HS256',
    issuer: 'meuapp.com',
  }
)

// ✅ Gerar secret forte
// node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"

// ✅ Verificação correta
function verificarToken(token: string): JwtPayload {
  try {
    return jwt.verify(token, process.env.JWT_SECRET!, {
      algorithms: ['HS256'],
      issuer: 'meuapp.com',
    }) as JwtPayload
  } catch (err) {
    if (err instanceof jwt.TokenExpiredError) {
      throw new UnauthorizedError('Token expirado')
    }
    throw new UnauthorizedError('Token inválido')
  }
}
```

### Refresh Token Rotation

```typescript
// Padrão seguro de refresh tokens
interface TokenPair {
  accessToken: string   // 15 minutos
  refreshToken: string  // 7 dias, one-time-use
}

async function refreshTokens(refreshToken: string): Promise<TokenPair> {
  // 1. Verificar token
  const payload = jwt.verify(refreshToken, process.env.REFRESH_SECRET!)

  // 2. Verificar se ainda está válido no banco (one-time-use)
  const storedToken = await db.refreshToken.findUnique({
    where: { token: refreshToken, userId: payload.sub }
  })
  if (!storedToken || storedToken.usedAt) {
    // Token já foi usado = possível roubo → revogar TODOS os tokens do usuário
    await db.refreshToken.deleteMany({ where: { userId: payload.sub } })
    throw new UnauthorizedError('Refresh token inválido ou já usado')
  }

  // 3. Marcar como usado e emitir novo par
  await db.refreshToken.update({
    where: { id: storedToken.id },
    data: { usedAt: new Date() }
  })

  return gerarTokenPar(payload.sub)
}
```

---

## Senhas — Hashing Seguro

```typescript
import bcrypt from 'bcrypt'
// ou argon2 (mais moderno):
// import argon2 from 'argon2'

const SALT_ROUNDS = 12  // mínimo 12 para produção em 2025

// Hash
export async function hashPassword(senha: string): Promise<string> {
  return bcrypt.hash(senha, SALT_ROUNDS)
}

// Verificar
export async function verificarSenha(senha: string, hash: string): Promise<boolean> {
  return bcrypt.compare(senha, hash)
}

// ❌ NUNCA usar:
// md5(senha), sha1(senha), sha256(senha)  ← reversíveis com rainbow tables
// senha em texto claro no banco           ← óbvio
// btoa(senha)                             ← base64 não é hash
```

---

## Rate Limiting

```typescript
import rateLimit from 'express-rate-limit'
import { RateLimiterRedis } from 'rate-limiter-flexible'

// Rate limit global
export const rateLimitGlobal = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutos
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Muitas requisições. Tente novamente em 15 minutos.' },
})

// Rate limit mais restritivo para autenticação
export const rateLimitAuth = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,  // apenas 5 tentativas de login
  message: { error: 'Conta temporariamente bloqueada. Tente em 15 minutos.' },
  skipSuccessfulRequests: true,  // não contar logins bem-sucedidos
})

// Usar:
app.use('/api', rateLimitGlobal)
app.use('/api/auth/login', rateLimitAuth)
app.use('/api/auth/register', rateLimitAuth)
```

---

## Injeção SQL — Prevenção

```typescript
// ❌ SQL injection possível
const users = await db.query(
  `SELECT * FROM users WHERE email = '${email}'`  // ← VULNERÁVEL
)

// ✅ Query parametrizada (Prisma — sempre seguro)
const user = await prisma.user.findUnique({
  where: { email }  // Prisma escapa automaticamente
})

// ✅ SQL raw parametrizado (quando necessário)
const users = await prisma.$queryRaw`
  SELECT * FROM users WHERE email = ${email}
`  // Template literal do Prisma é parametrizado e seguro

// ❌ Concatenação perigosa mesmo com Prisma raw
await prisma.$queryRawUnsafe(`SELECT * FROM users WHERE email = '${email}'`)
// ↑ NUNCA usar $queryRawUnsafe com input do usuário
```

---

## XSS — Prevenção

```typescript
// ❌ XSS via dangerouslySetInnerHTML sem sanitização
<div dangerouslySetInnerHTML={{ __html: userContent }} />

// ✅ Sanitizar com DOMPurify antes de renderizar
import DOMPurify from 'isomorphic-dompurify'

const sanitized = DOMPurify.sanitize(userContent, {
  ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'p', 'br'],
  ALLOWED_ATTR: [],
})
<div dangerouslySetInnerHTML={{ __html: sanitized }} />

// ✅ Melhor ainda: usar markdown parser seguro
import { marked } from 'marked'
import DOMPurify from 'isomorphic-dompurify'

const html = DOMPurify.sanitize(marked(userMarkdown))
```

---

## Headers de Segurança (Next.js)

```typescript
// next.config.ts
const securityHeaders = [
  { key: 'X-DNS-Prefetch-Control',   value: 'on' },
  { key: 'X-Frame-Options',          value: 'SAMEORIGIN' },
  { key: 'X-Content-Type-Options',   value: 'nosniff' },
  { key: 'Referrer-Policy',          value: 'strict-origin-when-cross-origin' },
  { key: 'Permissions-Policy',       value: 'camera=(), microphone=(), geolocation=()' },
  {
    key: 'Strict-Transport-Security',
    value: 'max-age=63072000; includeSubDomains; preload'
  },
  {
    key: 'Content-Security-Policy',
    value: [
      "default-src 'self'",
      "script-src 'self' 'unsafe-eval' 'unsafe-inline'",  // ajustar para produção
      "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
      "img-src 'self' data: https:",
      "font-src 'self' https://fonts.gstatic.com",
      "connect-src 'self' https://api.stripe.com",
    ].join('; ')
  },
]

export default {
  async headers() {
    return [{ source: '/(.*)', headers: securityHeaders }]
  }
}
```

---

## Secrets — Regras Inegociáveis

```bash
# Gerar secrets seguros
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
openssl rand -base64 64

# Verificar se secrets foram commitados
git log --all --full-history -- .env
git grep -l "sk_live\|password\|secret" $(git log --all --format="%H")

# Se encontrar secret commitado:
# 1. REVOGAR O SECRET IMEDIATAMENTE (não esperar)
# 2. Remover do histórico (mas assumir que foi comprometido)
# 3. Gerar novo secret
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch .env' \
  --prune-empty --tag-name-filter cat -- --all
```

🔴 **NUNCA** no código:
- API keys, JWT secrets, senhas de banco
- Private keys, certificados
- OAuth client secrets
- Stripe secret keys

✅ **Sempre:**
- Variáveis de ambiente com `.env.example` documentado
- Rotacionar secrets comprometidos imediatamente
- Principle of least privilege nas API keys

---

## Checklist de Segurança Completo

**Autenticação:**
- [ ] Senhas com bcrypt/argon2 (nunca MD5/SHA)
- [ ] JWT com algoritmo adequado e expiração
- [ ] Refresh token rotation implementado
- [ ] Rate limiting em rotas de auth (máx 5 tentativas)
- [ ] Cookies com Secure + HttpOnly + SameSite=Lax

**API:**
- [ ] Todos os endpoints autenticados (exceto públicos)
- [ ] Autorização verificada por request (não só no login)
- [ ] Validação de input com Zod em todas as rotas
- [ ] CORS configurado restritamente (sem `*` em prod)
- [ ] Headers de segurança configurados

**Banco de Dados:**
- [ ] Queries parametrizadas (nunca concatenação)
- [ ] Sem dados sensíveis em logs
- [ ] Backup automático configurado

---

## Priorização de Risco

| Severidade | Score CVSS | Ação |
|---|---|---|
| **Crítico** | 9.0-10.0 | Corrigir imediatamente — parar deploy se necessário |
| **Alto** | 7.0-8.9 | Corrigir em 24 horas |
| **Médio** | 4.0-6.9 | Corrigir no próximo sprint |
| **Baixo** | 0.1-3.9 | Documentar, corrigir quando possível |

---

## Referências

→ `references/owasp-checklist.md` — Checklist OWASP Top 10 completo com exemplos
→ `references/autenticacao-avancada.md` — OAuth2, PKCE, MFA, Passkeys
