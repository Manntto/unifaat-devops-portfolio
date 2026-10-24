# Portfólio DevOps — UniFAAT 2026-2

[![CI — TechNova Aula 08](https://github.com/matheus-mantovani/unifaat-devops-portfolio/actions/workflows/ci-aula08.yml/badge.svg)](https://github.com/matheus-mantovani/unifaat-devops-portfolio/actions/workflows/ci-aula08.yml)

**Aluno:** Matheus Mantovani  
**RA:** 1120245  
**Disciplina:** DevOps — Centro Universitário UniFAAT  
**Professor:** Alexandre Tavares  
**Semestre:** 2026-2

## Sobre

Repositório de atividades e projetos da disciplina de DevOps.
Aqui documento minha evolução desde os fundamentos de Git e Docker até pipelines completas de CI/CD na AWS.

## Estrutura

- `aula-01/` — Fundamentos de Git e Docker
- `aula-08/` — GitHub Actions e CI Pipelines

## Aprendizados

### Aula 01 — Git + Docker
- Controle de versão distribuído com Git: branches, commits atômicos, merge e repositórios remotos
- Containerização com Docker: Dockerfile, camadas de imagem, build e execução de containers
- Integração Git + Docker como base para ambientes reprodutíveis e versionáveis

### Aula 08 — GitHub Actions e CI Pipelines
- Pipeline CI multi-stage com GitHub Actions: lint → test → build com dependências via `needs`
- Configuração do ESLint com regras customizadas e integração no pipeline
- Testes automatizados com Jest + Supertest e relatório de coverage
- Docker build e smoke test integrados ao CI
- Gerenciamento de secrets no GitHub Actions com mascaramento automático de valores
- Cache de dependências com `actions/setup-node` para acelerar execuções
- Concurrency control para cancelar runs obsoletos e economizar minutos
