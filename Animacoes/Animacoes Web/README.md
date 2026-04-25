---
tags: [animacoes]
categoria: "Animacoes"
---

# Animações Web

**Biblioteca:** gsap (pacote npm)  
**Quando usar:** sequenciamento complexo, scroll-linked animations, controle preciso de tempo, ou animações que CSS não consegue fazer bem.

---

## Setup

```bash
npm install gsap
# React:
npm install @gsap/react
```

```typescript
// Registrar plugins UMA VEZ por app (antes de qualquer uso)
import { gsap } from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import { Flip } from 'gsap/Flip'
import { SplitText } from 'gsap/SplitText'  // Club GSAP (pago)

gsap.registerPlugin(ScrollTrigger, Flip, SplitText)
```

---

## Core API — Tweens

```javascript
// gsap.to() — do estado atual para o destino
gsap.to('.box', {
  x: 100,          // translateX (transform — nunca use left/top)
  y: 50,
  rotation: 45,
  scale: 1.2,
  autoAlpha: 1,    // opacity + visibility (preferir sobre opacity)
  duration: 0.6,
  ease: 'power2.inOut',
  delay: 0.2,
})

// gsap.from() — do estado definido para o estado atual
gsap.from('.hero-title', {
  opacity: 0,
  y: 30,
  duration: 0.8,
  ease: 'power3.out',
})

// gsap.fromTo() — controle total de início e fim
gsap.fromTo('.card',
  { opacity: 0, scale: 0.9 },
  { opacity: 1, scale: 1, duration: 0.5, ease: 'back.out(1.7)' }
)

// Stagger — animar múltiplos elementos em sequência
gsap.from('.card', {
  opacity: 0,
  y: 20,
  duration: 0.5,
  stagger: 0.08,       // 80ms entre cada elemento
  ease: 'power2.out',
})

// Stagger avançado (grid)
gsap.from('.grid-item', {
  scale: 0,
  stagger: {
    amount: 1,         // total de tempo para todos
    from: 'center',    // 'start' | 'end' | 'center' | 'edges' | índice
    grid: 'auto',
  }
})
```

---

## Timelines — Sequenciamento

```javascript
// Timeline básica (prefira sobre chaining com delay)
const tl = gsap.timeline({
  defaults: { duration: 0.5, ease: 'power2.out' },  // defaults para todos os tweens
  paused: true,     // não iniciar automaticamente
})

tl
  .from('.nav',     { opacity: 0, y: -20 })
  .from('.hero-h1', { opacity: 0, x: -40 })         // imediatamente após
  .from('.hero-p',  { opacity: 0, x: -40 }, '-=0.3') // 0.3s antes do anterior terminar
  .from('.hero-btn',{ opacity: 0, y: 20 }, '+=0.1')  // 0.1s após o anterior terminar
  .from('.hero-img',{ opacity: 0, scale: 0.9 }, 0.2) // 0.2s a partir do início da timeline

// Position parameter:
// sem parâmetro → após o anterior
// '<'           → mesmo momento que o anterior começa
// '<0.2'        → 0.2s após o anterior começar
// '-=0.3'       → 0.3s antes do anterior terminar
// '+=0.2'       → 0.2s após o anterior terminar
// 1.5           → tempo absoluto desde o início
// 'label'       → na posição de uma label

// Labels
tl.addLabel('phase2', '+=0.5')
tl.from('.section2', { opacity: 0 }, 'phase2')

// Controlar playback
tl.play()
tl.pause()
tl.reverse()
tl.seek(1.5)       // ir para o segundo 1.5
tl.progress(0.5)   // ir para o meio
```

---

## ScrollTrigger

```javascript
import { ScrollTrigger } from 'gsap/ScrollTrigger'
gsap.registerPlugin(ScrollTrigger)

// Animação ativada por scroll
gsap.from('.section-title', {
  opacity: 0,
  y: 50,
  scrollTrigger: {
    trigger: '.section-title',
    start: 'top 80%',     // [elemento] [viewport] — quando o top do elemento atinge 80% da viewport
    end: 'bottom 20%',
    toggleActions: 'play none none reverse',  // onEnter, onLeave, onEnterBack, onLeaveBack
    // toggleActions: 'play pause resume reset'
  }
})

// Scrub — animação vinculada à posição do scroll
gsap.to('.parallax-bg', {
  yPercent: -30,
  ease: 'none',       // IMPORTANTE: ease:'none' no scrub
  scrollTrigger: {
    trigger: '.hero',
    start: 'top top',
    end: 'bottom top',
    scrub: true,      // true = suave | número = lag em segundos
  }
})

// Pin — fixar elemento durante scroll
gsap.timeline({
  scrollTrigger: {
    trigger: '.sticky-section',
    pin: true,             // fixa o elemento
    start: 'top top',
    end: '+=500',          // 500px de scroll enquanto pinned
    scrub: 1,
  }
})
.from('.text-1', { opacity: 0 })
.from('.text-2', { opacity: 0 })
.from('.text-3', { opacity: 0 })

// Cleanup CRÍTICO
// ScrollTrigger cria instâncias que precisam ser destruídas
ScrollTrigger.refresh()  // chamar após mudanças de layout
// No React: usar gsap.context() ou useGSAP (ver seção React)
```

