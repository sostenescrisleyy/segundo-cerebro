# GSAP ScrollTrigger — Patterns Avançados

## Horizontal Scroll

```javascript
const sections = gsap.utils.toArray('.panel')

gsap.to(sections, {
  xPercent: -100 * (sections.length - 1),
  ease: 'none',
  scrollTrigger: {
    trigger: '.horizontal-scroll',
    pin: true,
    scrub: 1,
    snap: 1 / (sections.length - 1),
    end: () => `+=${document.querySelector('.horizontal-scroll').offsetWidth}`,
  }
})
```

## Infinite Marquee

```javascript
gsap.to('.marquee-track', {
  x: '-50%',
  duration: 20,
  ease: 'none',
  repeat: -1,   // -1 = infinito
})
// Pausar no hover:
document.querySelector('.marquee').addEventListener('mouseenter', () => gsap.globalTimeline.pause())
document.querySelector('.marquee').addEventListener('mouseleave', () => gsap.globalTimeline.resume())
```

## Counter Animado

```javascript
gsap.to('.counter', {
  innerHTML: 5000,
  duration: 2,
  ease: 'power2.out',
  snap: { innerHTML: 1 },  // arredondar para inteiros
  scrollTrigger: { trigger: '.counter', start: 'top 80%' }
})
```

## Morph SVG (Club)

```javascript
import { MorphSVGPlugin } from 'gsap/MorphSVGPlugin'
gsap.registerPlugin(MorphSVGPlugin)

gsap.to('#shape1', {
  morphSVG: '#shape2',
  duration: 1,
  ease: 'power2.inOut',
})
```

## Debug

```javascript
// Ver todos os ScrollTriggers ativos
ScrollTrigger.getAll().forEach(st => console.log(st))

// Marcadores visuais
scrollTrigger: { markers: true }  // só usar em desenvolvimento!

// Forçar refresh após mudanças de layout
ScrollTrigger.refresh(true)
```


---

← [[README|GSAP Animacoes]]
