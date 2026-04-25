---
tags: [frontend]
categoria: "Frontend"
---

# HTML Semântico e CSS Moderno

**Princípio:** HTML define significado, CSS define apresentação. Separação clara de responsabilidades. Semântica correta melhora SEO, acessibilidade e manutenção.

---

## HTML Semântico — Estrutura Correta

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="description" content="Descrição da página para SEO (150–160 chars)" />

  <!-- Open Graph (WhatsApp, LinkedIn, Facebook) -->
  <meta property="og:title"       content="Título da Página" />
  <meta property="og:description" content="Descrição para compartilhamento" />
  <meta property="og:image"       content="https://seusite.com/og-image.jpg" />
  <meta property="og:url"         content="https://seusite.com/pagina" />
  <meta property="og:type"        content="website" />

  <!-- Twitter/X Card -->
  <meta name="twitter:card"  content="summary_large_image" />
  <meta name="twitter:title" content="Título da Página" />

  <title>Título da Página | Nome do Site</title>
  <link rel="canonical" href="https://seusite.com/pagina" />
</head>
<body>
  <header>
    <nav aria-label="Navegação principal">
      <a href="/">Logo</a>
      <ul>
        <li><a href="/sobre">Sobre</a></li>
        <li><a href="/contato">Contato</a></li>
      </ul>
    </nav>
  </header>

  <main>
    <article>
      <header>
        <h1>Título Principal</h1>
        <time datetime="2025-07-01">1 de julho de 2025</time>
      </header>
      <section aria-labelledby="secao-intro">
        <h2 id="secao-intro">Introdução</h2>
        <p>Conteúdo...</p>
      </section>
    </article>

    <aside aria-label="Conteúdo relacionado">
      <h2>Leia também</h2>
    </aside>
  </main>

  <footer>
    <p><small>© 2025 Nome da Empresa</small></p>
  </footer>
</body>
</html>
```

**Tags semânticas essenciais:**

| Tag | Quando usar |
|---|---|
| `<header>` | Cabeçalho de página ou seção |
| `<nav>` | Grupo de links de navegação |
| `<main>` | Conteúdo principal (único por página) |
| `<article>` | Conteúdo independente e reutilizável |
| `<section>` | Agrupamento temático com título |
| `<aside>` | Conteúdo complementar/tangencial |
| `<footer>` | Rodapé de página ou seção |
| `<figure>` + `<figcaption>` | Imagem com legenda |
| `<time datetime="">` | Datas e horas |
| `<address>` | Informações de contato |

---

## CSS Custom Properties (Variáveis)

```css
/* :root = variáveis globais */
:root {
  /* Design tokens */
  --color-primary:   #7c3aed;
  --color-surface:   #ffffff;
  --color-text:      #18181b;
  --color-muted:     #71717a;

  --radius-sm: 0.25rem;
  --radius-md: 0.5rem;
  --radius-lg: 1rem;

  --shadow-sm: 0 1px 3px rgb(0 0 0 / 0.1);
  --shadow-md: 0 4px 16px rgb(0 0 0 / 0.12);

  --font-sans: 'Inter', system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', monospace;

  --spacing-unit: 0.25rem; /* 4px base */
}

/* Dark mode automático */
@media (prefers-color-scheme: dark) {
  :root {
    --color-surface: #09090b;
    --color-text:    #fafafa;
    --color-muted:   #a1a1aa;
  }
}

/* Ou dark mode manual com classe */
.dark {
  --color-surface: #09090b;
  --color-text:    #fafafa;
}
```

---

## CSS Grid — Layout Completo

```css
/* Grid responsivo sem media queries */
.grid-auto {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1.5rem;
}

/* Layout de página clássico */
.page-layout {
  display: grid;
  grid-template-areas:
    "header header"
    "sidebar main"
    "footer footer";
  grid-template-columns: 280px 1fr;
  grid-template-rows: auto 1fr auto;
  min-height: 100vh;
}

.page-layout > header  { grid-area: header; }
.page-layout > aside   { grid-area: sidebar; }
.page-layout > main    { grid-area: main; }
.page-layout > footer  { grid-area: footer; }

/* Centralizar qualquer coisa */
.center {
  display: grid;
  place-items: center;
}

/* Subgrid — filhos herdam colunas do pai */
.card-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
}
.card {
  display: grid;
  grid-row: span 3;
  grid-template-rows: subgrid; /* alinha título/body/footer entre cards */
}
```

---

## Flexbox — Casos de Uso

```css
/* Navbar */
.navbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

/* Centralizar verticalmente */
.hero {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
}

/* Sidebar + main que empurra footer para baixo */
.app {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}
.app main { flex: 1; }

