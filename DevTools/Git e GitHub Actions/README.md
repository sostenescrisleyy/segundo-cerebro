---
tags: [devtools]
categoria: "DevTools"
---

# Git — Referência Completa

**Versão:** Git 2.45+  
**Princípio:** Commits atômicos, mensagens claras, histórico como documentação.

---

## Conventional Commits

Padrão para mensagens de commit legíveis e que geram CHANGELOGs automáticos.

```
<type>(<scope>): <descrição curta>

[corpo opcional]

[rodapé opcional: BREAKING CHANGE ou refs]
```

| Type | Quando usar |
|---|---|
| `feat` | Nova funcionalidade |
| `fix` | Correção de bug |
| `docs` | Documentação |
| `style` | Formatação, sem mudança lógica |
| `refactor` | Refatoração sem nova feature ou fix |
| `perf` | Melhoria de performance |
| `test` | Testes |
| `build` | Build system, dependências |
| `ci` | CI/CD |
| `chore` | Tarefas de manutenção |
| `revert` | Reverte commit anterior |

```bash
git commit -m "feat(auth): adicionar login com Google OAuth"
git commit -m "fix(api): corrigir timeout em requests de upload"
git commit -m "feat!: remover suporte ao Node 16"
# O ! indica BREAKING CHANGE
```

---

## Fluxo de Trabalho Diário

```bash
# ── Iniciar feature ───────────────────────────────────────────
git checkout main && git pull
git checkout -b feat/nome-da-feature

# ── Durante o desenvolvimento ─────────────────────────────────
git add -p                      # adicionar interativamente (hunk por hunk)
git add src/components/Button.tsx
git commit -m "feat(ui): adicionar componente Button"

git stash push -m "wip: rascunho do formulário"   # guardar temporariamente
git stash pop                                       # recuperar

# ── Atualizar branch com main ─────────────────────────────────
git fetch origin
git rebase origin/main          # preferível ao merge para branches de feature

# ── Antes do PR: limpar histórico ────────────────────────────
git rebase -i origin/main       # squash de commits WIP

# ── Merge na main (via PR geralmente) ─────────────────────────
git checkout main
git merge --no-ff feat/nome-da-feature
git push origin main
git branch -d feat/nome-da-feature
```

---

## Comandos de Recuperação

```bash
# Desfazer último commit (manter alterações staged)
git reset --soft HEAD~1

# Desfazer último commit (manter alterações unstaged)
git reset --mixed HEAD~1

# PERIGO: descartar último commit e alterações
git reset --hard HEAD~1

# Reverter commit sem alterar histórico (seguro em main)
git revert abc1234

# Recuperar arquivo deletado
git checkout HEAD -- src/arquivo-deletado.ts

# Ver o que foi deletado
git fsck --lost-found
```

---

## Rebase Interativo

```bash
git rebase -i HEAD~5  # editar os últimos 5 commits

# Comandos disponíveis na tela de rebase:
# p, pick   → manter commit
# r, reword → manter mas editar mensagem
# e, edit   → pausar para editar arquivos
# s, squash → juntar com commit anterior
# f, fixup  → como squash mas descarta mensagem
# d, drop   → remover commit
```

---

## Cherry-pick e Bisect

```bash
# Copiar commit específico para branch atual
git cherry-pick abc1234
git cherry-pick abc1234..def5678  # range de commits

# Bisect — encontrar commit que introduziu um bug
git bisect start
git bisect bad                    # commit atual tem o bug
git bisect good v1.2.0            # essa versão não tinha
# Git vai fazer checkout de commits no meio do range
# Marcar cada um:
git bisect good                   # ou
git bisect bad
# Ao final, Git mostra o commit problemático
git bisect reset                  # finalizar
```

---

## Tags e Releases

```bash
# Tag anotada (para releases)
git tag -a v1.0.0 -m "Release v1.0.0: autenticação e dashboard"
git push origin v1.0.0
git push origin --tags           # push de todas as tags

# Listar e deletar
git tag -l "v1.*"
git tag -d v1.0.0-beta
git push origin --delete v1.0.0-beta
```

---

## .gitignore Padrão (Node.js)

```gitignore
# Dependências
node_modules/

# Build
dist/
.next/
out/
build/

# Ambiente
.env
.env.local
.env.production
!.env.example

# Logs
*.log
npm-debug.log*

# OS
.DS_Store
Thumbs.db

# Editor
.vscode/
.idea/
*.swp
```

---

## Git Hooks com Husky

```bash
npm install -D husky lint-staged
npx husky init
```

```bash
# .husky/pre-commit
npx lint-staged

# .husky/commit-msg
npx --no -- commitlint --edit $1
```

```json
// package.json
{
  "lint-staged": {
    "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{json,md}": ["prettier --write"]
  }
}
```

---

## Referências

→ `references/github-actions.md` — CI/CD com GitHub Actions: build, test, deploy


---

## Relacionado

[[Docker e Compose]] | [[Node.js]]


---

## Referencias

- [[Referencias/github-actions]]
