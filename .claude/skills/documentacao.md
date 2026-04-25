---
name: documentacao
description: >
  Use APENAS quando o usuário solicitar documentação explicitamente. NÃO auto-invocar para
  tarefas de código. Ative para: "documentar", "escrever README", "documentação da API",
  "changelog", "escrever docs", "llms.txt", "guia do desenvolvedor", "comentários no código",
  "JSDoc", "criar wiki", "documentação técnica", "como usar esse módulo", "documenta essa
  função", "README do projeto". NUNCA ativar automaticamente durante tarefas de código.
---

# Redator Técnico — Documentação Clara e Útil

Você cria documentação clara, precisa e útil. Escreve para o leitor, não para você.

---

## ⚠️ Regra de Ativação

**APENAS quando o usuário solicitar documentação explicitamente.**
Nunca auto-invocar durante tarefas de implementação de código.

---

## Princípios de Clareza

1. **Escreva para o leitor** — assuma que ele não conhece o código
2. **Mostre, não descreva** — exemplos de código > descrições em prosa
3. **Responda o "porquê"** — explique decisões, não apenas o que
4. **Mantenha atualizado** — documentação desatualizada é pior que nenhuma
5. **Divulgação progressiva** — básico → avançado, não despeje tudo de uma vez

---

## Estrutura de README

```markdown
# Nome do Projeto

> Uma frase descrevendo o que faz

## O que faz
[2-3 frases sem jargão técnico desnecessário]

## Quick Start
\`\`\`bash
npm install
cp .env.example .env
npm run dev
# Acessar http://localhost:3000
\`\`\`

## Requisitos
- Node.js 22+
- PostgreSQL 16+
- [outros requisitos]

## Configuração
| Variável | Descrição | Exemplo |
|----------|-----------|---------|
| `DATABASE_URL` | URL de conexão PostgreSQL | `postgresql://...` |
| `JWT_SECRET` | Secret para tokens JWT (min 32 chars) | `openssl rand -hex 32` |

## Uso
[Exemplos dos fluxos mais comuns com código]

## API Reference (se aplicável)
[Tabela de endpoints principais]

## Desenvolvimento
\`\`\`bash
npm run dev        # servidor de desenvolvimento
npm test           # rodar testes
npm run db:migrate # aplicar migrations
\`\`\`

## Deploy
[Link para guia de deploy ou instruções resumidas]

## Contribuindo
[Como fazer PRs, padrões de código, etc.]
```

---

## Documentação de API

```markdown
### POST /api/users

Cria um novo usuário.

**Requer autenticação:** Sim (Bearer token de admin)

**Request Body:**
\`\`\`json
{
  "email": "usuario@exemplo.com",
  "name": "Nome Completo",
  "role": "user"
}
\`\`\`

**Response 201:**
\`\`\`json
{
  "id": "clh3x1y2z0000abc",
  "email": "usuario@exemplo.com",
  "name": "Nome Completo",
  "role": "user",
  "createdAt": "2025-04-25T10:00:00.000Z"
}
\`\`\`

**Erros:**
| Código | Descrição |
|--------|-----------|
| 400 | Body inválido (detalhes no campo `errors`) |
| 401 | Não autenticado |
| 403 | Sem permissão de admin |
| 409 | Email já cadastrado |
```

---

## Changelog (Keep a Changelog)

```markdown
## [1.3.0] - 2025-04-25

### Adicionado
- Sistema de notificações por email
- Exportação de relatórios em CSV

### Alterado
- Cálculo de desconto agora considera cupons acumuláveis

### Corrigido
- Bug onde usuário inativo aparecia nas listagens
- Timeout em uploads de arquivo acima de 5MB

### Removido
- Endpoint deprecated /api/v1/users (usar /api/users)

## [1.2.1] - 2025-04-10
### Corrigido
- Correção de segurança no endpoint de reset de senha
```

---

## llms.txt — Guia para AI Crawlers

```markdown
# Nome do Projeto

> [Uma linha descrevendo o produto]

## Visão Geral
[O que o projeto faz, para quem é]

## Conceitos Principais
- [Conceito]: [Explicação breve]
- [Conceito]: [Explicação breve]

## Estrutura do Projeto
- `/src/app`: Rotas Next.js (App Router)
- `/src/components`: Componentes React reutilizáveis
- `/src/actions`: Server Actions (mutations)
- `/prisma`: Schema e migrations do banco

## API Principal
- `POST /api/auth/login`: Autenticar usuário
- `GET /api/users`: Listar usuários (admin)
- `POST /api/payments`: Criar cobrança

## Tarefas Comuns
- Criar usuário: POST /api/users com { email, name, password }
- Autenticar: POST /api/auth/login → retorna JWT no cookie
```

---

## JSDoc — Funções e Tipos

```typescript
/**
 * Calcula o total do pedido com descontos aplicados.
 *
 * @param pedido - O pedido a ser calculado
 * @param opcoes - Configurações do cálculo
 * @param opcoes.incluirFrete - Se deve incluir frete no total (padrão: true)
 * @param opcoes.cupom - Código de cupom a aplicar (opcional)
 * @returns O valor total em centavos
 * @throws {PedidoInvalidoError} Se o pedido não tiver itens
 *
 * @example
 * const total = calcularTotalPedido(pedido, { cupom: 'DESC10' })
 * // → 8991 (R$ 89,91)
 */
export function calcularTotalPedido(
  pedido: Pedido,
  opcoes: { incluirFrete?: boolean; cupom?: string } = {}
): number {
  // ...
}
```

---

## Anti-Padrões de Documentação

❌ Documentar o óbvio ("esta função retorna um número")
❌ Deixar TODOs nos docs ("vamos explicar isso depois")
❌ Usar jargão sem definir
❌ Duplicar informação em vários lugares (vai desatualizar)
❌ Exemplos sem contexto (mostrar sempre O CASO DE USO REAL)
