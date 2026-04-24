---
tags: [ia-apis]
categoria: "🤖 IA e APIs"
---

# Asaas API v3 — Guia de Integração Completo

**Docs:** https://docs.asaas.com  
**Base URL Produção:** `https://api.asaas.com/v3`  
**Base URL Sandbox:** `https://sandbox.asaas.com/api/v3`  
**Padrão:** REST + JSON  
**Certificações:** PCI-DSS, regulado pelo Banco Central do Brasil (código 461)

> ⚠️ **Regra absoluta:** `access_token` (chave de API) fica **exclusivamente no servidor**.  
> Nunca expor no frontend, nunca em variáveis públicas.

---

## Autenticação

Toda requisição exige o header:
```
access_token: $aas_xxxxxxxxxxxxxxxxxxxxxxxxxx
```

```typescript
// lib/asaas.ts
const ASAAS_API_KEY = process.env.ASAAS_API_KEY!
const ASAAS_BASE_URL = process.env.NODE_ENV === 'production'
  ? 'https://api.asaas.com/v3'
  : 'https://sandbox.asaas.com/api/v3'

export async function asaasRequest(
  method: string,
  path: string,
  body?: object
) {
  const response = await fetch(`${ASAAS_BASE_URL}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      'access_token': ASAAS_API_KEY,
    },
    body: body ? JSON.stringify(body) : undefined,
  })
  if (!response.ok) {
    const error = await response.json()
    throw new Error(JSON.stringify(error.errors))
  }
  return response.json()
}
```

> **Atenção PHP:** A chave começa com `$aas_` — use aspas simples ou escape o `$` para evitar interpolação.

---

## Passo 1 — Cadastrar Cliente

Todo pagamento exige um `customer` (ID do cliente). Criar uma vez e reutilizar.

```typescript
// POST /v3/customers
const customer = await asaasRequest('POST', '/customers', {
  name: 'João da Silva',
  cpfCnpj: '11144477735',      // CPF ou CNPJ (somente números)
  email: 'joao@email.com',
  mobilePhone: '11999998888',
  postalCode: '01310100',
  addressNumber: '100',
})
// Salve customer.id no seu banco: "cus_000005219613"
```

**Campos obrigatórios:** `name`, `cpfCnpj`  
**Retorno importante:** `customer.id` — use em todas as cobranças

---

## Passo 2 — Criar Cobrança

### Endpoint único para todas as formas de pagamento

```
POST /v3/payments
```

O campo `billingType` define a forma:

| billingType | Forma |
|---|---|
| `BOLETO` | Boleto bancário |
| `PIX` | QR Code dinâmico |
| `CREDIT_CARD` | Cartão de crédito |
| `DEBIT_CARD` | Cartão de débito |
| `UNDEFINED` | Deixa o cliente escolher |

---

### Cobrança via PIX

```typescript
// POST /v3/payments
const payment = await asaasRequest('POST', '/payments', {
  customer: 'cus_000005219613',
  billingType: 'PIX',
  value: 150.00,
  dueDate: '2025-06-30',         // formato yyyy-MM-dd
  description: 'Pedido #1234',
  externalReference: '1234',     // seu ID interno
})

// Buscar dados do QR Code para exibir ao cliente:
// GET /v3/payments/{id}/pixQrCode
const pixData = await asaasRequest('GET', `/payments/${payment.id}/pixQrCode`)

// pixData.encodedImage → base64 do QR Code (imagem)
// pixData.payload      → código copia e cola
// pixData.expirationDate → quando expira
```

**Exibir no frontend:**
```tsx
<img src={`data:image/png;base64,${pixData.encodedImage}`} alt="QR Code PIX" />
<p>Copia e cola: {pixData.payload}</p>
```

---

### Cobrança via Boleto

```typescript
const payment = await asaasRequest('POST', '/payments', {
  customer: 'cus_000005219613',
  billingType: 'BOLETO',
  value: 100.00,
  dueDate: '2025-07-10',
  description: 'Pedido #1235',
  // Opcional: juros/multa por atraso
  interest: { value: 1 },        // 1% ao mês
  fine: { value: 2 },            // 2% de multa
  // Opcional: desconto por antecipação
  discount: {
    value: 5,
    dueDateLimitDays: 3,         // desconto se pagar 3 dias antes
    type: 'PERCENTAGE'           // ou 'FIXED' para valor fixo
  },
})

// Retorno:
// payment.bankSlipUrl       → PDF do boleto
// payment.invoiceUrl        → fatura online
// payment.id                → ID da cobrança

