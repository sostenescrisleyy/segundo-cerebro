# Integração Completa com Next.js (App Router)

Sistema completo de upload de mídia (imagens + vídeos) usando Next.js 14+ com App Router.

## Estrutura de arquivos

```
app/
├── api/
│   ├── upload/route.ts          ← upload de imagens
│   └── video/upload/route.ts    ← credenciais TUS para vídeo
├── components/
│   ├── ImageUpload.tsx
│   └── VideoUpload.tsx
└── lib/
    ├── bunny-storage.ts         ← helpers de Storage
    ├── bunny-stream.ts          ← helpers de Stream
    └── bunny-optimizer.ts       ← helper de URL de imagem
```

## .env.local

```env
BUNNY_STORAGE_API_KEY=sua-storage-zone-password
BUNNY_STORAGE_ZONE=minha-zone
BUNNY_STORAGE_REGION=br
BUNNY_CDN_HOSTNAME=minhzone.b-cdn.net

BUNNY_STREAM_API_KEY=sua-stream-api-key
BUNNY_STREAM_LIBRARY_ID=123456
BUNNY_STREAM_CDN_HOSTNAME=vz-abc.b-cdn.net

BUNNY_ACCOUNT_API_KEY=chave-da-conta     # Para purge de cache
BUNNY_TOKEN_KEY=sua-token-key            # Para signed URLs (opcional)
```

---

## lib/bunny-storage.ts

```typescript
const BASE = process.env.BUNNY_STORAGE_REGION
  ? `https://${process.env.BUNNY_STORAGE_REGION}.storage.bunnycdn.com`
  : 'https://storage.bunnycdn.com'
const ZONE = process.env.BUNNY_STORAGE_ZONE!
const KEY = process.env.BUNNY_STORAGE_API_KEY!
const CDN = process.env.BUNNY_CDN_HOSTNAME!

export async function uploadBuffer(buffer: Buffer, path: string, mime: string) {
  const res = await fetch(`${BASE}/${ZONE}/${path}`, {
    method: 'PUT',
    headers: { AccessKey: KEY, 'Content-Type': mime },
    body: buffer,
  })
  if (!res.ok) throw new Error(`Upload falhou: ${res.status}`)
  return `https://${CDN}/${path}`
}

export async function deleteStorageFile(path: string) {
  await fetch(`${BASE}/${ZONE}/${path}`, {
    method: 'DELETE',
    headers: { AccessKey: KEY },
  })
}
```

## lib/bunny-optimizer.ts

```typescript
type ImageFormat = 'webp' | 'avif' | 'jpeg' | 'png'

interface ImageTransform {
  width?: number
  height?: number
  quality?: number
  format?: ImageFormat
  aspectRatio?: string
  crop?: string
  cropGravity?: 'center' | 'north' | 'south' | 'east' | 'west'
  autoOptimize?: 'low' | 'medium' | 'high'
}

export const bunnyImage = {
  // Thumbnail quadrado (ex: avatar, product card)
  thumbnail: (path: string, size = 300) =>
    `https://${process.env.BUNNY_CDN_HOSTNAME}/${path}?width=${size}&height=${size}&aspect_ratio=1:1&format=webp&quality=82`,

  // Banner/Hero (16:9)
  hero: (path: string, width = 1200) =>
    `https://${process.env.BUNNY_CDN_HOSTNAME}/${path}?width=${width}&aspect_ratio=16:9&format=webp&quality=80`,

  // Imagem original otimizada para WebP
  optimized: (path: string, width?: number) => {
    const q = width ? `?width=${width}&format=webp&quality=85` : '?format=webp&quality=85'
    return `https://${process.env.BUNNY_CDN_HOSTNAME}/${path}${q}`
  },

  // Customizado
  transform: (path: string, opts: ImageTransform) => {
    const params = new URLSearchParams()
    if (opts.width)         params.set('width', String(opts.width))
    if (opts.height)        params.set('height', String(opts.height))
    if (opts.quality)       params.set('quality', String(opts.quality))
    if (opts.format)        params.set('format', opts.format)
    if (opts.aspectRatio)   params.set('aspect_ratio', opts.aspectRatio)
    if (opts.crop)          params.set('crop', opts.crop)
    if (opts.cropGravity)   params.set('crop_gravity', opts.cropGravity)
    if (opts.autoOptimize)  params.set('auto_optimize', opts.autoOptimize)
    const q = params.toString()
    return `https://${process.env.BUNNY_CDN_HOSTNAME}/${path}${q ? `?${q}` : ''}`
  },
}
```

---

## app/api/upload/route.ts

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { uploadBuffer } from '@/lib/bunny-storage'
import { randomUUID } from 'crypto'

const MAX_SIZE = 10 * 1024 * 1024 // 10MB
const ALLOWED = ['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/svg+xml']

export async function POST(req: NextRequest) {
  const form = await req.formData()
  const file = form.get('file') as File | null

  if (!file) return NextResponse.json({ error: 'Arquivo ausente' }, { status: 400 })
  if (file.size > MAX_SIZE) return NextResponse.json({ error: 'Arquivo muito grande' }, { status: 413 })
  if (!ALLOWED.includes(file.type)) return NextResponse.json({ error: 'Tipo inválido' }, { status: 415 })

  const ext = file.name.split('.').pop() || 'jpg'
  const path = `media/images/${randomUUID()}.${ext}`
  const buffer = Buffer.from(await file.arrayBuffer())

  const url = await uploadBuffer(buffer, path, file.type)
  return NextResponse.json({ url, path })
}
```

