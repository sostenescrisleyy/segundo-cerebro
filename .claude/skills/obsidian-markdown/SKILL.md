---
name: obsidian-markdown
description: >
  Use when creating or editing Obsidian Markdown files (.md). Obsidian uses its own
  flavored Markdown with wikilinks, embeds, callouts, properties, and other Obsidian-specific
  syntax. Apply this skill whenever writing any .md file inside an Obsidian vault to ensure
  correct syntax, valid frontmatter, and proper wikilink formatting.
---

# Obsidian Flavored Markdown

Obsidian uses standard Markdown plus its own extensions. Always use Obsidian-specific
syntax when creating or editing files inside a vault.

---

## Frontmatter (Properties)

Every note can have YAML frontmatter between `---` delimiters at the very top of the file.

```markdown
---
tags: [tag1, tag2]
aliases: [Alternative Name, Short Name]
cssclasses: [class1, class2]
created: 2025-01-15
---
```

Rules:
- Frontmatter MUST be at the very first line — no blank lines before the opening `---`
- Tags are lowercase, no spaces (use hyphens: `my-tag`)
- `aliases` lets the note be found by other names via wikilinks

---

## Wikilinks (Internal Links)

Always use wikilinks for links between notes inside the vault. Never use relative
Markdown paths for internal links.

```markdown
[[Note Name]]                          → link to a note
[[Note Name|Display Text]]             → link with custom text
[[Folder/Note Name]]                   → link with path (use only if needed for disambiguation)
[[Note Name#Heading]]                  → link to a specific heading
[[Note Name#^block-id]]                → link to a specific block
![[Note Name]]                         → embed entire note inline
![[Note Name#Heading]]                 → embed a section
![[image.png]]                         → embed an image
![[Note Name|300]]                     → embed with width (images)
```

---

## Callouts

Callouts are styled blockquotes for highlighting content.

```markdown
> [!NOTE]
> This is a note callout.

> [!WARNING]
> This is a warning.

> [!TIP] Custom Title
> Callouts can have custom titles.

> [!INFO]- Collapsible callout (closed by default)
> This content is hidden until clicked.

> [!INFO]+ Collapsible callout (open by default)
> This content is visible by default but can be collapsed.
```

Available types: `NOTE` `INFO` `TIP` `WARNING` `DANGER` `ERROR` `EXAMPLE`
`ABSTRACT` `SUMMARY` `TLDR` `SUCCESS` `CHECK` `DONE` `QUESTION` `HELP` `FAQ`
`QUOTE` `CITE` `BUG` `TODO`

---

## Tags

```markdown
#tag                  → inline tag in note body
#parent/child         → nested tag hierarchy
#multi-word-tag       → hyphens for multi-word tags (no spaces)
```

Tags in frontmatter vs body:
- Frontmatter tags: `tags: [backend, typescript]` — preferred, always indexed
- Body tags: `#backend` inline in text — also valid, visible in note

---

## Highlights and Formatting

```markdown
==highlighted text==       → yellow highlight (Obsidian-specific)
~~strikethrough~~
**bold**
*italic*
***bold italic***
`inline code`
```

---

## Block References and IDs

```markdown
This is a paragraph with a block ID. ^my-block-id

[[Other Note#^my-block-id]]     → link to that specific block
![[Other Note#^my-block-id]]    → embed that specific block
```

Block IDs must be at the end of a line, start with `^`, contain only letters,
numbers, and hyphens.

---

## Checklist Tasks

```markdown
- [ ] Unchecked task
- [x] Completed task
- [/] In progress (Obsidian renders with a slash)
- [-] Cancelled (Obsidian renders with a dash)
```

---

## Best Practices for This Vault

- Use `[[wikilinks]]` for all internal links — never relative paths
- Add frontmatter to every note with at least `tags`
- Keep filenames clean: no accents, no special characters, spaces allowed
- Section headers follow the pattern: `## Section`, `### Subsection`
- Every skill README ends with a `## Relacionado` section of wikilinks
