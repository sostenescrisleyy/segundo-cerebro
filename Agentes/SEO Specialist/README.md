---
tags: [agentes]
categoria: "Agentes"
---


# Especialista em SEO e GEO

Especialista em SEO técnico e GEO (Generative Engine Optimization) para visibilidade em buscas
tradicionais e em IAs como ChatGPT, Perplexity e Google AI Overviews.

---

## Core Web Vitals — Impacto no SEO

| Métrica | Meta | Impacto no Ranking |
|---|---|---|
| **LCP** (Largest Contentful Paint) | ≤ 2.5s | Alto — fator direto de ranqueamento |
| **INP** (Interaction to Next Paint) | ≤ 200ms | Alto — substituiu FID em 2024 |
| **CLS** (Cumulative Layout Shift) | ≤ 0.1 | Médio-alto |
| **TTFB** (Time to First Byte) | ≤ 800ms | Impacto na eficiência do crawler |

---

## Checklist SEO Técnico Completo

```typescript
// next.config.ts — metadata do site
export const metadata: Metadata = {
  // Title único por página (50-60 chars)
  title: {
    default: 'Nome do Site',
    template: '%s | Nome do Site',    // ex: "Login | Nome do Site"
  },

  // Descrição única por página (150-160 chars)
  description: 'Descrição clara com keyword principal. Convida ao clique.',

  // Canonical automático (evitar conteúdo duplicado)
  alternates: {
    canonical: 'https://seusite.com',
  },

  // Open Graph (WhatsApp, LinkedIn, Facebook, Slack)
  openGraph: {
    type:      'website',
    locale:    'pt_BR',
    url:       'https://seusite.com',
    siteName:  'Nome do Site',
    title:     'Título para Redes Sociais (pode ser diferente do SEO)',
    description: 'Descrição para preview de link',
    images: [{
      url:    'https://seusite.com/og-image.jpg',  // 1200x630px
      width:   1200,
      height:   630,
      alt:    'Descrição da imagem para acessibilidade',
    }],
  },

  // Twitter/X Card
  twitter: {
    card:    'summary_large_image',
    creator: '@seuhandle',
    title:   'Título para Twitter',
    images:  ['https://seusite.com/og-image.jpg'],
  },

  // Robots
  robots: {
    index:  true,
    follow: true,
    googleBot: {
      index:             true,
      follow:            true,
      'max-video-preview':  -1,
      'max-image-preview':  'large',
      'max-snippet':        -1,
    },
  },
}
```

---

## Dados Estruturados (JSON-LD)

JSON-LD comunica ao Google o tipo exato de conteúdo para Rich Results.

```typescript
// Organização — páginas institucionais
const orgSchema = {
  '@context': 'https://schema.org',
  '@type':    'Organization',
  name:       'Sua Empresa',
  url:        'https://seusite.com',
  logo:       'https://seusite.com/logo.png',
  sameAs: [
    'https://instagram.com/seuhandle',
    'https://linkedin.com/company/suaempresa',
  ],
  contactPoint: {
    '@type':        'ContactPoint',
    telephone:      '+55-11-9999-9999',
    contactType:    'customer service',
    availableLanguage: 'Portuguese',
  },
}

// Produto — e-commerce
const produtoSchema = {
  '@context': 'https://schema.org',
  '@type':    'Product',
  name:       'Nome do Produto',
  description: 'Descrição detalhada',
  image:      ['https://seusite.com/produto.jpg'],
  sku:        'SKU-123',
  offers: {
    '@type':       'Offer',
    url:           'https://seusite.com/produto',
    price:         '97.00',
    priceCurrency: 'BRL',
    availability:  'https://schema.org/InStock',
    priceValidUntil: '2025-12-31',
  },
  aggregateRating: {
    '@type':       'AggregateRating',
    ratingValue:   '4.8',
    reviewCount:   '127',
  },
}

// Artigo de blog
const artigoSchema = {
  '@context':         'https://schema.org',
  '@type':            'BlogPosting',
  headline:           'Título do Artigo',
  description:        'Resumo do artigo',
  image:              'https://seusite.com/imagem-artigo.jpg',
  datePublished:      '2025-04-25T10:00:00-03:00',
  dateModified:       '2025-04-25T10:00:00-03:00',
  author: {
    '@type': 'Person',
    name:    'Nome do Autor',
    url:     'https://seusite.com/autor',
  },
  publisher: {
    '@type': 'Organization',
    name:    'Nome do Site',
    logo:    { '@type': 'ImageObject', url: 'https://seusite.com/logo.png' },
  },
}

// Implementar no Next.js App Router:
export default function Layout({ children }) {
  return (
    <html>
      <head>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(orgSchema) }}
        />
      </head>
      <body>{children}</body>
    </html>
  )
}
```

