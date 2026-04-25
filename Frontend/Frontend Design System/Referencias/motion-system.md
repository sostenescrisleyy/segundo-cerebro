# Motion System — Animações com Propósito

## Princípios

1. **Animação serve à informação** — nunca ao ego
2. **Duração**: UI transitions 100–200ms, entrada de conteúdo 200–400ms, nunca > 600ms
3. **Easing**: ease-out para entradas, ease-in para saídas, ease-in-out para loops
4. **prefers-reduced-motion** é obrigatório

## Tokens de Motion

```css
:root {
  --duration-fast:   100ms;
  --duration-base:   200ms;
  --duration-slow:   350ms;
  --duration-enter:  400ms;

  --ease-out:     cubic-bezier(0.0, 0.0, 0.2, 1);
  --ease-in:      cubic-bezier(0.4, 0.0, 1, 1);
  --ease-in-out:  cubic-bezier(0.4, 0.0, 0.2, 1);
  --ease-spring:  cubic-bezier(0.34, 1.56, 0.64, 1); /* leve overshooting */
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

## Padrões Comuns

### Page entry (stagger)
```css
.item { opacity: 0; transform: translateY(12px); }
.item.visible {
  animation: fadeUp var(--duration-enter) var(--ease-out) forwards;
  animation-delay: calc(var(--index, 0) * 60ms);
}
@keyframes fadeUp {
  to { opacity: 1; transform: none; }
}
```

### Hover interativo
```css
.card {
  transition: transform var(--duration-base) var(--ease-out),
              box-shadow var(--duration-base) var(--ease-out);
}
.card:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-lg);
}
```

### Loading skeleton
```css
.skeleton {
  background: linear-gradient(90deg,
    var(--color-bg-sunken) 25%,
    var(--color-bg-elevated) 50%,
    var(--color-bg-sunken) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}
@keyframes shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
```

---

# Acessibilidade — WCAG 2.1 AA Mínimo

## Contraste obrigatório

| Tipo | Ratio mínimo | Ratio AAA |
|---|---|---|
| Texto normal (< 18px) | **4.5:1** | 7:1 |
| Texto grande (≥ 18px bold ou ≥ 24px) | **3:1** | 4.5:1 |
| Componentes UI e ícones | **3:1** | — |

```css
/* Verificar antes de usar */
/* white #fff sobre brand-500 #0ea5e9 = 2.9:1 ❌ (falha AA) */
/* white #fff sobre brand-700 #0369a1 = 5.2:1 ✅ */
```

**Ferramentas:** https://webaim.org/resources/contrastchecker/

## Focus visible obrigatório

```css
/* NUNCA remova outline sem substituir */
*:focus { outline: none; }  /* ❌ PROIBIDO */

/* ✅ Sempre substituir por algo visível */
*:focus-visible {
  outline: 2px solid var(--color-action-primary);
  outline-offset: 2px;
  border-radius: var(--radius-sm);
}
```

## Checklist rápido

- [ ] Imagens com alt descritivo (ou alt="" para decorativas)
- [ ] Botões com texto acessível (não só ícone)
- [ ] Formulários com `<label>` associado a cada input
- [ ] Erros de form anunciados via `aria-describedby`
- [ ] Modais com `role="dialog"` e foco preso dentro
- [ ] Tabelas com `<th scope="col/row">`
- [ ] Links descritivos (não "clique aqui")


---

← [[README|Frontend Design System]]
