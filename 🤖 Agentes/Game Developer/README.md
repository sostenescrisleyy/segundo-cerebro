---
tags: [agentes]
categoria: "🤖 Agentes"
---


# Game Developer — Especialista em Desenvolvimento de Jogos

Especialista em jogos web, mobile e PC em múltiplas plataformas e engines.

---

## Seleção de Engine/Plataforma

```
O que você está construindo?
├── Jogo no browser → Phaser 3 (2D) / Three.js (3D) / Babylon.js (3D)
├── Jogo mobile (iOS + Android) → Unity ou Godot
├── Jogo PC indie → Godot (gratuito, MIT) ou Unity
├── Jogo AAA realista → Unreal Engine
├── Experiência 3D simples no browser → Three.js + React Three Fiber
└── Prototipagem rápida 2D → Godot
```

| Engine | Linguagem | Melhor Para | Licença |
|---|---|---|---|
| **Godot 4** | GDScript / C# | 2D/3D indie, prototipagem rápida | MIT (grátis) |
| **Unity** | C# | Mobile, cross-platform, ecossistema | Comercial |
| **Unreal Engine** | C++ / Blueprint | AAA, realismo visual | Royalty |
| **Phaser 3** | TypeScript | Jogos 2D no browser | MIT (grátis) |
| **Three.js** | JavaScript | Experiências 3D no browser | MIT (grátis) |

---

## Game Loop — Padrão Base

```typescript
// Game loop web com delta time correto
class Game {
  private lastTime = 0
  private isRunning = false

  start() {
    this.isRunning = true
    requestAnimationFrame(this.loop.bind(this))
  }

  private loop(currentTime: number) {
    if (!this.isRunning) return

    const deltaTime = Math.min((currentTime - this.lastTime) / 1000, 0.05)
    // Min: 0.05 evita physics explosion em tabs desativadas
    this.lastTime = currentTime

    this.update(deltaTime)  // física, IA, input — usa deltaTime
    this.render()           // desenha estado atual — sem deltaTime

    requestAnimationFrame(this.loop.bind(this))
  }

  private update(dt: number) {
    // Mover objetos com deltaTime (independente de FPS)
    this.player.x += this.player.velocityX * dt
    this.player.y += this.player.velocityY * dt
  }

  private render() {
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height)
    // Desenhar todos os objetos
  }
}
```

---

## Padrões de Design para Jogos

### Entity-Component System (ECS)

```typescript
// Para objetos complexos com muitos comportamentos
interface Component { update?(dt: number): void }

class Entity {
  private components = new Map<string, Component>()

  add(name: string, component: Component): this {
    this.components.set(name, component)
    return this
  }
  get<T extends Component>(name: string): T {
    return this.components.get(name) as T
  }
  update(dt: number) {
    this.components.forEach(c => c.update?.(dt))
  }
}

// Criar inimigo com comportamentos compostos
const inimigo = new Entity()
  .add('transform', new TransformComponent(100, 200))
  .add('health',    new HealthComponent(50))
  .add('ai',        new PatrolAIComponent())
  .add('physics',   new PhysicsComponent())
  .add('renderer',  new SpriteRenderer('inimigo.png'))
```

### State Machine (Player States)

```typescript
type PlayerState = 'idle' | 'running' | 'jumping' | 'attacking' | 'dead'

class PlayerStateMachine {
  private state: PlayerState = 'idle'

  private transitions: Record<PlayerState, Partial<Record<PlayerState, () => void>>> = {
    idle:      { running: this.startRunning,  jumping: this.startJump    },
    running:   { idle: this.stopRunning,       jumping: this.startJump    },
    jumping:   { idle: this.land                                           },
    attacking: { idle: this.finishAttack                                   },
    dead:      {}
  }

  transition(to: PlayerState) {
    const action = this.transitions[this.state][to]
    if (action) {
      action.call(this)
      this.state = to
    }
  }
}
```

### Object Pool (Balas/Partículas)

```typescript
// Evitar garbage collection com object pooling
class BulletPool {
  private pool: Bullet[] = []
  private active: Set<Bullet> = new Set()

  getBullet(): Bullet {
    // Reusar bullet inativa em vez de criar nova
    const bullet = this.pool.pop() ?? new Bullet()
    bullet.active = true
    this.active.add(bullet)
    return bullet
  }

  returnBullet(bullet: Bullet) {
    bullet.active = false
    this.active.delete(bullet)
    this.pool.push(bullet)  // devolver ao pool
  }

  update(dt: number) {
    this.active.forEach(bullet => {
      bullet.update(dt)
      if (bullet.isOutOfBounds()) {
        this.returnBullet(bullet)
      }
    })
  }
}
```

---

## Performance para Jogos

| Plataforma | FPS Alvo | Draw Calls | Polígonos |
|---|---|---|---|
| Browser 2D | 60 | < 100 | N/A |
| Browser 3D | 60 | < 150 | < 100K |
| Mobile | 60 | < 50 | < 50K |
| PC indie | 60-120 | < 1000 | < 1M |

```typescript
// Otimizações essenciais para browser games
// 1. Sprite sheets em vez de imagens individuais
const spriteSheet = new Image()
spriteSheet.src = '/sprites/characters.png'
ctx.drawImage(spriteSheet, srcX, srcY, 32, 32, destX, destY, 32, 32)

// 2. Canvas offscreen para elementos estáticos
const bgCanvas = document.createElement('canvas')
const bgCtx = bgCanvas.getContext('2d')!
// Desenhar background uma vez no bgCanvas
// Depois apenas blit no frame:
ctx.drawImage(bgCanvas, 0, 0)

// 3. Evitar garbage collection no hot path
const tempVector = { x: 0, y: 0 }  // reuso, não criar novo a cada frame
function calcularDirecao(from: Point, to: Point): typeof tempVector {
  tempVector.x = to.x - from.x
  tempVector.y = to.y - from.y
  return tempVector
}
```

---

## Anti-Padrões em Jogos

❌ Lógica dependente de FPS (usar deltaTime sempre)
❌ Spawn/destroy objetos frequentemente (usar object pools)
❌ Assets grandes na scene (usar asset bundles/lazy load)
❌ Cálculos pesados no render() (mover para update())
❌ Pular playtesting com jogadores reais

---

## Relacionado

- [[Performance Web]]
- [[Performance Imagens]]
