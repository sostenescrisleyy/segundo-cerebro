# Asaas — Erros, Webhooks e Boas Práticas

## Tratamento de Erros da API

A API retorna HTTP 4xx/5xx com corpo JSON:

```json
{
  "errors": [
    {
      "code": "invalid_action",
      "description": "Não é possível realizar esta ação."
    }
  ]
}
```

### Erros comuns e soluções:

| Código HTTP | Causa | Solução |
|---|---|---|
| `400` | Parâmetros inválidos ou ação impossível | Verificar campos obrigatórios e formato |
| `401` | `access_token` inválido ou ausente | Verificar a chave de API |
| `403` | Sem permissão para o recurso | Verificar escopos da chave de API |
| `404` | Recurso não encontrado | Verificar ID informado |
| `429` | Rate limit excedido (2000 req/dia padrão) | Implementar exponential backoff |
| `500` | Erro interno Asaas | Aguardar e tentar novamente |

```typescript
// Tratamento robusto de erros:
async function asaasRequest(method: string, path: string, body?: object) {
  try {
    const response = await fetch(`${BASE_URL}${path}`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        'access_token': process.env.ASAAS_API_KEY!,
      },
      body: body ? JSON.stringify(body) : undefined,
    })

    if (!response.ok) {
      const errorData = await response.json()
      const errorMsg = errorData.errors?.map((e: any) => e.description).join(', ')
      throw new Error(`Asaas API ${response.status}: ${errorMsg}`)
    }

    return response.json()
  } catch (error) {
    console.error('Asaas API Error:', error)
    throw error
  }
}
```

---

## Webhooks — Boas Práticas

### Penalização de fila

O Asaas pausa o envio de webhooks para URLs que retornam erros repetidamente. Se sua fila foi pausada:

1. Corrigir o problema no endpoint
2. Verificar logs no painel: Configurações → Webhooks → Logs
3. Reativar: Configurações → Webhooks → Reativar

### Erros de webhook e soluções:

| Erro | Causa | Solução |
|---|---|---|
| `400 Bad Request` | Endpoint retornou erro de parsing | Garantir que o endpoint aceita o JSON do Asaas |
| `403 Forbidden` | Endpoint bloqueou a requisição | Whitelist dos IPs do Asaas (ver abaixo) |
| `404 Not Found` | URL do webhook não existe | Verificar e atualizar a URL |
| `408 Read Timed Out` | Endpoint demorou > 30s para responder | Processar async, retornar 200 rapidamente |
| `500 Internal Server Error` | Bug no seu endpoint | Corrigir o handler |
| `Connect Timed Out` | Servidor inacessível | Verificar disponibilidade da URL |

### IPs oficiais do Asaas (whitelist no firewall/Cloudflare):

```
52.67.12.176
52.67.12.179
52.67.12.183
52.67.12.197
52.67.12.230
52.67.12.232
```

### Implementar idempotência nos webhooks:

```typescript
// Armazenar IDs processados para evitar duplicações
const processedPayments = new Set<string>()

export async function POST(req: Request) {
  const { event, payment } = await req.json()

  // Idempotência: ignorar eventos já processados
  const key = `${event}:${payment.id}`
  if (processedPayments.has(key)) {
    return Response.json({ received: true, duplicate: true })
  }
  processedPayments.add(key)

  // Processar rapidamente — lógica pesada em background
  // Retornar 200 ANTES de processar para não penalizar a fila
  processPaymentAsync(event, payment).catch(console.error)

  return Response.json({ received: true })
}

async function processPaymentAsync(event: string, payment: any) {
  // Processamento real aqui
}
```

> **Regra de ouro:** Retorne HTTP 200 IMEDIATAMENTE. Nunca faça processamento síncrono demorado dentro do handler de webhook.

---

## Boas Práticas de Integração

### 1. Sempre use `externalReference`

Vincule suas cobranças ao seu ID interno:

```typescript
{
  externalReference: `pedido_${orderId}`,
  // Asaas devolve no webhook — você sempre sabe qual pedido é
}
```

### 2. Sandbox → Produção

```typescript
const ASAAS_BASE_URL = process.env.NODE_ENV === 'production'
  ? 'https://api.asaas.com/v3'
  : 'https://sandbox.asaas.com/api/v3'
```

### 3. Nunca confiar apenas no retorno da criação da cobrança

Sempre usar webhook para confirmar pagamentos. O status no momento da criação é sempre `PENDING`.

### 4. Linha digitável do boleto pode mudar

Sempre buscar a linha digitável atualizada antes de exibir:

```typescript
const slip = await asaasRequest('GET', `/payments/${id}/identificationField`)
```

### 5. Rate Limit

Padrão: 2000 requisições por dia. Para aumentar, contatar o gerente de conta Asaas.

### 6. Polling vs Webhooks

- **Webhooks:** sempre preferível — reativo, sem desperdício de requisições
- **Polling:** usar apenas em casos onde webhook não é viável:

```typescript
// Polling simples para verificar status (use com moderação)
async function aguardarPagamento(paymentId: string, maxTentativas = 10) {
  for (let i = 0; i < maxTentativas; i++) {
    await new Promise(r => setTimeout(r, 3000)) // aguarda 3s
    const payment = await asaasRequest('GET', `/payments/${paymentId}`)
    if (['RECEIVED', 'CONFIRMED'].includes(payment.status)) {
      return payment
    }
    if (payment.status === 'OVERDUE') throw new Error('Pagamento vencido')
  }
  throw new Error('Timeout aguardando pagamento')
}
```

### 7. Verificar status antes de exibir QR Code

O QR Code Pix expira. Verificar `pixQrCode.expirationDate` e regenerar se necessário.

### 8. Ambiente de produção — verificar aprovação da conta

Contas novas podem ter limites menores. Para aumentar limites, enviar documentação no painel.

---

## Endpoints de Referência Rápida

| Ação | Método | Endpoint |
|---|---|---|
| Criar cliente | POST | `/v3/customers` |
| Criar cobrança | POST | `/v3/payments` |
| Buscar cobrança | GET | `/v3/payments/{id}` |
| QR Code Pix | GET | `/v3/payments/{id}/pixQrCode` |
| Linha digitável boleto | GET | `/v3/payments/{id}/identificationField` |
| Simular pagamento (sandbox) | POST | `/v3/payments/{id}/receiveInCash` |
| Estornar pagamento | POST | `/v3/payments/{id}/refund` |
| Criar assinatura | POST | `/v3/subscriptions` |
| Pagamentos de assinatura | GET | `/v3/subscriptions/{id}/payments` |
| Criar link de pagamento | POST | `/v3/paymentLinks` |
| Tokenizar cartão | POST | `/v3/creditCard/tokenize` |
| Criar subconta | POST | `/v3/accounts` |


---

← [[README|Asaas Pagamentos]]
