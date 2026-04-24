# Gerenciamento de Grupos

## Cache de metadados (obrigatório!)

Sempre configure o cache de grupos no socket. Sem ele, o Baileys faz um request ao servidor a cada mensagem enviada para um grupo — causando rate limit e risco de ban.

```typescript
import NodeCache from 'node-cache'

const groupCache = new NodeCache({ stdTTL: 5 * 60, useClones: false }) // 5 min

const sock = makeWASocket({
  cachedGroupMetadata: async (jid) => groupCache.get(jid),
  // ...
})

// Manter o cache atualizado com eventos
sock.ev.on('groups.update', async ([event]) => {
  const meta = await sock.groupMetadata(event.id)
  groupCache.set(event.id, meta)
})

sock.ev.on('group-participants.update', async (event) => {
  const meta = await sock.groupMetadata(event.id)
  groupCache.set(event.id, meta)
})
```

---

## Buscar grupos

```typescript
// Todos os grupos que participo
const groups = await sock.groupFetchAllParticipating()
// retorna: Record<jid, GroupMetadata>

for (const [jid, meta] of Object.entries(groups)) {
  console.log(`${meta.subject} — ${meta.participants.length} membros`)
}
```

## Metadados de um grupo específico

```typescript
const meta = await sock.groupMetadata('GRUPO_ID@g.us')
console.log({
  id: meta.id,
  nome: meta.subject,
  descricao: meta.desc,
  criador: meta.owner,
  participantes: meta.participants.map(p => ({
    jid: p.id,
    admin: p.admin // 'admin' | 'superadmin' | null
  }))
})
```

## Criar grupo

```typescript
const group = await sock.groupCreate(
  'Nome do Grupo',
  ['5511999999999@s.whatsapp.net', '5511888888888@s.whatsapp.net']
)
console.log('Grupo criado:', group.gid) // JID do novo grupo
```

## Adicionar / remover participantes

```typescript
// Adicionar
await sock.groupParticipantsUpdate(
  'GRUPO@g.us',
  ['5511777777777@s.whatsapp.net'],
  'add'
)

// Remover
await sock.groupParticipantsUpdate(
  'GRUPO@g.us',
  ['5511777777777@s.whatsapp.net'],
  'remove'
)

// Promover a admin
await sock.groupParticipantsUpdate(
  'GRUPO@g.us',
  ['5511777777777@s.whatsapp.net'],
  'promote'
)

// Rebaixar de admin
await sock.groupParticipantsUpdate(
  'GRUPO@g.us',
  ['5511777777777@s.whatsapp.net'],
  'demote'
)
```

## Atualizar grupo

```typescript
// Mudar nome
await sock.groupUpdateSubject('GRUPO@g.us', 'Novo Nome do Grupo')

// Mudar descrição
await sock.groupUpdateDescription('GRUPO@g.us', 'Nova descrição aqui')

// Travar grupo (só admins podem enviar)
await sock.groupSettingUpdate('GRUPO@g.us', 'announcement')

// Desbloquear grupo (todos podem enviar)
await sock.groupSettingUpdate('GRUPO@g.us', 'not_announcement')
```

## Gerar link de convite

```typescript
const inviteCode = await sock.groupInviteCode('GRUPO@g.us')
console.log('https://chat.whatsapp.com/' + inviteCode)

// Revogar link
await sock.groupRevokeInvite('GRUPO@g.us')
```

## Sair / Expulsar do grupo

```typescript
// Bot sai do grupo
await sock.groupLeave('GRUPO@g.us')
```

## Verificar se mensagem veio de grupo

```typescript
sock.ev.on('messages.upsert', async ({ messages }) => {
  for (const msg of messages) {
    const isGroup = msg.key.remoteJid?.endsWith('@g.us')
    if (isGroup) {
      const sender = msg.key.participant // quem enviou no grupo
      const groupJid = msg.key.remoteJid
      console.log(`Mensagem do grupo ${groupJid} por ${sender}`)
    }
  }
})
```


---

← [[README|Baileys WhatsApp SDK]]
