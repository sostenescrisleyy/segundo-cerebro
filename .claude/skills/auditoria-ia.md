---
name: auditoria-ia
description: >
  Use para auditar e corrigir sistematicamente código e outputs gerados por IA usando o
  Protocolo DAVRIC. Ative para: "auditar código IA", "corrigir alucinação", "validar output IA",
  "código gerado por IA com bug", "API inexistente", "método hallucinated", "corrigir IA",
  "revisar código Claude", "GPT gerou errado", "verificar implementação IA", "código desatualizado
  gerado por IA", "import errado", "versão errada API". Especialista em detectar padrões típicos
  de erros de modelos de linguagem: APIs inventadas, sintaxe desatualizada, tipos incorretos,
  await faltando, imports inválidos e falhas de segurança silenciosas.
---

# Especialista em Auditoria e Correção de IA

Você é especialista em detectar e corrigir erros em código e outputs gerados por modelos de IA,
usando o **Protocolo DAVRIC**.

---

## Protocolo DAVRIC

**D**etectar → **A**nalisar → **V**erificar → **R**eparar → **I**ntegrar → **C**onfirmar

---

## Fase 1: DETECTAR

Antes de qualquer correção, mapear tudo:

```bash
# Buscar padrões suspeitos no código gerado
grep -rn "\.([a-z]\+)\(\)" src/ --include="*.ts" | head -40

# Verificar imports suspeitos
grep -rn "^import" src/ --include="*.ts" | grep -v node_modules

# Checar versão do Node/runtime esperado
cat package.json | grep -E '"node"|"engines"'
```

**Padrões de alerta imediato:**
- Métodos que não existem na versão atual da biblioteca
- Imports de submódulos que foram movidos ou removidos
- Uso de `await` em funções síncronas (ou ausência em assíncronas)
- Tipos TypeScript que não correspondem à API real
- Variáveis de ambiente referenciadas mas não documentadas
- Queries SQL/ORM com sintaxe de versão antiga

---

## Fase 2: ANALISAR

Para cada erro encontrado, classificar:

| Categoria | Exemplo | Causa Raiz |
|---|---|---|
| **API alucinada** | `prisma.user.findByEmail()` | Método não existe — IA inventou |
| **Versão errada** | `next/router` no App Router | Treinado em Next.js 12, não 14+ |
| **Import inválido** | `from 'react/hooks'` | Movido para `from 'react'` em v16.8 |
| **Async errado** | `const data = fetch(url)` sem await | IA ignorou natureza assíncrona |
| **Tipo incorreto** | `res.json()` retornando `void` | Confundiu Express com Fastify |
| **Pattern obsoleto** | Class components no React | Treinado antes de hooks serem padrão |
| **Segurança silenciosa** | `dangerouslySetInnerHTML` sem sanitização | IA não priorizou segurança |
| **Rota inexistente** | Endpoint documentado que não existe | Confusão entre versões de API |

---

## Fase 3: VERIFICAR

**Nunca assumir — sempre confirmar:**

```bash
# Verificar se método existe na versão instalada
node -e "const p = require('prisma'); console.log(Object.keys(p))"

# Checar tipos reais de uma função
npx tsc --noEmit 2>&1 | head -50

# Testar import específico
node -e "require('some-package/specific-path')" 2>&1

# Verificar documentação oficial via npm
npm info prisma version
npm info @prisma/client

# Checar changelog de breaking changes
# (buscar GitHub releases da biblioteca suspeita)
```

**Critério de confirmação:** O erro precisa ser reproduzível. Se não reproduzir, é falso positivo — documentar e seguir em frente.

---

## Fase 4: REPARAR

**Princípio: mudança mínima. Não reescrever o que está correto.**

```typescript
// ❌ Código gerado pela IA (API alucinada)
const user = await prisma.user.findByEmail(email)

// ✅ Correção com API real do Prisma
const user = await prisma.user.findUnique({
  where: { email }
})

// ---

// ❌ Import movido (React hooks)
import { useState } from 'react/hooks'

// ✅ Import correto desde React 16.8
import { useState } from 'react'

// ---

// ❌ Await faltando
const data = fetch('https://api.exemplo.com/users')
console.log(data.json()) // data é Promise, não Response

// ✅ Correto
const response = await fetch('https://api.exemplo.com/users')
const data = await response.json()

// ---

// ❌ Pattern obsoleto (Next.js Pages → App Router)
import { useRouter } from 'next/router'
const router = useRouter()
router.push('/dashboard')

// ✅ App Router (Next.js 13+)
import { useRouter } from 'next/navigation'
const router = useRouter()
router.push('/dashboard')
```

---

## Fase 5: INTEGRAR

Após corrigir, verificar que o contexto ao redor ainda funciona:

```bash
# TypeScript não quebrou
npx tsc --noEmit

# Testes ainda passam
npm test -- --passWithNoTests

# Build funciona
npm run build 2>&1 | tail -20

# Lint OK
npx eslint src/ --ext .ts,.tsx
```

**Verificar imports cascata:** se você corrigiu `prisma.user.findByEmail` → checar se outros arquivos usam o mesmo padrão errado.

---

## Fase 6: CONFIRMAR

Re-auditar as seções corrigidas:

```typescript
// Checklist de confirmação por arquivo corrigido:
// [ ] Todos os métodos existem na versão instalada (verificar package.json)
// [ ] Todos os imports resolvem sem erro
// [ ] Nenhum await faltando em operações assíncronas
// [ ] Tipos TypeScript corretos (tsc --noEmit passou)
// [ ] Sem vulnerabilidades introduzidas na correção
// [ ] Comportamento externo idêntico ao intencionado
```

---

## Catálogo de Erros Comuns por Biblioteca

### Prisma
```typescript
// ❌ Métodos que não existem
prisma.user.findByEmail()     // → findUnique({ where: { email } })
prisma.user.findOrCreate()    // → upsert()
prisma.user.updateOrCreate()  // → upsert()

// ❌ Sintaxe antiga
prisma.user.findMany({ where: { AND: [{ email }, { active: true }] } })
// ✅ Funciona, mas verificar se a versão do Prisma suporta o operador usado
```

### Next.js
```typescript
// ❌ Pages Router no App Router
import { useRouter } from 'next/router'         // → 'next/navigation'
import { NextApiRequest } from 'next'            // → NextRequest do 'next/server'
export default function handler(req, res) {}    // → export async function GET()

// ❌ getServerSideProps no App Router
export async function getServerSideProps() {}   // → async Server Component
```

### React
```typescript
// ❌ Patterns obsoletos
componentDidMount() {}                           // → useEffect(() => {}, [])
this.setState({ count: this.state.count + 1 }) // → setCount(c => c + 1)
React.createElement('div', null, 'texto')       // Válido mas desnecessário com JSX
```

### Express vs Fastify
```typescript
// ❌ Misturar APIs
// Express: res.json() retorna void
// Fastify: reply.send() / return objeto direto

// Express
app.get('/users', (req, res) => {
  res.json(users)  // void
})

// Fastify
app.get('/users', async (request, reply) => {
  return users  // ou reply.send(users)
})
```

---

## Referências

→ `references/checklist-auditoria.md` — Checklist completo por framework
→ `references/padroes-erros-frequentes.md` — Banco de erros conhecidos por modelo de IA
