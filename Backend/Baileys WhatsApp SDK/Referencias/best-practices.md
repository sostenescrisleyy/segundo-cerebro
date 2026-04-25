# Boas Práticas, Anti-Ban e Performance

## ⚠️ Regras de Ouro para Não Ser Banido

### 1. Nunca envie em massa sem delay

```typescript
// ❌ ERRADO — ban garantido
for (const jid of listaContatos) {
  await sock.sendMessage(jid, { text: 'Promoção!' })
}

// ✅ CORRETO — delay entre envios
const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))

for (const jid of listaContatos) {
  await sock.sendMessage(jid, { text: 'Promoção!' })
  await sleep(2000 + Math.random() * 3000) // 2-5s aleatório
}
```

### 2. Não apareça online desnecessariamente

```typescript
const sock = makeWASocket({
  markOnlineOnConnect: false, // padrão true — coloque false
  // ...
})
```

### 3. Implemente cachedGroupMetadata (obrigatório)

Sem o cache, o Baileys faz requests ao servidor para cada mensagem de grupo — gatilho de rate limit:

```typescript
import NodeCache from 'node-cache'
const groupCache = new NodeCache({ stdTTL: 300 })

const sock = makeWASocket({
  cachedGroupMetadata: async (jid) => groupCache.get(jid),
})
```

### 4. Use auth state persistente

Reconexões frequentes com auth state diferente levantam suspeita. Use Redis/PostgreSQL e mantenha as mesmas credenciais entre restarts.

### 5. Não mude browser fingerprint constantemente

Defina um `browser` fixo no config e não altere entre sessões:

```typescript
browser: Browsers.ubuntu('MeuBot') // fixo
```

---

## Performance

### Store em memória (para getMessage)

O `getMessage` é necessário para reenviar mensagens e decriptar votos de poll:

```typescript
import { makeInMemoryStore } from 'baileys'

const store = makeInMemoryStore({})
store.readFromFile('./store.json') // opcional

// Persiste a cada 30s
setInterval(() => store.writeToFile('./store.json'), 30_000)

const sock = makeWASocket({
  getMessage: async (key) => {
    return store.messages[key.remoteJid!]?.get(key.id!) || undefined
  }
})

store.bind(sock.ev)
```

### Suprimir logs em produção

```typescript
import P from 'pino'

const sock = makeWASocket({
  logger: P({ level: 'error' }) // 'silent' ou 'error' em prod
})
```

### Usar streams para mídia grande

```typescript
// ❌ ERRADO — carrega tudo em memória
image: fs.readFileSync('./arquivo-grande.jpg')

// ✅ CORRETO — stream eficiente
image: { url: 'https://cdn.exemplo.com/foto.jpg' }
// ou
image: fs.createReadStream('./arquivo-grande.jpg')
```

---

## Reconexão robusta

```typescript
import { DisconnectReason } from 'baileys'
import { Boom } from '@hapi/boom'

let reconnectAttempts = 0
const MAX_RECONNECT = 5

sock.ev.on('connection.update', ({ connection, lastDisconnect }) => {
  if (connection !== 'close') {
    reconnectAttempts = 0 // reset ao conectar
    return
  }

  const error = lastDisconnect?.error as Boom
  const code = error?.output?.statusCode
  const reason = error?.message

  console.log('Desconectado. Código:', code, '| Razão:', reason)

  // Não reconectar se explicitamente deslogado
  if (code === DisconnectReason.loggedOut) {
    console.log('Conta deslogada — limpar sessão e pedir novo QR')
    clearSession() // sua função para limpar auth state
    return
  }

  // Reconectar com backoff exponencial
  if (reconnectAttempts < MAX_RECONNECT) {
    const delay = Math.min(1000 * 2 ** reconnectAttempts, 30_000)
    reconnectAttempts++
    console.log(`Reconectando em ${delay}ms (tentativa ${reconnectAttempts})`)
    setTimeout(startBot, delay)
  } else {
    console.error('Máximo de reconexões atingido. Verifique a conta.')
  }
})
```

---

## Checklist de Produção

- [ ] Auth state em Redis ou PostgreSQL (não arquivo)
- [ ] `cachedGroupMetadata` configurado com NodeCache
- [ ] `getMessage` implementado com store
- [ ] `markOnlineOnConnect: false`
- [ ] Logger em `'error'` ou `'silent'`
- [ ] Reconexão com backoff exponencial
- [ ] Delay entre envios em loop
- [ ] PM2 ou similar para manter o processo vivo
- [ ] Monitoramento de erros (Sentry, etc.)
- [ ] Backup/persistência do auth state


---

← [[README|Baileys WhatsApp SDK]]
