---
tags: [ia-apis]
categoria: "IA e APIs"
---

# Google Gemini API — Guia de Referência

**SDK oficial:** `@google/genai` (TypeScript/JavaScript)  
**Docs:** https://ai.google.dev/gemini-api/docs  
**AI Studio:** https://aistudio.google.com  
**Nota:** Os SDKs antigos `@google/generative-ai` e `@google-cloud/vertexai` estão depreciados para Gemini 2.0+. Use sempre `@google/genai`.

> ⚠️ **Regra absoluta:** `GEMINI_API_KEY` fica **exclusivamente no servidor**.  
> Nunca em variáveis com prefixo público (`NEXT_PUBLIC_`, `VITE_`, etc.), nunca no bundle JS.

---

## Setup

```bash
npm install @google/genai
```

```typescript
// lib/gemini.ts — servidor apenas
import { GoogleGenAI } from '@google/genai'

export const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
})
```

---

## Modelos: Escolha Certa para o Trabalho Certo

| Modelo | String | Quando usar | Context window |
|---|---|---|---|
| **Gemini 2.5 Flash** | `gemini-2.5-flash` | 🏆 Melhor custo-benefício — padrão para produção | 1M tokens |
| **Gemini 2.5 Pro** | `gemini-2.5-pro` | Raciocínio complexo, código avançado, análise longa | 1M tokens |
| **Gemini 2.5 Flash (thinking)** | `gemini-2.5-flash` com `thinkingConfig` | Tarefas que precisam de reasoning intermediário | 1M tokens |

> **Regra prática:** Comece com `gemini-2.5-flash`. Só suba para Pro quando o Flash não for suficiente para a tarefa.

---

## Geração Básica de Texto

```typescript
import { ai } from '@/lib/gemini'

// Simples
const response = await ai.models.generateContent({
  model: 'gemini-2.5-flash',
  contents: 'Explique o que é Row Level Security no Supabase.',
})
console.log(response.text)

// Com system instruction e configuração
const response = await ai.models.generateContent({
  model: 'gemini-2.5-flash',
  contents: [
    { role: 'user', parts: [{ text: 'Olá, meu nome é João.' }] },
    { role: 'model', parts: [{ text: 'Olá, João! Como posso ajudar?' }] },
    { role: 'user', parts: [{ text: 'Qual é o meu nome?' }] },
  ],
  config: {
    systemInstruction: 'Você é um assistente útil que responde em português.',
    temperature: 0.7,
    maxOutputTokens: 1024,
    topP: 0.9,
  },
})
```

---

## Streaming

```typescript
// Streaming básico
const stream = await ai.models.generateContentStream({
  model: 'gemini-2.5-flash',
  contents: 'Escreva um artigo sobre inteligência artificial.',
})

for await (const chunk of stream) {
  process.stdout.write(chunk.text ?? '')
}

// Streaming em Next.js Route Handler
// app/api/gemini/route.ts
import { ai } from '@/lib/gemini'

export async function POST(req: Request) {
  const { prompt } = await req.json()
  const encoder = new TextEncoder()

  const readableStream = new ReadableStream({
    async start(controller) {
      const stream = await ai.models.generateContentStream({
        model: 'gemini-2.5-flash',
        contents: prompt,
      })
      for await (const chunk of stream) {
        const text = chunk.text
        if (text) {
          controller.enqueue(encoder.encode(`data: ${JSON.stringify({ text })}\n\n`))
        }
      }
      controller.enqueue(encoder.encode('data: [DONE]\n\n'))
      controller.close()
    },
  })

  return new Response(readableStream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
    },
  })
}
```

---

## Multimodal: Imagens

```typescript
import fs from 'fs'

// Imagem como bytes inline (arquivos pequenos)
const imageBytes = fs.readFileSync('./produto.jpg')
const base64 = imageBytes.toString('base64')

const response = await ai.models.generateContent({
  model: 'gemini-2.5-flash',
  contents: [
    {
      role: 'user',
      parts: [
        {
          inlineData: {
            mimeType: 'image/jpeg',
            data: base64,
          },
        },
        { text: 'Descreva este produto e identifique qualquer defeito visível.' },
      ],
    },
  ],
})

// Imagem via URL (mais eficiente para imagens na web)
const response = await ai.models.generateContent({
  model: 'gemini-2.5-flash',
  contents: [
    {
      role: 'user',
      parts: [
        {
          fileData: {
            mimeType: 'image/jpeg',
            fileUri: 'https://cdn.example.com/produto.jpg',
          },
        },
        { text: 'O que está nesta imagem?' },
      ],
    },
  ],
})
```

