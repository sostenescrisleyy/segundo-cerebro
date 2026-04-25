---
tags: [backend]
categoria: "Backend"
---

# bunny.net — Guia Completo: Storage, Stream, CDN e Image Optimizer

## O que é o bunny.net?

O **bunny.net** é uma plataforma de CDN e armazenamento de mídia com 4 produtos principais:

| Produto | Para quê serve |
|---|---|
| **Bunny Storage** | Armazenar arquivos (S3-like) — imagens, docs, assets |
| **Bunny CDN / Pull Zone** | Distribuir arquivos globalmente via CDN |
| **Bunny Optimizer** | Transformar imagens on-the-fly por URL (resize, crop, WebP) |
| **Bunny Stream** | Upload, encode e streaming de vídeos com player embutido |

**Dashboard:** https://dash.bunny.net  
**Docs:** https://docs.bunny.net  
**API Base Storage:** `https://storage.bunnycdn.com` (ou região específica)  
**API Base Stream:** `https://video.bunnycdn.com`

---

## Chaves de API — Onde Encontrar

| Chave | Onde fica | Para quê |
|---|---|---|
| **Account API Key** | Dashboard → My Account → API Keys | Operações de conta, Pull Zones, purge |
| **Storage Zone Password** | Storage Zone → FTP & API Access | Upload/download de arquivos no Storage |
| **Stream Library API Key** | Stream → Library → Settings → API Key | Upload e gestão de vídeos |

> ⚠️ Use `AccessKey` como header — **não** `Authorization: Bearer`. Esse é o erro mais comum.

---

## Regiões do Storage

O endpoint varia conforme a região escolhida:

| Região | Endpoint |
|---|---|
| Frankfurt (padrão) | `https://storage.bunnycdn.com` |
| Nova York | `https://ny.storage.bunnycdn.com` |
| Los Angeles | `https://la.storage.bunnycdn.com` |
| Singapura | `https://sg.storage.bunnycdn.com` |
| Londres | `https://uk.storage.bunnycdn.com` |
| Estocolmo | `https://se.storage.bunnycdn.com` |
| São Paulo | `https://br.storage.bunnycdn.com` |
| Sydney | `https://syd.storage.bunnycdn.com` |

---

## Bunny Storage — Upload e Download de Arquivos

### Variáveis de ambiente

```env
BUNNY_STORAGE_API_KEY=sua-storage-zone-password
BUNNY_STORAGE_ZONE=nome-da-sua-storage-zone
BUNNY_CDN_HOSTNAME=suazone.b-cdn.net
BUNNY_STORAGE_REGION=br   # ou deixe vazio para Frankfurt
```

### Upload de arquivo (Node.js / TypeScript)

```typescript
import fs from 'fs'
import path from 'path'

const STORAGE_ZONE = process.env.BUNNY_STORAGE_ZONE!
const STORAGE_KEY = process.env.BUNNY_STORAGE_API_KEY!
const REGION = process.env.BUNNY_STORAGE_REGION || ''

function getStorageEndpoint(): string {
  return REGION
    ? `https://${REGION}.storage.bunnycdn.com`
    : 'https://storage.bunnycdn.com'
}

export async function uploadFile(
  localFilePath: string,
  remotePath: string       // ex: 'images/foto.jpg' ou 'videos/clip.mp4'
): Promise<string> {
  const endpoint = getStorageEndpoint()
  const fileBuffer = fs.readFileSync(localFilePath)
  const contentType = getMimeType(localFilePath)

  const url = `${endpoint}/${STORAGE_ZONE}/${remotePath}`

  const res = await fetch(url, {
    method: 'PUT',
    headers: {
      AccessKey: STORAGE_KEY,
      'Content-Type': contentType,
    },
    body: fileBuffer,
  })

  if (!res.ok) {
    throw new Error(`Upload falhou: ${res.status} ${await res.text()}`)
  }

  // Retorna URL pública via CDN
  const CDN = process.env.BUNNY_CDN_HOSTNAME!
  return `https://${CDN}/${remotePath}`
}

