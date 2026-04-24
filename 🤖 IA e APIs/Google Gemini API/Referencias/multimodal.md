# Gemini 2.5 — Thinking e Multimodal Avançado

## Thinking (Raciocínio Interno)

O Gemini 2.5 Flash e Pro possuem capacidade de "pensar" antes de responder, melhorando a qualidade em tarefas complexas de matemática, código e raciocínio lógico.

```typescript
// Thinking com budget controlado
const response = await ai.models.generateContent({
  model: 'gemini-2.5-flash',
  contents: 'Resolva: se um trem parte de SP a 120km/h e outro de RJ a 80km/h...',
  config: {
    thinkingConfig: {
      thinkingBudget: 8192,  // tokens de thinking (0 = desabilitar, -1 = sem limite)
    },
  },
})

// Ver o processo de pensamento (thought summaries)
const thoughts = response.candidates?.[0]?.content?.parts
  ?.filter(p => p.thought)
  ?.map(p => p.text)
  ?.join('\n')

console.log('Reasoning:', thoughts)
console.log('Resposta:', response.text)
```

```typescript
// Desabilitar thinking para respostas mais rápidas e baratas
const fastResponse = await ai.models.generateContent({
  model: 'gemini-2.5-flash',
  contents: 'Qual é a capital do Brasil?',
  config: {
    thinkingConfig: { thinkingBudget: 0 },  // sem reasoning
  },
})
```

**Quando usar thinking:**
- Matemática avançada, provas, álgebra
- Código complexo com múltiplas dependências
- Raciocínio lógico multi-step
- Análise de documentos longos com conclusões

**Quando NÃO usar (custo/latência):**
- FAQs simples, classificação de sentimentos
- Extração de dados estruturada simples
- Respostas curtas e diretas

---

## PDF — Análise de Documentos

```typescript
import fs from 'fs'

// PDF pequeno (<20MB) — inline
const pdfBytes = fs.readFileSync('./contrato.pdf')
const pdfBase64 = pdfBytes.toString('base64')

const response = await ai.models.generateContent({
  model: 'gemini-2.5-flash',
  contents: [
    {
      role: 'user',
      parts: [
        {
          inlineData: {
            mimeType: 'application/pdf',
            data: pdfBase64,
          },
        },
        { text: 'Extraia todas as cláusulas de rescisão deste contrato.' },
      ],
    },
  ],
})

// PDF grande — usar File API
const uploadedPdf = await ai.files.upload({
  file: {
    displayName: 'relatorio-anual.pdf',
    mimeType: 'application/pdf',
  },
  media: fs.createReadStream('./relatorio-anual.pdf'),
})

// Aguardar processamento (PDFs grandes podem demorar)
let file = await ai.files.get(uploadedPdf.name!)
while (file.state === 'PROCESSING') {
  await new Promise(r => setTimeout(r, 5000))
  file = await ai.files.get(uploadedPdf.name!)
}

if (file.state !== 'ACTIVE') throw new Error('Falha ao processar PDF')

const pdfAnalysis = await ai.models.generateContent({
  model: 'gemini-2.5-pro',  // Pro para análise profunda de documentos longos
  contents: [
    {
      role: 'user',
      parts: [
        { fileData: { mimeType: 'application/pdf', fileUri: file.uri! } },
        { text: 'Faça um resumo executivo e liste os principais KPIs.' },
      ],
    },
  ],
})
```

---

## Vídeo — Análise de Longa Duração

