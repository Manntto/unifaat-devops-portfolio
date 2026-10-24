# Análise Crítica — GitOps + CD Pipeline (Aula 10)

**Aluno:** Matheus Mantovani — RA 1120245  
**Disciplina:** DevOps — UNIFAAT 2026/2

---

## 1. Fluxo GitOps implementado

O pipeline desta aula implementa o padrão **GitOps** completo para infraestrutura e aplicação:

```
PR aberto → terraform-plan.yml dispara
           → terraform init + validate + fmt-check + plan
           → resultado postado como comentário no PR
           → revisor aprova ou rejeita com base no plan

Merge na main → terraform-apply.yml dispara
               → apply automático (infra atualizada)

Merge na main → cd.yml dispara
               → lint → test → build+push ECR → deploy EC2
```

### Por que isso é GitOps?

O repositório Git é a **única fonte de verdade** para o estado desejado da infraestrutura e da aplicação. Qualquer mudança passa pelo Git (pull request + review), e o pipeline lê o estado do repositório para convergir o ambiente real. Não há mudanças manuais diretas na AWS.

**Benefícios observados:**
- Rastreabilidade: cada mudança tem autor, PR e SHA associados
- Revisão: o plan no PR permite revisar *o que vai mudar* antes de mudar
- Reversibilidade: `git revert` + push aciona o pipeline para desfazer

---

## 2. Autenticação AWS: Learner Lab vs. Produção

### Abordagem atual (Learner Lab)

O ambiente AWS Academy Learner Lab fornece credenciais temporárias de sessão com duração de ~4 horas:

```yaml
aws-access-key-id:     ${{ secrets.AWS_ACCESS_KEY_ID }}
aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
aws-session-token:     ${{ secrets.AWS_SESSION_TOKEN }}
```

**Limitação crítica:** as credenciais expiram e precisam ser atualizadas manualmente nos Secrets do GitHub antes de cada execução do pipeline. Em um projeto real, isso inviabilizaria a automação contínua.

### Abordagem em produção: OIDC (OpenID Connect)

Em um ambiente real, a prática recomendada é usar **OIDC com IAM Roles** — sem armazenar credenciais:

```yaml
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789012:role/github-actions-role
    aws-region: us-east-1
```

O GitHub Actions obtém um token JWT temporário assinado pelo GitHub e troca por credenciais AWS via STS. Zero secrets armazenados, rotação automática.

**Por que não usamos aqui:** o Learner Lab não permite criar IAM Identity Providers nem configurar Trust Policies em roles arbitrárias.

---

## 3. Estratégia de Deploy: Recreate

### Como funciona

```bash
docker stop technova-api || true
docker rm   technova-api || true
docker run  -d --name technova-api -p 3000:3000 ...
```

O container existente é parado e removido antes de subir a nova versão.

### Prós

- **Simplicidade:** não requer orquestrador, load balancer ou múltiplas instâncias
- **Sem conflito de porta:** não há risco de duas versões ouvindo na mesma porta simultaneamente
- **Adequado para ambientes de lab/dev** com budget limitado

### Contras

- **Downtime:** há uma janela de indisponibilidade entre o `stop` e o momento em que a nova versão aceita conexões (tipicamente 5–15 segundos para a API iniciar)
- **Sem fallback automático:** se a nova versão falha ao subir, o serviço fica down até intervenção manual
- **Não é adequado para produção** com SLA de disponibilidade

### Quando usar Recreate

- Ambientes de desenvolvimento/staging com downtime aceitável
- Serviços sem SLA de disponibilidade (labs, ferramentas internas)
- Single-instance sem load balancer

### Alternativas para produção

| Estratégia | Downtime | Complexidade | Rollback |
|---|---|---|---|
| Recreate | Sim (~15s) | Baixa | Manual |
| Rolling Update | Não | Média | Semi-automático |
| Blue/Green | Não | Alta | Instantâneo |
| Canary | Não | Muito alta | Granular |

---

## 4. Continuous Delivery vs. Continuous Deployment

### Continuous Delivery (CD - Entrega)

O código está **sempre pronto para ser implantado**, mas o deploy em produção requer **aprovação humana**. O pipeline vai até a etapa de "artefato pronto" ou "staging validado".

**Exemplo:** pipeline que faz build, testa e publica no ECR — mas o deploy real precisa de um botão manual.

### Continuous Deployment (CD - Implantação)

Toda mudança que passa nos testes é **automaticamente implantada em produção** sem intervenção humana.

**Exemplo:** o pipeline desta aula — merge na main → deploy automático na EC2.

### O que implementamos

Este projeto implementa **Continuous Deployment**: o merge na `main` aciona automaticamente lint → test → build → push ECR → deploy EC2. Não há gate de aprovação humana entre o código e a produção.

**Trade-off:** velocidade de entrega vs. controle. Para um projeto acadêmico é ideal. Para sistemas críticos, um gate de aprovação antes do deploy em produção é recomendável.

---

## 5. Procedimento de Rollback

O pipeline não implementa rollback automático. Se o health check falha, o job `deploy` termina com erro, mas a EC2 pode estar com o container em estado de falha.

**Fluxo de rollback manual:**

1. Identificar SHA da versão estável no ECR (`aws ecr describe-images`)
2. SSH na EC2
3. `docker stop technova-api && docker rm technova-api`
4. `docker run` com a tag SHA anterior
5. Verificar `/health`

Detalhes completos em [`docs/runbook-rollback.md`](docs/runbook-rollback.md).

**Melhoria futura:** implementar rollback automático no pipeline caso o health check falhe, usando a tag `latest-stable` no ECR que só é atualizada após health check bem-sucedido.

---

## 6. Limitações identificadas

| Limitação | Impacto | Mitigação |
|---|---|---|
| Credenciais Learner Lab expiram em ~4h | Pipeline falha sem atualização manual | OIDC em produção |
| Estratégia Recreate causa downtime | Indisponibilidade a cada deploy | Rolling/Blue-Green em produção |
| Sem rollback automático | Intervenção manual necessária em falhas | Health check + rollback no pipeline |
| EC2 single instance | SPOF (Single Point of Failure) | Auto Scaling Group + Load Balancer |
| `technova-aula10-key.pub` no repositório | Baixo risco — chave pública é pública por definição | Usar `aws_key_pair` com dados dinâmicos |
| `terraform apply` sem plan prévio no apply workflow | Risco de apply de mudanças não revisadas em push direto | Adicionar `terraform plan -detailed-exitcode` antes do apply |
| SSH aberto para `0.0.0.0/0` | Exposição à internet | Restringir a IPs conhecidos ou usar SSM Session Manager |

---

## 7. Conclusão

O pipeline desta aula demonstra um fluxo GitOps funcional para ambiente de laboratório: infraestrutura gerenciada via Terraform com plan/apply no GitHub Actions, e CD da aplicação com build de imagem Docker, push para ECR e deploy em EC2.

As limitações são conhecidas e esperadas para um ambiente Learner Lab. Em produção, as mudanças mais críticas seriam: OIDC para autenticação, Blue/Green para deploys sem downtime, e rollback automático no pipeline.
