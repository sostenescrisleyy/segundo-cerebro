# URLs Assinadas (Token Authentication) — Arquivos Privados

Use quando precisar servir arquivos que requerem autenticação — documentos privados, vídeos pagos, conteúdo restrito.

## Bunny Storage — Token Authentication

### Configurar no Dashboard

1. Pull Zone → Shield → Token Authentication → Enable
2. Copie o **Security Token** (Token Key)

### Gerar URL assinada (Node.js)

```typescript
import { createHmac } from 'crypto'

interface SignedUrlOptions {
  expiresInSeconds?: number    // padrão: 1 hora
  userIp?: string              // opcional, amarra à IP
  directory?: boolean          // true = assina o diretório inteiro
}

export function generateSignedUrl(
  cdnUrl: string,              // ex: https://suazone.b-cdn.net/docs/relatorio.pdf
  tokenKey: string,            // Token Key do dashboard
  options: SignedUrlOptions = {}
): string {
  const { expiresInSeconds = 3600, userIp = '', directory = false } = options

  const url = new URL(cdnUrl)
  const expires = Math.floor(Date.now() / 1000) + expiresInSeconds

  // Construir string de hash: tokenKey + path + expires + [ip]
  const hashableBase = tokenKey + url.pathname + expires + (userIp || '')
  const token = createHmac('sha256', tokenKey)
    .update(hashableBase)
    .digest('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '')

  if (directory) {
    url.searchParams.set('token', token)
    url.searchParams.set('expires', String(expires))
    url.searchParams.set('token_path', url.pathname)
    return url.toString()
  }

  url.searchParams.set('token', token)
  url.searchParams.set('expires', String(expires))
  if (userIp) url.searchParams.set('token_ip', userIp)

  return url.toString()
}

// Uso:
const signedUrl = generateSignedUrl(
  'https://suazone.b-cdn.net/privado/documento.pdf',
  process.env.BUNNY_TOKEN_KEY!,
  { expiresInSeconds: 3600 }  // expira em 1 hora
)
// → https://suazone.b-cdn.net/privado/documento.pdf?token=abc123&expires=1234567890
```

---

## Bunny Stream — URLs Assinadas para Vídeos

Para vídeos privados em bibliotecas com Token Auth ativado.

### Configurar

1. Stream → Library → Security → Enable Token Authentication
2. Copie o **Authentication Key**

### Gerar URL de embed assinada

```typescript
import { createHash } from 'crypto'

export function signStreamUrl(
  videoId: string,
  authKey: string,
  expiresInSeconds = 3600
): { embedUrl: string; hlsUrl: string } {
  const libraryId = process.env.BUNNY_STREAM_LIBRARY_ID!
  const cdn = process.env.BUNNY_STREAM_CDN_HOSTNAME!
  const expires = Math.floor(Date.now() / 1000) + expiresInSeconds

  // SHA256(authKey + libraryId + expires + videoId)
  const signature = createHash('sha256')
    .update(`${authKey}${libraryId}${expires}${videoId}`)
    .digest('hex')

  const embedUrl =
    `https://iframe.mediadelivery.net/embed/${libraryId}/${videoId}` +
    `?token=${signature}&expires=${expires}`

  const hlsUrl =
    `https://${cdn}/${videoId}/playlist.m3u8` +
    `?token=${signature}&expires=${expires}`

  return { embedUrl, hlsUrl }
}

// Uso:
const { embedUrl } = signStreamUrl(
  'guid-do-video',
  process.env.BUNNY_STREAM_TOKEN_KEY!,
  7200  // 2 horas
)
```

---

## Middleware Express para verificar token

```typescript
import { Request, Response, NextFunction } from 'express'

export function requireSignedUrl(req: Request, res: Response, next: NextFunction) {
  const token = req.query.token as string
  const expires = Number(req.query.expires)

  if (!token || !expires) {
    return res.status(401).json({ error: 'Token ausente' })
  }

  if (Date.now() / 1000 > expires) {
    return res.status(401).json({ error: 'URL expirada' })
  }

  // Verificar token
  const expected = generateSignedUrlToken(req.path, expires)
  if (token !== expected) {
    return res.status(403).json({ error: 'Token inválido' })
  }

  next()
}
```

---

## Boas práticas de segurança

- Nunca exponha o `TOKEN_KEY` no client-side
- Gere URLs assinadas sempre no servidor
- Use `expiresInSeconds` curto para downloads sensíveis (ex: 300s = 5min)
- Para streaming de vídeo, 1–6 horas costuma ser suficiente
- Considere amarrar à IP do usuário com `userIp` para dados críticos
- Rotacione o Token Key periodicamente no dashboard


---

← [[README|Bunny.net CDN]]
