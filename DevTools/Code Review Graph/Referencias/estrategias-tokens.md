# Estratégias para Reduzir Tokens no Claude Code

## 1. CLAUDE.md bem estruturado (impacto imediato)

O `CLAUDE.md` na raiz é lido em toda sessão. Manter conciso e focado no que o Claude precisa saber — não repetir o que está no código.

```markdown
# CLAUDE.md

## Stack
Next.js 15 App Router + TypeScript + Prisma + PostgreSQL + Tailwind

## Convenções
- Componentes: `src/components/NomeComponente/index.tsx`
- Server Actions: `src/actions/nome-acao.ts`
- Rotas API: `src/app/api/recurso/route.ts`
- Tipos globais: `src/types/`

## Comandos úteis
- `npm run dev` — servidor dev
- `npm run db:migrate` — migrations Prisma
- `npm run test` — testes

## O que NÃO fazer
- Não usar `any` em TypeScript
- Não criar arquivos fora de `src/`
- Não commitar `.env`
```

**Evitar** no CLAUDE.md:
- Documentação extensa (vai para README)
- Código de exemplo longo
- Histórico de decisões antigas

---

## 2. Subpastas com CLAUDE.md locais

Para projetos grandes, criar `CLAUDE.md` em subpastas com contexto específico:

```
src/
  payments/
    CLAUDE.md    ← "Esta pasta usa Stripe. Sempre validar com Zod antes de processar."
  auth/
    CLAUDE.md    ← "JWT com refresh tokens. Nunca expor o secret."
```

O Claude lê o CLAUDE.md mais próximo do arquivo em que está trabalhando.

---

## 3. Ser específico nos prompts

```
# ❌ Caro em tokens (Claude lê o projeto todo para entender)
"Adiciona autenticação ao projeto"

# ✅ Econômico (Claude sabe exatamente onde atuar)
"Adiciona autenticação JWT em src/auth/middleware.ts,
usando o padrão que está em src/auth/utils.ts"
```

**Regra:** Quanto mais contexto no prompt, menos o Claude precisa buscar no projeto.

---

## 4. Usar `/compact` nos momentos certos

O Claude Code tem `/compact` para comprimir o histórico da conversa sem perder contexto.

- Usar após concluir uma tarefa grande antes de começar outra
- Usar quando o contador de tokens estiver alto
- Usar quando o contexto da conversa acumulou código que não é mais relevante

---

## 5. Referenciar arquivos diretamente

```
# ❌ Claude busca o arquivo
"Corrige o bug no formulário de login"

# ✅ Claude vai direto
"Corrige o bug em src/components/LoginForm/index.tsx linha 47
onde o email não está sendo validado antes do submit"
```

---

## 6. Usar `--allowedTools` para limitar escopo

No Claude Code, você pode limitar quais ferramentas o Claude usa:

```bash
# Permite apenas leitura, não escrita (para revisão)
claude --allowedTools "Read,Grep,Glob"

# Para tarefas específicas
claude --allowedTools "Read,Edit,Write" "corrige o bug no login"
```

---

## 7. `.gitignore` e `.claudeignore`

Criar `.claudeignore` para excluir arquivos que o Claude não precisa ver:

```
# .claudeignore
node_modules/
.next/
dist/
coverage/
*.lock
*.log
public/fonts/
public/images/
```

O Claude ignora esses arquivos ao explorar o projeto, reduzindo o contexto carregado.

---

## 8. Sessões com `/clear` estratégico

Cada sessão acumula tokens. Usar `/clear` para resetar:
- Após concluir uma feature inteira
- Quando trocar de contexto completamente (ex: de frontend para backend)
- Quando perceber que o Claude está "confuso" com contexto antigo

---

## 9. Resumo de impacto estimado

| Estratégia | Redução estimada | Esforço |
|---|---|---|
| code-review-graph (MCP) | 8–49× | Instalar 1 vez |
| CLAUDE.md bem estruturado | 2–3× | 30 min uma vez |
| Prompts específicos com paths | 1.5–2× | Hábito |
| `.claudeignore` | 1.2–1.5× | 10 min uma vez |
| CLAUDE.md em subpastas | 1.5–2× | Por módulo |
| `/compact` estratégico | 1.5–2× | Hábito |
| `/clear` entre tarefas | 1.2–1.5× | Hábito |


---

← [[README|Code Review Graph]]
