---
tags: [frontend]
categoria: "Frontend"
---

# Tailwind CSS — Guia de Referência

**Versão de referência:** Tailwind CSS v4 (lançado janeiro 2025)  
**Docs:** https://tailwindcss.com/docs  
**Mudança chave v4:** Configuração migrou de `tailwind.config.js` para CSS puro (`@theme` no `globals.css`)

---

## v4 vs v3: O que Mudou

| Aspecto | v3 | v4 |
|---|---|---|
| Configuração | `tailwind.config.js` | `@theme` no CSS |
| Utilitários customizados | `@layer utilities` | `@utility` |
| Performance | JIT | Rust engine (5x+ mais rápido) |
| `@apply` | Recomendado | Não recomendado — usar CSS direto |
| Container queries | Plugin | Nativo |
| Importação | `@tailwind base/components/utilities` | `@import "tailwindcss"` |

---

## Configuração v4 (globals.css)

```css
/* globals.css */
@import "tailwindcss";

/* ====================================================
   TOKENS DE DESIGN — @theme substitui tailwind.config
   ==================================================== */
@theme {
  /* Cores */
  --color-brand-50:  #f0f9ff;
  --color-brand-100: #e0f2fe;
  --color-brand-500: #0ea5e9;
  --color-brand-600: #0284c7;
  --color-brand-900: #0c4a6e;

  --color-bg-base:      #fafafa;
  --color-bg-elevated:  #ffffff;
  --color-text-primary: #18181b;

  /* Tipografia */
  --font-display: 'Fraunces Variable', serif;
  --font-body:    'Geist', sans-serif;
  --font-mono:    'Geist Mono', monospace;

  /* Espaçamento custom */
  --spacing-18: 4.5rem;
  --spacing-22: 5.5rem;

  /* Border radius */
  --radius-brand: 0.625rem;

  /* Animações */
  --animate-fade-up: fade-up 0.3s ease-out;
}

/* Keyframes customizados */
@keyframes fade-up {
  from { opacity: 0; transform: translateY(8px); }
  to   { opacity: 1; transform: translateY(0); }
}

/* Utilitários customizados (v4) */
@utility flex-center {
  display: flex;
  justify-content: center;
  align-items: center;
}

@utility text-balance {
  text-wrap: balance;
}

/* Dark mode com variáveis CSS */
@layer theme {
  .dark {
    --color-bg-base:      #09090b;
    --color-bg-elevated:  #18181b;
    --color-text-primary: #fafafa;
  }
}
```

**Com v4, as classes Tailwind ficam disponíveis automaticamente:**
```html
<!-- Tokens definidos em @theme viram classes automaticamente -->
<div class="bg-brand-500 text-brand-50 font-display">
  Usando tokens customizados
</div>
```

---

## Configuração v3 (tailwind.config.ts)

```typescript
// tailwind.config.ts
import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  darkMode: 'class',  // 'media' para preferência do sistema
  theme: {
    extend: {
      colors: {
        brand: {
          50:  '#f0f9ff',
          500: '#0ea5e9',
          900: '#0c4a6e',
        },
        background: 'hsl(var(--background))',  // CSS variables
        foreground:  'hsl(var(--foreground))',
      },
      fontFamily: {
        display: ['Fraunces Variable', 'serif'],
        body:    ['Geist', 'sans-serif'],
      },
      keyframes: {
        'fade-up': {
          from: { opacity: '0', transform: 'translateY(8px)' },
          to:   { opacity: '1', transform: 'translateY(0)' },
        },
      },
      animation: {
        'fade-up': 'fade-up 0.3s ease-out',
      },
    },
  },
}
export default config
```

---

## Helpers Essenciais: cn() + CVA

```typescript
// lib/utils.ts — instalar: npm install clsx tailwind-merge class-variance-authority
import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

// cn(): merge inteligente de classes (resolve conflitos)
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

// Por que não apenas clsx?
// clsx: "px-2 px-4" → "px-2 px-4" (ambas aplicadas, CSS ordem define)
// cn:   "px-2 px-4" → "px-4"       (última vence — comportamento esperado)
```

