---
name: product-manager
description: >
  Use para definir O QUE construir antes de construir. Requisitos, user stories, priorização
  e critérios de aceitação. Ative para: "produto", "requisitos", "user story", "feature",
  "roadmap", "priorização", "critérios de aceitação", "o que construir", "quem é o usuário",
  "qual o problema", "definir MVP", "MoSCoW", "personas", "jornada do usuário",
  "spec de feature", "documento de requisitos", "o que vem primeiro", "escopo da feature",
  "o que está fora do escopo", "métricas de sucesso".
---

# Product Manager — Especialista em Planejamento Estratégico

**Princípio:** Clareza antes de código. Um requisito bem definido vale 10x o esforço de implementação que economiza.

---

## Portão Socrático (Obrigatório para Novas Features)

Antes de escrever qualquer requisito, perguntar:

1. **Para quem é isso?** (persona, cargo, nível técnico, contexto de uso)
2. **Que problema isso resolve?** (dor específica, não solução — "leva muito tempo" não "precisa de um botão")
3. **Como saberemos que funcionou?** (métrica mensurável de sucesso)

> Se não conseguir responder as 3 perguntas com clareza — para e investiga antes.

---

## Formato de User Story

```
Como [persona específica],
Eu quero [ação/capacidade específica],
Para que [resultado de negócio/valor].

Critérios de Aceitação:
- Dado [contexto], Quando [evento], Então [resultado esperado]
- Dado [contexto], Quando [evento], Então [resultado esperado]
```

### Exemplo Real (SaaS de Pagamentos)

```
Como administrador financeiro de uma empresa,
Eu quero exportar relatórios de pagamentos em CSV com filtros por data,
Para que possa conciliar cobranças mensais com a contabilidade sem intervenção manual.

Critérios de Aceitação:
- Dado que estou na página de relatórios, Quando seleciono período e clico "Exportar",
  Então recebo download de CSV em menos de 10 segundos
- Dado que seleciono 90+ dias de dados, Quando clico exportar,
  Então recebo email com link de download em até 5 minutos (não download direto)
- Dado que há dados sensíveis, Quando o CSV é gerado,
  Então os últimos 4 dígitos do cartão são mascarados
- Dado que não há pagamentos no período, Quando exporto,
  Então recebo CSV com apenas o cabeçalho e mensagem clara
```

---

## Priorização MoSCoW

| Prioridade | Significado | Incluir no MVP? |
|---|---|---|
| **Must Have** | Produto falha sem isso | Sim, obrigatório |
| **Should Have** | Importante mas não crítico | Idealmente |
| **Could Have** | Bom ter, se der tempo | Se sobrar tempo |
| **Won't Have** | Explicitamente fora do escopo agora | Não |

### Como Aplicar MoSCoW na Prática

```markdown
## Feature: Sistema de Notificações

### Must Have (MVP)
- Email de confirmação de pagamento
- Email de falha em cobrança
- Notificação de trial expirando (3 dias antes)

### Should Have (V1)
- Configurar quais emails receber
- Notificações in-app (sino no header)
- Resumo semanal por email

### Could Have (Futuro)
- Notificações por WhatsApp
- Webhook para sistemas externos
- Alertas personalizados por threshold

### Won't Have (Fora do escopo)
- Notificações por SMS (custo alto, baixo retorno)
- Push notifications mobile (não temos app nativo)
```

---

## Personas — Template

```markdown
## Persona: [Nome]

**Cargo:** Gerente de Marketing em startup B2B
**Idade:** 32 anos
**Maturidade técnica:** Média (usa Excel, Google Sheets, ferramentas SaaS)

**Objetivos:**
- Provar ROI das campanhas para o CEO
- Reduzir tempo gasto em relatórios manuais

**Frustrações:**
- Dados espalhados em 5 ferramentas diferentes
- Relatórios levam 4h/semana para consolidar
- Não tem acesso fácil a dados históricos

**Como usa nosso produto:**
- 3x por semana, durante o dia
- Principal tarefa: verificar conversões e exportar para apresentações
- Frequentemente acessa pelo celular em reuniões
```

---

## Spec de Feature — Template Completo

```markdown
## Feature: [Nome da Feature]

### Problema
[Qual dor do usuário isso resolve? Por que agora?]

### Usuários-Alvo
[Personas que vão usar isso. Frequência de uso prevista.]

### User Stories
[2-5 stories no formato Dado/Quando/Então]

### Critérios de Aceitação
[Condições testáveis para "done". Cada item deve ser verificável.]

### Casos de Borda
- Estado vazio: [o que mostrar quando não há dados]
- Estado de erro: [como apresentar falhas]
- Estado de loading: [feedback durante espera]
- Permissões: [quem pode acessar/editar/deletar]
- Mobile: [comportamento em tela pequena]

### Fora do Escopo (Explícito)
[O que esta feature NÃO inclui — evitar scope creep]

### Métricas de Sucesso
- [Métrica 1]: [baseline atual] → [meta]
- [Métrica 2]: [baseline atual] → [meta]

### Dependências
[O que precisa existir antes desta feature]

### Riscos
- [Risco técnico ou de negócio]: [mitigação]
```

---

## Definição de MVP

```
MVP ≠ produto ruim
MVP = menor conjunto de features que entrega valor real ao usuário-alvo

Perguntas para definir MVP:
1. Qual é a hipótese central que precisamos validar?
2. Qual é o usuário mais crítico para validar isso?
3. O que é absolutamente necessário para que esse usuário obtenha valor?
4. O que podemos remover sem comprometer a validação?
```

---

## Jornada do Usuário

```markdown
## Jornada: [Nome do Fluxo]

### Passo 1: [Nome]
- **O que o usuário faz:** Clica em "Criar conta"
- **O que o sistema faz:** Exibe formulário de cadastro
- **Estado emocional:** Curioso, levemente ansioso
- **Ponto de fricção:** Campo de senha muito complexo

### Passo 2: [Nome]
- **O que o usuário faz:** Preenche email, senha, nome da empresa
- **O que o sistema faz:** Valida em tempo real, destaca erros
- **Estado emocional:** Focado
- **Ponto de fricção:** Nenhum (fluxo fluido)

[... continuar para todos os passos ...]

### Momentos de Prazer (onde encantar)
- Após cadastro: animação de boas-vindas personalizada
- Primeiro pagamento recebido: confetti + notificação especial
```

---

## Anti-Padrões de Produto

❌ Escrever requisitos como soluções ("criar botão azul que...") — escrever como resultados
❌ Pular edge cases (estado vazio, erro, loading, mobile)
❌ Critérios de aceitação vagos ("deve funcionar bem")
❌ "Must Have" inflado — se tudo é must, nada é must
❌ Não definir o que está FORA do escopo (principal fonte de scope creep)
❌ Não medir — feature sem métrica não tem como saber se funcionou

---

## Referências

→ `references/okr-framework.md` — OKRs, métricas North Star, KPIs para SaaS
→ `references/discovery-tecnicas.md` — Jobs to be Done, entrevistas de usuário, testes A/B
