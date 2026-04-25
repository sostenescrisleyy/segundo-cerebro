# OpenAI — System Prompts e Engenharia de Prompt

## Anatomia de um System Prompt Eficaz

```typescript
const systemPrompt = `
Você é um assistente de suporte da [Nome da Empresa].

## Sua função
Ajudar clientes com dúvidas sobre pedidos, devoluções e produtos.

## Como responder
- Seja direto e objetivo — máximo 3 parágrafos por resposta
- Use português brasileiro coloquial (não formal)
- Sempre ofereça uma próxima ação ao final

## O que você pode fazer
- Consultar status de pedidos (use a ferramenta search_order)
- Explicar nossa política de devolução (30 dias)
- Escalar para humano quando solicitado

## O que você NÃO deve fazer
- Prometer prazos que não estão confirmados
- Compartilhar dados de outros clientes
- Fazer afirmações sobre produtos que não vendemos

## Contexto do usuário
Nome: {{customer_name}}
Plano: {{plan_type}}
`
```

## Técnicas de Prompting

### Few-shot (exemplos no prompt)

```typescript
const messages = [
  {
    role: 'system',
    content: 'Classifique o sentimento do texto como: positivo, negativo, ou neutro.'
  },
  { role: 'user',      content: 'O produto chegou rápido e funciona muito bem!' },
  { role: 'assistant', content: 'positivo' },
  { role: 'user',      content: 'O suporte demorou 3 dias para responder.' },
  { role: 'assistant', content: 'negativo' },
  { role: 'user',      content: 'Recebi o pedido dentro do prazo.' },
  { role: 'assistant', content: 'neutro' },
  { role: 'user',      content: userInputToClassify }, // input real
]
```

### Chain of Thought

```typescript
{
  role: 'system',
  content: `Ao resolver problemas, sempre:
  1. Restate o problema com suas próprias palavras
  2. Liste as informações disponíveis
  3. Descreva seu raciocínio passo a passo
  4. Apresente a resposta final claramente`
}
```

### Controle de Formato

```typescript
// Forçar output em JSON sem Structured Outputs
{
  role: 'system',
  content: `Sempre responda APENAS com JSON válido, sem markdown, sem explicações.
  Formato obrigatório: {"result": "...", "confidence": 0.0-1.0}`
}
// + response_format: { type: 'json_object' } no request

// Limitar tamanho de resposta
{
  role: 'system',
  content: 'Responda em no máximo 2 frases. Seja conciso.'
}
```

---

# OpenAI Vision — Análise de Imagens

```typescript
// Análise de imagem por URL
const response = await openai.chat.completions.create({
  model: 'gpt-4o',
  messages: [{
    role: 'user',
    content: [
      {
        type: 'image_url',
        image_url: {
          url: 'https://cdn.example.com/produto.jpg',
          detail: 'high'  // 'low' (mais barato) | 'high' | 'auto'
        }
      },
      { type: 'text', text: 'Descreva este produto e identifique qualquer defeito visível.' }
    ]
  }],
  max_tokens: 500,
})

// Análise de imagem por base64 (upload local)
import fs from 'fs'
const imageBuffer = fs.readFileSync('./produto.jpg')
const base64 = imageBuffer.toString('base64')

await openai.chat.completions.create({
  model: 'gpt-4o',
  messages: [{
    role: 'user',
    content: [
      {
        type: 'image_url',
        image_url: { url: `data:image/jpeg;base64,${base64}` }
      },
      { type: 'text', text: 'O que está nesta imagem?' }
    ]
  }]
})
```

---

# OpenAI Audio

## Transcrição (Speech-to-Text)

```typescript
import fs from 'fs'

// Transcrição simples
const transcription = await openai.audio.transcriptions.create({
  file: fs.createReadStream('audio.mp3'),
  model: 'whisper-1',
  language: 'pt',  // força português
  response_format: 'json', // 'text' | 'srt' | 'vtt' | 'verbose_json'
})
console.log(transcription.text)

// Com timestamps (verbose_json)
const detailed = await openai.audio.transcriptions.create({
  file: fs.createReadStream('podcast.mp3'),
  model: 'whisper-1',
  response_format: 'verbose_json',
  timestamp_granularities: ['segment', 'word'],
})
// detailed.segments e detailed.words
```

## Text-to-Speech

```typescript
const speech = await openai.audio.speech.create({
  model: 'tts-1',      // mais rápido
  // model: 'tts-1-hd', // mais qualidade
  voice: 'nova',       // alloy | echo | fable | onyx | nova | shimmer
  input: 'Olá! Bem-vindo ao nosso assistente de voz.',
  response_format: 'mp3', // mp3 | opus | aac | flac
})

// Salvar em arquivo
const buffer = Buffer.from(await speech.arrayBuffer())
fs.writeFileSync('speech.mp3', buffer)

// Ou stream para o browser
export async function GET() {
  const stream = await openai.audio.speech.create({
    model: 'tts-1',
    voice: 'nova',
    input: 'Texto para falar',
    response_format: 'mp3',
  })
  return new Response(stream.body, {
    headers: { 'Content-Type': 'audio/mpeg' }
  })
}
```


---

← [[README|OpenAI API]]
