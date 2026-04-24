# 🧠 Segundo Cérebro — CLAUDE.md

Base de conhecimento técnico com 34 skills de desenvolvimento organizadas em 7 categorias.
Este vault é gerenciado com Claude Code. Leia este arquivo antes de qualquer ação.

---

## Estrutura do Vault

```
segundo-cerebro/
├── 🤖 IA e APIs/        → Anthropic, OpenAI, Gemini, Asaas, Stripe, Multi Agentes
├── ⚙️ Backend/           → Node.js, FastAPI, PostgreSQL, Docker, Prisma, Security
│                           Evolution API, Baileys, Bunny.net
├── 🎨 Frontend/          → Next.js 15, React 19, Vue 3, Tailwind v4, TypeScript
│                           HTML/CSS, Vite, shadcn/ui, Design System, Supabase
│                           Frontend Design, Boas Práticas
├── ✨ Animacoes/         → GSAP
├── 📱 Mobile/            → React Native + Expo
├── 🛠️ DevTools/          → Git + GitHub Actions, Zod, Figma, Code Review Graph
└── 🎯 Design e Negocio/  → Classificação Tipográfica, Briefing Identidade Visual
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
categoria: "⚙️ Backend"  ← nome exato da pasta pai
---
```

Tags válidas: `ia-apis` `backend` `frontend` `animacoes` `mobile` `devtools` `design`

## Convenções Obrigatórias

- Links internos sempre como wikilinks: `[[Nome da Skill]]`
- Nunca usar links markdown `[texto](caminho)` para notas internas
- Nomes de pasta e arquivo: sem acentos, sem caracteres especiais
- Seção `## Relacionado` com links para skills conectadas
- Seção `## Referencias` com links para subpastas quando existirem
- Nunca deletar o frontmatter `---` do início dos arquivos

## Como Adicionar uma Nova Skill

1. Criar pasta com nome limpo: `⚙️ Backend/Nome da Skill/`
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
ls "⚙️ Backend/"
```

## Integração com Claude Code

Este vault usa **obsidian-skills** (`.claude/skills/`) para o Claude entender
a sintaxe específica do Obsidian: wikilinks, propriedades, callouts e canvas.

Para usar o Code Review Graph neste vault:
```bash
code-review-graph visualize --format obsidian
```
Isso exporta o grafo do seu projeto de código diretamente para um vault Obsidian.