## app/api/video/upload/route.ts

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { createHash } from 'crypto'

export async function POST(req: NextRequest) {
  const { title } = await req.json()

  // 1. Criar objeto de vídeo
  const createRes = await fetch(
    `https://video.bunnycdn.com/library/${process.env.BUNNY_STREAM_LIBRARY_ID}/videos`,
    {
      method: 'POST',
      headers: {
        AccessKey: process.env.BUNNY_STREAM_API_KEY!,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({ title }),
    }
  )
  const video = await createRes.json()
  const videoId = video.guid
  const libraryId = process.env.BUNNY_STREAM_LIBRARY_ID!

  // 2. Gerar assinatura TUS
  const expirationTime = Math.floor(Date.now() / 1000) + 86400
  const signature = createHash('sha256')
    .update(`${libraryId}${process.env.BUNNY_STREAM_API_KEY}${expirationTime}${videoId}`)
    .digest('hex')

  return NextResponse.json({
    videoId,
    libraryId,
    expirationTime,
    signature,
    embedUrl: `https://iframe.mediadelivery.net/embed/${libraryId}/${videoId}`,
    thumbnailUrl: `https://${process.env.BUNNY_STREAM_CDN_HOSTNAME}/${videoId}/thumbnail.jpg`,
  })
}
```

---

## app/components/ImageUpload.tsx

```tsx
'use client'
import { useState } from 'react'
import { bunnyImage } from '@/lib/bunny-optimizer'

export function ImageUpload({ onUpload }: { onUpload: (url: string) => void }) {
  const [preview, setPreview] = useState<string>('')
  const [uploading, setUploading] = useState(false)
  const [progress, setProgress] = useState(0)

  async function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return

    // Preview local
    setPreview(URL.createObjectURL(file))
    setUploading(true)

    const form = new FormData()
    form.append('file', file)

    const res = await fetch('/api/upload', { method: 'POST', body: form })
    const { url } = await res.json()

    onUpload(url)
    setUploading(false)
  }

  return (
    <div>
      <input type="file" accept="image/*" onChange={handleChange} disabled={uploading} />
      {uploading && <p>Enviando...</p>}
      {preview && (
        <img
          src={bunnyImage.thumbnail(preview.replace('blob:', ''), 200)}
          alt="Preview"
        />
      )}
    </div>
  )
}
```

---

## Uso nos componentes (imagens otimizadas)

```tsx
// Em qualquer componente Server ou Client:
import { bunnyImage } from '@/lib/bunny-optimizer'

// Avatar
<img src={bunnyImage.thumbnail('avatars/user123.jpg', 80)} alt="Avatar" />

// Thumbnail de produto
<img src={bunnyImage.thumbnail('products/item42.jpg', 300)} alt="Produto" />

// Hero banner responsivo
<img
  src={bunnyImage.hero('banners/principal.jpg', 1200)}
  srcSet={`
    ${bunnyImage.hero('banners/principal.jpg', 600)} 600w,
    ${bunnyImage.hero('banners/principal.jpg', 1200)} 1200w
  `}
  alt="Banner"
/>
```

---

## next.config.js — Permitir domínio de imagens

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '*.b-cdn.net',
        pathname: '/**',
      },
    ],
  },
}
module.exports = nextConfig
```


---

← [[README|Bunny.net CDN]]
