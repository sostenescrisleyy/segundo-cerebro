---
name: json-canvas
description: >
  Use when creating or editing Obsidian Canvas files (.canvas). Canvas files use the
  JSON Canvas open format for visual boards with nodes, edges, groups, and connections.
  Apply when the user wants to create a visual map, diagram board, or canvas in Obsidian.
---

# JSON Canvas — Obsidian Canvas Files

Canvas files (`.canvas`) are visual boards using the open JSON Canvas format.
They contain nodes (cards, notes, files, web pages) and edges (connections between nodes).

---

## Basic Structure

```json
{
  "nodes": [],
  "edges": []
}
```

---

## Node Types

```json
{
  "nodes": [
    {
      "id": "node1",
      "type": "text",
      "text": "# Título\n\nConteúdo em markdown",
      "x": 0,
      "y": 0,
      "width": 300,
      "height": 150,
      "color": "1"
    },
    {
      "id": "node2",
      "type": "file",
      "file": "⚙️ Backend/Node.js/README.md",
      "x": 400,
      "y": 0,
      "width": 300,
      "height": 150
    },
    {
      "id": "node3",
      "type": "link",
      "url": "https://exemplo.com",
      "x": 800,
      "y": 0,
      "width": 300,
      "height": 150
    },
    {
      "id": "group1",
      "type": "group",
      "label": "Backend Skills",
      "x": -50,
      "y": -50,
      "width": 700,
      "height": 300,
      "color": "2"
    }
  ]
}
```

Node colors (built-in): `"1"` red · `"2"` orange · `"3"` yellow · `"4"` green · `"5"` cyan · `"6"` purple · or hex `"#ff0000"`

---

## Edges (Connections)

```json
{
  "edges": [
    {
      "id": "edge1",
      "fromNode": "node1",
      "toNode": "node2",
      "fromSide": "right",
      "toSide": "left",
      "label": "usa",
      "color": "4"
    }
  ]
}
```

Sides: `"top"` `"right"` `"bottom"` `"left"`

---

## Save Location

Canvas files go in the vault root or any subfolder:
```
segundo-cerebro/
├── mapa-backend.canvas
└── 🎨 Frontend/
    └── arquitetura-frontend.canvas
```

Open in Obsidian by clicking the `.canvas` file in the file explorer.
