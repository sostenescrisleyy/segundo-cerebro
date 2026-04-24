---
name: obsidian-cli
description: >
  Use when interacting with an Obsidian vault via the command line or when the user wants
  to open notes, run vault commands, or interact with Obsidian programmatically. Apply when
  asked to open a specific note in Obsidian, trigger vault commands, or work with the
  Obsidian URI scheme.
---

# Obsidian CLI and URI Scheme

Obsidian can be controlled from the command line and via URI scheme.
Use these patterns when the user wants to open notes or trigger vault actions.

---

## Obsidian URI Scheme

Open notes and execute commands via the `obsidian://` URI protocol.

```bash
# Open a specific note (URL-encode spaces as %20 or +)
open "obsidian://open?vault=segundo-cerebro&file=README"
open "obsidian://open?vault=segundo-cerebro&file=%E2%9A%99%EF%B8%8F%20Backend%2FNode.js%2FREADME"

# Search in vault
open "obsidian://search?vault=segundo-cerebro&query=docker"

# Create or open a note
open "obsidian://new?vault=segundo-cerebro&name=Nova%20Skill&content=conteudo"
```

On Linux, replace `open` with `xdg-open`.
On Windows, use `start` or `explorer`.

---

## Working with the Vault from Terminal

```bash
# Find all notes in vault
find /path/to/segundo-cerebro -name "*.md" -not -path "*/.obsidian/*" -not -path "*/.claude/*"

# Find notes by tag (in frontmatter)
grep -rl "tags:.*backend" /path/to/segundo-cerebro --include="*.md"

# Find notes containing specific text
grep -rl "Docker" /path/to/segundo-cerebro --include="*.md"

# List all skills (README files only)
find /path/to/segundo-cerebro -name "README.md" \
  -not -path "*/.obsidian/*" \
  -not -path "*/.claude/*"

# Count notes by category
for dir in /path/to/segundo-cerebro/*/; do
  echo "$(ls "$dir" | wc -l) $(basename "$dir")"
done
```

---

## Hot Reload / Refresh

After creating or editing files from the terminal while Obsidian is open,
Obsidian auto-detects file changes. If it doesn't refresh:

1. Click on any other note and back
2. Or use Cmd/Ctrl + R to reload the vault
3. Or run: `open "obsidian://open?vault=segundo-cerebro&file=README"`

---

## Vault Location

The vault is a plain folder of Markdown files. Common locations:

```
~/Documents/segundo-cerebro/       # macOS / Linux
C:\Users\name\Documents\segundo-cerebro\  # Windows
```

Claude Code runs from inside the vault root:
```bash
cd ~/Documents/segundo-cerebro
claude
```
