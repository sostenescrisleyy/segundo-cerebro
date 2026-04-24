# Boilerplate Completo — Bot WhatsApp com Baileys

Projeto pronto para copiar, com TypeScript, Redis, estrutura modular e boas práticas.

## package.json

```json
{
  "name": "meu-bot-wa",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "ts-node --esm src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js"
  },
  "dependencies": {
    "baileys": "latest",
    "@hapi/boom": "^10.0.0",
    "pino": "^9.0.0",
    "node-cache": "^5.1.2",
    "redis": "^4.6.0",
    "dotenv": "^16.0.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "@types/node": "^20.0.0",
    "ts-node": "^10.9.0"
  }
}
```

## tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*"]
}
```

## .env

```env
REDIS_URL=redis://localhost:6379
SESSION_ID=minha-sessao
LOG_LEVEL=error
```

## src/index.ts — Entry point completo

```typescript
import 'dotenv/config'
import makeWASocket, {
  DisconnectReason,
  Browsers,
  makeCacheableSignalKeyStore,
  fetchLatestBaileysVersion
} from 'baileys'
import { Boom } from '@hapi/boom'
import P from 'pino'
import NodeCache from 'node-cache'
import { createClient } from 'redis'
import { useRedisAuthState } from './auth/redis-auth-state.js'
import { handleMessage } from './handlers/message.js'

const redis = createClient({ url: process.env.REDIS_URL })
await redis.connect()

const groupCache = new NodeCache({ stdTTL: 5 * 60, useClones: false })
const messageStore = new Map<string, any>()

let reconnectCount = 0

async function startBot() {
  const sessionId = process.env.SESSION_ID || 'default'
  const { state, saveCreds } = await useRedisAuthState(redis, sessionId)
  const { version } = await fetchLatestBaileysVersion()
  const logger = P({ level: process.env.LOG_LEVEL || 'error' })

  const sock = makeWASocket({
    version,
    auth: {
      creds: state.creds,
      keys: makeCacheableSignalKeyStore(state.keys, logger)
    },
    logger,
    printQRInTerminal: true,
    browser: Browsers.ubuntu('MeuBot'),
    markOnlineOnConnect: false,
    cachedGroupMetadata: async (jid) => groupCache.get(jid),
    getMessage: async (key) => messageStore.get(`${key.remoteJid}:${key.id}`)
  })

  // --- Credenciais ---
  sock.ev.on('creds.update', saveCreds)

  // --- Conexão ---
  sock.ev.on('connection.update', ({ connection, lastDisconnect, qr }) => {
    if (qr) {
      console.log('📱 Escaneie o QR Code acima para conectar')
    }

    if (connection === 'open') {
      reconnectCount = 0
      console.log('✅ Bot conectado ao WhatsApp!')
    }

    if (connection === 'close') {
      const code = (lastDisconnect?.error as Boom)?.output?.statusCode
      if (code === DisconnectReason.loggedOut) {
        console.log('🔴 Conta deslogada. Exclua a sessão do Redis e reinicie.')
        return
      }
      if (reconnectCount < 5) {
        const delay = Math.min(1000 * 2 ** reconnectCount, 30_000)
        reconnectCount++
        console.log(`🔄 Reconectando em ${delay / 1000}s...`)
        setTimeout(startBot, delay)
      }
    }
  })

  // --- Mensagens ---
  sock.ev.on('messages.upsert', async ({ messages, type }) => {
    if (type !== 'notify') return
    for (const msg of messages) {
      if (!msg.message || msg.key.fromMe) continue
      // guardar no store para getMessage
      const storeKey = `${msg.key.remoteJid}:${msg.key.id}`
      messageStore.set(storeKey, msg.message)
      // processar
      await handleMessage(sock, msg).catch(console.error)
    }
  })

  // --- Cache de grupos ---
  sock.ev.on('groups.update', async ([e]) => {
    try {
      const meta = await sock.groupMetadata(e.id)
      groupCache.set(e.id, meta)
    } catch {}
  })

  sock.ev.on('group-participants.update', async (e) => {
    try {
      const meta = await sock.groupMetadata(e.id)
      groupCache.set(e.id, meta)
    } catch {}
  })
}

startBot()
```

## src/handlers/message.ts

```typescript
import { WAMessage } from 'baileys'

export function getMessageText(msg: WAMessage): string {
  return (
    msg.message?.conversation ||
    msg.message?.extendedTextMessage?.text ||
    msg.message?.imageMessage?.caption ||
    msg.message?.videoMessage?.caption ||
    ''
  )
}

export async function handleMessage(sock: any, msg: WAMessage) {
  const jid = msg.key.remoteJid!
  const text = getMessageText(msg).toLowerCase().trim()
  const sender = msg.key.participant || jid // em grupos, sender != jid

  if (!text.startsWith('!')) return // só responder a comandos

  const commands: Record<string, () => Promise<void>> = {
    '!ping': async () => {
      await sock.sendMessage(jid, { text: '🏓 Pong!' }, { quoted: msg })
    },
    '!help': async () => {
      await sock.sendMessage(jid, {
        text: '*Comandos disponíveis:*\n\n!ping\n!help\n!info'
      }, { quoted: msg })
    },
    '!info': async () => {
      const name = msg.pushName || 'usuário'
      await sock.sendMessage(jid, {
        text: `Olá, *${name}*! 👋\nSeu número: ${sender.split('@')[0]}`
      }, { quoted: msg })
    }
  }

  const handler = commands[text]
  if (handler) await handler()
}
```

## Rodando com PM2

```bash
npm install -g pm2
npm run build
pm2 start dist/index.js --name meu-bot-wa
pm2 save
pm2 startup
```


---

← [[README|Baileys WhatsApp SDK]]
