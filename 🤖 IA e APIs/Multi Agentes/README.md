---
tags: [ia-apis]
categoria: "🤖 IA e APIs"
---

# Multi-Agentes — Arquitetura e Padrões

**Princípio:** Sistemas multi-agente permitem paralelismo, especialização e tarefas que excedem o contexto de um único agente. A complexidade é real — use apenas quando o ganho justificar o custo de coordenação.

---

## Quando Usar Multi-Agentes

**Use** quando a tarefa:
- É grande demais para um único contexto
- Tem subtarefas claramente independentes (paralelizáveis)
- Beneficia de múltiplas perspectivas/verificações independentes
- Requer especialistas diferentes (pesquisa + código + revisão)

**Não use** quando:
- Uma única chamada resolve o problema
- As subtarefas têm dependências fortes entre si
- O overhead de coordenação supera o ganho
- Precisão crítica — cada handoff é uma fonte de erro

---

## Padrões Fundamentais

### 1. Orquestrador + Subagentes

O padrão mais comum. Um agente central planeja e delega.

```
Usuário
   ↓
[Orquestrador]
   ├── subtarefa A → [Agente Pesquisa]  → resultado A
   ├── subtarefa B → [Agente Código]    → resultado B
   └── subtarefa C → [Agente Revisão]  → resultado C
   ↓
Síntese final
```

```python
# Pseudocódigo Python — Orquestrador com Claude
import anthropic

client = anthropic.Anthropic()

def orquestrador(tarefa: str) -> str:
    # 1. Planejar as subtarefas
    plano = client.messages.create(
        model="claude-opus-4-5",
        max_tokens=1000,
        system="""Você é um orquestrador. Analise a tarefa e divida em subtarefas
        independentes. Responda em JSON: {"subtarefas": [...]}""",
        messages=[{"role": "user", "content": tarefa}]
    )

    subtarefas = json.loads(plano.content[0].text)["subtarefas"]

    # 2. Executar subtarefas (paralelo com threads/async)
    resultados = []
    for sub in subtarefas:
        resultado = subagente_executor(sub)
        resultados.append(resultado)

    # 3. Sintetizar
    return sintetizador(tarefa, resultados)

def subagente_executor(subtarefa: str) -> str:
    response = client.messages.create(
        model="claude-sonnet-4-5",   # modelo mais barato para subtarefas
        max_tokens=2000,
        system="Você é um especialista. Execute a subtarefa com precisão.",
        messages=[{"role": "user", "content": subtarefa}]
    )
    return response.content[0].text
```

---

### 2. Pipeline Sequencial

Cada agente processa e passa para o próximo. Saída de um é entrada do outro.

```
[Agente 1: Coleta]
      ↓ dados brutos
[Agente 2: Análise]
      ↓ análise estruturada
[Agente 3: Formatação]
      ↓ relatório final
```

```typescript
// Pipeline com TypeScript
interface PipelineStep {
  name: string
  systemPrompt: string
  model?: string
}

async function runPipeline(
  input: string,
  steps: PipelineStep[]
): Promise<string> {
  let current = input

  for (const step of steps) {
    const response = await anthropic.messages.create({
      model: step.model ?? 'claude-sonnet-4-5',
      max_tokens: 2000,
      system: step.systemPrompt,
      messages: [{ role: 'user', content: current }],
    })
    current = response.content[0].type === 'text'
      ? response.content[0].text
      : current
    console.log(`✅ ${step.name} concluído`)
  }

  return current
}

// Uso:
const resultado = await runPipeline(textoBruto, [
  { name: 'Extração',  systemPrompt: 'Extraia os dados estruturados em JSON.' },
  { name: 'Validação', systemPrompt: 'Valide e corrija os dados. Responda com o JSON corrigido.' },
  { name: 'Relatório', systemPrompt: 'Gere um relatório executivo baseado nos dados.' },
])
```

---

### 3. Paralelo com Agregação

Múltiplos agentes trabalham simultaneamente, um agregador consolida.

```typescript
// Execução paralela com Promise.all
async function paralelismo(tarefa: string): Promise<string> {
  const perspectivas = [
    { role: 'Analista técnico',    foco: 'viabilidade e complexidade técnica' },
    { role: 'Analista de negócio', foco: 'ROI e impacto no negócio' },
    { role: 'Analista de risco',   foco: 'riscos e mitigações' },
  ]

  // Executar todos em paralelo
  const analises = await Promise.all(
    perspectivas.map(p =>
      anthropic.messages.create({
        model: 'claude-sonnet-4-5',
        max_tokens: 1500,
        system: `Você é um ${p.role}. Analise com foco em: ${p.foco}`,
        messages: [{ role: 'user', content: tarefa }],
      }).then(r => ({ perspectiva: p.role, analise: r.content[0].text }))
    )
  )

  // Agregar
  const agregador = await anthropic.messages.create({
    model: 'claude-opus-4-5',
    max_tokens: 2000,
    system: 'Sintetize as análises em uma recomendação coesa e equilibrada.',
    messages: [{
      role: 'user',
      content: `Análises recebidas:\n\n${analises.map(a =>
        `## ${a.perspectiva}\n${a.analise}`
      ).join('\n\n')}\n\nTarefa original: ${tarefa}`,
    }],
  })

  return agregador.content[0].text
}
```

