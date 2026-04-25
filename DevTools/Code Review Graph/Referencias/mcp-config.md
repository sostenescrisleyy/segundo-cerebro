# Configuração Manual do MCP

## Claude Code — `.mcp.json`

O comando `code-review-graph install --platform claude-code` gera isso automaticamente.
Para configurar manualmente, criar `.mcp.json` na raiz do projeto:

```json
{
  "mcpServers": {
    "code-review-graph": {
      "command": "uvx",
      "args": ["code-review-graph", "serve"],
      "env": {}
    }
  }
}
```

Se não tiver `uv` instalado:
```json
{
  "mcpServers": {
    "code-review-graph": {
      "command": "code-review-graph",
      "args": ["serve"],
      "env": {}
    }
  }
}
```

## Cursor — `.cursor/mcp.json`

```json
{
  "mcpServers": {
    "code-review-graph": {
      "command": "uvx",
      "args": ["code-review-graph", "serve"]
    }
  }
}
```

## CLAUDE.md — Instruções para o Claude usar o grafo

O `code-review-graph install` injeta instruções no `CLAUDE.md` do projeto.
Conteúdo injetado (pode editar manualmente):

```markdown
## Code Review Graph

This project uses code-review-graph for token-efficient code analysis.

### When to use the graph
- Before reviewing any code change: call `get_minimal_context_tool` first
- When asked about impact of a change: use `get_impact_radius_tool`
- When reviewing a PR or diff: use `get_review_context_tool`
- When searching for a function/class: use `semantic_search_nodes_tool`

### Key principle
Always call `get_minimal_context_tool` before reading files directly.
The graph returns only what matters — reading full files is the fallback.
```

## Verificar se o MCP está funcionando

No Claude Code, após reiniciar:
```
/mcp                          → listar MCPs conectados
/code-review-graph:build-graph → deve executar sem erro
```

Se não aparecer, verificar:
1. `code-review-graph status` no terminal (garante que o binário funciona)
2. Reiniciar completamente o editor (não só a janela)
3. Verificar se o `.mcp.json` está na raiz do projeto (não em subpasta)


---

← [[README|Code Review Graph]]
