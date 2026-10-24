# Runbook — Procedimento de Rollback

**Projeto:** TechNova API — Aula 10  
**Responsável:** Matheus Mantovani (RA 1120245)  
**Última atualização:** 2025

---

## Contexto

Este runbook descreve os passos para reverter a TechNova API para uma versão anterior após um deploy com falha. O pipeline CD usa a estratégia **Recreate** (stop → rm → run), o que significa que não há Blue/Green — o rollback é manual e requer acesso SSH à EC2.

---

## Pré-requisitos

- Acesso SSH à EC2 (`technova-aula10-key`)
- AWS CLI configurado com credenciais válidas do Learner Lab
- Permissão de leitura no ECR (`<account-id>.dkr.ecr.us-east-1.amazonaws.com/technova-api`)

---

## Passo 1 — Identificar a tag SHA da versão anterior no ECR

No console AWS → ECR → Repositório `technova-api`, ou via CLI:

```bash
aws ecr describe-images \
  --repository-name technova-api \
  --region us-east-1 \
  --query 'sort_by(imageDetails, &imagePushedAt)[*].[imagePushedAt,imageTags]' \
  --output table
```

Anote a tag `sha-<7 caracteres>` da versão estável anterior. Exemplo: `sha-a1b2c3d`.

---

## Passo 2 — SSH na EC2

```bash
ssh -i ~/.ssh/technova-aula10-key ubuntu@<EC2_PUBLIC_IP>
```

Substitua `<EC2_PUBLIC_IP>` pelo IP público da instância (disponível no output do Terraform ou no console EC2).

---

## Passo 3 — Login no ECR

```bash
REGISTRY="<AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com"

aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin "$REGISTRY"
```

---

## Passo 4 — Pull da imagem da versão anterior

```bash
SHA_ANTERIOR="sha-a1b2c3d"   # substitua pelo SHA identificado no Passo 1
IMAGE="$REGISTRY/technova-api:$SHA_ANTERIOR"

docker pull "$IMAGE"
```

---

## Passo 5 — Stop e remoção do container atual

```bash
docker stop technova-api || true
docker rm technova-api || true
```

---

## Passo 6 — Subir o container com a versão anterior

```bash
docker run -d \
  --name technova-api \
  -p 3000:3000 \
  --restart unless-stopped \
  -e APP_VERSION="$SHA_ANTERIOR" \
  "$IMAGE"

echo "✅ Rollback concluído para: $IMAGE"
```

---

## Passo 7 — Verificar health check

Aguarde ~5 segundos e execute:

```bash
curl -s http://localhost:3000/health
```

Resposta esperada:

```json
{"status":"ok","version":"sha-a1b2c3d","uptime":2.34}
```

Ou teste externamente:

```bash
curl -s http://<EC2_PUBLIC_IP>:3000/health | grep '"status":"ok"'
```

---

## Passo 8 — Registrar o incidente

Após o rollback, abra uma issue no repositório com:

- Data/hora do deploy problemático
- SHA do deploy com falha
- SHA usado no rollback
- Descrição do comportamento observado
- Próximos passos para correção

---

## Notas importantes

| Situação | Ação |
|---|---|
| Container não inicia | `docker logs technova-api` para diagnóstico |
| ECR sem versão anterior | Restaurar via `git revert` + novo push para reacionar o pipeline |
| EC2 sem resposta SSH | Verificar Security Group (porta 22) e estado da instância no console AWS |
| Credenciais AWS expiradas | Atualizar secrets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` no GitHub |
