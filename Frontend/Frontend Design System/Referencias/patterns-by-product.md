# Patterns por Tipo de Produto

## SaaS / Dashboard

**Tom:** Funcional, denso, eficiente — dados em primeiro lugar  
**Tipografia:** Sans-serif técnica (Geist, DM Sans, IBM Plex Sans)  
**Cores:** Neutros dominantes, uma cor de destaque para ações primárias, semânticas para status  
**Espaçamento:** Compacto (base 4px), tabelas densas, sidebars fixas

```css
/* Tokens recomendados para SaaS */
--font-body: 'Geist', 'DM Sans', sans-serif;
--color-bg-base: #0f172a;        /* dark default para dashboards */
--color-bg-elevated: #1e293b;
--color-border: rgba(255,255,255,0.08);
--radius-md: 6px;                /* mais sharp para dados */
```

**Padrões obrigatórios:**
- Sidebar com ícones + labels (não só ícones)
- Tabelas com row hover, sorting indicators, empty states
- Status badges com cores semânticas (não decorativas)
- Loading skeletons (não spinners) para dados assíncronos

---

## E-commerce / Produto de Consumo

**Tom:** Aspiracional, desejável, confiável  
**Tipografia:** Display com serifas para títulos (Fraunces, Instrument Serif), sans para corpo  
**Cores:** Neutros quentes, cor de destaque com personalidade de marca  
**Espaçamento:** Generoso, respiro entre produtos

```css
--font-display: 'Fraunces', 'Playfair Display', serif;
--font-body: 'DM Sans', sans-serif;
--color-bg-base: #faf9f7;       /* fundo levemente quente */
--color-bg-elevated: #ffffff;
--radius-lg: 16px;              /* mais suave, convidativo */
```

**Padrões obrigatórios:**
- Imagens de produto em alta qualidade, aspect-ratio fixo
- Add-to-cart com feedback imediato (animação no ícone carrinho)
- Reviews com stars semânticas (não só decorativas)
- Breadcrumb claro para navegação em categoria

---

## Startup / Landing Page

**Tom:** Impactante, proposta de valor clara em 3 segundos  
**Tipografia:** Display bold para hero, legível para features  
**Cores:** Uma identidade forte que diferencia da concorrência  
**Estrutura:** Hero → Problema → Solução → Prova → CTA

```css
--font-display: 'Cabinet Grotesk', 'Syne', sans-serif;
--font-body: 'Inter Variable', sans-serif;  /* OK aqui, só no corpo */
/* Hero deve ter fonte DIFERENTE do corpo */
```

**Regras anti-genérico para landing:**
- Nunca: hero com gradiente roxo + "The future of X"
- Sim: hero com contraste forte + proposta específica e real
- Logos de clientes SÓ se reais — nunca placeholder logos
- CTA principal com microcopy que reduz ansiedade ("Free forever", "No credit card")

---

## Fintech / Bancário

**Tom:** Confiança, segurança, clareza absoluta  
**Tipografia:** Sans-serif neutro e limpo (IBM Plex Sans, Söhne)  
**Cores:** Azul institucional + verde para positivo + vermelho para negativo  
**Densidade:** Dados precisos, hierarquia numérica clara

```css
--font-body: 'IBM Plex Sans', sans-serif;
--font-mono: 'IBM Plex Mono', monospace;  /* OBRIGATÓRIO para números */
--color-positive: #16a34a;
--color-negative: #dc2626;
--color-neutral: #2563eb;
```

**Regras críticas:**
- Números SEMPRE com fonte monospace tabular (font-variant-numeric: tabular-nums)
- Valores negativos sempre em vermelho, nunca apenas com sinal "-"
- Confirmações de ação irreversível com dois passos
- Máscaras em inputs de CPF/CNPJ/cartão, não validação só no submit

---

## Editorial / Blog / Portfolio

**Tom:** Voz própria, legibilidade como prioridade máxima  
**Tipografia:** Serif para corpo longo (Lora, Merriweather), display para títulos  
**Cores:** Pouquíssimas — neutralidade que não compete com o conteúdo  
**Layout:** Coluna de leitura max-width: 65ch

```css
--font-display: 'Fraunces', serif;
--font-body: 'Lora', 'Merriweather', serif;
--text-body-size: 1.125rem;     /* 18px — leitura confortável */
--line-height-body: 1.75;       /* respiro entre linhas */
--measure: 65ch;                /* largura ideal de leitura */
```

**Regras de tipografia editorial:**
- line-height mínimo 1.6 para corpo
- Parágrafos com max-width: 65ch (nunca full-width)
- Distinção clara entre h1, h2, h3 (não apenas tamanho, também peso e espaçamento)
- Drop caps ou run-ins para artigos longos


---

← [[README|Frontend Design System]]