```typescript
// Upload de vídeo (pode ser longo — até 2h em 2M token context)
const uploadedVideo = await ai.files.upload({
  file: {
    displayName: 'reuniao-produto.mp4',
    mimeType: 'video/mp4',
  },
  media: fs.createReadStream('./reuniao-produto.mp4'),
})

// Aguardar processamento (vídeos podem demorar minutos)
let videoFile = await ai.files.get(uploadedVideo.name!)
while (videoFile.state === 'PROCESSING') {
  console.log(`Processando vídeo... ${videoFile.name}`)
  await new Promise(r => setTimeout(r, 10_000))  // verificar a cada 10s
  videoFile = await ai.files.get(uploadedVideo.name!)
}

const videoAnalysis = await ai.models.generateContent({
  model: 'gemini-2.5-pro',
  contents: [
    {
      role: 'user',
      parts: [
        { fileData: { mimeType: 'video/mp4', fileUri: videoFile.uri! } },
        {
          text: `Analise esta reunião e forneça:
          1. Resumo dos principais tópicos discutidos
          2. Decisões tomadas
          3. Itens de ação com responsáveis
          4. Próximos passos`,
        },
      ],
    },
  ],
  config: {
    thinkingConfig: { thinkingBudget: 4096 },  // thinking para análise estruturada
  },
})
```

---

## Múltiplas Imagens — Comparação e Análise

```typescript
// Comparar múltiplas imagens
async function compareProducts(imagePaths: string[]) {
  const parts = [
    ...imagePaths.map(path => ({
      inlineData: {
        mimeType: 'image/jpeg' as const,
        data: fs.readFileSync(path).toString('base64'),
      },
    })),
    { text: `Compare estes ${imagePaths.length} produtos. Liste as principais diferenças em termos de design, qualidade percebida e características visíveis.` },
  ]

  return ai.models.generateContent({
    model: 'gemini-2.5-flash',
    contents: [{ role: 'user', parts }],
    config: {
      responseMimeType: 'application/json',
      responseSchema: {
        type: 'OBJECT' as any,
        properties: {
          comparison: {
            type: 'ARRAY' as any,
            items: {
              type: 'OBJECT' as any,
              properties: {
                aspect: { type: 'STRING' as any },
                products: {
                  type: 'ARRAY' as any,
                  items: { type: 'STRING' as any },
                },
              },
            },
          },
          recommendation: { type: 'STRING' as any },
        },
      },
    },
  })
}
```

---

## Áudio — Transcrição e Análise

```typescript
// Upload de áudio para análise
const audioBytes = fs.readFileSync('./podcast.mp3')
const audioBase64 = audioBytes.toString('base64')

const transcription = await ai.models.generateContent({
  model: 'gemini-2.5-flash',
  contents: [
    {
      role: 'user',
      parts: [
        {
          inlineData: {
            mimeType: 'audio/mpeg',
            data: audioBase64,
          },
        },
        {
          text: 'Transcreva este áudio em português, identificando cada falante como "Falante 1", "Falante 2", etc.',
        },
      ],
    },
  ],
})

console.log(transcription.text)
```

---

## Controle de Custo com Context Caching

```typescript
// Context caching vs custo normal
// Sem cache: 100K tokens × N chamadas = custo total
// Com cache: 100K tokens (write) + pequeno read × N chamadas = ~90% economia

// Configuração eficiente: pré-carregar documento uma vez por hora
async function createDocumentAssistant(documentContent: string) {
  const cache = await ai.caches.create({
    model: 'gemini-2.5-flash',
    config: {
      ttl: '3600s',  // 1 hora
      systemInstruction: 'Você é um assistente especialista neste documento. Responda apenas com base no conteúdo fornecido.',
      contents: [
        {
          role: 'user',
          parts: [{ text: `DOCUMENTO:\n\n${documentContent}` }],
        },
      ],
    },
  })

  return {
    cacheName: cache.name,
    async ask(question: string) {
      const response = await ai.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: [{ role: 'user', parts: [{ text: question }] }],
        config: { cachedContent: cache.name },
      })
      return response.text
    },
    async destroy() {
      await ai.caches.delete(cache.name)
    },
  }
}

// Uso:
const assistant = await createDocumentAssistant(longDocument)
const answer1 = await assistant.ask('Quais são as cláusulas de rescisão?')
const answer2 = await assistant.ask('Qual é o prazo do contrato?')
await assistant.destroy()
```


---

← [[README|Google Gemini API]]
