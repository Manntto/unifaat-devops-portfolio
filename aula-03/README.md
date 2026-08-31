# Aula 03 — Terraform + IAM | Matheus Mantovani (RA: 1120245)

## Design da Estrutura IAM

### Por que esses dois grupos?

A separação entre `developers` e `platform-eng` reflete uma divisão real de responsabilidades:

- **developers** precisam ler dados da aplicação no S3 para debugar e desenvolver. Eles **não** precisam criar ou destruir infraestrutura — conceder isso seria um risco desnecessário. Por isso o grupo recebe apenas `s3:GetObject` e `s3:ListBucket` em buckets `technova-*`, mais um Deny explícito em ações destrutivas como proteção extra.

- **platform-eng** são os responsáveis pela infraestrutura: gerenciam instâncias EC2, movem dados no S3, e precisam de visibilidade ampla para fazer o trabalho. Mas mesmo eles têm restrição: o `Start/Stop` de EC2 só funciona em instâncias com a tag `Project=TechNova` — um platform engineer não pode acidentalmente derrubar instâncias de outro projeto na mesma conta.

### Como separei as responsabilidades dos usuários?

| Usuário | Grupo(s) | Raciocínio |
|---------|----------|------------|
| juliana-dev | developers | Dev sênior — lê S3, não precisa de EC2 |
| rafael-platform | developers **+** platform-eng | Platform engineer que também está no grupo developers para ter visibilidade de S3 leitura, mais as permissões completas de plataforma |
| lucas-intern | developers | Estagiário — mesma policy de leitura S3 que o grupo, mais o Deny destrutivo bloqueia qualquer ação irreversível que ele tente |

### Por que Rafael está em dois grupos?

Rafael precisa das permissões de platform-eng para gerenciar EC2, mas também precisa da política de S3 read do grupo developers para acompanhar logs e dados da aplicação. O Deny destrutivo do grupo developers não conflita com as permissões de platform-eng porque o Deny cobre S3 Delete e EC2 Terminate, enquanto a policy ec2_s3_full cobre operações diferentes (Start/Stop com tag, não Terminate).

---

## Princípio do Menor Privilégio

### O que é?

O princípio do menor privilégio (Least Privilege) diz que cada identidade — seja um usuário, grupo ou serviço — deve ter acesso **apenas** ao que é estritamente necessário para realizar sua função, e nada mais.

Na prática: em vez de dar `AmazonS3FullAccess` a um desenvolvedor que só precisa ler um bucket, você cria uma policy customizada que permite `s3:GetObject` e `s3:ListBucket` apenas no ARN específico daquele bucket.

### Como apliquei neste projeto

**Exemplo 1 — Policy s3_read com Condition:**

```hcl
Action = ["s3:ListBucket"]
Resource = ["arn:aws:s3:::technova-*"]
Condition = {
  StringLike = {
    "s3:prefix" = ["app/*", "app/"]
  }
}
```

O `ListBucket` só lista objetos dentro da pasta `app/`. Um desenvolvedor não consegue ver a estrutura completa do bucket — somente os objetos da aplicação. Se eu tivesse usado `AmazonS3ReadOnlyAccess`, ele poderia listar objetos de qualquer bucket na conta.

**Exemplo 2 — Condition por tag no EC2:**

```hcl
Action = ["ec2:StartInstances", "ec2:StopInstances"]
Condition = {
  StringEquals = {
    "aws:ResourceTag/Project" = "TechNova"
  }
}
```

Platform engineers só podem iniciar/parar instâncias marcadas com `Project=TechNova`. Uma instância de outro projeto na mesma conta está protegida. Sem essa Condition, eles poderiam acidentalmente parar qualquer instância na conta AWS.

### O que aconteceria com AmazonS3FullAccess?

Se eu tivesse usado `AmazonS3FullAccess` para o grupo developers:
- Lucas (estagiário) poderia deletar qualquer bucket na conta — incluindo backups de produção
- Juliana poderia sobrescrever objetos em qualquer bucket, não apenas os de `technova-*`
- Nenhum Deny da policy `deny_destructive` conseguiria cobrir o escopo total, porque `FullAccess` cobre toda a AWS, não apenas `technova-*`

