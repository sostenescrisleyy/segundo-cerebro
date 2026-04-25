# Catálogo de Eventos do Socket Baileys

Todos os eventos ficam em `sock.ev.on(EVENTO, handler)`.

## Conexão

| Evento | Descrição | Dados úteis |
|---|---|---|
| `connection.update` | Estado da conexão mudou | `connection`, `qr`, `lastDisconnect` |
| `creds.update` | Credenciais atualizadas (salvar!) | — |

```typescript
sock.ev.on('connection.update', ({ connection, qr, lastDisconnect }) => {
  // connection: 'connecting' | 'open' | 'close'
  // qr: string (base64 para gerar QR code)
  // lastDisconnect: { error: Boom, date: Date }
})
```

## Mensagens

| Evento | Descrição |
|---|---|
| `messages.upsert` | Nova mensagem ou mensagem atualizada |
| `messages.update` | Status de mensagem atualizado (enviado/lido/entregue) |
| `messages.delete` | Mensagem deletada |
| `messages.reaction` | Reação em mensagem |
| `message-receipt.update` | Recibo de entrega/leitura atualizado |

```typescript
// Nova mensagem
sock.ev.on('messages.upsert', ({ messages, type }) => {
  // type: 'notify' (nova) | 'append' (histórico)
  // Sempre filtre por type === 'notify' para novas mensagens
})

// Atualização de status de envio
sock.ev.on('messages.update', (updates) => {
  for (const { key, update } of updates) {
    if (update.status) {
      // 1=PENDING, 2=SERVER_ACK, 3=DELIVERY_ACK, 4=READ, 5=PLAYED
      console.log('Status:', update.status)
    }
  }
})
```

## Chats e Contatos

| Evento | Descrição |
|---|---|
| `chats.upsert` | Novo chat criado ou importado |
| `chats.update` | Chat atualizado (ex: silenciado) |
| `chats.delete` | Chat deletado |
| `contacts.upsert` | Novo contato |
| `contacts.update` | Contato atualizado (nome, foto, etc.) |
| `presence.update` | Status de presença (online/digitando/gravando) |

```typescript
// Presença (digitando, online, etc.)
sock.ev.on('presence.update', ({ id, presences }) => {
  for (const [jid, presence] of Object.entries(presences)) {
    // presence.lastKnownPresence: 'available'|'unavailable'|'composing'|'recording'
    console.log(jid, 'está', presence.lastKnownPresence)
  }
})

// Para receber presença de alguém, você precisa subscrever primeiro:
await sock.presenceSubscribe('5511999999999@s.whatsapp.net')
```

## Grupos

| Evento | Descrição |
|---|---|
| `groups.upsert` | Entrou em novo grupo |
| `groups.update` | Dados do grupo atualizados |
| `group-participants.update` | Participante adicionado/removido/promovido |

```typescript
sock.ev.on('group-participants.update', ({ id, participants, action }) => {
  // action: 'add' | 'remove' | 'promote' | 'demote'
  console.log(`Grupo ${id}: ${action}`, participants)
})
```

## Histórico e Sincronização

| Evento | Descrição |
|---|---|
| `messaging-history.set` | Histórico de mensagens sincronizado |
| `blocklist.set` | Lista de bloqueados carregada |
| `blocklist.update` | Lista de bloqueados atualizada |

## Calls (Chamadas)

```typescript
sock.ev.on('call', async (calls) => {
  for (const call of calls) {
    console.log('Chamada de:', call.from, 'status:', call.status)
    // Rejeitar automaticamente:
    if (call.status === 'offer') {
      await sock.rejectCall(call.id, call.from)
    }
  }
})
```

---

## Padrão de handler desacoplado

```typescript
// Evite lógica inline no evento — separe em handlers:
import { handleMessage } from './handlers/message'
import { handleConnection } from './handlers/connection'
import { handleGroupUpdate } from './handlers/groups'

sock.ev.on('messages.upsert', ({ messages, type }) => {
  if (type !== 'notify') return
  messages.forEach(msg => handleMessage(sock, msg))
})

sock.ev.on('connection.update', (update) => handleConnection(update, startBot))
sock.ev.on('group-participants.update', handleGroupUpdate)
```


---

← [[README|Baileys WhatsApp SDK]]
