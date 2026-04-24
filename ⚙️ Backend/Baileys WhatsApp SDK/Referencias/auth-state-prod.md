# Auth State para Produção (Redis / PostgreSQL)

O `useMultiFileAuthState` padrão grava arquivos JSON em disco a cada mensagem recebida/enviada — péssimo para produção. Implemente sua própria auth state.

## Contrato da Auth State

```typescript
// O objeto que você precisa fornecer ao makeWASocket:
type AuthenticationState = {
  creds: AuthenticationCreds
  keys: SignalKeyStoreWithTransaction
}

// O SignalKeyStoreWithTransaction precisa implementar:
interface SignalKeyStore {
  get<T extends keyof SignalDataTypeMap>(
    type: T,
    ids: string[]
  ): Promise<{ [id: string]: SignalDataTypeMap[T] }>

  set(data: SignalDataSet): Promise<void>

  clear?(): Promise<void>
}
```

---

## Implementação com Redis

```typescript
// src/auth/redis-auth-state.ts
import { createClient } from 'redis'
import {
  AuthenticationCreds,
  AuthenticationState,
  initAuthCreds,
  BufferJSON,
  SignalDataTypeMap,
  proto
} from 'baileys'

const KEY_MAP: { [T in keyof SignalDataTypeMap]: string } = {
  'pre-key': 'preKeys',
  'session': 'sessions',
  'sender-key': 'senderKeys',
  'app-state-sync-key': 'appStateSyncKeys',
  'app-state-sync-version': 'appStateVersions',
  'sender-key-memory': 'senderKeyMemory',
}

export async function useRedisAuthState(
  redis: ReturnType<typeof createClient>,
  sessionId: string
): Promise<{ state: AuthenticationState; saveCreds: () => Promise<void> }> {

  const writeData = async (data: any, key: string) => {
    await redis.set(
      `${sessionId}:${key}`,
      JSON.stringify(data, BufferJSON.replacer)
    )
  }

  const readData = async (key: string) => {
    const raw = await redis.get(`${sessionId}:${key}`)
    if (!raw) return null
    return JSON.parse(raw, BufferJSON.reviver)
  }

  const creds: AuthenticationCreds =
    (await readData('creds')) || initAuthCreds()

  return {
    state: {
      creds,
      keys: {
        get: async (type, ids) => {
          const data: { [_: string]: SignalDataTypeMap[typeof type] } = {}
          await Promise.all(
            ids.map(async (id) => {
              let value = await readData(`${KEY_MAP[type]}-${id}`)
              if (type === 'app-state-sync-key' && value) {
                value = proto.Message.AppStateSyncKeyData.fromObject(value)
              }
              data[id] = value
            })
          )
          return data
        },
        set: async (data) => {
          const tasks: Promise<void>[] = []
          for (const category in data) {
            for (const id in data[category as keyof SignalDataTypeMap]) {
              const value = data[category as keyof SignalDataTypeMap]![id]
              const key = `${KEY_MAP[category as keyof SignalDataTypeMap]}-${id}`
              tasks.push(value ? writeData(value, key) : redis.del(`${sessionId}:${key}`).then())
            }
          }
          await Promise.all(tasks)
        }
      }
    },
    saveCreds: () => writeData(creds, 'creds')
  }
}
```

### Como usar:

```typescript
import { createClient } from 'redis'
import { useRedisAuthState } from './auth/redis-auth-state'

const redis = createClient({ url: process.env.REDIS_URL })
await redis.connect()

const { state, saveCreds } = await useRedisAuthState(redis, 'session-1')
const sock = makeWASocket({ auth: state })
sock.ev.on('creds.update', saveCreds)
```

---

## Implementação com PostgreSQL (Prisma)

### Schema Prisma

```prisma
// prisma/schema.prisma
model AuthSession {
  id        String   @id
  sessionId String
  data      String   @db.Text
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@unique([sessionId, id])
  @@index([sessionId])
}
```

```typescript
// src/auth/postgres-auth-state.ts
import { PrismaClient } from '@prisma/client'
import {
  AuthenticationCreds,
  AuthenticationState,
  initAuthCreds,
  BufferJSON,
  SignalDataTypeMap,
  proto
} from 'baileys'

export async function usePostgresAuthState(
  prisma: PrismaClient,
  sessionId: string
): Promise<{ state: AuthenticationState; saveCreds: () => Promise<void> }> {

  const write = async (data: any, id: string) => {
    const serialized = JSON.stringify(data, BufferJSON.replacer)
    await prisma.authSession.upsert({
      where: { sessionId_id: { sessionId, id } },
      create: { id, sessionId, data: serialized },
      update: { data: serialized }
    })
  }

  const read = async (id: string) => {
    const row = await prisma.authSession.findUnique({
      where: { sessionId_id: { sessionId, id } }
    })
    if (!row) return null
    return JSON.parse(row.data, BufferJSON.reviver)
  }

  const creds: AuthenticationCreds = (await read('creds')) || initAuthCreds()

  return {
    state: {
      creds,
      keys: {
        get: async (type, ids) => {
          const data: { [_: string]: SignalDataTypeMap[typeof type] } = {}
          await Promise.all(ids.map(async (id) => {
            let value = await read(`${type}-${id}`)
            if (type === 'app-state-sync-key' && value) {
              value = proto.Message.AppStateSyncKeyData.fromObject(value)
            }
            data[id] = value
          }))
          return data
        },
        set: async (data) => {
          await Promise.all(
            Object.entries(data).flatMap(([type, ids]) =>
              Object.entries(ids!).map(([id, value]) =>
                value
                  ? write(value, `${type}-${id}`)
                  : prisma.authSession.deleteMany({ where: { sessionId, id: `${type}-${id}` } })
              )
            )
          )
        }
      }
    },
    saveCreds: () => write(creds, 'creds')
  }
}
```

---

## Multi-sessão com mapa de conexões

```typescript
// src/session-manager.ts
const sessions = new Map<string, ReturnType<typeof makeWASocket>>()

export async function createSession(sessionId: string) {
  const { state, saveCreds } = await useRedisAuthState(redis, sessionId)
  const sock = makeWASocket({ auth: state, /* ... */ })
  sock.ev.on('creds.update', saveCreds)
  sessions.set(sessionId, sock)
  return sock
}

export function getSession(sessionId: string) {
  return sessions.get(sessionId)
}

export async function deleteSession(sessionId: string) {
  const sock = sessions.get(sessionId)
  if (sock) {
    await sock.logout()
    sessions.delete(sessionId)
    // limpar chaves do Redis/Postgres com prefixo sessionId
  }
}
```


---

← [[README|Baileys WhatsApp SDK]]