// Linha digitável (atualizar a cada mudança):
const slip = await asaasRequest('GET', `/payments/${payment.id}/identificationField`)
// slip.identificationField → código de barras numérico
```

> **Dica:** Se você tiver uma chave Pix cadastrada na conta Asaas, o QR Code Pix aparece automaticamente no PDF do boleto.

---

### Cobrança via Cartão de Crédito

**Opção A — Redirecionar para fatura Asaas** (mais simples, cliente digita o cartão na página do Asaas):

```typescript
const payment = await asaasRequest('POST', '/payments', {
  customer: 'cus_000005219613',
  billingType: 'CREDIT_CARD',
  value: 299.90,
  dueDate: '2025-07-10',
  description: 'Assinatura Pro',
})
// Redirecionar para: payment.invoiceUrl
```

**Opção B — Checkout transparente** (cliente digita o cartão no SEU site):

```typescript
// Requer PCI-DSS ou usar tokenização via frontend seguro
const payment = await asaasRequest('POST', '/payments', {
  customer: 'cus_000005219613',
  billingType: 'CREDIT_CARD',
  value: 299.90,
  dueDate: '2025-07-10',
  // Dados do cartão (apenas do servidor, nunca do frontend diretamente)
  creditCard: {
    holderName: 'JOAO DA SILVA',
    number: '5162306219378829',
    expiryMonth: '08',
    expiryYear: '2026',
    ccv: '318',
  },
  creditCardHolderInfo: {
    name: 'João da Silva',
    email: 'joao@email.com',
    cpfCnpj: '11144477735',
    postalCode: '01310100',
    addressNumber: '100',
    phone: '11999998888',
    mobilePhone: '11999998888',
  },
  remoteIp: '187.123.45.67',    // IP real do cliente — OBRIGATÓRIO
})
```

**Opção C — Tokenização** (salvar cartão para cobranças futuras — recomendado):

```typescript
// Tokenizar uma vez:
const tokenData = await asaasRequest('POST', '/creditCard/tokenize', {
  customer: 'cus_000005219613',
  creditCard: { holderName, number, expiryMonth, expiryYear, ccv },
  creditCardHolderInfo: { name, email, cpfCnpj, postalCode, addressNumber },
  remoteIp: req.ip,
})
// Salve tokenData.creditCardToken no seu banco

// Cobrar com token (sem precisar dos dados do cartão de novo):
const payment = await asaasRequest('POST', '/payments', {
  customer: 'cus_000005219613',
  billingType: 'CREDIT_CARD',
  value: 299.90,
  dueDate: '2025-07-10',
  creditCardToken: 'tok_xxxxxxxx',
  remoteIp: req.ip,
})
```

**Parcelamento em cartão de crédito** (até 21x para Visa e Master, 12x outras bandeiras):

```typescript
{
  billingType: 'CREDIT_CARD',
  value: 2000.00,
  installmentCount: 10,
  installmentValue: 200.00,  // ou use totalValue: 2000.00
  // ... creditCard, creditCardHolderInfo
}
```

> **Bandeiras aceitas crédito:** Visa, Mastercard, Elo, Discover, Amex, Hipercard  
> **Bandeiras aceitas débito:** Visa Electron, Mastercard Maestro  
> **Prazo crédito:** recebimento em 32 dias corridos por parcela  
> **Antifraude:** automático e gratuito em todas as cobranças por cartão

---

## Cobranças Recorrentes (Assinaturas)

Para serviços com cobrança automática periódica.

```typescript
// POST /v3/subscriptions
const subscription = await asaasRequest('POST', '/subscriptions', {
  customer: 'cus_000005219613',
  billingType: 'CREDIT_CARD',   // ou PIX, BOLETO
  nextDueDate: '2025-07-01',    // primeira cobrança
  value: 49.90,
  cycle: 'MONTHLY',             // periodicidade
  description: 'Plano Pro Mensal',
  // Opcional: limitar cobranças
  endDate: '2026-07-01',        // data fim
  maxPayments: 12,              // ou número máximo de cobranças
  // Se for cartão de crédito:
  creditCard: { ... },
  creditCardHolderInfo: { ... },
  remoteIp: req.ip,
})
// Retorno: subscription.id → "sub_VXJBYgP2u0eO"
```

**Ciclos disponíveis:**

| cycle | Periodicidade |
|---|---|
| `WEEKLY` | Semanal |
| `BIWEEKLY` | Quinzenal |
| `MONTHLY` | Mensal |
| `BIMONTHLY` | Bimestral |
| `QUARTERLY` | Trimestral |
| `SEMIANNUALLY` | Semestral |
| `YEARLY` | Anual |

**Acompanhar pagamentos de uma assinatura:**

```typescript
// GET /v3/subscriptions/{id}/payments
const payments = await asaasRequest('GET', `/subscriptions/${subscription.id}/payments`)
```

> **Cartão de crédito:** O Asaas faz 3 tentativas de captura no dia do vencimento (8h, 14h, 20h) e mais 3 no dia seguinte. Se falhar, assinatura fica `OVERDUE` e o cliente precisa atualizar o cartão.

---

## Checkout Transparente (Asaas Checkout)

O Asaas oferece um checkout hospedado que você embute via iFrame ou link, sem que o cliente saia do seu site.

```typescript
// Criar cobrança e usar a invoiceUrl no checkout
const payment = await asaasRequest('POST', '/payments', {
  customer: 'cus_000005219613',
  billingType: 'UNDEFINED',     // cliente escolhe a forma
  value: 150.00,
  dueDate: '2025-07-10',
  // Redirecionar após pagamento:
  callback: {
    successUrl: 'https://seusite.com/obrigado',
    autoRedirect: true,
  }
})

