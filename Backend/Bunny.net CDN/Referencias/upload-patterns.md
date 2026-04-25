# Padrões de Upload — Express, Next.js, Multipart

## Express + Multer (memória)

```typescript
import express from 'express'
import multer from 'multer'
import { uploadFile } from '../storage/bunny'

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 } // 50MB max
})

const router = express.Router()

router.post('/upload', upload.single('file'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'Nenhum arquivo enviado' })

  const ext = req.file.originalname.split('.').pop()
  const uniqueName = `${Date.now()}-${Math.random().toString(36).slice(2)}.${ext}`
  const remotePath = `uploads/${uniqueName}`

  // Upload do buffer direto para o Bunny
  const cdnUrl = await uploadBuffer(req.file.buffer, remotePath, req.file.mimetype)
  res.json({ url: cdnUrl })
})

// Função auxiliar para upload a partir de Buffer
export async function uploadBuffer(
  buffer: Buffer,
  remotePath: string,
  contentType: string
): Promise<string> {
  const endpoint = getStorageEndpoint()
  const res = await fetch(`${endpoint}/${process.env.BUNNY_STORAGE_ZONE}/${remotePath}`, {
    method: 'PUT',
    headers: {
      AccessKey: process.env.BUNNY_STORAGE_API_KEY!,
      'Content-Type': contentType,
    },
    body: buffer,
  })
  if (!res.ok) throw new Error(`Upload falhou: ${res.status}`)
  return `https://${process.env.BUNNY_CDN_HOSTNAME}/${remotePath}`
}
```

---

## Next.js App Router — Server Action

```typescript
// app/actions/upload.ts
'use server'
import { uploadBuffer } from '@/lib/bunny-storage'

export async function uploadImageAction(formData: FormData) {
  const file = formData.get('file') as File
  if (!file || file.size === 0) throw new Error('Nenhum arquivo')

  const buffer = Buffer.from(await file.arrayBuffer())
  const ext = file.name.split('.').pop()
  const remotePath = `uploads/${Date.now()}.${ext}`

  const url = await uploadBuffer(buffer, remotePath, file.type)
  return { url }
}
```

```tsx
// app/components/UploadForm.tsx
'use client'
import { uploadImageAction } from '@/app/actions/upload'
import { useState } from 'react'

export function UploadForm() {
  const [url, setUrl] = useState<string>('')
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setLoading(true)
    const formData = new FormData(e.currentTarget)
    const { url } = await uploadImageAction(formData)
    setUrl(url)
    setLoading(false)
  }

  return (
    <form onSubmit={handleSubmit}>
      <input name="file" type="file" accept="image/*" required />
      <button type="submit" disabled={loading}>
        {loading ? 'Enviando...' : 'Upload'}
      </button>
      {url && <img src={`${url}?width=400&format=webp`} alt="Preview" />}
    </form>
  )
}
```

---

## Next.js App Router — API Route (Route Handler)

```typescript
// app/api/upload/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { uploadBuffer } from '@/lib/bunny-storage'

export async function POST(req: NextRequest) {
  const formData = await req.formData()
  const file = formData.get('file') as File

  if (!file) return NextResponse.json({ error: 'Arquivo ausente' }, { status: 400 })

  // Validação de tipo
  const allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/gif']
  if (!allowed.includes(file.type)) {
    return NextResponse.json({ error: 'Tipo não permitido' }, { status: 415 })
  }

  const buffer = Buffer.from(await file.arrayBuffer())
  const ext = file.type.split('/')[1]
  const remotePath = `media/${Date.now()}.${ext}`

  const cdnUrl = await uploadBuffer(buffer, remotePath, file.type)
  return NextResponse.json({ url: cdnUrl })
}

export const config = {
  api: { bodyParser: false } // necessário para formData
}
```

---

## Upload com progresso (browser → servidor → Bunny)

Para mostrar progresso ao usuário em uploads grandes:

```typescript
// No servidor (Express/Node), use pipe para stream eficiente
import Busboy from 'busboy'
import { pipeline } from 'stream/promises'

router.post('/upload-stream', (req, res) => {
  const busboy = Busboy({ headers: req.headers })

  busboy.on('file', async (fieldname, fileStream, { filename, mimeType }) => {
    const remotePath = `uploads/${Date.now()}-${filename}`
    const endpoint = getStorageEndpoint()

    // Faz pipe diretamente do browser → Bunny sem buffer intermediário
    const bunnyRes = await fetch(
      `${endpoint}/${process.env.BUNNY_STORAGE_ZONE}/${remotePath}`,
      {
        method: 'PUT',
        headers: {
          AccessKey: process.env.BUNNY_STORAGE_API_KEY!,
          'Content-Type': mimeType,
        },
        // @ts-ignore
        body: fileStream,
        duplex: 'half',
      }
    )

    if (!bunnyRes.ok) return res.status(500).json({ error: 'Upload falhou' })

    const cdnUrl = `https://${process.env.BUNNY_CDN_HOSTNAME}/${remotePath}`
    res.json({ url: cdnUrl })
  })

  req.pipe(busboy)
})
```

---

## Renomear / Mover arquivo (copiar + deletar)

O Bunny Storage não tem operação de "rename" nativa — copie e delete:

```typescript
export async function moveFile(
  fromPath: string,
  toPath: string
): Promise<string> {
  // 1. Download do arquivo original
  const buffer = await downloadFile(fromPath)
  // 2. Upload no novo caminho
  const newUrl = await uploadBuffer(buffer, toPath, 'application/octet-stream')
  // 3. Deletar o original
  await deleteFile(fromPath)
  return newUrl
}
```

---

## Gerar nome único para evitar colisões

```typescript
import { randomUUID } from 'crypto'
import path from 'path'

export function generateRemotePath(
  originalName: string,
  folder = 'uploads'
): string {
  const ext = path.extname(originalName).toLowerCase()
  const uuid = randomUUID()
  return `${folder}/${uuid}${ext}`
}

// Uso:
const remotePath = generateRemotePath('minha-foto.jpg', 'images/users')
// → 'images/users/a1b2c3d4-...-ef12.jpg'
```


---

← [[README|Bunny.net CDN]]
