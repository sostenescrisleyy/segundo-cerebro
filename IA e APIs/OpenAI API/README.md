---
tags: [ia-apis]
categoria: "IA e APIs"
---

# OpenAI API — Guia de Referência

**SDK:** `openai` (Node.js/TypeScript)  
**Docs:** https://platform.openai.com/docs  
**Modelos atuais:** `gpt-4o`, `gpt-4o-mini`, `gpt-4.1`, `o3`, `o4-mini`

> ⚠️ **Regra absoluta:** A chave da API (`OPENAI_API_KEY`) fica **exclusivamente no servidor**.  
> Nunca em `NEXT_PUBLIC_*`, nunca no bundle JS, nunca no browser.

---

## Setup e Cliente

```typescript
// lib/openai.ts — servidor apenas
import OpenAI from 'openai'

export const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
  maxRetries: 3,   // retry automático em erros 429/5xx
  timeout: 30_000, // 30s timeout
})
```

---

## Chat Completions

```typescript
// Básico
const response = await openai.chat.completions.create({
  model: 'gpt-4o-mini',     // mais barato para tarefas simples
  messages: [
    { role: 'system', content: 'Você é um assistente útil que responde em português.' },
    { role: 'user',   content: 'Explique o que é RLS no Supabase.' }
  ],
  temperature: 0.7,         // 0 = determinístico, 1 = criativo
  max_tokens: 1024,         // limite de saída — sempre definir!
})

const content = response.choices[0].message.content
const usage = response.usage // { prompt_tokens, completion_tokens, total_tokens }
```

### Escolha de Modelo

| Modelo | Quando usar | Custo relativo |
|---|---|---|
| `gpt-4o-mini` | Maioria das tarefas, classificação, summaries | Baixo |
| `gpt-4o` | Análise complexa, multi-modal, alta precisão | Médio |
| `gpt-4.1` | Contexto longo (1M tokens), coding avançado | Médio-alto |
| `o4-mini` | Raciocínio, matemática, código complexo | Médio |
| `o3` | Tarefas de raciocínio máximo | Alto |

---

## Streaming — Resposta em Tempo Real

```typescript
// app/api/chat/route.ts — Next.js Route Handler com streaming
import { openai } from '@/lib/openai'
import { OpenAIStream, StreamingTextResponse } from 'ai' // Vercel AI SDK

export async function POST(req: Request) {
  const { messages } = await req.json()

  const stream = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages,
    stream: true,
    max_tokens: 2048,
  })

  // Com Vercel AI SDK (mais simples):
  const aiStream = OpenAIStream(stream)
  return new StreamingTextResponse(aiStream)
}
```

```typescript
// Sem Vercel AI SDK — streaming nativo
export async function POST(req: Request) {
  const { messages } = await req.json()
  const encoder = new TextEncoder()

  const readableStream = new ReadableStream({
    async start(controller) {
      const stream = await openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages,
        stream: true,
      })

      for await (const chunk of stream) {
        const delta = chunk.choices[0]?.delta?.content
        if (delta) {
          controller.enqueue(encoder.encode(`data: ${JSON.stringify({ delta })}\n\n`))
        }
      }
      controller.enqueue(encoder.encode('data: [DONE]\n\n'))
      controller.close()
    }
  })

  return new Response(readableStream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
    }
  })
}
```

```tsx
// Cliente React consumindo SSE
'use client'
export function ChatMessage({ messageId }: { messageId: string }) {
  const [text, setText] = useState('')

  useEffect(() => {
    const eventSource = new EventSource(`/api/chat-stream?id=${messageId}`)
    eventSource.onmessage = (e) => {
      if (e.data === '[DONE]') { eventSource.close(); return }
      const { delta } = JSON.parse(e.data)
      setText(prev => prev + delta)
    }
    return () => eventSource.close()
  }, [messageId])

  return <p>{text}</p>
}
```

---

## Structured Outputs — Output Garantido

```typescript
import { zodResponseFormat } from 'openai/helpers/zod'
import { z } from 'zod'

// Schema de saída garantida
const ProductSchema = z.object({
  name:        z.string(),
  price:       z.number(),
  category:    z.enum(['electronics', 'clothing', 'food', 'other']),
  inStock:     z.boolean(),
  tags:        z.array(z.string()),
  description: z.string().optional(),
})

const response = await openai.beta.chat.completions.parse({
  model: 'gpt-4o',
  messages: [
    { role: 'system', content: 'Extract product information from the user text.' },
    { role: 'user',   content: 'Blue Nike Air Max, size 10, $120, available' }
  ],
  response_format: zodResponseFormat(ProductSchema, 'product'),
})

const product = response.choices[0].message.parsed
// product é tipado como Product — sem parsing manual!
```

---

## Function Calling (Tool Use)

