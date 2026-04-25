# Segundo Cérebro

Base de conhecimento técnico integrada ao **Claude Code** e ao **Obsidian**.
O Claude consulta este vault automaticamente em qualquer projeto, funcionando como memória técnica persistente.

> **54 skills · 8 categorias · 17 agentes especializados**

---

## O que é

Um vault Obsidian com skills técnicas organizadas por categoria, integrado ao Claude Code de forma **dinâmica e autoalimentada**:

- Ao abrir qualquer projeto, o Claude verifica se há documentação em `.claude/docs/` e lê ela antes de começar
- Durante o trabalho, Claude documenta decisões, arquitetura e gotchas diretamente no projeto
- Quando aprende algo reusável (lib, padrão, API), ele cria uma nova skill no vault
- O vault cresce automaticamente com o que você e o Claude descobrem juntos

Cada skill tem:
- Guia de uso e melhores práticas
- Exemplos prontos para copiar
- Links cruzados com skills relacionadas

---

## Pré-requisitos

| Ferramenta | Link | Obrigatório |
|---|---|---|
| Claude Code | [claude.ai/code](https://claude.ai/code) | Sim |
| Git | [git-scm.com](https://git-scm.com) | Sim |
| Obsidian | [obsidian.md](https://obsidian.md) | Opcional (para visualizar o vault) |

---

## Instalação

### macOS / Linux

```bash
# Clone em qualquer pasta de sua preferência
git clone https://github.com/sostenescrisleyy/segundo-cerebro.git ~/segundo-cerebro
cd ~/segundo-cerebro
bash setup.sh
```

### Windows (PowerShell)

```powershell
# Clone em qualquer pasta de sua preferência
git clone https://github.com/sostenescrisleyy/segundo-cerebro.git "$env:USERPROFILE\segundo-cerebro"
cd "$env:USERPROFILE\segundo-cerebro"

# Permitir execução de scripts (apenas na primeira vez)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

.\setup.ps1
```

O script detecta automaticamente o caminho onde o repositório foi clonado — **não precisa clonar em um lugar específico**.

---

## O que o setup faz

- Registra todas as skills no `~/.claude/CLAUDE.md` (global do Claude Code)
- Instala um hook em `~/.claude/hooks/` que injeta o contexto de docs do projeto no início de cada sessão
- Atualiza `~/.claude/settings.json` para ativar o hook automaticamente

O script é **idempotente** — pode ser rodado mais de uma vez sem duplicar configurações.

---

## Desfazer

```bash
# macOS / Linux
bash setup.sh --uninstall

# Windows
.\setup.ps1 -Uninstall
```

---

## Usar com o Obsidian

1. Abra o Obsidian
2. Clique em **Open folder as vault**
3. Selecione a pasta onde clonou este repositório
4. O vault abre com o grafo de conhecimento já configurado (tags coloridas por categoria)

---

## Estrutura de Skills

```
segundo-cerebro/
├── IA e APIs/           Anthropic, OpenAI, Gemini, Stripe, Asaas, Multi Agentes
├── Backend/             Node.js, FastAPI, PostgreSQL, Docker, Prisma
│                        Evolution API, Baileys, Bunny.net, Segurança
├── Frontend/            Next.js 15, React 19, Vue 3, Tailwind v4, TypeScript
│                        HTML/CSS, Vite, shadcn/ui, Supabase, Design System
├── Animacoes/           Animacoes Web (gsap)
├── Mobile/              React Native + Expo
├── DevTools/            Git + GitHub Actions, Zod, Figma, Code Review Graph
├── Design e Negocio/    Classificação Tipográfica, Briefing / Identidade Visual
├── Agentes/             17 agentes especializados (ver abaixo)
├── templates/           Templates para docs de projeto e novas skills
└── scripts/             Scripts utilitários (bootstrap de projeto)
```

---

## Skills por Categoria

### IA e APIs
- [Anthropic Claude API](IA%20e%20APIs/Anthropic%20Claude%20API/README.md)
- [OpenAI API](IA%20e%20APIs/OpenAI%20API/README.md)
- [Google Gemini API](IA%20e%20APIs/Google%20Gemini%20API/README.md)
- [Multi Agentes](IA%20e%20APIs/Multi%20Agentes/README.md)
- [Stripe Pagamentos](IA%20e%20APIs/Stripe%20Pagamentos/README.md)
- [Asaas Pagamentos](IA%20e%20APIs/Asaas%20Pagamentos/README.md)

### Backend
- [Node.js](Backend/Node.js/README.md)
- [FastAPI Python](Backend/FastAPI%20Python/README.md)
- [PostgreSQL](Backend/PostgreSQL/README.md)
- [Docker e Compose](Backend/Docker%20e%20Compose/README.md)
- [Prisma ORM](Backend/Prisma%20ORM/README.md)
- [Backend Security](Backend/Backend%20Security/README.md)
- [Evolution API WhatsApp](Backend/Evolution%20API%20WhatsApp/README.md)
- [Baileys WhatsApp SDK](Backend/Baileys%20WhatsApp%20SDK/README.md)
- [Bunny.net CDN](Backend/Bunny.net%20CDN/README.md)

### Frontend
- [Next.js 15](Frontend/Next.js%2015/README.md)
- [React 19](Frontend/React%2019/README.md)
- [Vue 3 e Nuxt](Frontend/Vue%203%20e%20Nuxt/README.md)
- [TypeScript](Frontend/TypeScript/README.md)
- [Tailwind CSS v4](Frontend/Tailwind%20CSS%20v4/README.md)
- [shadcn/ui](Frontend/shadcn%20ui/README.md)
- [Supabase](Frontend/Supabase/README.md)
- [Vite](Frontend/Vite/README.md)
- [HTML e CSS](Frontend/HTML%20e%20CSS/README.md)
- [Frontend Boas Práticas](Frontend/Frontend%20Boas%20Praticas/README.md)
- [Frontend Design System](Frontend/Frontend%20Design%20System/README.md)
- [Frontend Design](Frontend/Frontend%20Design/README.md)

### Animacoes
- [Animacoes Web](Animacoes/Animacoes%20Web/README.md)

### Mobile
- [React Native + Expo](Mobile/React%20Native%20Expo/README.md)

### DevTools
- [Git e GitHub Actions](DevTools/Git%20e%20GitHub%20Actions/README.md)
- [Zod Validação](DevTools/Zod%20Validacao/README.md)
- [Figma para Devs](DevTools/Figma%20para%20Devs/README.md)
- [Code Review Graph](DevTools/Code%20Review%20Graph/README.md)

### Design e Negocio
- [Classificação Tipográfica](Design%20e%20Negocio/Classificacao%20Tipografica/README.md)
- [Briefing Identidade Visual](Design%20e%20Negocio/Briefing%20Identidade%20Visual/README.md)

### Agentes
| Agente | Função |
|---|---|
| [Orquestrador](Agentes/Orquestrador/README.md) | Coordena múltiplos agentes em tarefas complexas |
| [Explorador de Codebase](Agentes/Explorador%20de%20Codebase/README.md) | Mapeia e documenta codebases desconhecidas |
| [Planejador de Projeto](Agentes/Planejador%20de%20Projeto/README.md) | Quebra requisitos em tarefas executáveis |
| [Arqueologista de Codigo](Agentes/Arqueologista%20de%20Codigo/README.md) | Analisa histórico e arqueologia de código legado |
| [Arquiteto de Banco](Agentes/Arquiteto%20de%20Banco/README.md) | Design de schemas e otimização de banco |
| [Auditor de Seguranca](Agentes/Auditor%20de%20Seguranca/README.md) | Auditoria de segurança e autenticação |
| [Auditoria IA](Agentes/Auditoria%20IA/README.md) | Revisão de código gerado por IA |
| [Debugger](Agentes/Debugger/README.md) | Diagnóstico e resolução de bugs |
| [DevOps Engineer](Agentes/DevOps%20Engineer/README.md) | Deploy, infraestrutura e CI/CD |
| [Documentacao](Agentes/Documentacao/README.md) | Geração de documentação técnica |
| [Engenheiro de Testes](Agentes/Engenheiro%20de%20Testes/README.md) | Estratégia de testes e cobertura |
| [Game Developer](Agentes/Game%20Developer/README.md) | Desenvolvimento de jogos |
| [Hostinger Email](Agentes/Hostinger%20Email/README.md) | Configuração de e-mail Hostinger |
| [Performance Imagens](Agentes/Performance%20Imagens/README.md) | Otimização de imagens e CDN |
| [Performance Web](Agentes/Performance%20Web/README.md) | Core Web Vitals e otimização |
| [Product Manager](Agentes/Product%20Manager/README.md) | Requisitos e gestão de produto |
| [SEO Specialist](Agentes/SEO%20Specialist/README.md) | SEO técnico e meta tags |

---

## Documentação por Projeto

Ao começar a trabalhar em qualquer projeto com o Claude Code, execute uma vez:

```bash
# macOS / Linux — dentro da pasta do projeto
bash ~/segundo-cerebro/scripts/novo-projeto.sh
```

Isso cria `.claude/docs/PROJETO.md` e `.claude/docs/ARQUITETURA.md` a partir dos templates. Depois peça ao Claude:

> "Analise o projeto e preencha os arquivos em .claude/docs/"

A partir daí, o Claude atualiza os docs automaticamente durante o trabalho.

---

## Adicionar uma Nova Skill

1. Crie a pasta dentro da categoria correta: `Backend/Nome da Skill/`
2. Crie o `README.md` com o frontmatter obrigatório:

```yaml
---
tags: [backend]
categoria: "Backend"
---
```

3. Adicione o link na seção correspondente deste README
4. Rode `bash setup.sh` para atualizar o Claude Code (é idempotente)

Tags válidas: `ia-apis` `backend` `frontend` `animacoes` `mobile` `devtools` `design` `agentes`

---

## Atualizar o Vault após Pull

```bash
# macOS / Linux
bash setup.sh

# Windows
.\setup.ps1
```

---

## Licença

Uso pessoal e educacional livre.
