# Bunny Stream — Upload e Streaming de Vídeos

**Base URL:** `https://video.bunnycdn.com`  
**Auth header:** `AccessKey: <STREAM_LIBRARY_API_KEY>`

## Variáveis de ambiente necessárias

```env
BUNNY_STREAM_API_KEY=sua-stream-library-api-key
BUNNY_STREAM_LIBRARY_ID=123456
BUNNY_STREAM_CDN_HOSTNAME=vz-abc123.b-cdn.net
```

---

## Método 1: Upload HTTP Direto (arquivos até ~500MB)

### Passo 1 — Criar objeto de vídeo

```typescript
interface CreateVideoResponse {
  guid: string
  title: string
  libraryId: number
  status: number
  storageSize: number
}

async function createVideoObject(title: string): Promise<CreateVideoResponse> {
  const res = await fetch(
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
  if (!res.ok) throw new Error(`Falha ao criar vídeo: ${res.status}`)
  return res.json()
}
```

### Passo 2 — Enviar o arquivo de vídeo (binário puro)

```typescript
import { createReadStream } from 'fs'
import { stat } from 'fs/promises'

async function uploadVideoFile(videoId: string, filePath: string): Promise<void> {
  const { size } = await stat(filePath)
  const stream = createReadStream(filePath)

  const res = await fetch(
    `https://video.bunnycdn.com/library/${process.env.BUNNY_STREAM_LIBRARY_ID}/videos/${videoId}`,
    {
      method: 'PUT',
      headers: {
        AccessKey: process.env.BUNNY_STREAM_API_KEY!,
        'Content-Type': 'application/octet-stream', // OBRIGATÓRIO — não use JSON!
        'Content-Length': String(size),
      },
      // @ts-ignore
      body: stream,
      duplex: 'half',
    }
  )
  if (!res.ok) throw new Error(`Upload do vídeo falhou: ${res.status}`)
}
```

### Uso combinado

```typescript
export async function uploadVideoHTTP(filePath: string, title: string) {
  const video = await createVideoObject(title)
  await uploadVideoFile(video.guid, filePath)
  return {
    videoId: video.guid,
    embedUrl: `https://iframe.mediadelivery.net/embed/${process.env.BUNNY_STREAM_LIBRARY_ID}/${video.guid}`,
    playUrl: `https://${process.env.BUNNY_STREAM_CDN_HOSTNAME}/${video.guid}/playlist.m3u8`,
    thumbnailUrl: `https://${process.env.BUNNY_STREAM_CDN_HOSTNAME}/${video.guid}/thumbnail.jpg`,
  }
}
```

---

## Método 2: TUS Resumable Upload (recomendado para arquivos grandes)

O TUS permite retomar uploads interrompidos — ideal para vídeos grandes, conexões instáveis ou uploads diretos do browser.

### Fluxo: Server → Client

```
1. Browser solicita upload ao seu servidor
2. Servidor cria o objeto de vídeo + gera assinatura
3. Servidor retorna: videoId, libraryId, expirationTime, signature
4. Browser faz upload direto ao Bunny via TUS (sem passar pelo servidor!)
```

### Servidor: gerar credenciais de upload

```typescript
import { createHash } from 'crypto'

interface UploadCredentials {
  videoId: string
  libraryId: string
  expirationTime: number
  signature: string
  embedUrl: string
}

export async function createTusUploadCredentials(
  title: string
): Promise<UploadCredentials> {
  // 1. Criar objeto de vídeo
  const video = await createVideoObject(title)
  const videoId = video.guid
  const libraryId = process.env.BUNNY_STREAM_LIBRARY_ID!
  const apiKey = process.env.BUNNY_STREAM_API_KEY!

  // 2. Gerar assinatura SHA256: libraryId + apiKey + expirationTime + videoId
  const expirationTime = Math.floor(Date.now() / 1000) + 86400 // 24h
  const signature = createHash('sha256')
    .update(`${libraryId}${apiKey}${expirationTime}${videoId}`)
    .digest('hex')

  return {
    videoId,
    libraryId,
    expirationTime,
    signature,
    embedUrl: `https://iframe.mediadelivery.net/embed/${libraryId}/${videoId}`,
  }
}
```

### Client: upload TUS no browser

```typescript
// npm install tus-js-client
import * as tus from 'tus-js-client'

