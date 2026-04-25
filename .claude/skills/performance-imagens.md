---
name: performance-imagens
description: >
  Use para otimização de imagens em aplicações web — WebP, AVIF, lazy loading, imagens
  responsivas, LQIP (blur placeholder) e estratégias de CDN. Ative para: "otimização de
  imagem", "webp", "avif", "lazy load imagem", "imagem responsiva", "LQIP", "CDN imagens",
  "next/image", "sharp", "squoosh", "imagem lenta", "LCP de imagem", "srcset", "sizes",
  "picture element", "placeholder blur", "imagem pesada", "compressão imagem", "formato moderno".
---

# Especialista em Performance de Imagens

Especialista em formatos modernos, estratégias de carregamento e CDN para imagens web.

---

## Seleção de Formato

| Formato | Suporte | Usar Para | Compressão vs JPEG |
|---|---|---|---|
| **AVIF** | 90%+ | Fotos, hero images, máxima compressão | ~50% menor |
| **WebP** | 97%+ | Uso geral, safe default | ~30% menor |
| **JPEG** | Universal | Fallback para fotos | baseline |
| **PNG** | Universal | Transparência necessária | — |
| **SVG** | Universal | Ícones, ilustrações, logos | vetorial |
| **GIF** | Universal | Animações simples (considerar WebM/MP4) | — |

---

## `<picture>` com Fallback Completo

```html
<picture>
  <!-- AVIF primeiro (melhor compressão) -->
  <source
    srcset="/img/hero-400.avif 400w, /img/hero-800.avif 800w, /img/hero-1200.avif 1200w"
    sizes="(max-width: 768px) 100vw, (max-width: 1200px) 80vw, 1200px"
    type="image/avif"
  />
  <!-- WebP como segundo (amplo suporte) -->
  <source
    srcset="/img/hero-400.webp 400w, /img/hero-800.webp 800w, /img/hero-1200.webp 1200w"
    sizes="(max-width: 768px) 100vw, (max-width: 1200px) 80vw, 1200px"
    type="image/webp"
  />
  <!-- JPEG como fallback universal -->
  <img
    src="/img/hero-800.jpg"
    alt="Descrição detalhada da imagem para SEO e acessibilidade"
    width="1200"
    height="600"
    loading="eager"          <!-- eager para imagem acima da dobra (LCP) -->
    decoding="sync"          <!-- sync para imagem crítica -->
    fetchpriority="high"     <!-- prioridade de busca alta -->
  />
</picture>

<!-- Para imagens abaixo da dobra: -->
<img
  src="/img/produto.webp"
  alt="Produto XYZ"
  width="400"
  height="300"
  loading="lazy"       <!-- lazy para imagens fora da viewport inicial -->
  decoding="async"
/>
```

---

## Next.js Image Component

```tsx
import Image from 'next/image'

// Imagem hero (LCP) — acima da dobra
<Image
  src="/hero.webp"
  alt="Banner principal do produto"
  width={1200}
  height={600}
  priority              // remove lazy, adiciona preload automático
  quality={85}          // 85 é ótimo equilíbrio qualidade/tamanho
  sizes="(max-width: 768px) 100vw, 1200px"
  placeholder="blur"    // LQIP automático para imagens locais
/>

// Imagem de produto (abaixo da dobra)
<Image
  src={product.imageUrl}
  alt={product.name}
  width={400}
  height={300}
  loading="lazy"        // default, explícito para clareza
  quality={80}
  sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 400px"
/>

// Imagem de avatar (tamanho fixo)
<Image
  src={user.avatar}
  alt={`Foto de ${user.name}`}
  width={48}
  height={48}
  className="rounded-full"
/>
```

---

## LQIP — Low Quality Image Placeholder (Blur Up)

```typescript
// Gerar blur placeholder com Sharp (server-side)
import sharp from 'sharp'

async function gerarBlurPlaceholder(caminhoImagem: string): Promise<string> {
  const buffer = await sharp(caminhoImagem)
    .resize(10, 10, { fit: 'inside' })  // reduzir para 10x10px
    .webp({ quality: 20 })
    .toBuffer()

  return `data:image/webp;base64,${buffer.toString('base64')}`
}

// Usar no componente:
const blurDataURL = await gerarBlurPlaceholder('./public/hero.webp')
// → "data:image/webp;base64,UklGRl..."

<Image
  src="/hero.webp"
  alt="Hero"
  width={1200}
  height={600}
  placeholder="blur"
  blurDataURL={blurDataURL}
/>
```

---

## Compressão com Sharp (Node.js)

```typescript
import sharp from 'sharp'
import path from 'path'

// Converter e otimizar imagem no upload
export async function processarUploadImagem(
  buffer: Buffer,
  nomeArquivo: string
): Promise<{ webp: Buffer; avif: Buffer; width: number; height: number }> {
  const imagem = sharp(buffer)
  const metadata = await imagem.metadata()

  // Redimensionar se muito grande (máximo 2000px de largura)
  const processada = metadata.width && metadata.width > 2000
    ? imagem.resize(2000, undefined, { withoutEnlargement: true })
    : imagem

  const [webp, avif] = await Promise.all([
    processada.clone().webp({ quality: 85 }).toBuffer(),
    processada.clone().avif({ quality: 80 }).toBuffer(),
  ])

  return {
    webp,
    avif,
    width:  Math.min(metadata.width ?? 800, 2000),
    height: metadata.height ?? 600,
  }
}
```

---

## CDN de Imagens

| Serviço | Vantagem | Use Quando |
|---|---|---|
| **Bunny.net CDN** | Barato, rápido, fácil de usar | Projeto com imagens de usuário |
| **Cloudflare Images** | Transformação on-the-fly | Múltiplos tamanhos dinâmicos |
| **Vercel Image Optimization** | Automático no Next.js | App no Vercel |
| **imgix** | Transformação avançada | E-commerce, catálogos |
| **Cloudinary** | Tudo incluso | Projetos com edição de imagem |

```typescript
// next.config.ts — permitir CDN externo
export default {
  images: {
    remotePatterns: [
      { protocol: 'https', hostname: 'cdn.seudominio.com' },
      { protocol: 'https', hostname: '*.bunnycdn.com' },
    ],
    formats: ['image/avif', 'image/webp'],  // preferir AVIF > WebP
    deviceSizes: [640, 750, 828, 1080, 1200, 1920],
    imageSizes:  [16, 32, 48, 64, 96, 128, 256, 384],
  },
}
```

---

## Checklist de Imagens

- [ ] Imagem hero com `priority` e `fetchpriority="high"`
- [ ] Todas imagens abaixo da dobra com `loading="lazy"`
- [ ] `width` e `height` definidos (evita CLS)
- [ ] Formato WebP ou AVIF (não JPEG/PNG bruto)
- [ ] `alt` descritivo em todas as imagens (SEO + acessibilidade)
- [ ] `srcset` para imagens responsivas
- [ ] LQIP/blur placeholder para imagens grandes
- [ ] Tamanho de arquivo: fotos < 200kb, thumbnails < 30kb
