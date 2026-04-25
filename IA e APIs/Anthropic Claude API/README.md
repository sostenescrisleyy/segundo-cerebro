---
tags: [ia-apis]
categoria: "IA e APIs"
---

# Anthropic Claude API — Guia de Referência

**SDK oficial:** `@anthropic-ai/sdk` (TypeScript/JavaScript)  
**Docs:** https://docs.anthropic.com  
**Console:** https://console.anthropic.com

> ⚠️ **Regra absoluta:** `ANTHROPIC_API_KEY` fica **exclusivamente no servidor**.  
> Nunca em variáveis públicas (`NEXT_PUBLIC_`, `VITE_`, etc.), nunca no bundle JS.

---

## Setup

```bash
npm install @anthropic-ai/sdk
```

```typescript
// lib/anthropic.ts — servidor apenas
import Anthropic from '@anthropic-ai/sdk'

export const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
  maxRetries: 3,   // retry automático em 429/5xx
  timeout: 60_000, // 60s para contextos longos
})
```

---

## Modelos: Escolha Certa para o Trabalho Certo

| Família | Modelo | Quando usar | Custo relativo |
|---|---|---|---|
| **Haiku** | `claude-haiku-4-5` | Classificação, summaries curtos, alto volume | Baixo |
| **Sonnet** | `claude-sonnet-4-6` | 🏆 Equilíbrio qualidade/custo — padrão para produção | Médio |
| **Opus** | `claude-opus-4-6` | Raciocínio complexo, análise profunda, máxima qualidade | Alto |

> **Regra prática:** Padrão é `claude-sonnet-4-6`. Use Haiku para tarefas simples de alto volume. Opus apenas quando a qualidade extra justifica o custo.

---

## Mensagens Básicas

```typescript
import { anthropic } from '@/lib/anthropic'

// Simples
const message = await anthropic.messages.create({
  model: 'claude-sonnet-4-6',
  max_tokens: 1024,         // SEMPRE definir — sem isso o custo é ilimitado
  messages: [
    { role: 'user', content: 'Explique o que é RLS no Supabase.' }
  ],
})

const text = message.content[0].type === 'text' ? message.content[0].text : ''
const usage = message.usage  // { input_tokens, output_tokens, cache_read_input_tokens }

// Com system prompt
const message = await anthropic.messages.create({
  model: 'claude-sonnet-4-6',
  max_tokens: 2048,
  system: 'Você é um assistente de suporte técnico especializado em Next.js. Responda em português.',
  messages: [
    { role: 'user', content: 'Como funciona o App Router?' }
  ],
  temperature: 0.5,   // 0-1: 0 = determinístico, 1 = criativo
})

// Conversa multi-turn
const conversation = await anthropic.messages.create({
  model: 'claude-sonnet-4-6',
  max_tokens: 1024,
  messages: [
    { role: 'user',      content: 'Meu nome é Ana.' },
    { role: 'assistant', content: 'Olá, Ana! Como posso ajudar?' },
    { role: 'user',      content: 'Qual é o meu nome?' },
  ],
})
```

---

## Streaming

```typescript
// Streaming básico
const stream = anthropic.messages.stream({
  model: 'claude-sonnet-4-6',
  max_tokens: 2048,
  messages: [{ role: 'user', content: 'Escreva um artigo sobre IA.' }],
})

// Iterar sobre eventos
for await (const event of stream) {
  if (event.type === 'content_block_delta' && event.delta.type === 'text_delta') {
    process.stdout.write(event.delta.text)
  }
}

// Obter mensagem final com uso de tokens
const finalMessage = await stream.getFinalMessage()
console.log('Tokens usados:', finalMessage.usage)

// Streaming em Next.js Route Handler
// app/api/chat/route.ts
export async function POST(req: Request) {
  const { messages } = await req.json()

  const stream = anthropic.messages.stream({
    model: 'claude-sonnet-4-6',
    max_tokens: 2048,
    messages,
  })

  const encoder = new TextEncoder()
  const readable = new ReadableStream({
    async start(controller) {
      for await (const event of stream) {
        if (event.type === 'content_block_delta' && event.delta.type === 'text_delta') {
          controller.enqueue(encoder.encode(
            `data: ${JSON.stringify({ text: event.delta.text })}\n\n`
          ))
        }
      }
      controller.enqueue(encoder.encode('data: [DONE]\n\n'))
      controller.close()
    },
  })

  return new Response(readable, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
    },
  })
}
```