---

### 4. Agente com Ferramentas (Tool Use)

Agente autônomo que decide quais ferramentas chamar.

```typescript
import Anthropic from '@anthropic-ai/sdk'

const client = new Anthropic()

// Definir ferramentas disponíveis
const tools: Anthropic.Tool[] = [
  {
    name: 'buscar_web',
    description: 'Busca informações na web sobre um tópico.',
    input_schema: {
      type: 'object' as const,
      properties: {
        query: { type: 'string', description: 'Termos de busca' },
      },
      required: ['query'],
    },
  },
  {
    name: 'executar_codigo',
    description: 'Executa código Python e retorna o resultado.',
    input_schema: {
      type: 'object' as const,
      properties: {
        codigo: { type: 'string', description: 'Código Python para executar' },
      },
      required: ['codigo'],
    },
  },
  {
    name: 'salvar_arquivo',
    description: 'Salva conteúdo em um arquivo.',
    input_schema: {
      type: 'object' as const,
      properties: {
        nome:      { type: 'string' },
        conteudo:  { type: 'string' },
      },
      required: ['nome', 'conteudo'],
    },
  },
]

// Loop agentico — agente decide quando parar
async function agenteAutonomo(objetivo: string): Promise<string> {
  const messages: Anthropic.MessageParam[] = [
    { role: 'user', content: objetivo }
  ]

  let iteracoes = 0
  const MAX_ITER = 10

  while (iteracoes < MAX_ITER) {
    iteracoes++

    const response = await client.messages.create({
      model: 'claude-opus-4-5',
      max_tokens: 4096,
      tools,
      messages,
      system: 'Complete o objetivo usando as ferramentas disponíveis. Quando terminar, responda com o resultado final.',
    })

    // Adicionar resposta do assistente ao histórico
    messages.push({ role: 'assistant', content: response.content })

    // Se parou naturalmente — tarefa concluída
    if (response.stop_reason === 'end_turn') {
      return response.content
        .filter(b => b.type === 'text')
        .map(b => b.text)
        .join('\n')
    }

    // Processar chamadas de ferramentas
    if (response.stop_reason === 'tool_use') {
      const toolResults: Anthropic.ToolResultBlockParam[] = []

      for (const block of response.content) {
        if (block.type !== 'tool_use') continue

        let resultado: string
        switch (block.name) {
          case 'buscar_web':
            resultado = await buscarWeb((block.input as any).query)
            break
          case 'executar_codigo':
            resultado = await executarCodigo((block.input as any).codigo)
            break
          case 'salvar_arquivo':
            resultado = await salvarArquivo((block.input as any).nome, (block.input as any).conteudo)
            break
          default:
            resultado = `Ferramenta desconhecida: ${block.name}`
        }

        toolResults.push({
          type: 'tool_result',
          tool_use_id: block.id,
          content: resultado,
        })
      }

      // Adicionar resultados ao histórico e continuar
      messages.push({ role: 'user', content: toolResults })
    }
  }

  return 'Limite de iterações atingido.'
}
```

---

### 5. Human-in-the-Loop (HITL)

Agente pausa para aprovação humana em decisões críticas.

```typescript
interface CheckpointResult {
  aprovado: boolean
  comentario?: string
}

async function agenteComAprovacao(tarefa: string): Promise<string> {
  // Fase 1: Planejamento (mostra ao humano antes de executar)
  const plano = await gerarPlano(tarefa)

  console.log('\n=== PLANO DO AGENTE ===')
  console.log(plano)
  console.log('======================\n')

  // Pausa para aprovação
  const aprovacao = await solicitarAprovacaoHumana(plano)

  if (!aprovacao.aprovado) {
    // Revisar com feedback humano
    return agenteComAprovacao(`${tarefa}\n\nFeedback do revisor: ${aprovacao.comentario}`)
  }

  // Fase 2: Execução com checkpoints
  const resultado = await executarComCheckpoints(plano, async (checkpoint) => {
    console.log(`\n⚠️ Checkpoint: ${checkpoint.descricao}`)
    console.log(`Ação que será tomada: ${checkpoint.acao}`)
    return solicitarAprovacaoHumana(checkpoint.acao)
  })

  return resultado
}
```

