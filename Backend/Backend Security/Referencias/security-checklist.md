# Checklist de Segurança — Pré-Deploy

## Secrets e Configuração
- [ ] Nenhum segredo no código (git grep -r "sk_live\|password=\|SECRET=" --include="*.ts")
- [ ] `.env` no `.gitignore` — nunca commitado com valores reais
- [ ] `.env.example` commitado com placeholders
- [ ] Variáveis de produção em secrets manager (não só .env)
- [ ] `NEXT_PUBLIC_` / `VITE_` / `REACT_APP_` usados APENAS para dados realmente públicos
- [ ] JWT_SECRET gerado com `openssl rand -hex 32` (≥32 bytes)
- [ ] Senhas de banco com caracteres especiais e ≥20 chars

## Autenticação e Autorização
- [ ] Todos os endpoints protegidos por `authenticate` middleware
- [ ] Todos os endpoints admin protegidos por `requireRole('admin')`
- [ ] JWT com expiração curta (≤15min para access, ≤7d para refresh)
- [ ] Tokens armazenados em cookies `httpOnly + Secure + SameSite=Lax`
- [ ] NUNCA `localStorage` para access tokens
- [ ] Refresh token rotation implementado (invalidar o token usado)
- [ ] Logout invalida refresh token no banco (blacklist ou delete)

## Validação de Input
- [ ] Todo input de usuário validado com schema (Zod, Joi, Yup)
- [ ] Validação no servidor — nunca só no frontend
- [ ] HTML aceito de usuários passa por DOMPurify/sanitize-html
- [ ] Uploads verificados por magic bytes (não só mimetype)
- [ ] Tamanho de arquivos limitado no servidor
- [ ] Content-Type verificado no servidor

## Banco de Dados
- [ ] Queries com ORM ou parameterizadas (zero SQL string concatenation)
- [ ] IDs públicos são UUIDs/ULIDs (não integers sequenciais)
- [ ] Queries filtradas pelo userId autenticado (BOLA prevention)
- [ ] Usuário do banco tem apenas as permissões necessárias (não root)
- [ ] Backup automático configurado

## Headers e Rede
- [ ] Helmet instalado e configurado
- [ ] CORS restrito a origens conhecidas em produção
- [ ] HTTPS obrigatório com HSTS
- [ ] Rate limiting no login e em endpoints sensíveis
- [ ] Content-Security-Policy configurado
- [ ] X-Frame-Options: DENY (anti-clickjacking)

## Erros e Logs
- [ ] Stack traces não expostos em respostas de produção
- [ ] Mensagens de erro genéricas para o cliente
- [ ] Logs detalhados apenas no servidor
- [ ] Dados sensíveis (tokens, senhas) nunca logados
- [ ] Erros de auth com resposta uniforme (não revelar "email não existe" vs "senha errada")

## Webhooks
- [ ] Assinatura HMAC verificada em todos os webhooks recebidos
- [ ] Replay protection com timestamp + nonce
- [ ] Idempotência implementada (mesmo webhook processado só uma vez)

---

# OWASP API Security Top 10 (2023)

## API1 — Broken Object Level Authorization (BOLA)
**Problema:** Usuário A acessa dados do Usuário B pela URL.  
**Solução:** Sempre filtrar queries pelo `userId` autenticado.
```typescript
// Sempre assim:
where: { id: params.id, userId: req.user.id }
```

## API2 — Broken Authentication
**Problema:** Tokens sem expiração, senhas fracas, sem rate limit em login.  
**Solução:** JWT curto, bcrypt para senhas, rate limit agressivo no login.

## API3 — Broken Object Property Level Authorization
**Problema:** Endpoint retorna campos que o usuário não deveria ver.  
**Solução:** Usar `select` explícito — nunca retornar o objeto inteiro do DB.
```typescript
// ❌ Retorna senha, tokens internos, etc.
return user

// ✅ Retorna apenas o necessário
return { id: user.id, name: user.name, email: user.email }
```

## API4 — Unrestricted Resource Consumption
**Problema:** Sem paginação, sem limite de tamanho de payload, sem rate limit.  
**Solução:** Rate limiting, paginação obrigatória, limits em queries.
```typescript
const limit = Math.min(req.query.limit ?? 20, 100) // máximo 100
const offset = req.query.offset ?? 0
```

## API5 — Broken Function Level Authorization
**Problema:** Funções admin acessíveis por usuários comuns.  
**Solução:** `requireRole('admin')` em TODOS os endpoints administrativos.

## API6 — Unrestricted Access to Sensitive Business Flows
**Problema:** Workflow de pagamento pode ser pulado.  
**Solução:** Verificar estado da transação no servidor em cada etapa.

## API7 — Server Side Request Forgery (SSRF)
**Problema:** Endpoint aceita URL de fora e faz request para ela — atacante aponta para `http://169.254.169.254/` (metadata AWS).  
**Solução:** Allowlist de domínios, nunca aceitar IP privado.
```typescript
import { isIP } from 'net'
function isPrivateIP(ip: string) {
  return /^(10\.|172\.(1[6-9]|2\d|3[01])\.|192\.168\.|127\.|169\.254\.)/.test(ip)
}
```

## API8 — Security Misconfiguration
**Problema:** CORS wildcard, stack trace em produção, headers padrão expostos.  
**Solução:** Helmet + CORS restrito + NODE_ENV checks.

## API9 — Improper Inventory Management
**Problema:** APIs de debug/v1 esquecidas em produção.  
**Solução:** Versionamento explícito, remover endpoints não-utilizados.

## API10 — Unsafe Consumption of APIs
**Problema:** Confiar cegamente em dados de APIs de terceiros.  
**Solução:** Validar respostas de terceiros com schemas, assim como inputs de usuário.


---

← [[README|Backend Security]]