---

## Tool Use (Function Calling)

```typescript
import Anthropic from '@anthropic-ai/sdk'

const tools: Anthropic.Tool[] = [
  {
    name: 'get_weather',
    description: 'Retorna o clima atual de uma cidade. Use sempre que perguntarem sobre clima ou temperatura.',
    input_schema: {
      type: 'object',
      properties: {
        city:    { type: 'string', description: 'Nome da cidade (ex: São Paulo)' },
        country: { type: 'string', description: 'Código de 2 letras do país (ex: BR)' },
      },
      required: ['city'],
    },
  },
  {
    name: 'search_products',
    description: 'Busca produtos no catálogo. Retorna lista com nome, preço e disponibilidade.',
    input_schema: {
      type: 'object',
      properties: {
        query:    { type: 'string' },
        category: { type: 'string', enum: ['eletronicos', 'roupas', 'alimentos'] },
        maxPrice: { type: 'number' },
      },
      required: ['query'],
    },
  },
]

async function runAgent(userMessage: string): Promise<string> {
  const messages: Anthropic.MessageParam[] = [
    { role: 'user', content: userMessage }
  ]

  while (true) {
    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-6',
      max_tokens: 4096,
      tools,
      messages,
    })

    // Adicionar resposta ao histórico
    messages.push({ role: 'assistant', content: response.content })

    // Verificar stop reason
    if (response.stop_reason === 'end_turn') {
      // Resposta textual final — sem mais tool calls
      const textBlock = response.content.find(b => b.type === 'text')
      return textBlock?.type === 'text' ? textBlock.text : ''
    }

    if (response.stop_reason !== 'tool_use') break

    // Processar tool calls
    const toolResults: Anthropic.ToolResultBlockParam[] = []

    for (const block of response.content) {
      if (block.type !== 'tool_use') continue

      let result: unknown
      if (block.name === 'get_weather') {
        result = await fetchWeather(block.input as any)
      } else if (block.name === 'search_products') {
        result = await searchProducts(block.input as any)
      }

      toolResults.push({
        type: 'tool_result',
        tool_use_id: block.id,
        content: JSON.stringify(result),
      })
    }

    // Adicionar resultados das ferramentas
    messages.push({ role: 'user', content: toolResults })
  }

  return ''
}
```

---

## Structured Output — JSON Garantido

```typescript
import { z } from 'zod'

// Usando XML tags (abordagem robusta sem beta)
async function extractProductInfo(text: string) {
  const message = await anthropic.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 1024,
    system: `Extraia informações de produtos e retorne APENAS JSON válido, sem markdown.
    Schema: {"name": string, "price": number, "category": string, "inStock": boolean, "tags": string[]}`,
    messages: [{ role: 'user', content: text }],
  })

  const content = message.content[0]
  if (content.type !== 'text') throw new Error('Resposta inesperada')

  // Parse com Zod para validação
  const ProductSchema = z.object({
    name:     z.string(),
    price:    z.number(),
    category: z.string(),
    inStock:  z.boolean(),
    tags:     z.array(z.string()),
  })

  return ProductSchema.parse(JSON.parse(content.text))
}

// Técnica: usar tool use para structured output garantido
async function extractWithTools<T>(text: string, schema: object): Promise<T> {
  const response = await anthropic.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 1024,
    tools: [{
      name: 'extract_data',
      description: 'Extraia os dados do texto conforme o schema fornecido.',
      input_schema: schema as any,
    }],
    tool_choice: { type: 'tool', name: 'extract_data' }, // força uso da tool
    messages: [{ role: 'user', content: text }],
  })

  const toolBlock = response.content.find(b => b.type === 'tool_use')
  if (!toolBlock || toolBlock.type !== 'tool_use') throw new Error('Tool use esperado')
  return toolBlock.input as T
}
```