---

## GSAP + React — useGSAP Hook

```tsx
import { useRef } from 'react'
import { gsap } from 'gsap'
import { useGSAP } from '@gsap/react'
import { ScrollTrigger } from 'gsap/ScrollTrigger'

gsap.registerPlugin(useGSAP, ScrollTrigger)

function HeroSection() {
  const containerRef = useRef<HTMLDivElement>(null)

  // useGSAP — cleanup automático na desmontagem
  useGSAP(() => {
    // SEMPRE usar scope (containerRef) para seletores CSS
    gsap.from('.hero-title', {
      opacity: 0,
      y: 30,
      duration: 0.8,
      ease: 'power3.out',
    })

    gsap.from('.hero-card', {
      opacity: 0,
      scale: 0.95,
      stagger: 0.1,
      scrollTrigger: {
        trigger: '.hero-cards',
        start: 'top 75%',
      }
    })

  }, { scope: containerRef })  // escopar seletores ao container

  return (
    <div ref={containerRef}>
      <h1 className="hero-title">...</h1>
      <div className="hero-cards">...</div>
    </div>
  )
}

// Alternativa: gsap.context() com useEffect
useEffect(() => {
  const ctx = gsap.context(() => {
    gsap.to('.box', { x: 100 })
  }, containerRef)

  return () => ctx.revert()  // cleanup
}, [])
```

---

## Plugins Essenciais

### Flip — Transições de Layout Mágicas
```javascript
import { Flip } from 'gsap/Flip'
gsap.registerPlugin(Flip)

// Capturar estado → mudar DOM → animar a mudança
const state = Flip.getState('.item')  // captura posição/tamanho atual
// ... mudar classes/layout ...
Flip.from(state, {
  duration: 0.5,
  ease: 'power2.inOut',
  absolute: true,   // usar position absolute durante a animação
})
```

### SplitText — Animar Letras/Palavras/Linhas (Club)
```javascript
import { SplitText } from 'gsap/SplitText'
gsap.registerPlugin(SplitText)

const split = new SplitText('.headline', { type: 'words,chars' })

gsap.from(split.chars, {
  opacity: 0,
  y: 20,
  rotationX: -90,
  stagger: 0.02,
  duration: 0.6,
  ease: 'back.out(1.7)',
})

// Limpeza após animação
split.revert()
```

---

## Easings Úteis

```javascript
// Mais usados
'power2.out'          // suave — saída rápida e pouso suave (padrão recomendado)
'power3.inOut'        // transição entre estados
'back.out(1.7)'       // pequeno overshoot — sensação elástica
'elastic.out(1, 0.3)' // elástico dramático
'bounce.out'          // quique realista
'expo.out'            // entrada muito rápida, parada precisa
'circ.inOut'          // circular suave
'none'                // linear — OBRIGATÓRIO para scrub animations
```

---

## Performance — Regras de Ouro

```javascript
// ✅ Animar sempre com transform e opacity (GPU compositing)
gsap.to('.box', { x: 100, y: 50, scale: 1.1, opacity: 0.8 })

// ❌ NUNCA animar propriedades de layout (triggeram reflow)
// gsap.to('.box', { left: 100, width: 200, height: 150 })

// ✅ will-change para elementos animados continuamente
.animated-element { will-change: transform; }
// Remover após animação terminar para liberar memória

// ✅ Batch ScrollTriggers
ScrollTrigger.batch('.card', {
  onEnter: els => gsap.from(els, { opacity: 0, y: 30, stagger: 0.05 }),
})

// ✅ Limpar instâncias não usadas
ScrollTrigger.getAll().forEach(st => st.kill())
```

---

## Referências

→ `references/scrolltrigger-patterns.md` — Horizontal scroll, pinning avançado, infinite loops


---

## Relacionado

[[React 19]] | [[Frontend Design]] | [[Vite]]


---

## Referencias

- [[Referencias/scrolltrigger-patterns]]