async function uploadVideoWithTus(
  file: File,
  credentials: UploadCredentials,
  onProgress?: (percent: number) => void
): Promise<void> {
  return new Promise((resolve, reject) => {
    const upload = new tus.Upload(file, {
      endpoint: 'https://video.bunnycdn.com/tusupload',
      retryDelays: [0, 3000, 5000, 10000, 20000, 60000, 60000],
      headers: {
        AuthorizationSignature: credentials.signature,
        AuthorizationExpire: String(credentials.expirationTime),
        VideoId: credentials.videoId,
        LibraryId: credentials.libraryId,
      },
      metadata: {
        filetype: file.type,
        title: file.name,
      },
      onError: reject,
      onProgress: (bytesUploaded, bytesTotal) => {
        const percent = Math.round((bytesUploaded / bytesTotal) * 100)
        onProgress?.(percent)
      },
      onSuccess: resolve,
    })

    // Tentar retomar upload anterior
    upload.findPreviousUploads().then((previous) => {
      if (previous.length) upload.resumeFromPreviousUpload(previous[0])
      upload.start()
    })
  })
}
```

---

## Fetch de vídeo por URL remota (sem fazer upload manual)

```typescript
async function fetchVideoFromUrl(url: string, title: string): Promise<string> {
  const video = await createVideoObject(title)
  
  const res = await fetch(
    `https://video.bunnycdn.com/library/${process.env.BUNNY_STREAM_LIBRARY_ID}/videos/fetch`,
    {
      method: 'POST',
      headers: {
        AccessKey: process.env.BUNNY_STREAM_API_KEY!,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({ url, headers: {} }),
    }
  )
  if (!res.ok) throw new Error(`Fetch falhou: ${res.status}`)
  return video.guid
}
```

---

## Consultar status do vídeo (verificar encoding)

```typescript
interface VideoStatus {
  guid: string
  title: string
  status: number // 0=Queued, 1=Processing, 2=Encoding, 3=Finished, 4=Error, 5=UploadFailed
  encodeProgress: number // 0–100
  storageSize: number
  availableResolutions: string // '240p,360p,480p,720p,1080p'
  views: number
  length: number
}

export async function getVideoStatus(videoId: string): Promise<VideoStatus> {
  const res = await fetch(
    `https://video.bunnycdn.com/library/${process.env.BUNNY_STREAM_LIBRARY_ID}/videos/${videoId}`,
    {
      headers: {
        AccessKey: process.env.BUNNY_STREAM_API_KEY!,
        Accept: 'application/json',
      },
    }
  )
  if (!res.ok) throw new Error(`Falha ao buscar vídeo: ${res.status}`)
  return res.json()
}

// Polling até encoding terminar
export async function waitForEncoding(videoId: string): Promise<void> {
  while (true) {
    const video = await getVideoStatus(videoId)
    if (video.status === 3) return        // Finished
    if (video.status === 4) throw new Error('Encoding falhou')
    if (video.status === 5) throw new Error('Upload falhou')
    console.log(`Encoding: ${video.encodeProgress}%`)
    await new Promise(r => setTimeout(r, 5000)) // poll a cada 5s
  }
}
```

---

## URLs do vídeo após encoding

```typescript
export function getVideoUrls(videoId: string) {
  const libraryId = process.env.BUNNY_STREAM_LIBRARY_ID
  const cdn = process.env.BUNNY_STREAM_CDN_HOSTNAME

  return {
    // Player embed (iframe) — mais fácil de usar
    embedUrl: `https://iframe.mediadelivery.net/embed/${libraryId}/${videoId}`,
    // HLS para player customizado
    hlsUrl: `https://${cdn}/${videoId}/playlist.m3u8`,
    // Thumbnail
    thumbnailUrl: `https://${cdn}/${videoId}/thumbnail.jpg`,
    // Thumbnail em tempo específico (em segundos)
    thumbnailAt: (seconds: number) =>
      `https://${cdn}/${videoId}/thumbnail.jpg?time=${seconds}`,
    // Preview animado
    previewUrl: `https://${cdn}/${videoId}/preview.webp`,
  }
}
```

---

## Embed do player no HTML

```html
<!-- Player responsivo simples -->
<div style="position:relative;padding-top:56.25%">
  <iframe
    src="https://iframe.mediadelivery.net/embed/LIBRARY_ID/VIDEO_ID?autoplay=false"
    style="position:absolute;top:0;left:0;width:100%;height:100%;border:none"
    allow="accelerometer;gyroscope;autoplay;encrypted-media;picture-in-picture"
    allowfullscreen>
  </iframe>
</div>
```

---

## Deletar vídeo

```typescript
async function deleteVideo(videoId: string): Promise<void> {
  const res = await fetch(
    `https://video.bunnycdn.com/library/${process.env.BUNNY_STREAM_LIBRARY_ID}/videos/${videoId}`,
    {
      method: 'DELETE',
      headers: { AccessKey: process.env.BUNNY_STREAM_API_KEY! },
    }
  )
  if (!res.ok) throw new Error(`Deleção falhou: ${res.status}`)
}
```


---

← [[README|Bunny.net CDN]]
