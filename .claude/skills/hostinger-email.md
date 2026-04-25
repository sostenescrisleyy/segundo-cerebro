---
name: hostinger-email
description: >
  Use para configuração de SMTP/IMAP Hostinger, autenticação, rate limits e implementação
  de email transacional com Nodemailer, PHPMailer ou Python. Ative para: "email", "smtp",
  "hostinger", "nodemailer", "enviar email", "email transacional", "IMAP", "POP3",
  "configurar email", "bounce", "fila de email", "template email", "email não chega",
  "erro de autenticação smtp", "porta 465", "porta 587", "SSL email".
---

# Especialista em Hostinger Email

Especialista em serviços de email da Hostinger para envio transacional e em massa.

---

## Configuração SMTP Hostinger

```
Host:  smtp.hostinger.com
Porta: 465 (SSL/TLS) — recomendado
       587 (STARTTLS) — alternativa
Auth:  Sim (email completo + senha)
```

---

## Nodemailer — Setup Completo

```typescript
import nodemailer from 'nodemailer'
import { z } from 'zod'

// Criar transporter singleton
const transporter = nodemailer.createTransport({
  host:   'smtp.hostinger.com',
  port:    465,
  secure:  true,  // true para porta 465
  auth: {
    user: process.env.SMTP_USER!,      // email completo: noreply@seudominio.com
    pass: process.env.SMTP_PASSWORD!,
  },
  // Timeout para evitar hanging
  connectionTimeout: 10000,
  greetingTimeout:   5000,
})

// Verificar conexão no startup
async function verificarConexaoEmail() {
  try {
    await transporter.verify()
    console.log('✅ SMTP Hostinger conectado')
  } catch (error) {
    console.error('❌ Falha na conexão SMTP:', error)
    throw error
  }
}

// Schema de validação para emails
const EmailSchema = z.object({
  to:      z.string().email(),
  subject: z.string().min(1).max(200),
  html:    z.string().min(1),
  text:    z.string().optional(),  // fallback plain text
})

// Função de envio com tratamento de erro
export async function enviarEmail(dados: z.infer<typeof EmailSchema>) {
  const validado = EmailSchema.parse(dados)

  try {
    const info = await transporter.sendMail({
      from:    `"${process.env.SMTP_FROM_NAME}" <${process.env.SMTP_USER}>`,
      to:       validado.to,
      subject:  validado.subject,
      html:     validado.html,
      text:     validado.text,
    })

    console.log(`📧 Email enviado: ${info.messageId} → ${validado.to}`)
    return { success: true, messageId: info.messageId }
  } catch (error) {
    console.error(`❌ Falha ao enviar para ${validado.to}:`, error)
    throw error
  }
}
```

---

## Templates de Email

```typescript
// templates/email-confirmacao.ts
export function templateConfirmacaoEmail(nome: string, linkConfirmacao: string): string {
  return `
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
  <h1 style="color: #1a1a2e;">Confirme seu email</h1>
  <p>Olá, <strong>${nome}</strong>!</p>
  <p>Clique no botão abaixo para confirmar seu cadastro:</p>
  <a href="${linkConfirmacao}"
     style="background:#7c3aed;color:#fff;padding:12px 24px;border-radius:6px;
            text-decoration:none;display:inline-block;margin:16px 0;">
    Confirmar Email
  </a>
  <p style="color:#666;font-size:14px;">
    Link válido por 24 horas. Se não foi você, ignore este email.
  </p>
</body>
</html>`
}
```

---

## Rate Limits e Fila

```typescript
// Hostinger: ~500 emails/hora no plano padrão
// Para volume maior: usar BullMQ com Redis

import { Queue, Worker } from 'bullmq'
import IORedis from 'ioredis'

const connection = new IORedis(process.env.REDIS_URL!)

// Fila de emails
const emailQueue = new Queue('emails', { connection })

// Adicionar email à fila
export async function enfileirarEmail(dados: EmailDados) {
  await emailQueue.add('enviar', dados, {
    attempts: 3,
    backoff: { type: 'exponential', delay: 2000 },
  })
}

// Worker que processa a fila
const worker = new Worker('emails', async (job) => {
  await enviarEmail(job.data)
}, {
  connection,
  limiter: {
    max:       10,   // máximo 10 emails
    duration: 1000,  // por segundo (600/min — seguro abaixo do limite)
  },
})
```

---

## Variáveis de Ambiente

```env
SMTP_HOST=smtp.hostinger.com
SMTP_PORT=465
SMTP_USER=noreply@seudominio.com
SMTP_PASSWORD=sua_senha_de_email
SMTP_FROM_NAME=Nome do Seu App
```
