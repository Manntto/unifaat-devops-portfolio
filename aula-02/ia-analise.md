# Análise do Uso de IA — Aula 02 TF

**Aluno:** Matheus Mantovani  
**RA:** 1120245

---

## Prompt Utilizado

> "Crie um docker-compose.yml para uma aplicação Node.js 20 com Express que usa PostgreSQL 15 como banco de dados e Redis 7 como cache. A API roda na porta 3000. O PostgreSQL precisa de volume nomeado para persistência. Todos os serviços devem estar na mesma rede bridge customizada. Use variáveis de ambiente com interpolação de arquivo .env. Adicione healthchecks, depends_on com condition, e restart policy unless-stopped."

---

## Output Original do Kiro (rascunho gerado)

```yaml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_NAME=technova
      - DB_USER=technova
      - DB_PASSWORD=secret123
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - technova-net
    restart: unless-stopped

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=technova
      - POSTGRES_USER=technova
      - POSTGRES_PASSWORD=secret123
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U technova"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - technova-net
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    networks:
      - technova-net
    restart: unless-stopped

networks:
  technova-net:
    driver: bridge

volumes:
  pgdata:
```

---

## Alterações que Fiz Manualmente

| O que mudei | Por quê |
|-------------|---------|
| Removi `version: '3.8'` do topo | A propriedade `version` está obsoleta no Docker Compose v2+ e gera warning — foi removida do spec oficial |
| Substituí senhas hardcoded (`secret123`) por variáveis `${DB_PASSWORD}` e `${POSTGRES_PASSWORD}` | Senha hardcoded no YAML é um risco de segurança; qualquer pessoa com acesso ao repositório teria acesso à senha |
| Adicionei healthcheck no Redis (`redis-cli ping`) | O Kiro não incluiu healthcheck no Redis — sem ele o `depends_on` com `condition: service_healthy` não funciona para o Redis |
| Adicionei `start_period: 30s` no healthcheck do PostgreSQL | O Postgres leva tempo para inicializar na primeira vez (inicialização do cluster); sem esse parâmetro os retries podem falhar antes do banco estar pronto |
| Adicionei `-d ${POSTGRES_DB}` no `pg_isready` do healthcheck | Verificação mais precisa: garante que o banco específico está pronto, não apenas o serviço PostgreSQL |
| Adicionei `container_name` em cada serviço | Facilita identificação nos logs e em comandos `docker exec` durante o desenvolvimento |
| Adicionei mapeamento de portas no PostgreSQL e Redis | Permite conexão direta às portas para debug com ferramentas externas (DBeaver, Redis Insight) |
| Adicionei `name: technova-net` na rede | Garante nome previsível para inspecionar a rede com `docker network inspect` |
| Interpolei a porta da API com `${PORT:-3000}` | Permite override via `.env` sem quebrar se a variável não for definida (valor padrão) |

---

## O que o Kiro Acertou

- Estrutura geral do YAML estava correta e funcional como ponto de partida
- Usou `depends_on` com `condition: service_healthy` — a forma correta de garantir ordem de inicialização
- Volume nomeado `pgdata` configurado corretamente no local certo (`/var/lib/postgresql/data`)
- Rede bridge customizada `technova-net` conectando todos os serviços
- `restart: unless-stopped` em todos os serviços — boa prática padrão para ambientes de dev
- Healthcheck do PostgreSQL com `pg_isready` estava no caminho certo

---

## O que o Kiro Errou ou Omitiu

- **Senhas hardcoded** — o maior problema: `secret123` estava direto no YAML em vez de usar variáveis do `.env`
- **Sem healthcheck no Redis** — o `depends_on` da API pede `condition: service_healthy` para o Redis, mas sem healthcheck isso causaria erro na inicialização
- **`version: '3.8'` obsoleto** — continua funcionando mas gera warning e não é necessário no Compose v2+
- **Sem `start_period`** no healthcheck do Postgres — pode causar falhas na primeira inicialização quando o banco ainda está criando o cluster
- **Sem `.env.example`** — o Kiro não criou o template de variáveis; tive que criar manualmente
- **Sem mapeamento de portas** no Postgres e Redis — dificulta o debug local com ferramentas externas

---

## Minha Avaliação

- **Tempo economizado usando IA:** ~8 minutos (não precisei lembrar a sintaxe exata do healthcheck e da estrutura base do Compose)
- **Tempo gasto validando/corrigindo:** ~15 minutos (identificar problemas de segurança, testar, ajustar o healthcheck do Redis e o `start_period`)
- **Nota para o output da IA (1-10):** 6/10 — estrutura sólida, mas os problemas de segurança (senha hardcoded) e a falta do healthcheck no Redis são erros que comprometeriam o funcionamento
- **Usaria novamente para este tipo de tarefa?** Sim, mas como rascunho inicial — nunca como output final. O fluxo ideal é: gerar com IA → revisar criticamente → corrigir → testar. A IA acelera a largada, mas o julgamento técnico ainda é meu.
