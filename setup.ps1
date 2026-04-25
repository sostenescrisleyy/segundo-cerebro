# setup.ps1 — Configura o vault Segundo Cérebro no Claude Code global (Windows).
# - Registra todas as skills no ~\.claude\CLAUDE.md
# - Instala o hook de contexto em ~\.claude\hooks\
# - Atualiza ~\.claude\settings.json para ativar o hook
#
# Uso:
#   .\setup.ps1              # instalar
#   .\setup.ps1 -Uninstall   # remover tudo

param([switch]$Uninstall)

$ErrorActionPreference = "Stop"

$VAULT      = $PSScriptRoot
$CLAUDE_DIR = Join-Path $env:USERPROFILE ".claude"
$CLAUDE_MD  = Join-Path $CLAUDE_DIR "CLAUDE.md"
$SETTINGS   = Join-Path $CLAUDE_DIR "settings.json"
$HOOKS_DIR  = Join-Path $CLAUDE_DIR "hooks"
$HOOK_SCRIPT= Join-Path $HOOKS_DIR "segundo-cerebro.ps1"
$MARKER     = "# Segundo Cérebro"
$V          = $VAULT.Replace("\", "/")   # Forward slashes para paths no CLAUDE.md

# ── Desinstalação ─────────────────────────────────────────────────────────────
if ($Uninstall) {
  Write-Host "🗑️  Removendo configuração do Segundo Cérebro..."

  if (Test-Path $CLAUDE_MD) {
    $content = Get-Content $CLAUDE_MD -Raw -Encoding UTF8
    if ($content -match [regex]::Escape($MARKER)) {
      $cleaned = $content -replace ("(?s)\r?\n" + [regex]::Escape($MARKER) + ".*?(?=\r?\n# |\z)"), ""
      Set-Content -Path $CLAUDE_MD -Value $cleaned -Encoding UTF8 -NoNewline
      Write-Host "   ✅ Bloco removido de ~/.claude/CLAUDE.md"
    }
  }

  if (Test-Path $HOOK_SCRIPT) {
    Remove-Item $HOOK_SCRIPT
    Write-Host "   ✅ Hook removido"
  }

  if (Test-Path $SETTINGS) {
    $s = Get-Content $SETTINGS -Raw | ConvertFrom-Json
    if ($s.hooks -and $s.hooks.UserPromptSubmit) {
      $s.hooks.UserPromptSubmit = @(
        $s.hooks.UserPromptSubmit | Where-Object {
          -not ($_.hooks | Where-Object { $_.command -like "*segundo-cerebro*" })
        }
      )
      $s | ConvertTo-Json -Depth 10 | Set-Content $SETTINGS -Encoding UTF8
      Write-Host "   ✅ Hook removido de settings.json"
    }
  }

  Write-Host ""
  Write-Host "✅ Desinstalação concluída."
  exit 0
}

# ── Instalação ────────────────────────────────────────────────────────────────
foreach ($dir in @($CLAUDE_DIR, $HOOKS_DIR)) {
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
}

# ── 1. CLAUDE.md ──────────────────────────────────────────────────────────────
$alreadyMd = (Test-Path $CLAUDE_MD) -and ((Get-Content $CLAUDE_MD -Raw -Encoding UTF8) -match [regex]::Escape($MARKER))
if ($alreadyMd) {
  Write-Host "✅ CLAUDE.md já configurado"
} else {
  $block = @"


$MARKER

Este ambiente usa o vault Segundo Cérebro como referência técnica.
Caminho: $V

Antes de implementar qualquer feature, consulte a skill correspondente no vault:

### Backend
- Docker / Compose → $V/Backend/Docker e Compose/README.md
- Prisma ORM → $V/Backend/Prisma ORM/README.md
- Node.js → $V/Backend/Node.js/README.md
- FastAPI (Python) → $V/Backend/FastAPI Python/README.md
- PostgreSQL → $V/Backend/PostgreSQL/README.md
- Segurança de Backend → $V/Backend/Backend Security/README.md
- Baileys (WhatsApp SDK) → $V/Backend/Baileys WhatsApp SDK/README.md
- Evolution API (WhatsApp) → $V/Backend/Evolution API WhatsApp/README.md
- Bunny.net CDN → $V/Backend/Bunny.net CDN/README.md

### Frontend
- Next.js 15 → $V/Frontend/Next.js 15/README.md
- React 19 → $V/Frontend/React 19/README.md
- TypeScript → $V/Frontend/TypeScript/README.md
- Tailwind CSS v4 → $V/Frontend/Tailwind CSS v4/README.md
- shadcn/ui → $V/Frontend/shadcn ui/README.md
- Supabase → $V/Frontend/Supabase/README.md
- Vue 3 / Nuxt → $V/Frontend/Vue 3 e Nuxt/README.md
- Vite → $V/Frontend/Vite/README.md
- HTML e CSS → $V/Frontend/HTML e CSS/README.md
- Boas Práticas Frontend → $V/Frontend/Frontend Boas Praticas/README.md
- Design System → $V/Frontend/Frontend Design System/README.md
- Design (geral) → $V/Frontend/Frontend Design/README.md

### Animacoes
- Animacoes Web → $V/Animacoes/Animacoes Web/README.md

### Mobile
- React Native / Expo → $V/Mobile/React Native Expo/README.md

### DevTools
- Git / GitHub Actions → $V/DevTools/Git e GitHub Actions/README.md
- Zod (validação) → $V/DevTools/Zod Validacao/README.md
- Code Review Graph → $V/DevTools/Code Review Graph/README.md
- Figma para Devs → $V/DevTools/Figma para Devs/README.md

### IA e APIs
- Anthropic Claude API → $V/IA e APIs/Anthropic Claude API/README.md
- OpenAI API → $V/IA e APIs/OpenAI API/README.md
- Google Gemini API → $V/IA e APIs/Google Gemini API/README.md
- Multi Agentes → $V/IA e APIs/Multi Agentes/README.md
- Stripe → $V/IA e APIs/Stripe Pagamentos/README.md
- Asaas → $V/IA e APIs/Asaas Pagamentos/README.md

### Design e Negocio
- Briefing / Identidade Visual → $V/Design e Negocio/Briefing Identidade Visual/README.md
- Classificação Tipográfica → $V/Design e Negocio/Classificacao Tipografica/README.md

### Agentes
- Orquestrador → $V/Agentes/Orquestrador/README.md
- Explorador de Codebase → $V/Agentes/Explorador de Codebase/README.md
- Planejador de Projeto → $V/Agentes/Planejador de Projeto/README.md
- Arqueologista de Codigo → $V/Agentes/Arqueologista de Codigo/README.md
- Arquiteto de Banco → $V/Agentes/Arquiteto de Banco/README.md
- Auditor de Seguranca → $V/Agentes/Auditor de Seguranca/README.md
- Auditoria IA → $V/Agentes/Auditoria IA/README.md
- Debugger → $V/Agentes/Debugger/README.md
- DevOps Engineer → $V/Agentes/DevOps Engineer/README.md
- Documentacao → $V/Agentes/Documentacao/README.md
- Engenheiro de Testes → $V/Agentes/Engenheiro de Testes/README.md
- Game Developer → $V/Agentes/Game Developer/README.md
- Hostinger Email → $V/Agentes/Hostinger Email/README.md
- Performance Imagens → $V/Agentes/Performance Imagens/README.md
- Performance Web → $V/Agentes/Performance Web/README.md
- Product Manager → $V/Agentes/Product Manager/README.md
- SEO Specialist → $V/Agentes/SEO Specialist/README.md

## Documentação Automática de Projetos

### Ao abrir qualquer projeto:
1. Verifique se existe .claude/docs/ no projeto atual
2. Se existir, leia os arquivos .md relevantes antes de começar
3. Se não existir e a sessão for de trabalho significativo:
   - Analise o projeto (package.json, estrutura, README existente)
   - Crie .claude/docs/PROJETO.md e .claude/docs/ARQUITETURA.md
   - Use os templates em $V/templates/docs/

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
"@
  Add-Content -Path $CLAUDE_MD -Value $block -Encoding UTF8
  Write-Host "✅ CLAUDE.md configurado"
}

# ── 2. Hook script (PowerShell) ───────────────────────────────────────────────
$hookContent = @"
# segundo-cerebro.ps1 — Injeta contexto de docs do projeto uma vez por sessão.
# Throttle: dispara uma vez a cada 2 horas por projeto.

`$PROJECT_DIR = (Get-Location).Path
`$VAULT       = "$V"
`$DOCS_DIR    = Join-Path `$PROJECT_DIR ".claude\docs"

# Não roda dentro do próprio vault
if (`$PROJECT_DIR.Replace('\','/') -like "`$VAULT*") { exit 0 }

# Throttle: uma vez a cada 2h por projeto
`$sessionKey  = "sc-" + [System.Math]::Abs(`$PROJECT_DIR.GetHashCode()).ToString()
`$sessionFile = Join-Path `$env:TEMP `$sessionKey

if (Test-Path `$sessionFile) {
  `$last = [long](Get-Content `$sessionFile)
  `$now  = [long](Get-DateUnixTime)
  if ((`$now - `$last) -lt 7200) { exit 0 }
}

function Get-DateUnixTime { [long]([datetime]::UtcNow - [datetime]'1970-01-01').TotalSeconds }
Get-DateUnixTime | Set-Content `$sessionFile -Encoding UTF8

