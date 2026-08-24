# Aula 01 — Fundamentos de Git e Docker

## O que aprendi

### Git
- O Git é um sistema de controle de versão **distribuído**: cada desenvolvedor possui uma cópia completa do histórico do projeto, não apenas o servidor central
- O fluxo básico é: **editar → `git add` (staging) → `git commit` → `git push`**
- Branches permitem desenvolver funcionalidades isoladas sem afetar o código principal — criei a branch `feature/aula-01-app` para desenvolver a aplicação desta aula
- Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`) tornam o histórico legível e rastreável
- O `.gitignore` evita que arquivos sensíveis (`.env`, `node_modules/`, `*.pem`) sejam versionados por acidente

### Docker
- Containers compartilham o kernel do host, tornando-os muito mais leves que VMs — inicializam em segundos
- Uma **imagem** é o template imutável; um **container** é a instância em execução dessa imagem
- O Dockerfile é a "receita" do ambiente: versionável no Git, garante reprodutibilidade em qualquer máquina
- A otimização de camadas (copiar `package.json` antes do código-fonte) evita reinstalar dependências a cada build
- O `.dockerignore` impede que `node_modules/` do host seja copiado para a imagem — as deps são instaladas dentro do container

## Comandos Git praticados

```bash
git init
git add <arquivo>
git commit -m "feat: ..."
git checkout -b feature/aula-01-app
git checkout main
git merge feature/aula-01-app
git remote add origin <url>
git push -u origin main
git push origin feature/aula-01-app
git log --oneline
git status
```

## Comandos Docker praticados

```bash
docker build -t portfolio-aula01:1.0 .
docker run -d --name portfolio-test -p 3000:3000 portfolio-aula01:1.0
docker ps
docker logs portfolio-test
docker stop portfolio-test
docker rm portfolio-test
curl http://localhost:3000
curl http://localhost:3000/health
```

## Como executar este container

```bash
cd aula-01/app
docker build -t portfolio-aula01:1.0 .
docker run -d --name portfolio-test -p 3000:3000 portfolio-aula01:1.0
curl http://localhost:3000
curl http://localhost:3000/health
```

## Dificuldades encontradas

- Entender a diferença entre `COPY . .` e a ordem das instruções no Dockerfile para aproveitar o cache de camadas — resolvido copiando o `package.json` antes do restante do código
- Lembrar de criar o `.dockerignore` antes de buildar para não copiar o `node_modules/` local para dentro da imagem
