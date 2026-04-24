---
tags: [frontend]
categoria: "🎨 Frontend"
---

# Frontend Craft — UI com Intenção, Identidade e Sistema

## A Regra de Ouro

> **Nunca crie pixels sem antes entender o projeto.**  
> Um componente sem contexto de design system é lixo visual, não importa o quão tecnicamente correto seja.

Todo trabalho de frontend começa com uma pergunta: **o projeto já tem identidade?**

---

## Fase 1 — Descoberta do Design System

Antes de qualquer código, execute este diagnóstico. Leia o projeto como um detetive:

### 1.1 Sinais que revelam um design system existente

Procure por estes artefatos no projeto:

```
// Arquivos CSS/Tailwind que revelam tokens:
tailwind.config.ts → extend.colors, extend.fontFamily, extend.spacing
globals.css / tokens.css → variáveis CSS :root {}
theme.ts / tokens.ts → exportações de design tokens

// Arquivos de configuração de UI:
components/ui/ → shadcn, radix patterns
.storybook/ → componentes documentados
design-system/ → tokens, primitives

// Pistas no código existente:
className="text-brand-primary" → sistema de cores custom
style={{ color: 'var(--color-accent)' }} → CSS variables
font-family no global CSS → tipografia do projeto
```

### 1.2 O que extrair quando o sistema existe

Se encontrar sinais do design system, mapeie imediatamente:

| Dimensão | O que capturar | Onde encontrar |
|---|---|---|
| **Cor primária** | Hex + nome do token | tailwind.config, CSS vars |
| **Cor de fundo** | Base e variações | globals.css, theme |
| **Tipografia display** | Família, peso, tamanho | globals.css, layout |
| **Tipografia corpo** | Família, line-height | globals.css |
| **Espaçamento base** | Unidade (4px? 8px?) | padding/gap existentes |
| **Raio de borda** | Sharp? Arredondado? | buttons, cards existentes |
| **Sombras** | Estilo (flat, elevado?) | cards existentes |
| **Tom de voz** | Formal? Descontraído? | textos/labels existentes |

**Nunca assuma — sempre extraia do código real.**

---

## Fase 2 — Quando Não Existe Design System

Se o projeto não tem identidade definida, **PARE e pergunte**. Mas pergunte certo — não peça "qual cor você quer?". Pergunte de forma que revele a essência do produto.

### 2.1 As Perguntas Certas (máximo 4, nunca mais)

Escolha as mais relevantes para o contexto:

**Sobre o produto:**
- "Qual é o público principal — consumidor final, profissionais, B2B enterprise?"
- "O produto é mais utilitário (ferramenta) ou experiencial (produto de desejo)?"
- "Qual empresa ou produto do mercado tem o feeling que você admira?"

**Sobre a personalidade visual:**
- "Se a interface fosse um material, seria: vidro fosco, papel texturizado, metal escovado, ou madeira escura?"
- "O produto precisa transmitir mais: confiança, modernidade, acolhimento, ou poder?"
- "Prefere visual escuro (dark) ou claro (light) como padrão?"

**Sobre tipografia:**
- "Prefere texto com serifas (mais clássico/editorial) ou sem serifas (mais técnico/moderno)?"
- "Títulos devem chamar atenção com peso forte, ou manter leveza e elegância?"

**Sobre densidade:**
- "A interface tem mais dados (dashboard denso) ou mais respiro (produto de consumo)?"

### 2.2 Construindo o System Design do Zero

Com as respostas, monte os tokens antes do primeiro componente:

```css
/* ====================================================
   PRIMITIVE TOKENS — a paleta bruta
   ==================================================== */
:root {
  /* Escala de cores — nunca menos de 5 steps */
  --brand-50:  #f0f9ff;
  --brand-100: #e0f2fe;
  --brand-500: #0ea5e9;   /* ← cor principal */
  --brand-600: #0284c7;
  --brand-900: #0c4a6e;

  --neutral-50:  #fafafa;
  --neutral-100: #f4f4f5;
  --neutral-500: #71717a;
  --neutral-900: #18181b;
}

/* ====================================================
   SEMANTIC TOKENS — o significado
   ==================================================== */
:root {
  /* Superfícies */
  --color-bg-base:      var(--neutral-50);
  --color-bg-elevated:  #ffffff;
  --color-bg-sunken:    var(--neutral-100);

  /* Texto */
  --color-text-primary:   var(--neutral-900);
  --color-text-secondary: var(--neutral-500);
  --color-text-disabled:  var(--neutral-400);

  /* Ações */
  --color-action-primary:        var(--brand-500);
  --color-action-primary-hover:  var(--brand-600);
  --color-action-primary-text:   #ffffff;

  /* Feedback */
  --color-success: #16a34a;
  --color-warning: #d97706;
  --color-error:   #dc2626;
  --color-info:    var(--brand-500);

  /* Tipografia */
  --font-display: 'Cal Sans', 'Fraunces', serif;  /* impacto, personalidade */
  --font-body:    'Geist', 'DM Sans', sans-serif; /* legibilidade */
  --font-mono:    'Geist Mono', 'JetBrains Mono', monospace;

  /* Escala tipográfica (base 16px, razão 1.25) */
  --text-xs:   0.75rem;   /* 12px */
  --text-sm:   0.875rem;  /* 14px */
  --text-base: 1rem;      /* 16px */
  --text-lg:   1.25rem;   /* 20px */
  --text-xl:   1.5rem;    /* 24px */
  --text-2xl:  2rem;      /* 32px */
  --text-3xl:  2.5rem;    /* 40px */

  /* Espaçamento (base 4px) */
  --space-1: 0.25rem;  /* 4px */
  --space-2: 0.5rem;   /* 8px */
  --space-3: 0.75rem;  /* 12px */
  --space-4: 1rem;     /* 16px */
  --space-6: 1.5rem;   /* 24px */
  --space-8: 2rem;     /* 32px */
  --space-12: 3rem;    /* 48px */
  --space-16: 4rem;    /* 64px */

  /* Bordas */
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --radius-xl: 16px;
  --radius-full: 9999px;

  /* Sombras */
  --shadow-sm: 0 1px 2px rgba(0,0,0,0.04), 0 1px 6px rgba(0,0,0,0.04);
  --shadow-md: 0 4px 6px rgba(0,0,0,0.05), 0 10px 15px rgba(0,0,0,0.08);
  --shadow-lg: 0 20px 25px rgba(0,0,0,0.06), 0 40px 60px rgba(0,0,0,0.1);
}
```