---

## Memória Compartilhada entre Agentes

```typescript
// Memória em arquivo compartilhado (simples, para Claude Code)
interface MemoriaCompartilhada {
  contexto:      string
  decisoes:      Array<{ agente: string; decisao: string; motivo: string }>
  artefatos:     Record<string, string>
  progresso:     Record<string, 'pendente' | 'em-progresso' | 'concluido' | 'erro'>
}

class GerenciadorMemoria {
  private arquivo = './.agentes/memoria.json'

  async ler(): Promise<MemoriaCompartilhada> {
    try {
      return JSON.parse(await fs.readFile(this.arquivo, 'utf8'))
    } catch {
      return { contexto: '', decisoes: [], artefatos: {}, progresso: {} }
    }
  }

  async escrever(memoria: MemoriaCompartilhada): Promise<void> {
    await fs.mkdir('./.agentes', { recursive: true })
    await fs.writeFile(this.arquivo, JSON.stringify(memoria, null, 2))
  }

  async registrarDecisao(agente: string, decisao: string, motivo: string): Promise<void> {
    const mem = await this.ler()
    mem.decisoes.push({ agente, decisao, motivo })
    await this.escrever(mem)
  }

  async salvarArtefato(nome: string, conteudo: string): Promise<void> {
    const mem = await this.ler()
    mem.artefatos[nome] = conteudo
    await this.escrever(mem)
  }
}

// Cada agente usa o gerenciador para coordinar
const memoria = new GerenciadorMemoria()
await memoria.registrarDecisao('agente-arquitetura', 'Usar PostgreSQL', 'Dados relacionais com joins complexos')
await memoria.salvarArtefato('schema.sql', schemaSql)
```

---

## Segurança em Sistemas Multi-Agente

```
⚠️ PRINCÍPIOS DE SEGURANÇA:

1. CONFIANÇA MÍNIMA — subagentes recebem apenas as permissões que precisam
2. VALIDAR INPUTS — nunca executar instruções de subagentes sem validação
3. PROMPT INJECTION — conteúdo externo pode conter instruções maliciosas
4. AUDITORIA — logar todas as ações de todos os agentes
5. LIMITES DE RECURSÃO — sempre definir MAX_ITERATIONS
6. REVERSIBILIDADE — preferir ações reversíveis; confirmar as irreversíveis
```

```typescript
// Validação de output de subagente antes de executar
function validarOutputSubagente(output: string, contextoEsperado: string): boolean {
  // 1. Não deve conter tentativas de escape/injection
  const padroesSuspeitos = [
    /ignore previous instructions/i,
    /system prompt/i,
    /\bsudo\b/,
    /rm -rf/,
    /DROP TABLE/i,
  ]
  if (padroesSuspeitos.some(p => p.test(output))) {
    console.error('⚠️ Output suspeito detectado no subagente')
    return false
  }

  // 2. Deve ser relevante ao contexto esperado
  // (verificação semântica simplificada)
  return true
}
```

---

## AGENTS.md — Documentação do Sistema

Todo projeto multi-agente deve ter um `AGENTS.md` na raiz:

```markdown
# AGENTS.md — Segundo Cérebro

## Visão Geral
Sistema de N agentes especializados para [objetivo].

## Agentes Disponíveis

### Orquestrador
- **Responsabilidade:** Planejamento e delegação
- **Modelo:** claude-opus-4-5
- **Memória:** Lê e escreve em `.agentes/memoria.json`
- **Ferramentas:** Criar subtarefas, registrar decisões

### Agente de Pesquisa
- **Responsabilidade:** Busca e síntese de informação
- **Modelo:** claude-sonnet-4-5
- **Memória:** Somente leitura
- **Ferramentas:** web_search, read_file

### Agente de Código
- **Responsabilidade:** Escrita e revisão de código
- **Modelo:** claude-sonnet-4-5
- **Ferramentas:** read_file, write_file, execute_code

## Regras de Coordenação
1. Nenhum agente modifica arquivos fora do seu escopo
2. Toda decisão importante é registrada na memória compartilhada
3. Agentes não chamam outros agentes diretamente — só via orquestrador
4. Human-in-the-loop obrigatório antes de: deploys, deleções, e-mails
```

---

## Referências

→ `references/frameworks-agentes.md` — LangChain, CrewAI, AutoGen, LangGraph, Magentic-One  
→ `references/padroes-avancados.md` — Reflexão, crítico-revisor, debate entre agentes, agente avaliador


---

## Relacionado

[[Anthropic Claude API]] | [[OpenAI API]] | [[Node.js]] | [[FastAPI Python]]


---

## Referencias

- [[Referencias/frameworks-agentes]]
- [[Referencias/padroes-avancados]]