function getMimeType(filePath: string): string {
  const ext = path.extname(filePath).toLowerCase()
  const map: Record<string, string> = {
    '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg',
    '.png': 'image/png', '.gif': 'image/gif',
    '.webp': 'image/webp', '.svg': 'image/svg+xml',
    '.mp4': 'video/mp4', '.webm': 'video/webm',
    '.pdf': 'application/pdf',
    '.mp3': 'audio/mpeg', '.wav': 'audio/wav',
  }
  return map[ext] || 'application/octet-stream'
}
```

### Upload via stream (arquivos grandes — sem carregar em memória)

```typescript
import { createReadStream } from 'fs'
import { stat } from 'fs/promises'

export async function uploadLargeFile(
  localFilePath: string,
  remotePath: string
): Promise<string> {
  const endpoint = getStorageEndpoint()
  const { size } = await stat(localFilePath)
  const stream = createReadStream(localFilePath)

  const res = await fetch(`${endpoint}/${STORAGE_ZONE}/${remotePath}`, {
    method: 'PUT',
    headers: {
      AccessKey: STORAGE_KEY,
      'Content-Type': getMimeType(localFilePath),
      'Content-Length': String(size),
    },
    // @ts-ignore — Node 18+ suporta ReadableStream
    body: stream,
    duplex: 'half',
  })

  if (!res.ok) throw new Error(`Upload falhou: ${res.status}`)
  return `https://${process.env.BUNNY_CDN_HOSTNAME}/${remotePath}`
}
```

### Download de arquivo

```typescript
export async function downloadFile(remotePath: string): Promise<Buffer> {
  const endpoint = getStorageEndpoint()
  const res = await fetch(`${endpoint}/${STORAGE_ZONE}/${remotePath}`, {
    headers: { AccessKey: STORAGE_KEY },
  })
  if (!res.ok) throw new Error(`Download falhou: ${res.status}`)
  return Buffer.from(await res.arrayBuffer())
}
```

### Listar arquivos de uma pasta

```typescript
export async function listFiles(remotePath: string = '/') {
  const endpoint = getStorageEndpoint()
  const url = `${endpoint}/${STORAGE_ZONE}/${remotePath.replace(/^\//, '')}`
  const res = await fetch(url, { headers: { AccessKey: STORAGE_KEY } })
  if (!res.ok) throw new Error(`Listagem falhou: ${res.status}`)
  return res.json() as Promise<BunnyFile[]>
}

interface BunnyFile {
  Guid: string
  ObjectName: string
  Path: string
  Length: number
  LastChanged: string
  IsDirectory: boolean
  ContentType: string
}
```

### Deletar arquivo

```typescript
export async function deleteFile(remotePath: string): Promise<void> {
  const endpoint = getStorageEndpoint()
  const res = await fetch(`${endpoint}/${STORAGE_ZONE}/${remotePath}`, {
    method: 'DELETE',
    headers: { AccessKey: STORAGE_KEY },
  })
  if (!res.ok) throw new Error(`Deleção falhou: ${res.status}`)
}
```

---

## Bunny Optimizer — Transformação de Imagens por URL

Sem código adicional — adicione parâmetros à URL da imagem CDN.

> Requer Bunny Optimizer ativado na Pull Zone (Dashboard → Pull Zone → Optimizer).

### Parâmetros disponíveis

| Parâmetro | Exemplo | Descrição |
|---|---|---|
| `width` | `?width=800` | Redimensionar por largura (mantém proporção) |
| `height` | `?height=600` | Redimensionar por altura (mantém proporção) |
| `aspect_ratio` | `?aspect_ratio=16:9` | Cortar para proporção |
| `quality` | `?quality=75` | Qualidade 0–100 (padrão: 85) |
| `format` | `?format=webp` | Converter formato: `webp`, `avif`, `jpeg`, `png` |
| `crop` | `?crop=800,600` | Cortar para dimensões exatas `w,h` ou `w,h,x,y` |
| `crop_gravity` | `?crop_gravity=center` | Foco do crop: `center`, `north`, `south`, `east`, `west` |
| `sharpen` | `?sharpen=true` | Nitidez |
| `blur` | `?blur=10` | Desfoque 0–100 |
| `brightness` | `?brightness=10` | Brilho -100 a +100 |
| `saturation` | `?saturation=20` | Saturação |
| `flip` | `?flip=true` | Espelhar verticalmente |
| `flop` | `?flop=true` | Espelhar horizontalmente |
| `auto_optimize` | `?auto_optimize=medium` | Otimização automática: `low`, `medium`, `high` |
| `class` | `?class=thumbnail` | Classe de imagem pré-configurada no dashboard |

### Exemplos práticos

```typescript
const CDN = 'https://suazone.b-cdn.net'

