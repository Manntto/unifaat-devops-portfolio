#!/bin/bash
set -euo pipefail

# ── Configurações ────────────────────────────────────────────────────────────
REGION="us-east-1"
REPO_NAME="technova-api"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 ECR Push — TechNova API"
echo "Região: $REGION"

# ── 1. Account ID e Registry URI ─────────────────────────────────────────────
echo ""
echo "📋 Obtendo Account ID..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --region "$REGION")
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
echo "Account ID: $ACCOUNT_ID"
echo "Registry:   $REGISTRY"

# ── 2. Criar repositório ECR (idempotente) ────────────────────────────────────
echo ""
echo "📦 Garantindo repositório ECR '$REPO_NAME'..."
aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$REGION" > /dev/null 2>&1 || \
  aws ecr create-repository \
    --repository-name "$REPO_NAME" \
    --region "$REGION" \
    --image-scanning-configuration scanOnPush=true \
    --tags Key=Projeto,Value=technova Key=Aula,Value=09 Key=Aluno,Value=MathesMantovani \
    --output table
echo "✅ Repositório pronto."

# ── 3. Login no ECR ───────────────────────────────────────────────────────────
echo ""
echo "🔑 Autenticando Docker no ECR..."
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"
echo "✅ Login realizado."

# ── 4. Tags ───────────────────────────────────────────────────────────────────
echo ""
echo "🏷️  Calculando tags..."
SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
TAG_SHA="sha-${SHA}"
TAG_LATEST="latest"

# Semver: lê da git tag v*.*.* mais recente, senão usa 1.0.0
GIT_TAG=$(git describe --tags --match "v*.*.*" --abbrev=0 2>/dev/null || echo "v1.0.0")
SEMVER="${GIT_TAG#v}"   # Remove o 'v' inicial
MAJOR="${SEMVER%%.*}"
MINOR="${SEMVER%.*}"; MINOR="${MINOR#*.}"

IMAGE_URI="${REGISTRY}/${REPO_NAME}"

echo "  SHA:    $TAG_SHA"
echo "  latest: $TAG_LATEST"
echo "  semver: $SEMVER ($MAJOR, ${MAJOR}.${MINOR})"

# ── 5. Build ──────────────────────────────────────────────────────────────────
echo ""
echo "🐳 Buildando imagem Docker..."
docker build -t "$REPO_NAME" "$SCRIPT_DIR"
echo "✅ Build concluído."

# ── 6. Tag + Push ─────────────────────────────────────────────────────────────
echo ""
echo "📤 Fazendo push das tags..."

for TAG in "$TAG_SHA" "$TAG_LATEST" "$SEMVER" "${MAJOR}.${MINOR}" "$MAJOR"; do
  docker tag "$REPO_NAME" "${IMAGE_URI}:${TAG}"
  docker push "${IMAGE_URI}:${TAG}"
  echo "  ✅ pushed: ${IMAGE_URI}:${TAG}"
done

# ── 7. Resumo ─────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
echo "✅ ECR Push concluído!"
echo "   Repositório: ${IMAGE_URI}"
echo "   Tags publicadas:"
echo "     - sha-${SHA} (rastreabilidade)"
echo "     - latest     (conveniência)"
echo "     - ${SEMVER}  (semver completo)"
echo "     - ${MAJOR}.${MINOR} (semver menor)"
echo "     - ${MAJOR}   (semver maior)"
echo ""
echo "Para fazer pull:"
echo "  docker pull ${IMAGE_URI}:latest"
echo "  docker pull ${IMAGE_URI}:sha-${SHA}"
echo "══════════════════════════════════════════════════════"