---

## Multimodal: Arquivos Grandes com File API

Para arquivos > ~20MB ou que serão reutilizados em múltiplas requisições:

```typescript
import { createPartFromUri } from '@google/genai'

// 1. Upload do arquivo (salvo por 48 horas no servidor do Google)
const uploadedFile = await ai.files.upload({
  file: {
    displayName: 'meu-video.mp4',
    mimeType: 'video/mp4',
  },
  // Pode passar um Buffer ou stream
  media: fs.createReadStream('./meu-video.mp4'),
})

console.log('File URI:', uploadedFile.uri)  // reutilize este URI

// 2. Usar o arquivo carregado
const response = await ai.models.generateContent({
  model: 'gemini-2.5-flash',
  contents: [
    {
      role: 'user',
      parts: [
        createPartFromUri(uploadedFile.uri!, uploadedFile.mimeType!),
        { text: 'Faça um resumo detalhado deste vídeo.' },
      ],
    },
  ],
})

// 3. (Opcional) Deletar o arquivo quando não precisar mais
await ai.files.delete(uploadedFile.name!)
```

---

## Structured Output — Saída em JSON Garantida

```typescript
import { Type } from '@google/genai'

const response = await ai.models.generateContent({
  model: 'gemini-2.5-flash',
  contents: 'Extraia as informações do produto: "Camiseta Nike Azul, tamanho M, R$ 89,90, disponível"',
  config: {
    responseMimeType: 'application/json',
    responseSchema: {
      type: Type.OBJECT,
      properties: {
        name:     { type: Type.STRING,  description: 'Nome do produto' },
        price:    { type: Type.NUMBER,  description: 'Preço em reais' },
        size:     { type: Type.STRING,  description: 'Tamanho' },
        color:    { type: Type.STRING,  description: 'Cor' },
        inStock:  { type: Type.BOOLEAN, description: 'Se está disponível' },
        tags:     { type: Type.ARRAY, items: { type: Type.STRING } },
      },
      required: ['name', 'price', 'inStock'],
    },
  },
})

// response.text é um JSON string garantido
const product = JSON.parse(response.text!) as {
  name: string; price: number; size?: string; color?: string; inStock: boolean; tags?: string[]
}
```

---

## Function Calling (Tool Use)

```typescript
import { Type, FunctionCallingConfigMode } from '@google/genai'

const tools = [
  {
    functionDeclarations: [
      {
        name: 'get_weather',
        description: 'Retorna o clima atual de uma cidade',
        parameters: {
          type: Type.OBJECT,
          properties: {
            city:    { type: Type.STRING, description: 'Nome da cidade' },
            country: { type: Type.STRING, description: 'Código do país (ex: BR)' },
          },
          required: ['city'],
        },
      },
      {
        name: 'search_products',
        description: 'Busca produtos no catálogo pelo nome',
        parameters: {
          type: Type.OBJECT,
          properties: {
            query:    { type: Type.STRING, description: 'Termo de busca' },
            maxPrice: { type: Type.NUMBER },
          },
          required: ['query'],
        },
      },
    ],
  },
]

// Loop de agente
async function runAgent(userMessage: string) {
  const history: any[] = [
    { role: 'user', parts: [{ text: userMessage }] }
  ]

  while (true) {
    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: history,
      config: {
        tools,
        toolConfig: {
          functionCallingConfig: {
            mode: FunctionCallingConfigMode.AUTO, // AUTO | ANY | NONE
          },
        },
      },
    })

    const candidate = response.candidates?.[0]
    if (!candidate) break

    // Adicionar resposta do modelo ao histórico
    history.push({ role: 'model', parts: candidate.content.parts })

    // Verificar se há chamadas de função
    const functionCalls = candidate.content.parts.filter(p => p.functionCall)

    if (functionCalls.length === 0) {
      // Sem chamadas → resposta final
      return response.text
    }

    // Executar as funções e adicionar resultados ao histórico
    const functionResults = []
    for (const part of functionCalls) {
      const { name, args } = part.functionCall!
      let result: unknown

      if (name === 'get_weather') {
        result = await fetchWeather(args.city, args.country)
      } else if (name === 'search_products') {
        result = await searchProductsDB(args.query, args.maxPrice)
      }

      functionResults.push({
        functionResponse: {
          name,
          response: { result },
        },
      })
    }

    history.push({ role: 'user', parts: functionResults })
  }
}
```

