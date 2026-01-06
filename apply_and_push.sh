#!/usr/bin/env bash
set -euo pipefail

# Ajusta estas variáveis conforme necessário
REPO_URL="https://github.com/kaksz914/PROJECTO-FINAL.git"
BRANCH="add-ci-quality"
PR_TITLE="chore: add CI, quality and contributing files"
PR_BODY="Adiciona Checkstyle, SpotBugs, JaCoCo, GitHub Actions CI, dependabot, templates e hooks pré-commit para melhorar qualidade do projeto."

# Verificações
command -v git >/dev/null 2>&1 || { echo "git não instalado. Instala git e tenta de novo."; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "gh (GitHub CLI) não encontrado. Instala e autentica com 'gh auth login'."; exit 1; }

# Verifica se patches existem
PATCHES=(0001-docs.patch 0002-ci.patch 0003-quality.patch 0004-tests.patch)
for p in "${PATCHES[@]}"; do
  if [ ! -f "$p" ]; then
    echo "Ficheiro de patch não encontrado: $p"
    echo "Coloca os ficheiros de patch no diretório atual e corre novamente."
    exit 1
  fi
done

# Se diretório não for repositório git, inicializa e faz um commit inicial mínimo
if [ ! -d .git ]; then
  echo "Inicializando repositório git local e adicionando remote..."
  git init
  git remote add origin "$REPO_URL"
  # cria branch main local se necessário
  git checkout -b main || git branch -M main
  # se não houver commits, cria um commit inicial (evita erro ao empurrar depois)
  if [ -z "$(git rev-parse --verify --quiet HEAD 2>/dev/null)" ]; then
    echo "# PROJECTO-FINAL" > README.md
    git add README.md
    git commit -m "chore: initial commit"
    git push -u origin main || echo "Push inicial falhou — verifica permissões/remote."
  fi
fi

# Aplica os patches na ordem
echo "Aplicando patches com git am..."
for p in "${PATCHES[@]}"; do
  echo "Aplicando $p..."
  git am "$p" || {
    echo "git am encontrou um problema. Podes resolver conflitos manualmente e depois correr 'git am --continue'."
    exit 1
  }
done

# Cria a branch de funcionalidade a partir de main
echo "Criando branch $BRANCH..."
git checkout -b "$BRANCH"

# Push da branch
echo "Fazendo push da branch para origin..."
git push -u origin "$BRANCH"

# Cria o PR com gh
echo "Criando PR com gh..."
gh pr create --title "$PR_TITLE" --body "$PR_BODY" --base main || {
  echo "Falha ao criar PR com gh. Podes criar manualmente em https://github.com/$(gh repo view --json nameWithOwner --jq .nameWithOwner)/pulls"
  exit 1
}

echo "Pronto — PR criado. Abre o repositório no GitHub para rever."
