# Performance Checklist — Antes do Deploy

## JavaScript
- [ ] Bundle analisado (vite-bundle-visualizer / next-bundle-analyzer)?
- [ ] Rotas com code splitting (dynamic imports)?
- [ ] Dependências pesadas importadas por método, não por pacote completo?
- [ ] `console.log` removidos de produção?
- [ ] Source maps de produção configurados?

## Imagens
- [ ] Todas as imagens em WebP (ou AVIF)?
- [ ] `width` e `height` definidos em todas as `<img>`?
- [ ] Imagens acima da dobra com `loading="eager"` e `fetchpriority="high"`?
- [ ] Imagens abaixo da dobra com `loading="lazy"`?
- [ ] `srcset` e `sizes` configurados para imagens responsive?
- [ ] SVGs inline para ícones críticos (evitar requests extras)?

## Fontes
- [ ] `font-display: swap` ou `optional` configurado?
- [ ] Apenas os pesos necessários carregados?
- [ ] `preconnect` para domínios de fontes externas?
- [ ] Fontes variáveis consideradas (1 arquivo, múltiplos pesos)?

## CSS
- [ ] CSS crítico (above-the-fold) inlined?
- [ ] CSS não-crítico carregado de forma lazy?
- [ ] Sem seletores com especificidade excessiva?
- [ ] Animações usando `transform` e `opacity` (não `top`/`left`/`width`)?

## Network
- [ ] HTTP/2 ou HTTP/3 configurado no servidor?
- [ ] Cache headers configurados (stale-while-revalidate)?
- [ ] CDN configurado para assets estáticos?
- [ ] Compressão Gzip/Brotli habilitada?
- [ ] `preload` para recursos críticos?
- [ ] `dns-prefetch` para domínios de terceiros?

## Core Web Vitals (Lighthouse)
- [ ] LCP < 2.5s?
- [ ] INP < 200ms?
- [ ] CLS < 0.1?
- [ ] Performance score > 90 (mobile)?

## Acessibilidade (Axe / Lighthouse)
- [ ] Sem erros de acessibilidade automáticos?
- [ ] Testado com teclado apenas (Tab, Enter, Esc)?
- [ ] Contraste de cor verificado?
- [ ] Screen reader testado (NVDA/VoiceOver)?


---

← [[README|Frontend Boas Praticas]]
