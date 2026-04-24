---
tags: [backend]
categoria: "⚙️ Backend"
---

# Baileys — Guia Completo para Criar Sistemas WhatsApp

## O que é o Baileys?

O **Baileys** é uma biblioteca TypeScript/Node.js que se conecta diretamente ao WhatsApp Web via WebSocket, sem precisar de Selenium ou navegador. É a base da Evolution API, Whatsapp-web.js alternativa de código aberto, e de milhares de bots.

**Pacote oficial:** `baileys` (npm — novo nome desde 2025)  
**Pacote legado:** `@whiskeysockets/baileys` (ainda funciona)  
**Documentação:** https://baileys.wiki  
**GitHub:** https://github.com/WhiskeySockets/Baileys  
**Node.js mínimo:** 17+

> ⚠️ **Aviso importante:** O Baileys conecta em uma conta pessoal/business via "Dispositivos Vinculados". Não usa a API oficial do WhatsApp Business (WABA). Use com responsabilidade.

---

## Setup do Projeto

### 1. Criar projeto Node.js/TypeScript

```bash
mkdir meu-bot-wa && cd meu-bot-wa
npm init -y

# Instalar Baileys e dependências essenciais
npm install baileys @hapi/boom pino

# Para TypeScript (recomendado):
npm install -D typescript @types/node ts-node
npx tsc --init
```

### 2. Estrutura recomendada do projeto

```
meu-bot-wa/
├── src/
│   ├── index.ts          ← entry point, conexão
│   ├── auth/
│   │   └── auth-state.ts ← auth state (Redis/Postgres em prod)
│   ├── handlers/
│   │   ├── message.ts    ← lógica de mensagens recebidas
│   │   └── connection.ts ← lógica de conexão/reconexão
│   └── utils/
│       └── jid.ts        ← helpers de JID/número
├── .env
├── package.json
└── tsconfig.json
```

---

## Conexão Básica (index.ts)

```typescript
import makeWASocket, {
  DisconnectReason,
  useMultiFileAuthState,
  fetchLatestBaileysVersion,
  makeCacheableSignalKeyStore,
  Browsers
} from 'baileys'
import { Boom } from '@hapi/boom'
import P from 'pino'

async function startBot() {
  // ⚠️ useMultiFileAuthState é APENAS para dev/testes
  // Em produção, implemente sua própria auth state (veja references/auth-state-prod.md)
  const { state, saveCreds } = await useMultiFileAuthState('./auth')
  const { version } = await fetchLatestBaileysVersion()

  const sock = makeWASocket({
    version,
    auth: {
      creds: state.creds,
      // wrapping em cache melhora performance com grupos
      keys: makeCacheableSignalKeyStore(state.keys, P({ level: 'silent' }))
    },
    logger: P({ level: 'silent' }), // 'debug' para dev
    printQRInTerminal: true,
    browser: Browsers.ubuntu('MyBot'),
    // ESSENCIAL para grupos — evita rate limit e bans
    cachedGroupMetadata: async (jid) => groupCache.get(jid),
    // ESSENCIAL para reenvio e decriptação de polls
    getMessage: async (key) => {
      return store.messages[key.remoteJid!]?.get(key.id!) || undefined
    }
  })

  // Salvar credenciais sempre que atualizar
  sock.ev.on('creds.update', saveCreds)

  // Gerenciar conexão
  sock.ev.on('connection.update', (update) => {
    const { connection, lastDisconnect, qr } = update
    if (connection === 'close') {
      const code = (lastDisconnect?.error as Boom)?.output?.statusCode
      const shouldReconnect = code !== DisconnectReason.loggedOut
      console.log('Desconectado. Reconectar?', shouldReconnect, '| Código:', code)
      if (shouldReconnect) startBot() // cria novo socket
    } else if (connection === 'open') {
      console.log('✅ Conectado ao WhatsApp!')
    }
  })

  // Receber mensagens
  sock.ev.on('messages.upsert', async ({ messages, type }) => {
    if (type !== 'notify') return // ignora historico antigo
    for (const msg of messages) {
      if (!msg.message || msg.key.fromMe) continue // ignora próprias msgs
      await handleMessage(sock, msg)
    }
  })

  return sock
}

startBot()
```

---

## Conexão via Pairing Code (sem QR)

```typescript
const sock = makeWASocket({
  auth: state,
  printQRInTerminal: false,
  browser: Browsers.macOS('Chrome') // obrigatório para pairing code
})

sock.ev.on('connection.update', async ({ connection, qr }) => {
  if (connection === 'connecting' || !!qr) {
    const phoneNumber = '5511999999999' // E.164 sem + nem espaços
    const code = await sock.requestPairingCode(phoneNumber)
    console.log('Código de pareamento:', code) // ex: ABCD-1234
  }
})
```

---

## Enviando Mensagens

### Texto simples

```typescript
await sock.sendMessage('5511999999999@s.whatsapp.net', {
  text: 'Olá! Mensagem enviada pelo bot 🤖'
})
```

### Texto com formatação (Markdown WhatsApp)

```typescript
await sock.sendMessage(jid, {
  text: '*Negrito* _Itálico_ ~Tachado~ ```Mono```'
})
```

### Responder a uma mensagem

```typescript
await sock.sendMessage(jid, {
  text: 'Respondendo aqui!',
}, { quoted: msgRecebida }) // passa a msg original como quoted
```

### Imagem

```typescript
import fs from 'fs'

// Via buffer (arquivo local)
await sock.sendMessage(jid, {
  image: fs.readFileSync('./foto.jpg'),
  caption: 'Legenda da imagem'
})

// Via URL (mais eficiente — não carrega em memória)
await sock.sendMessage(jid, {
  image: { url: 'https://exemplo.com/foto.jpg' },
  caption: 'Imagem da web'
})
```

