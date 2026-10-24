# Análise Crítica — IA no CI/CD e Amazon ECR

**Aluno:** Matheus Mantovani | **RA:** 1120245 | **Aula:** 09

## Por que Amazon ECR?

O Amazon ECR foi escolhido como registry por três razões principais:

**1. Mesmo ecossistema da infra.** A infraestrutura da TechNova já roda na AWS (EC2, RDS provisionados com Terraform nas aulas anteriores). Ter o registry na mesma cloud elimina latência e custo de transferência de dados — pull do ECR para EC2 na mesma região é gratuito.

**2. Privacidade por padrão.** Ao contrário do Docker Hub (público por padrão), o ECR cria repositórios privados. Imagens de produção não devem ser públicas — contêm configurações, estrutura interna da aplicação e possivelmente segredos de build.

**3. Restrições do Learner Lab.** O Lab não permite criar usuários IAM, o que inviabiliza Docker Hub com credenciais de longa duração no CI. O ECR usa as credenciais temporárias da sessão (`aws_session_token`) via `aws ecr get-login-password` — compatível com o Lab. Alternativas como ghcr.io funcionariam para o workflow de GitHub Actions, mas não para scripts locais autenticados na AWS.

## Estratégia de Tagging

O `ecr-push.sh` publica 5 tags a cada execução:

| Tag | Exemplo | Propósito |
|-----|---------|-----------|
| `sha-XXXXXXX` | `sha-4745062` | Rastreabilidade total — identifica exatamente qual commit gerou a imagem |
| `latest` | `latest` | Conveniência — `docker pull` sem especificar versão |
| `X.Y.Z` | `1.2.3` | Semver completo — release específico |
| `X.Y` | `1.2` | Semver menor — sempre aponta para o patch mais recente de 1.2 |
| `X` | `1` | Semver maior — sempre aponta para o minor mais recente de v1 |

A tag `sha-*` é a mais importante para rollback: permite identificar exatamente qual versão está rodando em produção e reverter com `docker pull registry/technova-api:sha-abc1234`.

## Padrões Detectados pelo AI Review

O script `ai-review.js` detecta 8 padrões classificados por severidade:

| ID | Severidade | O que detecta |
|----|-----------|---------------|
| `SECRET_HARDCODED` | 🔴 CRITICAL | Credenciais em texto claro (password=, api_key=, token=) |
| `EVAL_USAGE` | 🔴 CRITICAL | Chamadas `eval()` — execução de código arbitrário |
| `SQL_INJECTION` | 🔴 CRITICAL | Concatenação de req.body/params em queries SQL |
| `WEAK_CRYPTO` | 🔴 CRITICAL | Uso de MD5 ou SHA1 — algoritmos inseguros |
| `CONSOLE_LOG` | 🟡 WARNING | console.log() em código que vai para produção |
| `EMPTY_CATCH` | 🟡 WARNING | Blocos catch vazios que silenciam erros |
| `HTTP_NOT_HTTPS` | 🟡 WARNING | URLs HTTP (sem criptografia) em chamadas externas |
| `TODO_FIXME` | 🔵 INFO | Comentários TODO/FIXME não resolvidos |

## Lógica do Quality Gate

O quality gate é simples e binário:
- **CRITICAL encontrado** → `process.exit(1)` → workflow falha → PR bloqueado
- **Apenas WARNING/INFO** → `process.exit(0)` → workflow passa → merge permitido

Essa decisão reflete o princípio de menor surpresa: problemas de segurança (hardcoded secrets, eval, SQL injection) são objetivamente perigosos e não devem chegar ao main sem revisão. Warnings são informativos — o desenvolvedor pode optar por ignorá-los com justificativa.

## Quando confiar na IA vs. quando exige review humano

**Confiar na IA:**
- Padrões de segurança conhecidos (secrets, eval, SQL injection)
- Violações de convenções de código (console.log em produção, catch vazio)
- Primeiros minutos após abrir o PR — feedback imediato para o autor

**Sempre revisão humana:**
- Lógica de negócio complexa — a IA vê apenas o diff, não o contexto
- Decisões de arquitetura — a IA não sabe por que uma escolha foi feita
- Falsos positivos do AI review — a IA pode apontar `token` em um comentário como "secret hardcoded"
- PRs de refatoração grande — a IA pode confundir contexto entre linhas removidas e adicionadas

## Limitações identificadas

1. **Contexto limitado ao diff:** a IA não vê o projeto inteiro — pode perder problemas que emergem da interação entre arquivos.
2. **Falsos positivos em strings literais:** o padrão `SECRET_HARDCODED` pode acusar uma variável chamada `secretLabel` com valor `'Confidencial'`.
3. **Regex não entende semântica:** `eval()` em um comentário seria acusado. A análise correta exigiria AST parsing.
4. **Sem aprendizado:** o script aplica os mesmos padrões independentemente do contexto do projeto — uma base de código com comentários `// TODO: remover antes do release` não é tratada diferente de um TODO genuíno.
