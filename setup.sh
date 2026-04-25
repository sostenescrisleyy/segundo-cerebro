#!/usr/bin/env bash
# Configura o vault Segundo Cérebro no Claude Code global.
# - Registra todas as skills no ~/.claude/CLAUDE.md
# - Instala o hook de contexto em ~/.claude/hooks/
# - Atualiza ~/.claude/settings.json para ativar o hook
#
# Seguro para rodar múltiplas vezes (idempotente).
# Uso:
#   bash setup.sh              # instalar
#   bash setup.sh --uninstall  # remover tudo

set -euo pipefail

VAULT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
SETTINGS="$CLAUDE_DIR/settings.json"
HOOKS_DIR="$CLAUDE_DIR/hooks"
HOOK_SCRIPT="$HOOKS_DIR/segundo-cerebro.sh"
MARKER="# Segundo Cérebro"

# ── Desinstalação ─────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--uninstall" ]]; then
  echo "🗑️  Removendo configuração do Segundo Cérebro..."

  # Remove bloco do CLAUDE.md
  if grep -q "$MARKER" "$CLAUDE_MD" 2>/dev/null; then
    perl -i -0pe "s/\n\Q$MARKER\E.*?(?=\n# |\z)//s" "$CLAUDE_MD"
    echo "   ✅ Bloco removido de ~/.claude/CLAUDE.md"
  fi

  # Remove hook script
  if [ -f "$HOOK_SCRIPT" ]; then
    rm "$HOOK_SCRIPT"
    echo "   ✅ Hook removido de ~/.claude/hooks/"
  fi

  # Remove hook do settings.json
  if command -v python3 &>/dev/null && [ -f "$SETTINGS" ]; then
    python3 - "$SETTINGS" <<'PY'
import json, sys
path = sys.argv[1]
try:
  with open(path) as f:
    s = json.load(f)
  ups = s.get("hooks", {}).get("UserPromptSubmit", [])
  s["hooks"]["UserPromptSubmit"] = [
    h for h in ups
    if not any("segundo-cerebro" in hh.get("command", "") for hh in h.get("hooks", []))
  ]
  with open(path, "w") as f:
    json.dump(s, f, indent=2, ensure_ascii=False)
  print("   ✅ Hook removido de settings.json")
except Exception as e:
  print(f"   ⚠️  Não foi possível atualizar settings.json: {e}")
PY
  fi

  echo ""
  echo "✅ Desinstalação concluída."
  exit 0
fi

# ── Instalação ────────────────────────────────────────────────────────────────
mkdir -p "$CLAUDE_DIR" "$HOOKS_DIR"

# ── 1. CLAUDE.md ──────────────────────────────────────────────────────────────
if grep -q "$MARKER" "$CLAUDE_MD" 2>/dev/null; then
  echo "✅ CLAUDE.md já configurado"
else
  cat >> "$CLAUDE_MD" << EOF

$MARKER

Este ambiente usa o vault Segundo Cérebro como referência técnica.
Caminho: $VAULT

Antes de implementar qualquer feature, consulte a skill correspondente no vault:

### Backend
- Docker / Compose → $VAULT/Backend/Docker e Compose/README.md
- Prisma ORM → $VAULT/Backend/Prisma ORM/README.md
- Node.js → $VAULT/Backend/Node.js/README.md
- FastAPI (Python) → $VAULT/Backend/FastAPI Python/README.md
- PostgreSQL → $VAULT/Backend/PostgreSQL/README.md
- Segurança de Backend → $VAULT/Backend/Backend Security/README.md
- Baileys (WhatsApp SDK) → $VAULT/Backend/Baileys WhatsApp SDK/README.md
- Evolution API (WhatsApp) → $VAULT/Backend/Evolution API WhatsApp/README.md
- Bunny.net CDN → $VAULT/Backend/Bunny.net CDN/README.md

### Frontend
- Next.js 15 → $VAULT/Frontend/Next.js 15/README.md
- React 19 → $VAULT/Frontend/React 19/README.md
- TypeScript → $VAULT/Frontend/TypeScript/README.md
- Tailwind CSS v4 → $VAULT/Frontend/Tailwind CSS v4/README.md
- shadcn/ui → $VAULT/Frontend/shadcn ui/README.md
- Supabase → $VAULT/Frontend/Supabase/README.md
- Vue 3 / Nuxt → $VAULT/Frontend/Vue 3 e Nuxt/README.md
- Vite → $VAULT/Frontend/Vite/README.md
- HTML e CSS → $VAULT/Frontend/HTML e CSS/README.md
- Boas Práticas Frontend → $VAULT/Frontend/Frontend Boas Praticas/README.md
- Design System → $VAULT/Frontend/Frontend Design System/README.md
- Design (geral) → $VAULT/Frontend/Frontend Design/README.md