### Vídeo

```typescript
await sock.sendMessage(jid, {
  video: { url: 'https://exemplo.com/video.mp4' },
  caption: 'Vídeo do bot',
  gifPlayback: false // true para tratar como GIF animado
})
```

### Documento (PDF, etc.)

```typescript
await sock.sendMessage(jid, {
  document: fs.readFileSync('./relatorio.pdf'),
  mimetype: 'application/pdf',
  fileName: 'relatorio.pdf'
})
```

### Áudio (PTT / mensagem de voz)

```typescript
await sock.sendMessage(jid, {
  audio: fs.readFileSync('./audio.ogg'),
  mimetype: 'audio/ogg; codecs=opus',
  ptt: true // true = aparece como mensagem de voz
})
```

### Localização

```typescript
await sock.sendMessage(jid, {
  location: {
    degreesLatitude: -23.5505,
    degreesLongitude: -46.6333,
    // name: 'São Paulo', // opcional
  }
})
```

### Contato (vCard)

```typescript
const vcard = `BEGIN:VCARD\nVERSION:3.0\nFN:João Silva\nTEL;type=CELL;waid=5511999999999:+55 11 99999-9999\nEND:VCARD`
await sock.sendMessage(jid, {
  contacts: {
    displayName: 'João Silva',
    contacts: [{ vcard }]
  }
})
```

### Reação (emoji)

```typescript
await sock.sendMessage(jid, {
  react: {
    text: '👍', // emoji de reação
    key: msgRecebida.key // key da mensagem a reagir
  }
})
```

### Marcar como lida

```typescript
await sock.readMessages([msg.key])
```

---

## Recebendo e Tratando Mensagens

```typescript
// src/handlers/message.ts
import { WAMessage, proto } from 'baileys'

export function getTextFromMessage(msg: WAMessage): string | undefined {
  return (
    msg.message?.conversation ||
    msg.message?.extendedTextMessage?.text ||
    msg.message?.imageMessage?.caption ||
    msg.message?.videoMessage?.caption ||
    msg.message?.buttonsResponseMessage?.selectedDisplayText ||
    msg.message?.listResponseMessage?.singleSelectReply?.selectedRowId
  )
}

export async function handleMessage(sock: any, msg: WAMessage) {
  const jid = msg.key.remoteJid!
  const text = getTextFromMessage(msg)?.toLowerCase().trim()
  const isGroup = jid.endsWith('@g.us')

  if (!text) return

  // comandos simples
  if (text === '!ping') {
    await sock.sendMessage(jid, { text: 'Pong! 🏓' }, { quoted: msg })
  }

  if (text === '!info') {
    const pushName = msg.pushName || 'usuário'
    await sock.sendMessage(jid, {
      text: `Olá, *${pushName}*! Você enviou: _${text}_`
    }, { quoted: msg })
  }
}
```

---

## Grupos

Para detalhes completos sobre grupos (criar, adicionar participantes, admin, metadados), leia:
→ `references/groups.md`

### Resumo rápido

```typescript
// Buscar todos os grupos que participo
const groups = await sock.groupFetchAllParticipating()
const groupIds = Object.keys(groups) // array de JIDs

// Enviar para grupo
await sock.sendMessage('1234567890-123456@g.us', { text: 'Oi galera!' })

// Metadados do grupo
const meta = await sock.groupMetadata('ID@g.us')
console.log(meta.subject, meta.participants)
```

---

## Auth State para Produção

> ⚠️ `useMultiFileAuthState` escreve JSON em disco a cada mensagem. **Nunca use em produção.**

Para produção, implemente um auth state customizado usando Redis ou PostgreSQL.  
→ Guia completo em: `references/auth-state-prod.md`

---

## Boas Práticas e Anti-Ban

Para evitar banimento da conta:

- **Nunca faça bulk messaging** (envio em massa sem delay)
- Adicione `await sleep(1000)` entre mensagens em loop
- Use `markOnlineOnConnect: false` no socket config
- Não use listas de números comprados — use contatos reais
- Implemente `cachedGroupMetadata` (obrigatório para grupos)
- Use auth state persistente em Redis/DB (não arquivo)

→ Guia completo em: `references/best-practices.md`

---

## Formatos de JID (identificadores)

| Tipo | Formato | Exemplo |
|---|---|---|
| Contato pessoal | `número@s.whatsapp.net` | `5511999999999@s.whatsapp.net` |
| Grupo | `id@g.us` | `1234567890-1234567890@g.us` |
| Status (broadcast) | `status@broadcast` | `status@broadcast` |
| Newsletter | `id@newsletter` | — |

---

## Referências

| Arquivo | Conteúdo |
|---|---|
| `references/auth-state-prod.md` | Auth state customizado com Redis e PostgreSQL |
| `references/groups.md` | Gerenciamento completo de grupos |
| `references/events.md` | Catálogo de todos os eventos do socket |
| `references/best-practices.md` | Anti-ban, performance, estabilidade |
| `references/rest-api-wrapper.md` | Como transformar Baileys em uma REST API multi-sessão |
| `references/project-boilerplate.md` | Boilerplate completo pronto para uso |


---

## Relacionado

[[Evolution API WhatsApp]] | [[Node.js]]


---

## Referencias

- [[Referencias/auth-state-prod]]
- [[Referencias/best-practices]]
- [[Referencias/events]]
- [[Referencias/groups]]
- [[Referencias/project-boilerplate]]
- [[Referencias/rest-api-wrapper]]
