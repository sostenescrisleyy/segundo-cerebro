# Asaas — Prazos de Liquidação e Taxas

## Prazos de Liquidação

| Forma de Pagamento | Prazo para cair na conta Asaas |
|---|---|
| **Pix** | Instantâneo (segundos), 24/7 |
| **Boleto** | D+1 útil após compensação |
| **Cartão de Crédito** | 32 dias corridos após confirmação de cada parcela |
| **Cartão de Débito** | Até 3 dias úteis após confirmação |

> **Importante:** Prazos acima são para crédito na **conta Asaas**. Transferência para conta bancária externa tem prazo adicional conforme configuração da conta.

---

## Antecipação de Recebíveis

O Asaas permite antecipar recebíveis antes dos prazos acima:

- **Boleto:** recebe em até 3 dias úteis (sujeito a análise)
- **Cartão de crédito:** recebe em até 2 dias úteis (sujeito a análise)
- **Requisito:** ter concluído pelo menos uma transferência (TED ou Pix) da conta Asaas para conta bancária externa

**Via API:** `POST /v3/anticipations`

---

## Modelo de Cobrança de Taxas

- **Gerar cobrança:** Gratuito (taxa só é cobrada após liquidação)
- **Cancelar boleto:** Gratuito
- **Taxa por boleto compensado:** cobrada sobre o valor recebido
- **Cobrança PIX:** Taxa cobrada após confirmação
- **Cartão de crédito:** Taxa cobrada após captura

> As taxas variam conforme plano e volume. Novos clientes têm taxas promocionais por 3 meses. Consultar: https://www.asaas.com/precos-e-taxas

---

## Pix — Detalhes

- Disponível 24h/7 dias por semana, 365 dias no ano
- Aprovação instantânea
- **30 transações Pix gratuitas por mês** na conta Asaas
- QR Code dinâmico tem data de expiração
- QR Code estático: valor fixo ou em aberto, sem expiração

**Tipos de Pix no Asaas:**
- **QR Code dinâmico:** vinculado a uma cobrança específica (recomendado)
- **QR Code estático:** reutilizável, sem prazo
- **Pix Recorrente:** Pix vinculado a assinaturas
- **Pix Automático:** débito automático via Pix (requerer ativação)

---

## Retenção de Valores e Status de Cobrança

### Prazo de retenção por forma de pagamento:

- **Pix e Boleto:** valores ficam disponíveis para saque após compensação
- **Cartão de Crédito:** valores ficam retidos por 32 dias (prazo de chargeback)

### Chargeback (cartão):

- Período de contestação varia conforme bandeira
- Asaas notifica via webhook com evento específico
- Sistema antifraude automático e gratuito reduz risco

### Estorno:

- Pix: estorno quase imediato
- Boleto: requer dados bancários do pagador
- Cartão: possível dentro do prazo da operadora, gratuito
- **API:** `POST /v3/payments/{id}/refund`


---

← [[README|Asaas Pagamentos]]