// Thumbnail 300x300 quadrado em WebP
`${CDN}/foto.jpg?width=300&height=300&aspect_ratio=1:1&format=webp&quality=80`

// Banner 1200x630 para redes sociais
`${CDN}/foto.jpg?width=1200&height=630&crop=1200,630&crop_gravity=center&format=webp`

// Imagem responsiva pequena para mobile
`${CDN}/foto.jpg?width=480&auto_optimize=medium&format=webp`

// Avatar circular (crop quadrado)
`${CDN}/perfil.jpg?width=100&height=100&aspect_ratio=1:1&crop_gravity=center`
```

### Helper TypeScript para gerar URLs otimizadas

```typescript
interface ImageOptions {
  width?: number
  height?: number
  quality?: number
  format?: 'webp' | 'avif' | 'jpeg' | 'png'
  aspectRatio?: string   // '16:9', '4:3', '1:1'
  crop?: string          // '800,600' ou '800,600,0,0'
  cropGravity?: 'center' | 'north' | 'south' | 'east' | 'west'
  blur?: number
  sharpen?: boolean
  autoOptimize?: 'low' | 'medium' | 'high'
}

export function optimizeImageUrl(
  remotePath: string,
  options: ImageOptions = {}
): string {
  const CDN = process.env.BUNNY_CDN_HOSTNAME!
  const params = new URLSearchParams()

  if (options.width)        params.set('width', String(options.width))
  if (options.height)       params.set('height', String(options.height))
  if (options.quality)      params.set('quality', String(options.quality))
  if (options.format)       params.set('format', options.format)
  if (options.aspectRatio)  params.set('aspect_ratio', options.aspectRatio)
  if (options.crop)         params.set('crop', options.crop)
  if (options.cropGravity)  params.set('crop_gravity', options.cropGravity)
  if (options.blur)         params.set('blur', String(options.blur))
  if (options.sharpen)      params.set('sharpen', 'true')
  if (options.autoOptimize) params.set('auto_optimize', options.autoOptimize)

  const query = params.toString()
  return `https://${CDN}/${remotePath}${query ? `?${query}` : ''}`
}

// Uso:
optimizeImageUrl('photos/produto.jpg', {
  width: 600, format: 'webp', quality: 80
})
// → https://suazone.b-cdn.net/photos/produto.jpg?width=600&format=webp&quality=80
```

---

## Bunny Stream — Upload e Streaming de Vídeos

→ Guia completo com upload HTTP, TUS resumável e embed player em: `references/bunny-stream.md`

---

## Purge do Cache CDN (forçar atualização)

```typescript
async function purgeUrl(cdnUrl: string): Promise<void> {
  const ACCOUNT_KEY = process.env.BUNNY_ACCOUNT_API_KEY!
  const encoded = encodeURIComponent(cdnUrl)
  const res = await fetch(
    `https://api.bunny.net/purge?url=${encoded}&async=false`,
    {
      method: 'POST',
      headers: { AccessKey: ACCOUNT_KEY },
    }
  )
  if (!res.ok) throw new Error(`Purge falhou: ${res.status}`)
}
```

---

## Upload via Multipart (Express / Next.js API Route)

→ Padrão completo com multer/busboy para receber upload do browser e repassar para o Bunny em: `references/upload-patterns.md`

---

## Segurança — URLs Assinadas (Token Auth)

Para proteger arquivos privados com URLs com expiração:

→ Guia completo de signed URLs em: `references/signed-urls.md`

---

## Referências

| Arquivo | Conteúdo |
|---|---|
| `references/bunny-stream.md` | Upload HTTP, TUS resumável, embed player, assinatura |
| `references/upload-patterns.md` | Padrões de upload: Express, Next.js, multipart, buffer |
| `references/signed-urls.md` | URLs assinadas para arquivos protegidos |
| `references/nextjs-integration.md` | Integração completa com Next.js (App Router + Server Actions) |


---

## Relacionado

[[Next.js 15]] | [[Supabase]]


---

## Referencias

- [[Referencias/bunny-stream]]
- [[Referencias/nextjs-integration]]
- [[Referencias/signed-urls]]
- [[Referencias/upload-patterns]]
