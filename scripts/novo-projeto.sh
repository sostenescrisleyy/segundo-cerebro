#!/usr/bin/env bash
# Executa na raiz de qualquer projeto para criar a estrutura inicial de docs.
# Uso: bash ~/segundo-cerebro/scripts/novo-projeto.sh

set -euo pipefail

VAULT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$(pwd)"
DOCS_DIR="$PROJECT_DIR/.claude/docs"
DECISIONS_DIR="$DOCS_DIR/decisions"

PROJECT_NAME="$(basename "$PROJECT_DIR")"
DATE="$(date +%Y-%m-%d)"

# Não roda dentro do próprio vault
if [[ "$PROJECT_DIR" == "$VAULT"* ]]; then
  echo "⚠️  Execute este script dentro do seu projeto, não dentro do vault."
  exit 1
fi

echo "📁 Projeto: $PROJECT_NAME"
echo "📂 Criando estrutura em .claude/docs/ ..."

mkdir -p "$DOCS_DIR" "$DECISIONS_DIR"

# Cria PROJETO.md apenas se não existir
if [ ! -f "$DOCS_DIR/PROJETO.md" ]; then
  sed "s/{{NOME_DO_PROJETO}}/$PROJECT_NAME/g; s/{{DATA}}/$DATE/g" \
    "$VAULT/templates/docs/PROJETO.md" > "$DOCS_DIR/PROJETO.md"
  echo "  ✅ PROJETO.md criado"
else
  echo "  ⏭️  PROJETO.md já existe — não sobrescrito"
fi

# Cria ARQUITETURA.md apenas se não existir
if [ ! -f "$DOCS_DIR/ARQUITETURA.md" ]; then
  sed "s/{{NOME_DO_PROJETO}}/$PROJECT_NAME/g; s/{{DATA}}/$DATE/g" \
    "$VAULT/templates/docs/ARQUITETURA.md" > "$DOCS_DIR/ARQUITETURA.md"
  echo "  ✅ ARQUITETURA.md criado"
else
  echo "  ⏭️  ARQUITETURA.md já existe — não sobrescrito"
fi

echo ""
echo "✅ Estrutura pronta em .claude/docs/"
echo ""
echo "   Próximo passo: abra o Claude Code neste projeto e peça:"
echo "   'Analise o projeto e preencha .claude/docs/PROJETO.md e ARQUITETURA.md'"