---

## Prompt Caching — Redução de Custo em até 90%

O Prompt Caching é a funcionalidade mais impactante da API Anthropic para reduzir custos. Tokens cacheados custam **10% do preço normal** após a escrita inicial.

```typescript
// Marcar conteúdo estático para cache com cache_control
const response = await anthropic.messages.create({
  model: 'claude-sonnet-4-6',
  max_tokens: 1024,
  system: [
    {
      type: 'text',
      text: seuSystemPromptLongo,         // 10k+ tokens — pago uma vez
      cache_control: { type: 'ephemeral' } // marcar para cache
    },
  ],
  messages: [{ role: 'user', content: perguntaDoUsuario }],
})

// Verificar se o cache foi usado
console.log('Cache write:', response.usage.cache_creation_input_tokens)
console.log('Cache read:',  response.usage.cache_read_input_tokens)
console.log('Cache hit:', (response.usage.cache_read_input_tokens ?? 0) > 0)
```

### Cache para Conversa Multi-turn

```typescript
// Marcar o último bloco de cada turn para cache incremental
function buildMessagesWithCache(
  history: Anthropic.MessageParam[],
  newMessage: string
): Anthropic.MessageParam[] {
  // Cache em todas as mensagens do histórico
  const cachedHistory = history.map((msg, i) => ({
    ...msg,
    content: Array.isArray(msg.content)
      ? msg.content.map((block, j) => {
          // Marcar o último bloco de cada mensagem
          const isLast = j === msg.content.length - 1
          if (isLast && typeof block === 'object' && block.type === 'text') {
            return { ...block, cache_control: { type: 'ephemeral' as const } }
          }
          return block
        })
      : msg.content,
  }))

  return [
    ...cachedHistory,
    { role: 'user' as const, content: newMessage },
  ]
}
```

### Cache para Documentos (RAG)

```typescript
// Para grandes documentos usados em múltiplas perguntas
async function createDocumentChat(documentContent: string) {
  const systemWithDoc: Anthropic.TextBlockParam[] = [
    {
      type: 'text',
      text: 'Você é um assistente especialista. Responda apenas com base no documento fornecido.',
    },
    {
      type: 'text',
      text: `DOCUMENTO:\n\n${documentContent}`,
      cache_control: { type: 'ephemeral' }, // documento cacheado — pago uma vez
    },
  ]

  return async function ask(question: string) {
    return anthropic.messages.create({
      model: 'claude-sonnet-4-6',
      max_tokens: 1024,
      system: systemWithDoc,
      messages: [{ role: 'user', content: question }],
    })
  }
}
```

---

## Visão — Análise de Imagens

```typescript
import fs from 'fs'

// Imagem local (base64)
const imageData = fs.readFileSync('./produto.jpg').toString('base64')

const response = await anthropic.messages.create({
  model: 'claude-sonnet-4-6',
  max_tokens: 1024,
  messages: [
    {
      role: 'user',
      content: [
        {
          type: 'image',
          source: {
            type: 'base64',
            media_type: 'image/jpeg',
            data: imageData,
          },
        },
        { type: 'text', text: 'Descreva este produto e identifique defeitos visíveis.' },
      ],
    },
  ],
})

// Imagem por URL
const response = await anthropic.messages.create({
  model: 'claude-sonnet-4-6',
  max_tokens: 1024,
  messages: [
    {
      role: 'user',
      content: [
        {
          type: 'image',
          source: { type: 'url', url: 'https://cdn.example.com/foto.jpg' },
        },
        { type: 'text', text: 'O que está nesta imagem?' },
      ],
    },
  ],
})
```