---

## Context Caching — Redução de Custo para Contextos Grandes

Ideal para documentos grandes (>32K tokens) reutilizados em múltiplas chamadas:

```typescript
import { GoogleGenAI } from '@google/genai'

// 1. Criar cache com o conteúdo estático (ex: documentação, manual)
const cache = await ai.caches.create({
  model: 'gemini-2.5-flash',
  config: {
    ttl: '3600s',  // 1 hora de vida do cache
    systemInstruction: 'Você é um assistente especialista neste documento.',
    contents: [
      {
        role: 'user',
        parts: [{ text: documentoCompleto }],  // 100k+ tokens — pago só uma vez
      },
    ],
  },
})

console.log('Cache name:', cache.name)

// 2. Reutilizar o cache em múltiplas requisições
for (const pergunta of perguntas) {
  const response = await ai.models.generateContent({
    model: 'gemini-2.5-flash',
    contents: [{ role: 'user', parts: [{ text: pergunta }] }],
    config: {
      cachedContent: cache.name,  // referencia o cache — não reprocessa o doc
    },
  })
  console.log(response.text)
}

// 3. (Opcional) Deletar cache antes do TTL
await ai.caches.delete(cache.name)
```

---

## Grounding com Google Search

```typescript
const response = await ai.models.generateContent({
  model: 'gemini-2.5-flash',
  contents: 'Quais são as últimas notícias sobre IA generativa hoje?',
  config: {
    tools: [{ googleSearch: {} }],  // Habilita busca em tempo real
  },
})

// A resposta inclui fontes citadas
console.log(response.text)

// Metadados de grounding (fontes, queries, etc.)
const groundingMeta = response.candidates?.[0]?.groundingMetadata
if (groundingMeta?.webSearchQueries) {
  console.log('Buscou por:', groundingMeta.webSearchQueries)
}
if (groundingMeta?.groundingChunks) {
  groundingMeta.groundingChunks.forEach(chunk => {
    console.log('Fonte:', chunk.web?.uri)
  })
}
```

---

## Embeddings

```typescript
// Embedding de texto único
const result = await ai.models.embedContent({
  model: 'gemini-embedding-exp-03-07',  // ou text-embedding-004 para estável
  contents: 'O que é machine learning?',
  config: {
    taskType: 'RETRIEVAL_DOCUMENT',  // ou RETRIEVAL_QUERY, SEMANTIC_SIMILARITY
  },
})

const embedding = result.embeddings?.[0]?.values  // array de floats

// Batch embeddings (mais eficiente)
const batchResult = await ai.models.batchEmbedContents({
  model: 'text-embedding-004',
  requests: textos.map(text => ({
    content: { parts: [{ text }] },
    taskType: 'RETRIEVAL_DOCUMENT',
  })),
})
```

---

## Contagem de Tokens

```typescript
// Contar tokens antes de enviar (controle de custo)
const tokenCount = await ai.models.countTokens({
  model: 'gemini-2.5-flash',
  contents: [{ role: 'user', parts: [{ text: promptLongo }] }],
})

console.log('Total de tokens:', tokenCount.totalTokens)

if (tokenCount.totalTokens! > 100_000) {
  // Usar context caching ou dividir a tarefa
}
```

---

## Tratamento de Erros

```typescript
import { GoogleGenAI } from '@google/genai'

async function safeGenerate(prompt: string) {
  try {
    return await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: prompt,
    })
  } catch (error: any) {
    if (error.status === 429) {
      // Rate limit — aguardar e tentar novamente
      await new Promise(r => setTimeout(r, 60_000))
      throw new Error('Rate limit atingido. Tente novamente.')
    }
    if (error.status === 400) {
      // Conteúdo bloqueado pelo safety filter
      throw new Error('Conteúdo bloqueado pelas políticas de segurança.')
    }
    throw error
  }
}
```

---

## Referências

→ `references/thinking.md` — Gemini 2.5 com thinking/raciocínio, budgets  
→ `references/multimodal.md` — PDF, áudio, vídeo longo, imagens múltiplas


---

## Relacionado

[[OpenAI API]] | [[Anthropic Claude API]]


---

## Referencias

- [[Referencias/multimodal]]
