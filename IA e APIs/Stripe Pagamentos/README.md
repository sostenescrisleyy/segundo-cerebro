---
tags: [ia-apis]
categoria: "IA e APIs"
---

# Stripe — Integração de Pagamentos

**SDK:** stripe (Node.js) + @stripe/stripe-js (frontend)  
**Princípio:** Nunca processar dados de cartão no seu servidor. Usar Stripe Elements ou Checkout. Sempre confirmar pagamentos via webhook.

---

## Setup

```bash
npm install stripe @stripe/stripe-js @stripe/react-stripe-js
```

```typescript
// lib/stripe.ts — singleton server-side
import Stripe from 'stripe'

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2025-04-30',
})
```

---

## Stripe Checkout — Solução Mais Rápida

Redireciona para página de pagamento hospedada pelo Stripe (sem PCI compliance necessário):

```typescript
// app/api/checkout/route.ts
import { stripe } from '@/lib/stripe'

export async function POST(req: Request) {
  const { priceId, userId } = await req.json()

  const session = await stripe.checkout.sessions.create({
    mode:     'subscription',   // ou 'payment' para pagamento único
    payment_method_types: ['card'],
    line_items: [{ price: priceId, quantity: 1 }],
    customer_email: userEmail,   // ou customer: stripeCustomerId
    metadata: { userId },        // retorna no webhook
    success_url: `${process.env.NEXT_PUBLIC_URL}/dashboard?success=1`,
    cancel_url:  `${process.env.NEXT_PUBLIC_URL}/pricing`,
    // Para assinaturas:
    subscription_data: {
      trial_period_days: 14,
      metadata: { userId },
    },
  })

  return Response.json({ url: session.url })
}

// No cliente:
const { url } = await fetch('/api/checkout', {
  method: 'POST',
  body: JSON.stringify({ priceId: 'price_xxx' }),
}).then(r => r.json())

window.location.href = url  // redireciona para o Stripe
```

---

## Payment Intent — Checkout Transparente

Para integrar o formulário no próprio site (requer mais implementação):

```typescript
// Criar PaymentIntent no servidor
const paymentIntent = await stripe.paymentIntents.create({
  amount:   1999,           // em centavos (R$ 19,99)
  currency: 'brl',
  metadata: { orderId: '123' },
  automatic_payment_methods: { enabled: true },
})

return { clientSecret: paymentIntent.client_secret }
```

```tsx
// Componente de pagamento no cliente
import { Elements, PaymentElement, useStripe, useElements } from '@stripe/react-stripe-js'
import { loadStripe } from '@stripe/stripe-js'

const stripePromise = loadStripe(process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY!)

function CheckoutForm() {
  const stripe   = useStripe()
  const elements = useElements()

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!stripe || !elements) return

    const { error } = await stripe.confirmPayment({
      elements,
      confirmParams: { return_url: `${window.location.origin}/success` },
    })

    if (error) toast.error(error.message)
  }

  return (
    <form onSubmit={handleSubmit}>
      <PaymentElement />
      <button type="submit">Pagar R$ 19,99</button>
    </form>
  )
}

export function PaymentPage({ clientSecret }: { clientSecret: string }) {
  return (
    <Elements stripe={stripePromise} options={{ clientSecret }}>
      <CheckoutForm />
    </Elements>
  )
}
```

---

## Webhooks — Confirmação de Pagamentos

**Regra de ouro:** NUNCA liberar acesso baseado no redirecionamento do Checkout. SEMPRE usar webhook.

```typescript
// app/api/webhooks/stripe/route.ts
import { stripe } from '@/lib/stripe'
import Stripe from 'stripe'

export async function POST(req: Request) {
  const body      = await req.text()
  const signature = req.headers.get('stripe-signature')!

  let event: Stripe.Event
  try {
    event = stripe.webhooks.constructEvent(
      body, signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    )
  } catch {
    return new Response('Webhook inválido', { status: 400 })
  }

  switch (event.type) {

    case 'checkout.session.completed': {
      const session = event.data.object as Stripe.Checkout.Session
      const userId  = session.metadata?.userId
      if (session.payment_status === 'paid') {
        await db.user.update({
          where: { id: userId },
          data:  { plan: 'pro', subscriptionId: session.subscription as string }
        })
      }
      break
    }

    case 'customer.subscription.updated': {
      const sub = event.data.object as Stripe.Subscription
      await db.subscription.update({
        where: { stripeId: sub.id },
        data: { status: sub.status, currentPeriodEnd: new Date(sub.current_period_end * 1000) }
      })
      break
    }

    case 'customer.subscription.deleted': {
      const sub = event.data.object as Stripe.Subscription
      await db.user.update({
        where: { subscriptionId: sub.id },
        data:  { plan: 'free', subscriptionId: null }
      })
      break
    }

    case 'invoice.payment_failed': {
      const invoice = event.data.object as Stripe.Invoice
      // Notificar cliente sobre falha no pagamento
      await sendPaymentFailedEmail(invoice.customer_email!)
      break
    }
  }

  return new Response('ok', { status: 200 })
}
```

---

## Customer Portal — Gerenciar Assinatura

Permite ao cliente cancelar, mudar plano e atualizar cartão sem você implementar isso:

```typescript
// app/api/portal/route.ts
export async function POST(req: Request) {
  const { customerId } = await req.json()

  const session = await stripe.billingPortal.sessions.create({
    customer:   customerId,
    return_url: `${process.env.NEXT_PUBLIC_URL}/dashboard`,
  })

  return Response.json({ url: session.url })
}
```

---

## Referências

→ `references/stripe-products.md` — Criar produtos, preços, cupons e trials via API


---

## Relacionado

[[Next.js 15]] | [[Supabase]] | [[Node.js]]


---

## Referencias

- [[Referencias/extra]]