```typescript
const tools: OpenAI.Chat.ChatCompletionTool[] = [
  {
    type: 'function',
    function: {
      name: 'search_products',
      description: 'Busca produtos no catálogo por nome ou categoria',
      strict: true,  // sempre true — garante aderência ao schema
      parameters: {
        type: 'object',
        properties: {
          query:    { type: 'string', description: 'Termo de busca' },
          category: { type: 'string', enum: ['electronics', 'clothing', 'food'] },
          maxPrice: { type: 'number', description: 'Preço máximo em reais' },
        },
        required: ['query'],
        additionalProperties: false,
      },
    },
  }
]

async function agentLoop(userMessage: string) {
  const messages: OpenAI.Chat.ChatCompletionMessageParam[] = [
    { role: 'system', content: 'Você é um assistente de loja. Use as ferramentas para ajudar o cliente.' },
    { role: 'user', content: userMessage },
  ]

  while (true) {
    const response = await openai.chat.completions.create({
      model: 'gpt-4o',
      messages,
      tools,
      tool_choice: 'auto', // 'required' força uso de tool, 'none' proíbe
    })

    const message = response.choices[0].message
    messages.push(message)

    // Nenhuma tool call? Resposta final
    if (!message.tool_calls?.length) {
      return message.content
    }

    // Executar as ferramentas chamadas
    for (const toolCall of message.tool_calls) {
      const args = JSON.parse(toolCall.function.arguments)
      let result: string

      if (toolCall.function.name === 'search_products') {
        const products = await searchProducts(args) // sua função real
        result = JSON.stringify(products)
      } else {
        result = JSON.stringify({ error: 'Tool not found' })
      }

      messages.push({
        role: 'tool',
        tool_call_id: toolCall.id,
        content: result,
      })
    }
  }
}
```

---

## Embeddings — Busca Semântica

```typescript
// Gerar embedding de um texto
async function getEmbedding(text: string): Promise<number[]> {
  const response = await openai.embeddings.create({
    model: 'text-embedding-3-small', // mais barato e rápido
    // model: 'text-embedding-3-large', // mais preciso
    input: text,
  })
  return response.data[0].embedding // array de 1536 floats
}

// Busca semântica com pgvector no Supabase
const queryEmbedding = await getEmbedding(userQuery)

const { data } = await supabase.rpc('match_documents', {
  query_embedding: queryEmbedding,
  match_threshold: 0.78,
  match_count: 5,
})
```

```sql
-- Supabase: criar coluna e função de busca vetorial
ALTER TABLE documents ADD COLUMN embedding vector(1536);

CREATE OR REPLACE FUNCTION match_documents(
  query_embedding vector(1536),
  match_threshold float,
  match_count int
)
RETURNS TABLE (id bigint, content text, similarity float)
LANGUAGE sql STABLE
AS $$
  SELECT id, content,
    1 - (embedding <=> query_embedding) AS similarity
  FROM documents
  WHERE 1 - (embedding <=> query_embedding) > match_threshold
  ORDER BY embedding <=> query_embedding
  LIMIT match_count;
$$;
```

---

## Controle de Custo

```typescript
// 1. Estimar tokens antes de enviar
import { encoding_for_model } from 'tiktoken'
const enc = encoding_for_model('gpt-4o')
const tokenCount = enc.encode(systemPrompt + userMessage).length
enc.free()
if (tokenCount > 8000) throw new Error('Prompt muito longo')

// 2. Limitar output
max_tokens: 512 // nunca omitir — custo ilimitado por padrão

// 3. Cachear respostas repetitivas (prompt caching automático em prompts > 1024 tokens)
// Manter o system prompt ESTÁTICO no início para maximizar cache hits

// 4. Batch API para processamento não-urgente (50% de desconto)
const batch = await openai.batches.create({
  input_file_id: fileId,
  endpoint: '/v1/chat/completions',
  completion_window: '24h',
})
```

---

## Tratamento de Erros

```typescript
import OpenAI from 'openai'

async function safeCompletion(messages: OpenAI.Chat.ChatCompletionMessageParam[]) {
  try {
    return await openai.chat.completions.create({ model: 'gpt-4o-mini', messages })
  } catch (error) {
    if (error instanceof OpenAI.APIError) {
      if (error.status === 429) {
        // Rate limit — esperar e tentar de novo (SDK faz retry automático, mas pode customizar)
        throw new Error('Limite de taxa atingido. Tente novamente em instantes.')
      }
      if (error.status === 400) {
        throw new Error('Conteúdo inválido ou bloqueado pela moderação.')
      }
      if (error.status >= 500) {
        throw new Error('Serviço OpenAI temporariamente indisponível.')
      }
    }
    throw error
  }
}
```

---

## Referências

→ `references/system-prompts.md` — engenharia de prompts, few-shot, chain of thought  
→ `references/vision-audio.md` — análise de imagens, transcrição de áudio, TTS


---

## Relacionado

[[Anthropic Claude API]] | [[Google Gemini API]] | [[Multi Agentes]]


---

## Referencias

- [[Referencias/system-prompts]]
