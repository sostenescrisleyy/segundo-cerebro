---
tags: [devtools]
categoria: "DevTools"
---

# Figma — Guia para Desenvolvedores

**Princípio:** Figma é o ponto de verdade do design. Developers extraem tokens, assets e especificações para implementar fielmente.

---

## Dev Mode — Inspecionar Componentes

O Dev Mode (atalho `Ctrl/Cmd + Alt + D`) mostra:

- **CSS gerado** automaticamente para cada elemento
- **Medidas** e espaçamentos em pixels
- **Tokens** de variáveis (cores, tipografia, espaçamento)
- **Assets** prontos para exportar
- **Anotações** dos designers

**Atalhos essenciais:**
```
Ctrl/Cmd + Alt + C  → copiar CSS do elemento selecionado
Alt + clique        → medir distância entre elementos
Ctrl/Cmd + Alt + G  → agrupar
Ctrl/Cmd + clique   → selecionar dentro de grupo
Z                   → zoom to selection
```

---

## Figma API — Extrair Design Tokens

```typescript
// Buscar arquivo e extrair estilos
const FIGMA_TOKEN   = process.env.FIGMA_ACCESS_TOKEN
const FIGMA_FILE_ID = 'abc123xyz'

async function getFigmaFile() {
  const res = await fetch(
    `https://api.figma.com/v1/files/${FIGMA_FILE_ID}`,
    { headers: { 'X-Figma-Token': FIGMA_TOKEN } }
  )
  return res.json()
}

// Buscar estilos do arquivo
async function getFigmaStyles() {
  const res = await fetch(
    `https://api.figma.com/v1/files/${FIGMA_FILE_ID}/styles`,
    { headers: { 'X-Figma-Token': FIGMA_TOKEN } }
  )
  return res.json()
}

// Exportar assets (ícones, imagens)
async function exportAssets(nodeIds: string[]) {
  const ids = nodeIds.join(',')
  const res = await fetch(
    `https://api.figma.com/v1/images/${FIGMA_FILE_ID}?ids=${ids}&format=svg&scale=1`,
    { headers: { 'X-Figma-Token': FIGMA_TOKEN } }
  )
  const { images } = await res.json()
  // images = { [nodeId]: 'https://cdn.figma.com/...' }
  return images
}
```

---

## Variáveis do Figma → CSS Tokens

O Figma Variáveis (novo sistema) pode ser exportado e convertido em CSS/JS:

```typescript
// Script para extrair variáveis do Figma e gerar tokens CSS
async function generateTokens() {
  const res = await fetch(
    `https://api.figma.com/v1/files/${FIGMA_FILE_ID}/variables/local`,
    { headers: { 'X-Figma-Token': FIGMA_TOKEN } }
  )
  const { meta: { variables, variableCollections } } = await res.json()

  // Gerar :root CSS
  const cssVars = Object.values(variables)
    .map((v: any) => {
      const name  = v.name.replaceAll('/', '-').toLowerCase()
      const value = v.resolvedValuesByMode[Object.keys(v.resolvedValuesByMode)[0]]
      if (v.resolvedType === 'COLOR') {
        const { r, g, b, a } = value.resolvedValue
        return `  --${name}: rgba(${Math.round(r*255)}, ${Math.round(g*255)}, ${Math.round(b*255)}, ${a});`
      }
      if (v.resolvedType === 'FLOAT') {
        return `  --${name}: ${value.resolvedValue}px;`
      }
      return `  --${name}: ${value.resolvedValue};`
    })
    .join('\n')

  return `:root {\n${cssVars}\n}`
}
```

---

## Auto-layout → Flexbox/Grid

O Auto-layout do Figma mapeia diretamente para CSS:

| Figma Auto-layout | CSS equivalente |
|---|---|
| Horizontal | `display: flex; flex-direction: row` |
| Vertical | `display: flex; flex-direction: column` |
| Gap | `gap: Xpx` |
| Padding | `padding: top right bottom left` |
| Fill container | `flex: 1` |
| Hug contents | `width: fit-content` / `height: fit-content` |
| Fixed width/height | `width: Xpx; height: Xpx` |
| Align center | `align-items: center; justify-content: center` |
| Wrap | `flex-wrap: wrap` |

---

## Plugins Úteis para Devs

- **Figma Tokens** — exportar variáveis como JSON/CSS para Style Dictionary
- **Inspect** — inspeção melhorada com código
- **CSS to Figma** — converter CSS em componente Figma
- **Iconify** — biblioteca de ícones diretamente no Figma
- **Stark** — verificar contraste de acessibilidade (WCAG)
- **Content Reel** — preencher designs com dados reais

---

## Boas Práticas de Handoff

**O que pedir ao designer antes de implementar:**

- Nomes de variáveis de cores e tipografia (tokens)
- Comportamento responsivo definido (breakpoints)
- Estados: hover, focus, disabled, loading, error
- Animações e transições especificadas
- Versão mobile dos componentes
- Grid e margens definidos

**Fluxo recomendado:**
1. Checar se há Design System / componentes reutilizáveis no Figma
2. Extrair tokens do Dev Mode antes de escrever CSS
3. Verificar TODOS os estados do componente (não só o happy path)
4. Tirar dúvidas no Figma com comentário no próprio arquivo
5. Usar `Inspect` → `Copy as CSS` como ponto de partida


---

## Relacionado

[[Frontend Design System]] | [[Classificacao Tipografica]] | [[Frontend Design]]


---

## Referencias

- [[Referencias/extra]]
