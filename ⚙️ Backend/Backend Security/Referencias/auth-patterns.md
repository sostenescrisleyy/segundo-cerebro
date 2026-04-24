# Padrões de Autenticação Avançada

## Bcrypt para Senhas (obrigatório)

```typescript
import bcrypt from 'bcrypt'

const SALT_ROUNDS = 12 // 10 mínimo, 12 recomendado, 14 para alto valor

async function hashPassword(plain: string): Promise<string> {
  return bcrypt.hash(plain, SALT_ROUNDS)
}

async function verifyPassword(plain: string, hashed: string): Promise<boolean> {
  return bcrypt.compare(plain, hashed)
}

// Tempo constante — evita timing attacks
// bcrypt.compare sempre toma ~tempo mesmo quando errado ✅
```

## Refresh Token Rotation

```typescript
// No banco: tabela de refresh tokens
model RefreshToken {
  id        String   @id @default(cuid())
  token     String   @unique
  userId    String
  expiresAt DateTime
  usedAt    DateTime? // marcar quando usado (detecção de reuso)
  revokedAt DateTime?
}

async function rotateRefreshToken(oldToken: string) {
  const record = await db.refreshToken.findUnique({ where: { token: oldToken } })

  // Token não existe
  if (!record) throw new Error('Invalid refresh token')

  // Token expirado
  if (record.expiresAt < new Date()) throw new Error('Refresh token expired')

  // DETECÇÃO DE REUSO: token já foi usado antes?
  // Isso indica que um atacante roubou o token e tentou usá-lo
  if (record.usedAt) {
    // Revogar TODOS os tokens do usuário — possível comprometimento
    await db.refreshToken.updateMany({
      where: { userId: record.userId },
      data: { revokedAt: new Date() }
    })
    throw new Error('Token reuse detected — all sessions invalidated')
  }

  // Marcar como usado
  await db.refreshToken.update({
    where: { id: record.id },
    data: { usedAt: new Date() }
  })

  // Criar novo token
  const { accessToken, refreshToken } = generateTokens(record.userId)
  await db.refreshToken.create({
    data: { token: refreshToken, userId: record.userId, expiresAt: new Date(Date.now() + 7 * 86400 * 1000) }
  })

  return { accessToken, refreshToken }
}
```

## Magic Links (passwordless)

```typescript
import { randomBytes } from 'crypto'

async function sendMagicLink(email: string) {
  // 1. Verificar se email existe
  const user = await db.user.findUnique({ where: { email } })
  // IMPORTANTE: não revelar se email existe ou não
  // Sempre retornar a mesma mensagem de "verifique seu email"

  if (!user) return // retorna normalmente sem indicar que não existe

  // 2. Gerar token seguro
  const token = randomBytes(32).toString('hex')
  const hashedToken = createHash('sha256').update(token).digest('hex')
  const expiresAt = new Date(Date.now() + 15 * 60 * 1000) // 15 min

  // 3. Salvar hash no banco (nunca o token em si)
  await db.magicLink.create({
    data: { hashedToken, userId: user.id, expiresAt }
  })

  // 4. Enviar link com token original (não o hash)
  const link = `${process.env.APP_URL}/auth/verify?token=${token}`
  await sendEmail(email, 'Seu link de acesso', `Clique aqui: ${link}`)
}

async function verifyMagicLink(token: string) {
  const hashedToken = createHash('sha256').update(token).digest('hex')

  const record = await db.magicLink.findUnique({ where: { hashedToken } })

  if (!record || record.expiresAt < new Date() || record.usedAt) {
    throw new Error('Link inválido ou expirado')
  }

  // Marcar como usado (one-time use)
  await db.magicLink.update({ where: { id: record.id }, data: { usedAt: new Date() } })

  // Retornar tokens de sessão
  return generateTokens(record.userId)
}
```

## Proteção de Endpoints com Timing-Safe Comparison

```typescript
import { timingSafeEqual } from 'crypto'

// Para comparar API keys, webhook signatures, etc.
function safeCompare(a: string, b: string): boolean {
  if (a.length !== b.length) return false // evitar timing leak no length
  return timingSafeEqual(Buffer.from(a), Buffer.from(b))
}

// Nunca usar === para comparar tokens/hashes
// '==' e '===' são vulneráveis a timing attacks
if (token === storedToken) { /* ❌ */ }
if (safeCompare(token, storedToken)) { /* ✅ */ }
```

## Proteção de Webhooks (ex: Stripe, GitHub)

```typescript
import { createHmac, timingSafeEqual } from 'crypto'

function verifyWebhookSignature(
  payload: string | Buffer,
  signature: string,
  secret: string
): boolean {
  const expected = createHmac('sha256', secret)
    .update(payload)
    .digest('hex')

  // Stripe usa prefixo "sha256="
  const sig = signature.replace('sha256=', '')

  return timingSafeEqual(
    Buffer.from(sig, 'hex'),
    Buffer.from(expected, 'hex')
  )
}

// Uso no handler do webhook
app.post('/webhooks/stripe',
  express.raw({ type: 'application/json' }), // raw body obrigatório
  async (req, res) => {
    const sig = req.headers['stripe-signature'] as string
    const valid = verifyWebhookSignature(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET!)

    if (!valid) return res.status(400).json({ error: 'Invalid signature' })

    // Verificar replay attack com timestamp
    const event = JSON.parse(req.body)
    const ageSeconds = Date.now() / 1000 - event.created
    if (ageSeconds > 300) return res.status(400).json({ error: 'Request too old' })

    // Processar evento
    await handleStripeEvent(event)
    res.json({ received: true })
  }
)
```


---

← [[README|Backend Security]]
