#!/bin/bash

VAULT="$HOME/Desktop/segundo-cerebro"
CLAUDE_DIR="$HOME/.claude"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
MARKER="# Segundo Cérebro"

mkdir -p "$CLAUDE_DIR"

if grep -q "$MARKER" "$CLAUDE_MD" 2>/dev/null; then
  echo "✅ Vault já configurado em ~/.claude/CLAUDE.md"
  exit 0
fi

cat >> "$CLAUDE_MD" << EOF

$MARKER

Este ambiente usa o vault Segundo Cérebro como referência técnica.
Caminho: $VAULT

Antes de implementar qualquer feature, consulte a skill correspondente no vault:

### ⚙️ Backend
- Docker / Compose → $VAULT/⚙️ Backend/Docker e Compose/README.md
- Prisma ORM → $VAULT/⚙️ Backend/Prisma ORM/README.md
- Node.js → $VAULT/⚙️ Backend/Node.js/README.md
- FastAPI (Python) → $VAULT/⚙️ Backend/FastAPI Python/README.md
- PostgreSQL → $VAULT/⚙️ Backend/PostgreSQL/README.md
- Segurança de Backend → $VAULT/⚙️ Backend/Backend Security/README.md
- Baileys (WhatsApp SDK) → $VAULT/⚙️ Backend/Baileys WhatsApp SDK/README.md
- Evolution API (WhatsApp) → $VAULT/⚙️ Backend/Evolution API WhatsApp/README.md
- Bunny.net CDN → $VAULT/⚙️ Backend/Bunny.net CDN/README.md

### 🎨 Frontend
- Next.js 15 → $VAULT/🎨 Frontend/Next.js 15/README.md
- React 19 → $VAULT/🎨 Frontend/React 19/README.md
- TypeScript → $VAULT/🎨 Frontend/TypeScript/README.md
- Tailwind CSS v4 → $VAULT/🎨 Frontend/Tailwind CSS v4/README.md
- shadcn/ui → $VAULT/🎨 Frontend/shadcn ui/README.md
- Supabase → $VAULT/🎨 Frontend/Supabase/README.md
- Vue 3 / Nuxt → $VAULT/🎨 Frontend/Vue 3 e Nuxt/README.md
- Vite → $VAULT/🎨 Frontend/Vite/README.md
- HTML e CSS → $VAULT/🎨 Frontend/HTML e CSS/README.md
- Boas Práticas Frontend → $VAULT/🎨 Frontend/Frontend Boas Praticas/README.md
- Design System → $VAULT/🎨 Frontend/Frontend Design System/README.md
- Design (geral) → $VAULT/🎨 Frontend/Frontend Design/README.md

### ✨ Animações
- GSAP → $VAULT/✨ Animacoes/GSAP Animacoes/README.md

### 📱 Mobile
- React Native / Expo → $VAULT/📱 Mobile/React Native Expo/README.md

### 🛠️ DevTools
- Git / GitHub Actions → $VAULT/🛠️ DevTools/Git e GitHub Actions/README.md
- Zod (validação) → $VAULT/🛠️ DevTools/Zod Validacao/README.md
- Code Review Graph → $VAULT/🛠️ DevTools/Code Review Graph/README.md
- Figma para Devs → $VAULT/🛠️ DevTools/Figma para Devs/README.md

### 🤖 IA e APIs
- Anthropic Claude API → $VAULT/🤖 IA e APIs/Anthropic Claude API/README.md
- OpenAI API → $VAULT/🤖 IA e APIs/OpenAI API/README.md
- Google Gemini API → $VAULT/🤖 IA e APIs/Google Gemini API/README.md
- Multi Agentes → $VAULT/🤖 IA e APIs/Multi Agentes/README.md
- Stripe → $VAULT/🤖 IA e APIs/Stripe Pagamentos/README.md
- Asaas → $VAULT/🤖 IA e APIs/Asaas Pagamentos/README.md

### 🎯 Design e Negócio
- Briefing / Identidade Visual → $VAULT/🎯 Design e Negocio/Briefing Identidade Visual/README.md
- Classificação Tipográfica → $VAULT/🎯 Design e Negocio/Classificacao Tipografica/README.md
EOF

echo "✅ Vault configurado em ~/.claude/CLAUDE.md"
echo "   O Claude Code consultará o vault em qualquer projeto."
