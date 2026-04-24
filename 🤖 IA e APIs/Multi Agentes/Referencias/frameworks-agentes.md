# Frameworks de Agentes — Comparativo

## CrewAI — Agentes com Papéis e Objetivos

```python
from crewai import Agent, Task, Crew, Process

# Definir agentes com personalidade e ferramentas
pesquisador = Agent(
    role='Analista de Mercado',
    goal='Coletar dados precisos e atualizados sobre o mercado',
    backstory='Especialista com 10 anos em análise de tendências',
    tools=[search_tool, scrape_tool],
    llm='claude-opus-4-5',
    verbose=True,
)

redator = Agent(
    role='Redator Técnico',
    goal='Transformar dados em relatórios claros e acionáveis',
    backstory='Comunicador especializado em transformar dados complexos',
    llm='claude-sonnet-4-5',
)

# Tarefas encadeadas
tarefa_pesquisa = Task(
    description='Pesquise as principais tendências de {topico} nos últimos 6 meses',
    expected_output='Lista com 10 tendências com dados e fontes',
    agent=pesquisador,
)

tarefa_relatorio = Task(
    description='Crie um relatório executivo baseado na pesquisa',
    expected_output='Relatório de 2 páginas com introdução, análise e recomendações',
    agent=redator,
    context=[tarefa_pesquisa],  # depende da tarefa anterior
)

# Crew com processo hierárquico
crew = Crew(
    agents=[pesquisador, redator],
    tasks=[tarefa_pesquisa, tarefa_relatorio],
    process=Process.hierarchical,
    manager_llm='claude-opus-4-5',
    verbose=True,
)

resultado = crew.kickoff(inputs={'topico': 'inteligência artificial no varejo'})
```

---

## LangGraph — Workflows com Estado

```python
from langgraph.graph import StateGraph, END
from typing import TypedDict, List

class EstadoWorkflow(TypedDict):
    mensagens: List[dict]
    pesquisa:  str
    rascunho:  str
    aprovado:  bool

def agente_pesquisa(estado: EstadoWorkflow) -> dict:
    # Executar pesquisa
    resultado_pesquisa = fazer_pesquisa(estado['mensagens'][-1]['content'])
    return {'pesquisa': resultado_pesquisa}

def agente_escrita(estado: EstadoWorkflow) -> dict:
    rascunho = escrever_com_pesquisa(estado['pesquisa'])
    return {'rascunho': rascunho}

def revisor_humano(estado: EstadoWorkflow) -> dict:
    print(f"\nRascunho:\n{estado['rascunho']}")
    aprovado = input("Aprovado? (s/n): ").lower() == 's'
    return {'aprovado': aprovado}

def rota_apos_revisao(estado: EstadoWorkflow) -> str:
    return END if estado['aprovado'] else 'agente_escrita'

# Construir grafo
grafo = StateGraph(EstadoWorkflow)
grafo.add_node('pesquisa', agente_pesquisa)
grafo.add_node('escrita',  agente_escrita)
grafo.add_node('revisao',  revisor_humano)

grafo.set_entry_point('pesquisa')
grafo.add_edge('pesquisa', 'escrita')
grafo.add_edge('escrita', 'revisao')
grafo.add_conditional_edges('revisao', rota_apos_revisao)

app = grafo.compile()
resultado = app.invoke({'mensagens': [{'content': 'Escreva sobre IA em 2025'}]})
```

---

## Comparativo Rápido

| Framework | Melhor para | Complexidade | Observação |
|---|---|---|---|
| **CrewAI** | Equipes de agentes com papéis | Média | Alto nível, fácil de começar |
| **LangGraph** | Workflows complexos com estado | Alta | Controle granular de fluxo |
| **AutoGen** | Conversas multi-agente | Média | Microsoft, bom para debate |
| **LangChain** | Pipelines com ferramentas | Alta | Muito flexível, verboso |
| **Sem framework** | Controle total, código simples | Baixa | Direto com SDK Anthropic |

**Recomendação:** Começar sem framework (SDK direto) → adicionar LangGraph se precisar de state management complexo → usar CrewAI se precisar de abstração de "times de agentes".


---

← [[README|Multi Agentes]]