/* Cards com altura igual */
.cards {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
}
.card {
  flex: 1 1 300px;      /* grow, shrink, basis */
  display: flex;
  flex-direction: column;
}
.card-body { flex: 1; } /* empurra footer do card para baixo */
```

---

## CSS Moderno — Funções e Features

```css
/* clamp() — tipografia fluida */
h1 { font-size: clamp(1.5rem, 5vw, 3rem); }
p  { font-size: clamp(1rem,  2vw, 1.25rem); }

/* Container queries — componente responde ao container */
.card-wrapper {
  container-type: inline-size;
  container-name: card;
}
@container card (min-width: 400px) {
  .card { flex-direction: row; }
}

/* aspect-ratio */
.thumbnail { aspect-ratio: 16 / 9; object-fit: cover; }
.avatar    { aspect-ratio: 1;      border-radius: 50%; }

/* :is() e :where() — seletores agrupados */
:is(h1, h2, h3) { line-height: 1.2; }
:where(ul, ol) > li + li { margin-top: 0.5rem; }

/* :has() — seletor pai */
.card:has(img)   { padding-top: 0; }
form:has(:invalid) button[type="submit"] { opacity: 0.5; }

/* Scroll snap */
.slider {
  display: flex;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  scroll-behavior: smooth;
}
.slide { scroll-snap-align: start; flex: 0 0 100%; }

/* Camadas (@layer) — controle de especificidade */
@layer reset, base, components, utilities;
@layer base { * { box-sizing: border-box; margin: 0; } }
```

---

## Animações e Transições

```css
/* Transição padrão */
.btn {
  transition: background-color 150ms ease, transform 100ms ease;
}
.btn:hover  { background-color: var(--color-primary-dark); }
.btn:active { transform: scale(0.97); }

/* Respeitar preferências de movimento */
@media (prefers-reduced-motion: no-preference) {
  .fade-in {
    animation: fadeIn 0.4s ease forwards;
  }
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(8px); }
  to   { opacity: 1; transform: translateY(0); }
}

/* View Transitions API */
::view-transition-old(root) { animation: slideOut 0.3s ease; }
::view-transition-new(root) { animation: slideIn  0.3s ease; }
```

---

## Acessibilidade Essencial

```html
<!-- Imagem: sempre alt -->
<img src="foto.jpg" alt="Descrição da imagem" />
<img src="decorativa.svg" alt="" role="presentation" />

<!-- Botão: sempre texto ou aria-label -->
<button aria-label="Fechar modal">✕</button>

<!-- Formulário: sempre label associado -->
<label for="email">E-mail</label>
<input id="email" type="email" required aria-describedby="email-error" />
<span id="email-error" role="alert">E-mail inválido</span>

<!-- Skip link (para leitores de tela) -->
<a href="#main-content" class="sr-only focus:not-sr-only">
  Pular para o conteúdo principal
</a>

<!-- Modal acessível -->
<dialog id="modal" aria-labelledby="modal-title" aria-modal="true">
  <h2 id="modal-title">Título do Modal</h2>
  <button autofocus>Fechar</button>
</dialog>
```

```css
/* Classe sr-only — visível apenas para leitores de tela */
.sr-only {
  position: absolute; width: 1px; height: 1px;
  padding: 0; margin: -1px; overflow: hidden;
  clip: rect(0,0,0,0); white-space: nowrap; border: 0;
}

/* Focus visible — anel de foco acessível */
:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}
:focus:not(:focus-visible) { outline: none; }
```

---

## Formulários Modernos

```html
<form novalidate>
  <!-- Input com validação nativa + aria -->
  <div class="field">
    <label for="nome">Nome completo <span aria-hidden="true">*</span></label>
    <input id="nome" name="nome" type="text"
           required minlength="3" maxlength="100"
           autocomplete="name"
           aria-required="true" />
  </div>

  <!-- Select -->
  <select id="estado" name="estado" autocomplete="address-level1">
    <option value="">Selecione o estado</option>
    <option value="SP">São Paulo</option>
    <option value="RJ">Rio de Janeiro</option>
  </select>

  <!-- Textarea -->
  <textarea id="mensagem" name="mensagem"
            rows="4" maxlength="500"
            placeholder="Sua mensagem..."></textarea>

  <!-- Checkbox / Radio -->
  <fieldset>
    <legend>Forma de contato</legend>
    <label><input type="radio" name="contato" value="email" /> E-mail</label>
    <label><input type="radio" name="contato" value="tel"   /> Telefone</label>
  </fieldset>
</form>
```

---

## Referências

→ `references/responsive.md` — Media queries, breakpoints, mobile-first  
→ `references/css-tricks.md` — Truques modernos: scroll-driven, mask, backdrop-filter


---

## Relacionado

[[Tailwind CSS v4]] | [[Frontend Design System]] | [[Frontend Boas Praticas]]


---

## Referencias

- [[Referencias/responsive]]