---

## Diagrama de Permissões

```
AWS Account
│
├── Group: 1120245-technova-developers
│   ├── Users: juliana-dev, lucas-intern, rafael-platform
│   ├── Policy: 1120245-technova-s3-read
│   │   └── Allow: s3:GetObject, s3:ListBucket → arn:aws:s3:::technova-*
│   │   └── Condition: s3:prefix = "app/*" (no ListBucket)
│   └── Policy: 1120245-technova-deny-destructive
│       └── Deny: s3:DeleteBucket, ec2:TerminateInstances, iam:DeleteUser, ...
│
├── Group: 1120245-technova-platform-eng
│   ├── Users: rafael-platform
│   └── Policy: 1120245-technova-ec2-s3-full
│       ├── Allow: ec2:Describe* → *
│       ├── Allow: ec2:Start/Stop/Reboot → instâncias com tag Project=TechNova
│       └── Allow: s3:GetObject, s3:PutObject, s3:ListBucket, s3:DeleteObject → technova-*
│
└── Role: 1120245-technova-ec2-role
    ├── Trust Policy: ec2.amazonaws.com pode assumir (sts:AssumeRole)
    ├── Policy: 1120245-technova-ec2-s3-app-data
    │   └── Allow: s3:GetObject, s3:PutObject, s3:ListBucket → technova-app-data-*
    └── Instance Profile: 1120245-technova-ec2-profile
        └── Anexado a instâncias EC2 para acesso automático sem access keys
```

---

## Comandos Utilizados

```bash
# Inicializa o diretório Terraform e baixa o provider AWS
terraform init

# Valida a sintaxe HCL sem acessar a AWS
terraform validate

# Formata automaticamente os arquivos .tf
terraform fmt

# Mostra o que será criado/alterado/destruído (dry-run)
terraform plan

# Cria os recursos na AWS (requer credenciais configuradas)
terraform apply

# Remove todos os recursos criados (SEMPRE executar após testes)
terraform destroy
```

---

## Reflexão: Console AWS vs. Terraform

### Abordagem Manual (Console AWS)

Carlos, o CTO da TechNova, levou 3 horas criando infraestrutura pelo Console da AWS. No dia seguinte, o estagiário deletou um bucket por engano e não havia como saber o que estava configurado para recriar.

Problemas concretos da abordagem manual:
- **Sem auditoria**: não existe registro de quem criou o quê, quando, e com quais configurações
- **Sem reprodutibilidade**: para criar um ambiente idêntico (staging, disaster recovery), é preciso começar do zero clicando em cada tela
- **Sem revisão por pares**: ninguém vê o que vai ser criado antes de ser criado — não existe o equivalente a um Pull Request
- **Escala mal**: com 4 pessoas tudo bem; com 20 pessoas e múltiplos ambientes, vira caos

### Abordagem com Terraform

Com Terraform, toda a estrutura IAM da TechNova — 2 grupos, 3 usuários, 3 policies, 1 role, 1 instance profile — está descrita em 5 arquivos `.tf` com menos de 400 linhas de código. Qualquer membro da equipe pode:

1. `git clone` do repositório
2. `terraform plan` para ver exatamente o que será criado antes de criar
3. `terraform apply` para criar tudo em minutos, de forma idêntica a qualquer ambiente

A mudança de permissão vira um Pull Request: é revisável, auditável, revertível. Se o estagiário Lucas tiver as permissões erradas, basta abrir um PR alterando a `membership` do grupo — sem nenhum clique no console.

**Qual é mais segura e auditável?** O Terraform, sem dúvida. O Git fornece o histórico completo de quem mudou qual permissão, quando e por quê (mensagem do commit). Um auditor de compliance pode revisar o histórico de IAM lendo o `git log` — algo impossível com o Console AWS.