### Animacoes
- Animacoes Web → $VAULT/Animacoes/Animacoes Web/README.md

### Mobile
- React Native / Expo → $VAULT/Mobile/React Native Expo/README.md

### DevTools
- Git / GitHub Actions → $VAULT/DevTools/Git e GitHub Actions/README.md
- Zod (validação) → $VAULT/DevTools/Zod Validacao/README.md
- Code Review Graph → $VAULT/DevTools/Code Review Graph/README.md
- Figma para Devs → $VAULT/DevTools/Figma para Devs/README.md

### IA e APIs
- Anthropic Claude API → $VAULT/IA e APIs/Anthropic Claude API/README.md
- OpenAI API → $VAULT/IA e APIs/OpenAI API/README.md
- Google Gemini API → $VAULT/IA e APIs/Google Gemini API/README.md
- Multi Agentes → $VAULT/IA e APIs/Multi Agentes/README.md
- Stripe → $VAULT/IA e APIs/Stripe Pagamentos/README.md
- Asaas → $VAULT/IA e APIs/Asaas Pagamentos/README.md

### Design e Negocio
- Briefing / Identidade Visual → $VAULT/Design e Negocio/Briefing Identidade Visual/README.md
- Classificação Tipográfica → $VAULT/Design e Negocio/Classificacao Tipografica/README.md

### Agentes
- Orquestrador → $VAULT/Agentes/Orquestrador/README.md
- Explorador de Codebase → $VAULT/Agentes/Explorador de Codebase/README.md
- Planejador de Projeto → $VAULT/Agentes/Planejador de Projeto/README.md
- Arqueologista de Codigo → $VAULT/Agentes/Arqueologista de Codigo/README.md
- Arquiteto de Banco → $VAULT/Agentes/Arquiteto de Banco/README.md
- Auditor de Seguranca → $VAULT/Agentes/Auditor de Seguranca/README.md
- Auditoria IA → $VAULT/Agentes/Auditoria IA/README.md
- Debugger → $VAULT/Agentes/Debugger/README.md
- DevOps Engineer → $VAULT/Agentes/DevOps Engineer/README.md
- Documentacao → $VAULT/Agentes/Documentacao/README.md
- Engenheiro de Testes → $VAULT/Agentes/Engenheiro de Testes/README.md
- Game Developer → $VAULT/Agentes/Game Developer/README.md
- Hostinger Email → $VAULT/Agentes/Hostinger Email/README.md
- Performance Imagens → $VAULT/Agentes/Performance Imagens/README.md
- Performance Web → $VAULT/Agentes/Performance Web/README.md
- Product Manager → $VAULT/Agentes/Product Manager/README.md
- SEO Specialist → $VAULT/Agentes/SEO Specialist/README.md

## Documentação Automática de Projetos

### Ao abrir qualquer projeto:
1. Verifique se existe .claude/docs/ no projeto atual
2. Se existir, leia os arquivos .md relevantes antes de começar
3. Se não existir e a sessão for de trabalho significativo:
   - Analise o projeto (package.json, estrutura, README existente)
   - Crie .claude/docs/PROJETO.md e .claude/docs/ARQUITETURA.md
   - Use os templates em $VAULT/templates/docs/
   - Ou execute: bash $VAULT/scripts/novo-projeto.sh

### Durante o trabalho, documente em .claude/docs/ quando:
- Tomar uma decisão arquitetural relevante → decisions/YYYYMMDD-titulo.md
- Descobrir um comportamento não óbvio do projeto → PROJETO.md (seção Gotchas)
- Mapear a estrutura do código → ARQUITETURA.md
- Encontrar um padrão importante do projeto → ARQUITETURA.md

### Quando criar uma nova skill no vault vs. doc de projeto:

| Criar SKILL no vault se...          | Criar DOC do projeto se...         |
|-------------------------------------|------------------------------------|
| Aprendeu sobre uma tech reusável    | Específico desta codebase          |
| Padrão de framework/biblioteca      | Regra de negócio local             |
| Integração com API/serviço externo  | Configuração do ambiente local     |
| Resolveu problema não documentado   | Bug fix de versão específica       |

