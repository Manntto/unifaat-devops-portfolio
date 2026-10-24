# Aula 09 — Docker Registry (ECR) + AI Review no CI/CD

**Aluno:** Matheus Mantovani | **RA:** 1120245

## Objetivo

Publicar uma imagem Docker no Amazon ECR com estratégia de tagging semântica e integrar um analisador estático de PRs (AI Review) ao pipeline de CI/CD.

## Estrutura

```
aula-09/
├── .github/                    # (raiz do repo)
│   ├── workflows/
│   │   └── ai-review.yml       # Workflow de AI Review no GitHub Actions
│   └── scripts/
│       └── ai-review.js        # Analisador estático de PRs
├── screenshots/                # Evidências de execução
├── Dockerfile                  # Multi-stage com usuário não-root
├── .dockerignore
├── app.js                      # TechNova API — Express
├── package.json
├── ecr-push.sh                 # Script de build + push para ECR
├── ia-cicd-analise.md          # Análise crítica sobre IA no CI/CD
└── README.md
```

## Pré-requisitos

- AWS CLI configurado (Learner Lab ativo)
- Docker instalado e rodando
- Node.js 20+
- Git

## Como usar

### 1. Testar a API localmente

```bash
cd aula-09
npm install
npm start
# API disponível em http://localhost:3000
```

Endpoints:
- `GET /` — informações do serviço
- `GET /health` — status de saúde
- `GET /version` — versão da aplicação

### 2. Build da imagem Docker

```bash
cd aula-09
docker build -t technova-api .
docker run -p 3000:3000 technova-api
```

### 3. Push para o ECR (requer AWS Lab ativo)

```bash
cd aula-09
chmod +x ecr-push.sh
./ecr-push.sh
```

O script:
1. Obtém o Account ID automaticamente via `aws sts`
2. Cria o repositório ECR `technova-api` (se não existir), com scan automático
3. Faz login no ECR com credenciais temporárias do Lab
4. Builda e publica 5 tags: `sha-<commit>`, `latest`, semver completo, minor e major

### 4. Testar o AI Review localmente

```bash
# Sem diff (resultado limpo)
node .github/scripts/ai-review.js

# Com diff simulado contendo problemas
PR_DIFF='+const password = "minha-senha-123"' node .github/scripts/ai-review.js
```

## AI Review — Como funciona

O workflow `.github/workflows/ai-review.yml` dispara em todo PR e:

1. Obtém o diff das linhas adicionadas em arquivos `.js`, `.ts`, `.py` e `.sh`
2. Executa `ai-review.js`, que aplica 8 padrões de detecção
3. Posta o resultado como comentário no PR
4. Falha o workflow (quality gate) se houver achados **CRITICAL**

### Padrões detectados

| Severidade | Padrão |
|-----------|--------|
| 🔴 CRITICAL | Secrets hardcoded, `eval()`, SQL injection, criptografia fraca |
| 🟡 WARNING | `console.log`, catch vazio, URLs HTTP |
| 🔵 INFO | TODO/FIXME não resolvidos |

## Evidências

Adicione screenshots na pasta `screenshots/` após executar:
- ECR repository criado no console AWS
- Output do `ecr-push.sh` com as 5 tags publicadas
- Comentário do AI Review em um PR real
- Workflow passando (sem CRITICAL) e falhando (com CRITICAL)

## Análise crítica

Ver [ia-cicd-analise.md](./ia-cicd-analise.md) para discussão sobre:
- Por que ECR vs. Docker Hub / ghcr.io
- Estratégia de tagging e uso de semver
- Limitações do AI Review baseado em regex
- Quando confiar na IA vs. quando exige revisão humana