---

## Fase 3 — Princípios de Execução

### 3.1 Tipografia com Personalidade

```css
/* ✅ Correto — fontes com caráter */
--font-display: 'Fraunces', 'Playfair Display', serif;    /* editorial */
--font-display: 'Space Grotesk', 'DM Sans', sans-serif;  /* tech moderno */
--font-display: 'Cabinet Grotesk', 'Syne', sans-serif;   /* contemporâneo */
--font-display: 'Instrument Serif', Georgia, serif;       /* refinado */

/* ❌ Errado — fontes genéricas de IA */
font-family: Inter, sans-serif;      /* overused ao extremo */
font-family: Roboto, sans-serif;     /* Google MD genérico */
font-family: -apple-system, sans-serif; /* invisível, sem identidade */
```

**Regra:** cada projeto merece pelo menos uma fonte display que não seja Inter. Use Google Fonts ou variáveis CSS com fallback digno.

### 3.2 Cores com Intenção

```css
/* ✅ Correto — hierarquia clara, não "todas as cores iguais" */
.heading { color: var(--color-text-primary); }     /* 100% opacidade */
.subtext { color: var(--color-text-secondary); }   /* ~60% luminosidade */
.caption { color: var(--color-text-disabled); }    /* ~40% luminosidade */

/* ✅ Correto — uma cor dominante, acentos pontuais */
background: var(--color-bg-base);           /* 70% da tela */
.card { background: var(--color-bg-elevated); }  /* 25% */
.badge { background: var(--color-action-primary); } /* 5% — impacto */

/* ❌ Errado — gradientes de IA sem propósito */
background: linear-gradient(135deg, #667eea, #764ba2);
background: linear-gradient(to right, #f093fb, #f5576c);
```

### 3.3 Espaçamento Consistente

Sempre use a escala de tokens, nunca valores soltos:

```css
/* ✅ Correto */
padding: var(--space-4) var(--space-6);
gap: var(--space-3);
margin-top: var(--space-8);

/* ❌ Errado */
padding: 13px 22px;   /* valores arbitrários quebram o ritmo visual */
gap: 7px;             /* número primo = sem sistema */
```

### 3.4 Componentes com Estado Completo

Todo componente interativo deve ter todos os estados:

```css
.button {
  /* Base */
  background: var(--color-action-primary);
  transition: all 150ms ease;

  /* Hover — sempre 1 step mais escuro/claro */
  &:hover { background: var(--color-action-primary-hover); }

  /* Focus — acessibilidade obrigatória */
  &:focus-visible {
    outline: 2px solid var(--color-action-primary);
    outline-offset: 2px;
  }

  /* Active — feedback tátil */
  &:active { transform: scale(0.98); }

  /* Disabled — sem pointer, redução visual */
  &:disabled {
    opacity: 0.45;
    cursor: not-allowed;
    pointer-events: none;
  }
}
```

---

## Fase 4 — O que NUNCA Fazer

### 4.1 Padrões proibidos (sinais de UI genérica de IA)

```
❌ Gradiente roxo/rosa em hero sections sem razão
❌ Cards com box-shadow: 0 2px 8px rgba(0,0,0,0.1) sem personalidade
❌ Todos os botões com border-radius: 8px (varia por projeto!)
❌ Usar Inter para tudo sem questionar
❌ Placeholder text cinza em todos os inputs iguais
❌ Ícones Heroicons/Feather sem adaptar ao tom do projeto
❌ Seções com padding-top: 80px; padding-bottom: 80px genérico
❌ Headers com logo + nav links + CTA button (copy-paste sem pensar)
❌ Footer com 3 colunas "Produto / Empresa / Legal" sem identidade
❌ Modal com overlay escuro 50% + card branco + título bold
```

### 4.2 Perguntas de checklist antes de entregar

- [ ] O componente usa tokens do projeto ou valores hardcoded?
- [ ] A tipografia tem personalidade própria ou é Inter/Roboto?
- [ ] As cores seguem a hierarquia (primário 5%, neutro 70%)?
- [ ] Todos os estados interativos estão implementados?
- [ ] O espaçamento usa a escala de 4/8px?
- [ ] O design comunica o tom de voz do produto?
- [ ] Se eu tirar o logo, dá para identificar a marca pelo visual?

---

## Fase 5 — Referências por Tipo de Projeto

→ Para patterns específicos por tipo de produto: `references/patterns-by-product.md`  
→ Para animações e micro-interações: `references/motion-system.md`  
→ Para acessibilidade e contraste WCAG: `references/accessibility.md`  
→ Para dark mode e temas: `references/theming.md`


---

## Relacionado

[[Tailwind CSS v4]] | [[React 19]] | [[Figma para Devs]] | [[Frontend Design]]


---

## Referencias

- [[Referencias/motion-system]]
- [[Referencias/patterns-by-product]]
- [[Referencias/theming]]