### Para criar uma nova skill no vault:
1. cd $VAULT
2. mkdir -p "CATEGORIA/Nome da Skill/Referencias"
3. cp $VAULT/templates/skill/README.md "CATEGORIA/Nome da Skill/"
4. Edite com o conteúdo aprendido (frontmatter correto!)
5. Adicione o link no README.md raiz do vault
6. bash $VAULT/setup.sh (roda o setup sem duplicar — é idempotente)
EOF
  echo "✅ CLAUDE.md configurado"
fi

# ── 2. Hook script ─────────────────────────────────────────────────────────────
cat > "$HOOK_SCRIPT" << HOOK
#!/usr/bin/env bash
# Segundo Cérebro — injeta contexto de docs do projeto uma vez por sessão.
# Throttle: dispara uma vez a cada 2 horas por projeto.

PROJECT_DIR="\$(pwd)"
VAULT="$VAULT"
DOCS_DIR="\$PROJECT_DIR/.claude/docs"

# Não roda dentro do próprio vault
[[ "\$PROJECT_DIR" == "\$VAULT"* ]] && exit 0

# Throttle: uma vez a cada 2 horas por projeto
SESSION_KEY="sc-\$(printf '%s' "\$PROJECT_DIR" | cksum | cut -d' ' -f1)"
SESSION_FILE="/tmp/\$SESSION_KEY"

if [ -f "\$SESSION_FILE" ]; then
  ELAPSED=\$(( \$(date +%s) - \$(cat "\$SESSION_FILE" 2>/dev/null || echo 0) ))
  [ "\$ELAPSED" -lt 7200 ] && exit 0
fi
date +%s > "\$SESSION_FILE"

# Injeta contexto
echo ""
echo "┌─ SEGUNDO CÉREBRO ─────────────────────────────┐"

if [ -d "\$DOCS_DIR" ] && [ -n "\$(ls -A "\$DOCS_DIR" 2>/dev/null)" ]; then
  echo "│ 📁 Docs deste projeto (.claude/docs/):"
  find "\$DOCS_DIR" -name "*.md" | sort | while IFS= read -r f; do
    rel="\${f#\$DOCS_DIR/}"
    echo "│   • \$rel"
  done
  echo "│"
  echo "│ → Leia os docs relevantes antes de começar."
else
  echo "│ 📭 Nenhuma documentação em .claude/docs/ ainda."
  echo "│"
  echo "│ → Se for trabalho significativo, crie os docs:"
  echo "│   bash \$VAULT/scripts/novo-projeto.sh"
fi

echo "└────────────────────────────────────────────────┘"
echo ""
HOOK

chmod +x "$HOOK_SCRIPT"
echo "✅ Hook instalado em ~/.claude/hooks/"

# ── 3. settings.json ──────────────────────────────────────────────────────────
HOOK_CMD="bash \"$HOOK_SCRIPT\""

if grep -q "segundo-cerebro" "$SETTINGS" 2>/dev/null; then
  echo "✅ Hook já registrado em settings.json"
elif command -v python3 &>/dev/null; then
  python3 - "$SETTINGS" "$HOOK_CMD" <<'PY'
import json, sys, os

settings_path, hook_cmd = sys.argv[1], sys.argv[2]
settings = {}

if os.path.exists(settings_path):
  try:
    with open(settings_path) as f:
      settings = json.load(f)
  except json.JSONDecodeError:
    pass

settings.setdefault("hooks", {}).setdefault("UserPromptSubmit", []).append({
  "hooks": [{"type": "command", "command": hook_cmd}]
})

with open(settings_path, "w") as f:
  json.dump(settings, f, indent=2, ensure_ascii=False)

print("✅ Hook registrado em settings.json")
PY
else
  echo "⚠️  python3 não encontrado. Adicione manualmente ao $SETTINGS:"
  printf '   {"hooks":{"UserPromptSubmit":[{"hooks":[{"type":"command","command":"%s"}]}]}}\n' "$HOOK_CMD"
fi

# ── Resumo ────────────────────────────────────────────────────────────────────
echo ""
echo "✅ Segundo Cérebro configurado com sucesso!"
echo "   Vault: $VAULT"
echo "   Hook:  $HOOK_SCRIPT"
echo "   Settings: $SETTINGS"
echo ""
echo "   O Claude Code consultará o vault e os docs de cada projeto automaticamente."
echo "   Para desfazer: bash setup.sh --uninstall"
