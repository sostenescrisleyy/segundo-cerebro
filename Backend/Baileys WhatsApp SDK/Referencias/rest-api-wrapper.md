# Transformar Baileys em uma REST API Multi-Sessão

Ideal quando você quer uma API HTTP para integrar com outros sistemas (n8n, Chatwoot, etc.) sem usar a Evolution API.

## Stack recomendada

- **Fastify** (ou Express) — servidor HTTP
- **Redis** — auth state + cache
- **TypeScript** — type safety

## Instalação

```bash
npm install fastify @fastify/multipart baileys redis node-cache pino
npm install -D typescript @types/node ts-node
```

## Estrutura

```
baileys-api/
├── src/
│   ├── app.ts              ← Fastify app
│   ├── session-manager.ts  ← gerenciador de sessões
│   ├── auth/
│   │   └── redis-auth.ts   ← auth state Redis
│   └── routes/
│       ├── session.ts      ← POST /session, DELETE /session/:id
│       └── message.ts      ← POST /message/send
└── package.json
```

## session-manager.ts

```typescript
import makeWASocket, {
  DisconnectReason, Browsers,
  makeCacheableSignalKeyStore
} from 'baileys'
import { Boom } from '@hapi/boom'
import P from 'pino'
import NodeCache from 'node-cache'
import { useRedisAuthState } from './auth/redis-auth'

const sessions = new Map<string, any>()
const groupCaches = new Map<string, NodeCache>()

export async function createSession(sessionId: string, redis: any) {
  const { state, saveCreds } = await useRedisAuthState(redis, sessionId)
  const groupCache = new NodeCache({ stdTTL: 300, useClones: false })
  groupCaches.set(sessionId, groupCache)

  const sock = makeWASocket({
    auth: {
      creds: state.creds,
      keys: makeCacheableSignalKeyStore(state.keys, P({ level: 'silent' }))
    },
    logger: P({ level: 'silent' }),
    browser: Browsers.ubuntu('BaileysAPI'),
    markOnlineOnConnect: false,
    cachedGroupMetadata: async (jid) => groupCache.get(jid),
  })

  sock.ev.on('creds.update', saveCreds)
  sock.ev.on('groups.update', async ([e]) => {
    const meta = await sock.groupMetadata(e.id)
    groupCache.set(e.id, meta)
  })
  sock.ev.on('group-participants.update', async (e) => {
    const meta = await sock.groupMetadata(e.id)
    groupCache.set(e.id, meta)
  })
  sock.ev.on('connection.update', ({ connection, lastDisconnect }) => {
    if (connection === 'close') {
      const code = (lastDisconnect?.error as Boom)?.output?.statusCode
      if (code !== DisconnectReason.loggedOut) createSession(sessionId, redis)
      else sessions.delete(sessionId)
    }
  })

  sessions.set(sessionId, sock)
  return sock
}

export function getSession(sessionId: string) {
  return sessions.get(sessionId)
}

export function listSessions() {
  return [...sessions.keys()]
}

export async function deleteSession(sessionId: string) {
  const sock = sessions.get(sessionId)
  if (sock) {
    await sock.logout()
    sessions.delete(sessionId)
  }
}
```

## routes/message.ts

```typescript
import { FastifyInstance } from 'fastify'
import { getSession } from '../session-manager'

export async function messageRoutes(app: FastifyInstance) {
  // Enviar mensagem de texto
  app.post('/message/:sessionId/send-text', async (req, reply) => {
    const { sessionId } = req.params as any
    const { to, text } = req.body as any

    const sock = getSession(sessionId)
    if (!sock) return reply.status(404).send({ error: 'Sessão não encontrada' })

    const jid = to.includes('@') ? to : `${to}@s.whatsapp.net`
    const msg = await sock.sendMessage(jid, { text })
    return { success: true, messageId: msg?.key?.id }
  })

  // Enviar imagem
  app.post('/message/:sessionId/send-image', async (req, reply) => {
    const { sessionId } = req.params as any
    const { to, url, caption } = req.body as any

    const sock = getSession(sessionId)
    if (!sock) return reply.status(404).send({ error: 'Sessão não encontrada' })

    const jid = to.includes('@') ? to : `${to}@s.whatsapp.net`
    await sock.sendMessage(jid, { image: { url }, caption })
    return { success: true }
  })
}
```

## routes/session.ts

```typescript
import { FastifyInstance } from 'fastify'
import { createSession, deleteSession, listSessions, getSession } from '../session-manager'

export async function sessionRoutes(app: FastifyInstance, { redis }: any) {
  app.get('/sessions', async () => {
    return { sessions: listSessions() }
  })

  app.post('/sessions/:sessionId', async (req, reply) => {
    const { sessionId } = req.params as any
    if (getSession(sessionId)) return reply.status(409).send({ error: 'Já existe' })
    await createSession(sessionId, redis)
    return { created: true }
  })

  app.delete('/sessions/:sessionId', async (req) => {
    const { sessionId } = req.params as any
    await deleteSession(sessionId)
    return { deleted: true }
  })
}
```

## app.ts

```typescript
import Fastify from 'fastify'
import { createClient } from 'redis'
import { messageRoutes } from './routes/message'
import { sessionRoutes } from './routes/session'

async function main() {
  const app = Fastify({ logger: true })
  const redis = createClient({ url: process.env.REDIS_URL })
  await redis.connect()

  app.register(messageRoutes)
  app.register(sessionRoutes, { redis })

  await app.listen({ port: 3000, host: '0.0.0.0' })
  console.log('✅ API rodando em http://localhost:3000')
}

main()
```

## Endpoints disponíveis

| Método | Rota | Descrição |
|---|---|---|
| GET | `/sessions` | Lista sessões ativas |
| POST | `/sessions/:id` | Cria sessão (dispara QR) |
| DELETE | `/sessions/:id` | Desconecta e deleta sessão |
| POST | `/message/:id/send-text` | Envia texto |
| POST | `/message/:id/send-image` | Envia imagem |


---

← [[README|Baileys WhatsApp SDK]]
