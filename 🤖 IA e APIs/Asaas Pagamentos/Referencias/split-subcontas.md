# Asaas — Split de Pagamento e BaaS (Subcontas)

## Split de Pagamento

Permite dividir o valor de uma cobrança entre múltiplas carteiras (wallets) Asaas.
Ideal para marketplaces, plataformas e representantes comerciais.

### Split em cobrança avulsa

```typescript
// POST /v3/payments
const payment = await asaasRequest('POST', '/payments', {
  customer: 'cus_000005219613',
  billingType: 'PIX',
  value: 1000.00,
  dueDate: '2025-07-10',
  split: [
    {
      walletId: 'xxxx-wallet-fornecedor',
      fixedValue: 700.00,         // valor fixo
    },
    {
      walletId: 'yyyy-wallet-parceiro',
      percentualValue: 5,         // 5% do valor líquido
    },
  ],
})
```

> **Atenção:** `walletId` é o ID de carteira de outra conta Asaas — diferente do `customerId`.

### Split em assinaturas

```typescript
// POST /v3/subscriptions
const subscription = await asaasRequest('POST', '/subscriptions', {
  customer: 'cus_000005219613',
  billingType: 'CREDIT_CARD',
  nextDueDate: '2025-07-01',
  value: 100.00,
  cycle: 'MONTHLY',
  split: [
    {
      walletId: 'wallet-do-parceiro',
      percentualValue: 20,   // 20% vai para o parceiro
    },
  ],
  creditCard: { ... },
  creditCardHolderInfo: { ... },
  remoteIp: req.ip,
})
```

### Tipos de split:

| Campo | Tipo | Descrição |
|---|---|---|
| `walletId` | string | ID de carteira Asaas do destinatário |
| `fixedValue` | number | Valor fixo a transferir |
| `percentualValue` | number | Percentual do valor **líquido** a transferir |

> Não use `fixedValue` e `percentualValue` ao mesmo tempo no mesmo split.

---

## BaaS — Banking as a Service com Subcontas

Permite criar contas digitais Asaas para terceiros dentro da sua plataforma.
Ideal para marketplaces, SaaS financeiros, plataformas de vendedores.

### Fluxo de criação de subconta

```typescript
// POST /v3/accounts
const subAccount = await asaasRequest('POST', '/accounts', {
  name: 'Empresa Parceira LTDA',
  email: 'financeiro@parceira.com',
  loginEmail: 'financeiro@parceira.com',
  cpfCnpj: '12345678000199',    // CNPJ da empresa
  birthDate: '1990-01-15',
  companyType: 'LIMITED',       // MEI, LIMITED, INDIVIDUAL, ASSOCIATION
  phone: '11999998888',
  mobilePhone: '11999998888',
  site: 'https://parceira.com',
  address: 'Rua Exemplo',
  addressNumber: '100',
  complement: 'Sala 1',
  province: 'Centro',
  postalCode: '01310100',
})
// subAccount.id → ID da subconta
// subAccount.apiKey → chave de API da subconta (gerada automaticamente)
// subAccount.walletId → ID da carteira para receber splits
```

### Gerenciar chave de API de subconta

```typescript
// Gerar nova chave para subconta
// POST /v3/userAccount/keys/{id}
// onde {id} é o ID da subconta

// Listar chaves de uma subconta
// GET /v3/userAccount/keys/{id}
```

### Fluxo de aprovação de subcontas

1. Criar subconta → status `PENDING`
2. Enviar documentos → `POST /v3/myAccount/documents`
3. Aprovação pelo Asaas → status `ACTIVE`
4. Subconta pode agora receber cobranças e splits

> Subcontas em **período de avaliação** têm limites de movimentação. Após aprovação completa, limites são liberados.

---

## Conta Escrow

Para plataformas que precisam garantir o valor antes de liberar para o vendedor.

- Valores ficam bloqueados na conta escrow até liberação manual
- Protege marketplaces em casos de disputas
- **Ativar:** configurar via painel do Asaas (Plano Avançado)

### Fluxo:
1. Cliente paga → valor vai para conta escrow (bloqueado)
2. Plataforma confirma entrega → `POST /v3/escrow/{id}/unblock`
3. Valor liberado para o vendedor

---

## Notificações Automáticas

O Asaas envia lembretes automáticos por e-mail, SMS e WhatsApp:

```typescript
// Ao criar cobrança, notificações padrão já estão ativas
// Personalizar por cliente:
// PUT /v3/customers/{id}/notifications
await asaasRequest('PUT', `/customers/${customerId}/notifications`, {
  sendType: 'EMAIL',          // EMAIL, SMS, WHATSAPP
  scheduleOffset: 3,          // dias antes do vencimento
  emailEnabledForProvider: true,
  smsEnabledForProvider: true,
})
```

**Canais:**
- E-mail: incluído em pacote (após pagamento da cobrança)
- SMS: incluído no mesmo pacote do e-mail
- WhatsApp: cobrado por mensagem enviada
- Robô de voz: cobrado por ligação (somente após vencimento)
- Carta/Correios: cobrado por boleto enviado (somente antes do vencimento)


---

← [[README|Asaas Pagamentos]]
