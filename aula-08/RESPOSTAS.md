# Respostas — Aula 08: GitHub Actions e CI Pipelines

**Aluno:** Matheus Mantovani
**RA:** 1120245

## Questão 1
**O que dispara a execução de um workflow do GitHub Actions?**

Resposta: **b)** Eventos configurados no campo `on:` do YAML, como push, pull_request ou workflow_dispatch.

O campo `on:` define os triggers do workflow. No projeto deste TF, configurei dois triggers: `push` para a branch main e `pull_request`, ambos filtrados pelo path `aula-08/**` para que o CI só dispare quando arquivos da aula 08 forem alterados — evitando execuções desnecessárias por mudanças em outras aulas.

## Questão 2
**Qual é a função da keyword `needs` em um workflow multi-stage?**

Resposta: **c)** Cria dependência entre jobs — o job só executa se os jobs listados em `needs` passarem.

No pipeline deste TF, `needs: lint` no job `test` garante que os testes só rodam se o lint passar. E `needs: [lint, test]` no job `build` garante que o Docker build só acontece se lint e testes passarem. Isso cria a cadeia lint → test → build, economizando minutos do GitHub Actions quando há falhas nas etapas iniciais.

## Questão 3
**Onde devem ser armazenadas credenciais AWS para uso em GitHub Actions?**

Resposta: **c)** Em GitHub Secrets (Settings → Secrets), referenciadas com `${{ secrets.NAME }}`.

No workflow deste TF, usei `${{ secrets.APP_ENV }}` no job de testes para demonstrar o uso de secrets. O valor nunca aparece nos logs — o GitHub substitui automaticamente por `***`. Para um caso real com AWS, os secrets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` e `AWS_SESSION_TOKEN` seriam configurados em Settings → Secrets → Actions.

## Questão 4
**Qual é o propósito de environments com approval gates no GitHub Actions?**

Resposta: **b)** Garantir que deploys para ambientes sensíveis (como produção) requeiram aprovação humana antes de executar.

Environments com protection rules criam um "portão" antes de jobs críticos. Um job com `environment: production` pausa o pipeline e aguarda aprovação de um reviewer antes de continuar. Isso é fundamental para evitar deploys acidentais em produção — a automação cuida da verificação técnica, mas o humano toma a decisão final de quando deployar.