// Usar payment.invoiceUrl no frontend:
// <a href={payment.invoiceUrl}>Pagar agora</a>
// ou embedded:
// <iframe src={payment.invoiceUrl} />
```

---

## Link de Pagamento

```typescript
// POST /v3/paymentLinks
const paymentLink = await asaasRequest('POST', '/paymentLinks', {
  name: 'Curso de Design',
  description: 'Acesso completo ao curso',
  value: 197.00,
  billingType: 'UNDEFINED',    // PIX, BOLETO, CREDIT_CARD ou UNDEFINED
  chargeType: 'DETACHED',      // DETACHED (avulso) | INSTALLMENT | RECURRENT
  dueDateLimitDays: 3,         // válido por 3 dias após acesso
  // Para recorrente:
  // chargeType: 'RECURRENT',
  // subscriptionCycle: 'MONTHLY',
  // Para parcelado:
  // chargeType: 'INSTALLMENT',
  // maxInstallmentCount: 12,
})
// paymentLink.url → link para compartilhar
```

---

## Webhooks

Configurar no painel do Asaas ou via API. Essencial para confirmar pagamentos.

**Eventos principais:**

| Evento | Quando ocorre |
|---|---|
| `PAYMENT_CREATED` | Nova cobrança criada |
| `PAYMENT_RECEIVED` | Pagamento confirmado (PIX instantâneo, boleto D+1) |
| `PAYMENT_CONFIRMED` | Cartão capturado com sucesso |
| `PAYMENT_OVERDUE` | Vencida sem pagamento |
| `PAYMENT_DELETED` | Cancelada |
| `PAYMENT_REFUNDED` | Estornada |

```typescript
// app/api/webhooks/asaas/route.ts
export async function POST(req: Request) {
  const body = await req.json()
  const { event, payment } = body

  switch (event) {
    case 'PAYMENT_RECEIVED':
    case 'PAYMENT_CONFIRMED':
      // ✅ Liberar acesso / entregar produto
      await liberarAcessoParaCobranca(payment.externalReference)
      break
    case 'PAYMENT_OVERDUE':
      // ⚠️ Suspender acesso / enviar lembrete
      await suspenderAcessoParaCobranca(payment.externalReference)
      break
    case 'PAYMENT_REFUNDED':
      // 🔄 Cancelar acesso / processar devolução
      await cancelarAcessoParaCobranca(payment.externalReference)
      break
  }

  return Response.json({ received: true })
}
```

**Payload do webhook — campos importantes:**

```json
{
  "event": "PAYMENT_RECEIVED",
  "payment": {
    "id": "pay_080225913252",
    "customer": "cus_G7Dvo4iphUNk",
    "subscription": "sub_VXJBYgP2u0eO",
    "value": 100.0,
    "netValue": 94.51,
    "billingType": "PIX",
    "status": "RECEIVED",
    "externalReference": "seu-id-interno-1234",
    "paymentDate": "2025-07-01",
    "confirmedDate": "2025-07-01"
  }
}
```

> **Use `externalReference`** para vincular cobranças ao seu banco de dados interno.

---

## Status das Cobranças

| Status | Significado |
|---|---|
| `PENDING` | Aguardando pagamento |
| `RECEIVED` | Pago (confirmado) |
| `CONFIRMED` | Cartão capturado |
| `OVERDUE` | Vencida sem pagamento |
| `REFUNDED` | Estornada |
| `DELETED` | Cancelada |
| `RECEIVED_IN_CASH` | Recebida manualmente |

---

## Sandbox — Ambiente de Testes

```
Base URL: https://sandbox.asaas.com/api/v3
```

- Criar conta em: https://sandbox.asaas.com
- Gerar chave de API no painel sandbox
- Adicionar saldo fictício: via painel (Minha Conta → Adicionar saldo)

**Simular pagamento de cobrança no sandbox:**

```typescript
// POST /v3/payments/{id}/receiveInCash
await asaasRequest('POST', `/payments/${paymentId}/receiveInCash`, {
  paymentDate: new Date().toISOString().split('T')[0],
  value: 100.00,
})
```

**Cartões de teste para cartão de crédito:**
- Aprovado: `5162306219378829` (Mastercard)
- Reprovado: `4916561358240741` (Visa)

---

## Referências

→ `references/prazos-taxas.md` — Prazos de liquidação e estrutura de taxas  
→ `references/split-subcontas.md` — Split de pagamento e BaaS com subcontas  
→ `references/erros-webhook.md` — Tratamento de erros, penalização de fila e boas práticas


---

## Relacionado

[[Next.js 15]] | [[Supabase]] | [[Node.js]]


---

## Referencias

- [[Referencias/erros-webhook]]
- [[Referencias/prazos-taxas]]
- [[Referencias/split-subcontas]]
