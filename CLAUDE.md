# 🧠 Segundo Cérebro — CLAUDE.md

Base de conhecimento técnico com 54 skills de desenvolvimento organizadas em 8 categorias.
Este vault é gerenciado com Claude Code. Leia este arquivo antes de qualquer ação.

---

## Estrutura do Vault

```
segundo-cerebro/
├── IA e APIs/           → Anthropic, OpenAI, Gemini, Asaas, Stripe, Multi Agentes
├── Backend/             → Node.js, FastAPI, PostgreSQL, Docker, Prisma, Security
│                           Evolution API, Baileys, Bunny.net
├── Frontend/            → Next.js 15, React 19, Vue 3, Tailwind v4, TypeScript
│                           HTML/CSS, Vite, shadcn/ui, Design System, Supabase
│                           Frontend Design, Boas Práticas
├── Animacoes/           → Animacoes Web (gsap)
├── Mobile/              → React Native + Expo
├── DevTools/            → Git + GitHub Actions, Zod, Figma, Code Review Graph
├── Design e Negocio/    → Classificação Tipográfica, Briefing Identidade Visual
└── Agentes/             → 17 agentes especializados (Debugger, DevOps, SEO, etc.)
```

## Anatomia de uma Skill

Cada skill segue exatamente esta estrutura — nunca alterar o padrão:

```
NomeDaSkill/
├── README.md          ← arquivo principal com frontmatter + conteúdo + links
└── Referencias/
    └── referencia.md  ← arquivos de apoio com link de volta ao README
```

Frontmatter obrigatório no `README.md`:
```yaml
---
tags: [backend]          ← tag da categoria (sem emoji, sem acento)
categoria: "Backend"  ← nome exato da pasta pai
---
```

Tags válidas: `ia-apis` `backend` `frontend` `animacoes` `mobile` `devtools` `design` `agentes`

## Convenções Obrigatórias

- Links internos sempre como wikilinks: `[[Nome da Skill]]`
- Nunca usar links markdown `[texto](caminho)` para notas internas
- Nomes de pasta e arquivo: sem acentos, sem caracteres especiais
- Seção `## Relacionado` com links para skills conectadas
- Seção `## Referencias` com links para subpastas quando existirem
- Nunca deletar o frontmatter `---` do início dos arquivos

## Como Adicionar uma Nova Skill

1. Criar pasta com nome limpo: `Backend/Nome da Skill/`
2. Criar `README.md` com frontmatter correto
3. Criar `Referencias/` se houver conteúdo de apoio
4. Adicionar o link no `README.md` raiz do vault na seção correta

## Como Atualizar uma Skill Existente

- Editar apenas o corpo do `README.md`, nunca o frontmatter
- Preservar as seções `## Relacionado` e `## Referencias`
- Adicionar novas referências em `Referencias/` se necessário

## Comandos Úteis no Terminal

```bash
# Buscar conteúdo dentro do vault
grep -r "palavra-chave" . --include="*.md"

# Listar todas as skills
find . -name "README.md" -not -path "./.obsidian/*" -not -path "./.claude/*"

# Ver skills de uma categoria
ls "Backend/"
```

## Documentação Automática de Projetos

Quando o Claude Code abre em qualquer projeto, ele deve:

### 1. Verificar docs existentes
```bash
ls .claude/docs/ 2>/dev/null
```
Se existirem arquivos `.md`, leia-os antes de começar.

### 2. Criar docs quando não existirem
Para sessões de trabalho significativo (feature, refactor, debug):
```bash
# Na pasta do projeto
bash ~/segundo-cerebro/scripts/novo-projeto.sh
```
Isso cria `.claude/docs/PROJETO.md` e `.claude/docs/ARQUITETURA.md` a partir dos templates.

### 3. Documentar durante o trabalho
| Situação | Onde documentar |
|---|---|
| Decisão arquitetural | `.claude/docs/decisions/YYYYMMDD-titulo.md` |
| Comportamento não óbvio | `.claude/docs/PROJETO.md` → seção Gotchas |
| Estrutura do código | `.claude/docs/ARQUITETURA.md` |
| Padrão do projeto | `.claude/docs/ARQUITETURA.md` |

---

## Skill Harvesting — Quando Criar uma Nova Skill

| Criar SKILL no vault se... | Criar DOC do projeto se... |
|---|---|
| Aprendeu sobre uma tech reusável | Específico desta codebase |
| Padrão de framework/biblioteca | Regra de negócio local |
| Integração com API/serviço externo | Configuração do ambiente local |
| Resolveu problema não documentado | Bug fix de versão específica |

### Como criar uma nova skill:
1. `cd ~/segundo-cerebro`
2. Crie a pasta: `mkdir -p "Backend/Nome da Skill/Referencias"`
3. Copie o template: `cp templates/skill/README.md "Backend/Nome da Skill/"`
4. Edite com frontmatter correto (tag + categoria)
5. Adicione o link no `README.md` raiz do vault
6. `bash setup.sh` para atualizar o Claude Code (é idempotente)

---

## Integração com Claude Code

Este vault usa **obsidian-skills** (`.claude/skills/`) para o Claude entender
a sintaxe específica do Obsidian: wikilinks, propriedades, callouts e canvas.

O hook em `~/.claude/hooks/segundo-cerebro.sh` (instalado pelo `setup.sh`) injeta
o contexto de docs do projeto no início de cada sessão automaticamente.