---

## sitemap.xml — Next.js App Router

```typescript
// app/sitemap.ts
import { MetadataRoute } from 'next'
import { prisma } from '@/lib/prisma'

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const posts = await prisma.post.findMany({
    where: { published: true },
    select: { slug: true, updatedAt: true },
  })

  const postUrls = posts.map(post => ({
    url:          `https://seusite.com/blog/${post.slug}`,
    lastModified: post.updatedAt,
    changeFrequency: 'weekly' as const,
    priority:     0.8,
  }))

  return [
    {
      url:          'https://seusite.com',
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority:     1.0,
    },
    {
      url:          'https://seusite.com/sobre',
      lastModified: new Date(),
      changeFrequency: 'monthly',
      priority:     0.5,
    },
    ...postUrls,
  ]
}

// app/robots.ts
export default function robots() {
  return {
    rules: [
      { userAgent: '*', allow: '/' },
      { userAgent: '*', disallow: ['/api/', '/admin/'] },
    ],
    sitemap: 'https://seusite.com/sitemap.xml',
  }
}
```

---

## E-E-A-T — Sinais de Qualidade do Google

| Fator | Significado | Como Demonstrar |
|---|---|---|
| **Experience** | Experiência direta com o tema | Casos reais, fotos, exemplos específicos |
| **Expertise** | Conhecimento profundo | Autor com credenciais, conteúdo detalhado |
| **Authoritativeness** | Reconhecimento externo | Backlinks, menções, prêmios |
| **Trustworthiness** | Confiabilidade | HTTPS, autoria clara, fontes citadas, CNPJ |

---

## GEO — Otimização para IAs

Para aparecer no ChatGPT, Perplexity, Google AI Overviews e Claude:

```markdown
# Princípios GEO

1. RESPONDA DIRETAMENTE no primeiro parágrafo
   Antes: "Neste artigo exploraremos as vantagens de..."
   Depois: "O preço médio de desenvolvimento de um SaaS é R$15.000-R$80.000..."

2. USE DADOS ESPECÍFICOS (IAs adoram números)
   "melhora muito" → "reduz tempo de deploy em 73%"

3. ESTRUTURE COM HEADERS QUE SÃO PERGUNTAS
   "## Quanto custa desenvolver um SaaS?"
   "## Qual é o melhor banco de dados para SaaS?"

4. CRIE SEÇÕES FAQ EXPLÍCITAS
   <FAQ>
   Q: Quanto tempo leva para desenvolver?
   A: Em média 3-6 meses para MVP...
   </FAQ>

5. ADICIONE llms.txt (novo padrão para AI crawlers)
```

```markdown
# llms.txt — na raiz do site
# Este arquivo guia crawlers de IA sobre seu conteúdo

# Nome do Site
> Plataforma SaaS para gestão de [X]

## O que fazemos
Desenvolvemos [produto] para [público] que precisam de [solução].

## Conteúdo principal
- [/blog]: Artigos técnicos sobre desenvolvimento SaaS
- [/docs]: Documentação completa da API
- [/casos]: Cases de sucesso de clientes

## Não indexar
- /admin
- /api
- /privado
```

---

## Ferramentas de Auditoria

```bash
# Lighthouse (Core Web Vitals)
npx lighthouse https://seusite.com --output=html --output-path=./relatorio.html

# Verificar dados estruturados
# → https://validator.schema.org/

# Verificar Open Graph
# → https://opengraph.xyz/

# Verificar rich results
# → https://search.google.com/test/rich-results

# Verificar indexação
# → Google Search Console (https://search.google.com/search-console)
```

---

## Relacionado

- [[Performance Web]]
- [[Product Manager]]
- [[Orquestrador]]
