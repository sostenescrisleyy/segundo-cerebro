# Anthropic Claude — Engenharia de Prompt e Padrões Avançados

## System Prompts com XML (melhor abordagem para Claude)

Claude foi treinado para responder bem a estruturação com XML. Use tags para organizar instruções complexas:

```typescript
const systemPrompt = `
Você é um assistente de suporte técnico da [Empresa].

<perfil>
  Nome: Assistente Técnico
  Especialidade: Next.js, React, TypeScript, Node.js
  Idioma: Português brasileiro, tom profissional mas acessível
</perfil>

<regras>
  - Responda APENAS sobre os produtos e tecnologias listados em <especialidade>
  - Para perguntas fora do escopo, redirecione educadamente
  - Sempre inclua exemplos de código quando relevante
  - Máximo 400 palavras por resposta, a menos que código seja necessário
  - Use markdown para formatação
</regras>

<especialidade>
  Next.js 15, React 19, TypeScript 5, Node.js, Supabase, Tailwind CSS
</especialidade>

<tom>
  Profissional mas amigável. Direto ao ponto. Evite jargão desnecessário.
</tom>
`
```

## Few-Shot com XML

```typescript
const systemWithExamples = `
Você classifica textos de feedback de clientes em categorias.

<categorias>
  - bug: problema técnico ou comportamento inesperado
  - feature: pedido de nova funcionalidade
  - elogio: feedback positivo
  - reclamacao: insatisfação geral
  - duvida: pergunta ou confusão
</categorias>

<exemplos>
  <exemplo>
    <input>O botão de login não funciona no Safari</input>
    <output>bug</output>
  </exemplo>
  <exemplo>
    <input>Seria incrível ter modo escuro</input>
    <output>feature</output>
  </exemplo>
  <exemplo>
    <input>Adoro a velocidade do novo dashboard!</input>
    <output>elogio</output>
  </exemplo>
</exemplos>

Responda APENAS com uma das categorias, sem explicação.
`
```

## Reduzir Alucinações

```typescript
// Técnicas para respostas mais factualmente precisas:

// 1. Pedir explicitamente para não inventar
const systemAntialucinacao = `
Responda apenas com base nas informações fornecidas no contexto.
Se a informação não estiver disponível no contexto, diga explicitamente:
"Não tenho informação suficiente sobre isso no contexto fornecido."
Nunca invente dados, datas, nomes ou estatísticas.
`

// 2. Incluir contexto com marcação clara
const messages = [
  {
    role: 'user' as const,
    content: `
<contexto>
${documentoDoCliente}
</contexto>

<pergunta>
${perguntaDoUsuario}
</pergunta>
    `
  }
]

// 3. Pedir citações
const systemComCitacoes = `
Ao responder perguntas sobre o documento fornecido, sempre cite a seção ou parágrafo relevante
entre colchetes, ex: [Seção 3.2] ou [Parágrafo 5].
`
```

## Chain of Thought para Tarefas Complexas

```typescript
// Forçar raciocínio passo a passo antes da resposta final
const systemCoT = `
Para cada problema técnico, siga EXATAMENTE este processo:

<processo>
  1. IDENTIFIQUE o problema real (não o sintoma)
  2. LISTE possíveis causas, da mais provável à menos provável
  3. DESCARTE causas com base nas informações disponíveis
  4. PROPONHA solução para a causa mais provável
  5. MENCIONE como confirmar se a solução funcionou
</processo>

Estruture sua resposta seguindo esses passos explicitamente.
`
```

## Controle de Formato de Saída

```typescript
// Para outputs estruturados sem tool use
const systemJSON = `
Responda SEMPRE em JSON válido, sem texto adicional, sem markdown, sem comentários.
Schema obrigatório:
{
  "summary": string (máx 100 palavras),
  "keyPoints": string[] (3-5 pontos),
  "sentiment": "positive" | "negative" | "neutral",
  "confidence": number (0-1)
}
`

// Para listas estruturadas
const systemLista = `
Responda sempre em formato de lista numerada.
Cada item deve ter: número, título em negrito, e explicação em 1-2 frases.
Exemplo:
1. **Título**: Explicação aqui.
`
```

---

# Padrões de Agentes com Claude

## Parallel Tool Calls

```typescript
// Claude pode chamar múltiplas ferramentas em paralelo quando não dependem entre si
const response = await anthropic.messages.create({
  model: 'claude-sonnet-4-6',
  max_tokens: 4096,
  tools: [weatherTool, stockTool, newsTool],
  messages: [{
    role: 'user',
    content: 'Me dê um briefing do dia: clima de SP, cotação do dólar, e principais notícias de tech.'
  }],
})

// Claude pode retornar tool_use para as 3 ferramentas simultaneamente
const toolCalls = response.content.filter(b => b.type === 'tool_use')
console.log('Chamadas paralelas:', toolCalls.length)  // pode ser 3

// Executar em paralelo (mais eficiente)
const results = await Promise.all(
  toolCalls.map(async (tool) => {
    if (tool.type !== 'tool_use') return null
    const result = await executeTool(tool.name, tool.input)
    return {
      type: 'tool_result' as const,
      tool_use_id: tool.id,
      content: JSON.stringify(result),
    }
  })
)
```

## Agente com Memória via Cache

```typescript
interface AgentState {
  systemContext: string
  history: Anthropic.MessageParam[]
}

class CachedAgent {
  private state: AgentState

  constructor(systemContext: string) {
    this.state = { systemContext, history: [] }
  }

  async chat(userMessage: string): Promise<string> {
    this.state.history.push({ role: 'user', content: userMessage })

    // Cachear o histórico completo — só o último turn é novo
    const messagesWithCache = this.state.history.map((msg, i) => {
      const isLast = i === this.state.history.length - 1
      if (!isLast) return msg

      // Marcar última mensagem para cache incremental
      return {
        ...msg,
        content: typeof msg.content === 'string'
          ? [{ type: 'text' as const, text: msg.content, cache_control: { type: 'ephemeral' as const } }]
          : msg.content,
      }
    })

    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-6',
      max_tokens: 2048,
      system: [
        {
          type: 'text',
          text: this.state.systemContext,
          cache_control: { type: 'ephemeral' },
        },
      ],
      messages: messagesWithCache,
    })

    const assistantText = response.content
      .filter(b => b.type === 'text')
      .map(b => b.type === 'text' ? b.text : '')
      .join('')

    this.state.history.push({ role: 'assistant', content: assistantText })
    return assistantText
  }
}
```


---

← [[README|Anthropic Claude API]]
