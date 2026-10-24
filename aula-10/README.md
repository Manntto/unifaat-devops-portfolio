# Aula 10 — GitOps + CD Pipeline (TechNova API)

**Aluno:** Matheus Mantovani — RA 1120245  
**Disciplina:** DevOps — UNIFAAT 2026/2  
**Tema:** GitOps, Continuous Deployment, Terraform via Actions, Deploy em EC2

---

## Visão geral

Este trabalho final implementa um pipeline completo de **GitOps + Continuous Deployment**:

- **Infraestrutura como Código** com Terraform (VPC, EC2, Security Group, Key Pair)
- **Terraform Plan no PR** — o plan é postado como comentário antes do merge
- **Terraform Apply automático** no merge para `main`
- **CD Pipeline** para a TechNova API: lint → test → build → push ECR → deploy EC2

---

## Estrutura

```
aula-10/
├── .github/workflows/          # ← workflows na RAIZ do repositório
│   ├── terraform-plan.yml      # dispara em PRs com mudanças no terraform/
│   ├── terraform-apply.yml     # dispara em push na main com mudanças no terraform/
│   └── cd.yml                  # lint → test → build+push ECR → deploy EC2
├── terraform/
│   ├── provider.tf             # provider AWS + backend S3
│   ├── variables.tf            # variáveis do projeto
│   ├── main.tf                 # VPC, Subnet, IGW, RT, SG, Key Pair, EC2
│   └── outputs.tf              # IP público, DNS, URL da API
├── technova-api/
│   ├── app.js                  # Express API com /, /health, /version
│   ├── package.json
│   ├── package-lock.json
│   ├── __tests__/api.test.js   # testes com Jest + Supertest
│   ├── .eslintrc.json
│   ├── Dockerfile              # multi-stage: builder → runtime non-root
│   └── .dockerignore
├── docs/
│   └── runbook-rollback.md     # procedimento passo a passo de rollback
├── screenshots/                # evidências de execução do pipeline
├── gitops-cd-analise.md        # análise crítica completa
└── README.md
```

---

## Pré-requisitos

- Conta AWS Academy Learner Lab ativa
- Docker instalado localmente
- Terraform >= 1.5.0
- Node.js 20
- AWS CLI configurado

---

## 1. Gerar o Key Pair SSH

O Terraform lê a chave pública do arquivo `terraform/technova-aula10-key.pub`. Gere o par localmente:

```bash
ssh-keygen -t rsa -b 4096 -f aula-10/terraform/technova-aula10-key -N ""
```

**Importante:**
- `technova-aula10-key` (privada) → adicione ao `.gitignore` ou guarde em local seguro. **Nunca commite a chave privada.**
- `technova-aula10-key.pub` (pública) → commite no repositório

---

## 2. Configurar Secrets no GitHub

Acesse `Settings → Secrets and variables → Actions` no repositório e crie:

| Secret | Descrição |
|---|---|
| `AWS_ACCESS_KEY_ID` | Credencial do Learner Lab |
| `AWS_SECRET_ACCESS_KEY` | Credencial do Learner Lab |
| `AWS_SESSION_TOKEN` | Token de sessão do Learner Lab (~4h de validade) |
| `AWS_ACCOUNT_ID` | ID da conta AWS (12 dígitos) |
| `EC2_HOST` | IP público da EC2 (disponível após `terraform apply`) |
| `EC2_SSH_KEY` | Conteúdo da chave privada `technova-aula10-key` |

> ⚠️ As credenciais do Learner Lab expiram a cada ~4 horas. Atualize `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` e `AWS_SESSION_TOKEN` antes de cada execução do pipeline de infraestrutura.

---

## 3. Provisionar a EC2 com Terraform

Após configurar os secrets e commitar a chave `.pub`:

```bash
cd aula-10/terraform
terraform init
terraform plan
terraform apply
```

Anote o IP público exibido no output e adicione ao secret `EC2_HOST`.

Também é necessário criar o repositório ECR antes do pipeline CD:

```bash
aws ecr create-repository --repository-name technova-api --region us-east-1
```

---

## 4. Como o pipeline funciona

### Pipeline de Infraestrutura (Terraform)

```
PR com mudanças em aula-10/terraform/
  └── terraform-plan.yml
        ├── terraform init
        ├── terraform validate
        ├── terraform fmt -check
        ├── terraform plan
        └── Posta resultado como comentário no PR

Merge na main
  └── terraform-apply.yml
        ├── terraform init
        └── terraform apply -auto-approve
```

### Pipeline de Aplicação (CD)

```
Push na main com mudanças em aula-10/technova-api/
  └── cd.yml
        ├── lint (ESLint)
        ├── test (Jest + coverage)
        ├── build + push ECR (sha-<7chars> + latest)
        └── deploy EC2
              ├── SSH → docker stop/rm/run
              └── health check (30 tentativas × 5s)
```

---

## 5. Executar localmente

### Testar a API

```bash
cd aula-10/technova-api
npm install
npm run lint
npm test
```

### Rodar a API localmente

```bash
node app.js
curl http://localhost:3000/
curl http://localhost:3000/health
curl http://localhost:3000/version
```

### Build da imagem Docker

```bash
docker build -t technova-api:local aula-10/technova-api/
docker run -d -p 3000:3000 --name technova-api technova-api:local
curl http://localhost:3000/health
```

---

## 6. Rollback

Consulte o procedimento completo em [`docs/runbook-rollback.md`](docs/runbook-rollback.md).

Resumo rápido:

```bash
# 1. Identificar SHA anterior no ECR
aws ecr describe-images --repository-name technova-api --region us-east-1

# 2. SSH na EC2 e fazer rollback
ssh -i ~/.ssh/technova-aula10-key ubuntu@<EC2_IP>
REGISTRY="<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com"
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "$REGISTRY"
docker stop technova-api && docker rm technova-api
docker run -d --name technova-api -p 3000:3000 --restart unless-stopped "$REGISTRY/technova-api:sha-<SHA_ANTERIOR>"
```

---

## 7. Análise crítica

Consulte [`gitops-cd-analise.md`](gitops-cd-analise.md) para a análise completa cobrindo:

- Fluxo GitOps (plan no PR → apply no merge)
- Autenticação Learner Lab vs. OIDC em produção
- Estratégia Recreate: prós, contras e alternativas
- Continuous Delivery vs. Continuous Deployment
- Limitações identificadas e mitigações