```typescript
// Componentes com variantes — cva
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const buttonVariants = cva(
  // Classes base — sempre aplicadas
  'inline-flex items-center justify-center font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50',
  {
    variants: {
      variant: {
        default:     'bg-brand-500 text-white hover:bg-brand-600 focus-visible:ring-brand-500',
        secondary:   'bg-zinc-100 text-zinc-900 hover:bg-zinc-200',
        outline:     'border border-zinc-300 bg-transparent hover:bg-zinc-50',
        ghost:       'hover:bg-zinc-100',
        destructive: 'bg-red-500 text-white hover:bg-red-600',
      },
      size: {
        sm:   'h-8  px-3 text-sm  rounded-md',
        md:   'h-10 px-4 text-sm  rounded-md',
        lg:   'h-11 px-6 text-base rounded-lg',
        icon: 'h-10 w-10 rounded-md',
      },
    },
    defaultVariants: {
      variant: 'default',
      size:    'md',
    },
  }
)

interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean
}

export function Button({ className, variant, size, ...props }: ButtonProps) {
  return (
    <button
      className={cn(buttonVariants({ variant, size }), className)}
      {...props}
    />
  )
}
```

---

## Responsividade: Mobile-First Obrigatório

```
Breakpoints padrão Tailwind:
sm:  640px  (≥ 640px)
md:  768px  (≥ 768px)
lg:  1024px (≥ 1024px)
xl:  1280px (≥ 1280px)
2xl: 1536px (≥ 1536px)
```

```html
<!-- Mobile-first: base sem prefixo, depois adiciona para telas maiores -->
<div class="
  flex flex-col gap-4      /* mobile: coluna */
  md:flex-row md:gap-6     /* tablet: linha */
  lg:gap-8                 /* desktop: mais espaço */
">

<!-- Container queries — componente responde ao SEU container, não à tela -->
<div class="@container">
  <div class="grid grid-cols-1 @md:grid-cols-2 @lg:grid-cols-3">
    <!-- Adapta baseado no tamanho do container pai, não do viewport -->
  </div>
</div>

<!-- max-* para upper limits (mobile-last, usar com moderação) -->
<p class="text-base max-md:text-sm">
  Texto base em desktop, menor em mobile
</p>
```

---

## Dark Mode com Classes

```html
<!-- dark: prefixo ativado com class="dark" no <html> -->
<div class="
  bg-white text-zinc-900              /* light */
  dark:bg-zinc-950 dark:text-zinc-50  /* dark */
">

<!-- Com tokens semânticos (melhor abordagem) -->
<div class="bg-background text-foreground">
  <!-- Troca de tema só altera as variáveis CSS — não precisa de dark: em todo lugar -->
</div>
```

```css
/* globals.css — tokens semânticos com dark mode */
:root {
  --background: 255 255 255;
  --foreground: 9 9 11;
}
.dark {
  --background: 9 9 11;
  --foreground: 250 250 250;
}

/* tailwind.config.ts */
// colors: { background: 'rgb(var(--background))', foreground: 'rgb(var(--foreground))' }
```

---

## Animações e Transições

```html
<!-- Transição básica -->
<button class="
  bg-brand-500
  transition-colors duration-150 ease-out
  hover:bg-brand-600
  active:scale-95 transition-transform
">

<!-- Fade up no mount (custom animation) -->
<div class="animate-fade-up">
  Aparece com animação
</div>

<!-- Reduced motion — sempre respeitar -->
<div class="animate-fade-up motion-reduce:animate-none">

<!-- Delay com arbitrary value -->
<div class="animate-fade-up [animation-delay:200ms]">
<div class="animate-fade-up [animation-delay:400ms]">
```

---

## Anti-Padrões Comuns

```html
<!-- ❌ Utility soup — classes demais num elemento -->
<button class="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600
  active:bg-blue-700 disabled:opacity-50 font-medium text-sm shadow-sm
  focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2
  transition-all duration-150 ease-in-out inline-flex items-center gap-2">
  <!-- Extraia para componente Button com CVA -->

<!-- ❌ Valores arbitrários desnecessários -->
<div class="mt-[13px] w-[342px] text-[13.5px]">
<!-- Use tokens do theme: mt-3, w-80, text-sm -->

<!-- ❌ @apply para tudo -->
.btn { @apply px-4 py-2 bg-blue-500 text-white rounded; }
<!-- Extraia para componente React, não CSS -->

<!-- ✅ Correto: componente com variantes via CVA -->
<Button variant="default" size="md">Clique aqui</Button>

<!-- ✅ Correto: cn() para condicionais -->
<div className={cn(
  'rounded-lg border p-4',
  isActive && 'border-brand-500 bg-brand-50',
  isError  && 'border-red-500 bg-red-50'
)}>
```

---

## Referências

→ `references/components.md` — biblioteca de componentes comuns: Card, Input, Badge, Modal  
→ `references/typography.md` — escala tipográfica, prose plugin, fluid typography


---

## Relacionado

[[React 19]] | [[Next.js 15]] | [[shadcn ui]] | [[HTML e CSS]]


---

## Referencias

- [[Referencias/components]]