Write-Host ""
Write-Host "┌─ SEGUNDO CÉREBRO ─────────────────────────────┐"

if ((Test-Path `$DOCS_DIR) -and (Get-ChildItem `$DOCS_DIR -Filter "*.md" -Recurse)) {
  Write-Host "│ 📁 Docs deste projeto (.claude/docs/):"
  Get-ChildItem `$DOCS_DIR -Filter "*.md" -Recurse | Sort-Object FullName | ForEach-Object {
    `$rel = `$_.FullName.Replace(`$DOCS_DIR, "").TrimStart('\','/')
    Write-Host "│   • `$rel"
  }
  Write-Host "│"
  Write-Host "│ → Leia os docs relevantes antes de começar."
} else {
  Write-Host "│ 📭 Nenhuma documentação em .claude/docs/ ainda."
  Write-Host "│"
  Write-Host "│ → Se for trabalho significativo, crie os docs:"
  Write-Host "│   bash `$VAULT/scripts/novo-projeto.sh"
}

Write-Host "└────────────────────────────────────────────────┘"
Write-Host ""
"@

Set-Content -Path $HOOK_SCRIPT -Value $hookContent -Encoding UTF8
Write-Host "✅ Hook instalado em ~/.claude/hooks/"

# ── 3. settings.json ──────────────────────────────────────────────────────────
$hookCmd = "powershell -NoProfile -File `"$HOOK_SCRIPT`""

$alreadyHook = (Test-Path $SETTINGS) -and ((Get-Content $SETTINGS -Raw) -like "*segundo-cerebro*")
if ($alreadyHook) {
  Write-Host "✅ Hook já registrado em settings.json"
} else {
  $s = if (Test-Path $SETTINGS) {
    try { Get-Content $SETTINGS -Raw | ConvertFrom-Json } catch { [pscustomobject]@{} }
  } else { [pscustomobject]@{} }

  if (-not $s.hooks) { $s | Add-Member -NotePropertyName hooks -NotePropertyValue ([pscustomobject]@{}) }
  if (-not $s.hooks.UserPromptSubmit) {
    $s.hooks | Add-Member -NotePropertyName UserPromptSubmit -NotePropertyValue @()
  }

  $s.hooks.UserPromptSubmit += [pscustomobject]@{
    hooks = @([pscustomobject]@{ type = "command"; command = $hookCmd })
  }

  $s | ConvertTo-Json -Depth 10 | Set-Content $SETTINGS -Encoding UTF8
  Write-Host "✅ Hook registrado em settings.json"
}

# ── Resumo ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "✅ Segundo Cérebro configurado com sucesso!"
Write-Host "   Vault:    $VAULT"
Write-Host "   Hook:     $HOOK_SCRIPT"
Write-Host "   Settings: $SETTINGS"
Write-Host ""
Write-Host "   O Claude Code consultará o vault e os docs de cada projeto automaticamente."
Write-Host "   Para desfazer: .\setup.ps1 -Uninstall"
