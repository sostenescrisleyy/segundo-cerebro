---
tags: [devtools]
categoria: "🛠️ DevTools"
---

# code-review-graph — Redução de Tokens no Claude Code

**Repo:** github.com/tirth8205/code-review-graph  
**Install:** `pip install code-review-graph`  
**Resultado:** 8.2× menos tokens em média (até 49× em monorepos)

**O problema:** O Claude Code re-lê o codebase inteiro a cada tarefa.  
**A solução:** Um grafo estrutural persistente que retorna apenas os arquivos relevantes via MCP.

---

## Como Funciona

```
Codebase → Tree-sitter Parser → Grafo SQLite (nós + arestas)
                                        ↓
Mudança no arquivo → Blast-radius analysis → Contexto mínimo para o Claude
```

O grafo mapeia **funções, classes, imports, call sites e herança** de 23 linguagens. Quando um arquivo muda, traça todos os callers, dependentes e testes afetados — o Claude lê apenas esse conjunto mínimo.

**Atualização incremental:** re-indexa só os arquivos alterados via SHA-256 diff. Um projeto de 2.900 arquivos atualiza em menos de 2 segundos.

---

## Instalação e Setup

```bash
# 1. Instalar
pip install code-review-graph
# ou com pipx (recomendado para isolamento):
pipx install code-review-graph

# 2. Auto-configurar para todos os editores detectados
code-review-graph install

# Ou para um editor específico:
code-review-graph install --platform claude-code
code-review-graph install --platform cursor
code-review-graph install --platform codex

# 3. Indexar o projeto (primeira vez ~10s para 500 arquivos)
cd seu-projeto/
code-review-graph build

# 4. Reiniciar o editor após instalar
```

> **Requer:** Python 3.10+ e [uv](https://docs.astral.sh/uv/) (recomendado — o config MCP usa `uvx` automaticamente se disponível).

---

## Uso no Claude Code

Após o setup, usar via slash commands:

```
/code-review-graph:build-graph       → Construir ou reconstruir o grafo
/code-review-graph:review-delta      → Revisar mudanças desde o último commit
/code-review-graph:review-pr         → Review completo com blast-radius
```

Ou simplesmente dizer ao Claude:
```
Build the code review graph for this project
```

O Claude passa a usar os 28 MCP tools automaticamente para buscar contexto mínimo em vez de ler tudo.

---

## MCP Tools Essenciais (o Claude usa automaticamente)

| Tool | Para que serve | Tokens economizados |
|---|---|---|
| `get_minimal_context_tool` | Contexto ultra-compacto (~100 tokens) — chamar primeiro | ★★★★★ |
| `get_impact_radius_tool` | Quais arquivos são afetados por uma mudança | ★★★★★ |
| `get_review_context_tool` | Contexto otimizado para code review | ★★★★ |
| `query_graph_tool` | Callers, callees, testes, imports de um símbolo | ★★★★ |
| `detect_changes_tool` | Análise de risco de mudanças com score | ★★★ |
| `semantic_search_nodes_tool` | Busca semântica de entidades no código | ★★★ |
| `traverse_graph_tool` | BFS/DFS a partir de qualquer nó com budget de tokens | ★★★ |
| `get_architecture_overview_tool` | Visão geral de arquitetura por comunidades | ★★ |
| `get_knowledge_gaps_tool` | Nós isolados, hotspots sem teste, pontos fracos | ★★ |

---

## CLI — Comandos do Dia a Dia

```bash
# Construção e atualização
code-review-graph build             # indexar tudo (primeira vez)
code-review-graph update            # atualização incremental (arquivos alterados)
code-review-graph watch             # modo contínuo — atualiza ao salvar

# Informação
code-review-graph status            # estatísticas do grafo

# Visualização e export
code-review-graph visualize                      # HTML interativo (D3.js)
code-review-graph visualize --format obsidian    # exportar vault Obsidian com wikilinks
code-review-graph visualize --format graphml     # exportar para Gephi/yEd
code-review-graph visualize --format svg         # imagem estática
code-review-graph visualize --format cypher      # Neo4j

# Análise
code-review-graph detect-changes    # análise de risco com score
code-review-graph wiki              # gerar wiki markdown das comunidades

# Benchmark
code-review-graph eval --all        # medir tokens naive vs grafo
```

---

## Benchmarks Reais

| Repositório | Tokens sem grafo | Tokens com grafo | Redução |
|---|---|---|---|
| FastAPI | 4.944 | 614 | **8.1×** |
| Flask | 44.751 | 4.252 | **9.1×** |
| Gin (Go) | 21.972 | 1.153 | **16.4×** |
| httpx | 12.044 | 1.728 | **6.9×** |
| Next.js | 9.882 | 1.249 | **8.0×** |
| **Média** | — | — | **8.2×** |
| Monorepo Next.js | 27.732 arquivos | ~15 arquivos lidos | **49×** |

**Recall de impacto: 100%** — o grafo nunca deixa de detectar um arquivo afetado. Pode ter falsos positivos (conservador), mas nunca falsos negativos.

---

## Configurar Exclusões

Criar `.code-review-graphignore` na raiz do projeto:

```
# Ignorar arquivos gerados
generated/**
*.generated.ts
*.pb.go

# Dependências externas
vendor/**
node_modules/**

# Build outputs
dist/**
.next/**
__pycache__/**
```

> Em repos Git, arquivos do `.gitignore` já são excluídos automaticamente (usa `git ls-files`). O `.code-review-graphignore` serve para excluir arquivos *rastreados* pelo Git que não são relevantes para análise.

---

## Dependências Opcionais

```bash
# Embeddings locais (sentence-transformers) — busca semântica local
pip install code-review-graph[embeddings]

# Embeddings Google Gemini
pip install code-review-graph[google-embeddings]

# Detecção de comunidades (algoritmo Leiden via igraph)
pip install code-review-graph[communities]

# Benchmarks e gráficos de comparação
pip install code-review-graph[eval]

# Geração de wiki com LLM (via Ollama)
pip install code-review-graph[wiki]

# Tudo de uma vez
pip install code-review-graph[all]
```

---

## Linguagens Suportadas (23 + Notebooks)

**Web:** TypeScript/TSX, JavaScript, Vue, Svelte, PHP, Solidity  
**Backend:** Python, Go, Rust, Java, Scala, C#, Ruby, Kotlin  
**Systems:** C, C++, Zig, PowerShell  
**Mobile:** Swift, Dart  
**Scripting:** R, Perl, Lua, Julia  
**Notebooks:** Jupyter/Databricks `.ipynb` (Python, R, SQL multi-linguagem)

---

## Quando o Grafo NÃO Ajuda

- **Mudanças em arquivo único pequeno:** para arquivos simples em projetos pequenos, o contexto do grafo pode ser maior que o arquivo em si (veja benchmark do Express: 0.7×)
- **Projetos com < 50 arquivos:** o overhead de metadados não compensa
- **Primeiros 10 segundos:** o build inicial indexa tudo; o ganho começa nas consultas seguintes

---

## Referências

→ `references/mcp-config.md` — Configuração manual do MCP para Claude Code e Cursor  
→ `references/estrategias-tokens.md` — Estratégias além do grafo para reduzir custo de tokens


---

## Relacionado

[[Git e GitHub Actions]] | [[Multi Agentes]] | [[Node.js]] | [[TypeScript]]


---

## Referencias

- [[Referencias/mcp-config]]
- [[Referencias/estrategias-tokens]]