---

## Extended Thinking — Raciocínio Profundo

```typescript
// Para tarefas que exigem raciocínio complexo (matemática, código difícil, estratégia)
const response = await anthropic.messages.create({
  model: 'claude-sonnet-4-6',   // ou claude-opus-4-6
  max_tokens: 16_000,
  thinking: {
    type: 'enabled',
    budget_tokens: 10_000,  // tokens que Claude pode "pensar" internamente
  },
  messages: [
    { role: 'user', content: 'Resolva: Prove que sqrt(2) é irracional.' }
  ],
})

// A resposta inclui blocos de thinking + texto final
for (const block of response.content) {
  if (block.type === 'thinking') {
    console.log('Raciocínio interno:', block.thinking)
  }
  if (block.type === 'text') {
    console.log('Resposta final:', block.text)
  }
}
```

---

## Batch API — Processamento em Massa (50% de desconto)

```typescript
// Para processamento não-urgente de alto volume
const batch = await anthropic.messages.batches.create({
  requests: textos.map((texto, i) => ({
    custom_id: `item-${i}`,
    params: {
      model: 'claude-haiku-4-5',
      max_tokens: 256,
      messages: [
        { role: 'user', content: `Classifique o sentimento: "${texto}"` }
      ],
    },
  })),
})

console.log('Batch ID:', batch.id)

// Verificar status (processar em até 24h, mas geralmente < 1h)
let status = await anthropic.messages.batches.retrieve(batch.id)
while (status.processing_status === 'in_progress') {
  await new Promise(r => setTimeout(r, 30_000))  // verificar a cada 30s
  status = await anthropic.messages.batches.retrieve(batch.id)
}

// Obter resultados
for await (const result of await anthropic.messages.batches.results(batch.id)) {
  if (result.result.type === 'succeeded') {
    const text = result.result.message.content[0]
    console.log(result.custom_id, text.type === 'text' ? text.text : '')
  }
}
```

---

## Processamento de PDFs

```typescript
import fs from 'fs'

const pdfData = fs.readFileSync('./contrato.pdf').toString('base64')

const response = await anthropic.messages.create({
  model: 'claude-sonnet-4-6',
  max_tokens: 4096,
  messages: [
    {
      role: 'user',
      content: [
        {
          type: 'document',
          source: {
            type: 'base64',
            media_type: 'application/pdf',
            data: pdfData,
          },
          cache_control: { type: 'ephemeral' }, // cachear o PDF para múltiplas perguntas
        },
        { type: 'text', text: 'Extraia todas as cláusulas de penalidade deste contrato.' },
      ],
    },
  ],
})
```

---

## Tratamento de Erros

```typescript
import Anthropic from '@anthropic-ai/sdk'

async function safeCreate(params: Anthropic.MessageCreateParamsNonStreaming) {
  try {
    return await anthropic.messages.create(params)
  } catch (error) {
    if (error instanceof Anthropic.APIError) {
      switch (error.status) {
        case 429:
          // Rate limit — SDK já faz retry automático (3x por padrão)
          throw new Error('Rate limit excedido. Tente novamente em alguns minutos.')
        case 400:
          throw new Error(`Parâmetros inválidos: ${error.message}`)
        case 529:
          // Sobrecarga — tente novamente mais tarde
          throw new Error('API temporariamente sobrecarregada.')
        default:
          throw new Error(`Erro da API Anthropic (${error.status}): ${error.message}`)
      }
    }
    throw error
  }
}
```

---

## Referências

→ `references/prompting.md` — System prompts com XML, few-shot, redução de alucinações  
→ `references/agents.md` — Padrões de agentes, computer use, parallel tool calls


---

## Relacionado

[[OpenAI API]] | [[Google Gemini API]] | [[Multi Agentes]]


---

## Referencias

- [[Referencias/prompting]]
