# =============================================================================
# policies.tf — Custom Policies + Attachments
# Critério 5 (mínimo 3 policies) + Critério 6 (Condition + Deny explícito)
# Aula 03 — Matheus Mantovani (RA: 1120245)
# Nota: AWS Academy não permite iam:TagPolicy — tags removidas das policies
# =============================================================================

# ─── POLICY 1: S3 Read-Only em buckets technova-* ────────────────────────────
# Princípio do menor privilégio: apenas GetObject e ListBucket, apenas em
# buckets cujo nome começa com "technova-" — não acessa nenhum outro bucket.

resource "aws_iam_policy" "s3_read" {
  name        = local.policy_s3_read
  description = "Leitura em buckets S3 prefixados com technova-. Anexada ao grupo developers."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3ListBucket"
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::technova-*"
        ]
        # Condition: restringe ListBucket ao prefixo "app/" dentro do bucket
        # Impede que o dev veja objetos fora da pasta da aplicação
        Condition = {
          StringLike = {
            "s3:prefix" = ["app/*", "app/"]
          }
        }
      },
      {
        Sid    = "AllowS3GetObject"
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = [
          "arn:aws:s3:::technova-*/*"
        ]
      }
    ]
  })
}

# ─── POLICY 2: EC2 + S3 Full para Platform Engineers ─────────────────────────
# Permite EC2 Describe + Start/Stop (com Condition por tag) + S3 read/write.
# A Condition no Start/Stop garante que só instâncias com tag Project=TechNova
# podem ser iniciadas/paradas — protege recursos de outros projetos.

resource "aws_iam_policy" "ec2_s3_full" {
  name        = local.policy_ec2_s3_full
  description = "EC2 Describe irrestrito + Start/Stop somente em instâncias TechNova + S3 read/write em technova-*"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2Describe"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeImages",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:DescribeTags"
        ]
        Resource = ["*"]
      },
      {
        # Condition: só pode Start/Stop instâncias que tenham a tag Project=TechNova
        Sid    = "AllowEC2StartStopTagged"
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RebootInstances"
        ]
        Resource = ["arn:aws:ec2:*:*:instance/*"]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Project" = "TechNova"
          }
        }
      },
      {
        Sid    = "AllowS3ReadWrite"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::technova-*",
          "arn:aws:s3:::technova-*/*"
        ]
      }
    ]
  })
}

# ─── POLICY 3: Deny explícito em ações destrutivas ───────────────────────────
# Deny explícito SEMPRE prevalece sobre qualquer Allow — mesmo que outra policy
# conceda a ação, este Deny garante que ninguém no grupo developers pode
# executar ações que deletam ou encerram recursos na conta.

resource "aws_iam_policy" "deny_destructive" {
  name        = local.policy_deny_destructive
  description = "Deny explícito em Delete* e Terminate* para o grupo developers. Proteção contra ações irreversíveis."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyDestructiveS3"
        Effect = "Deny"
        Action = [
          "s3:DeleteBucket",
          "s3:DeleteObject",
          "s3:DeleteBucketPolicy",
          "s3:PutBucketPolicy"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "DenyDestructiveEC2"
        Effect = "Deny"
        Action = [
          "ec2:TerminateInstances",
          "ec2:DeleteVpc",
          "ec2:DeleteSubnet",
          "ec2:DeleteSecurityGroup",
          "ec2:DeleteInternetGateway"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "DenyDestructiveIAM"
        Effect = "Deny"
        Action = [
          "iam:DeleteUser",
          "iam:DeleteGroup",
          "iam:DeleteRole",
          "iam:DeletePolicy",
          "iam:DetachUserPolicy",
          "iam:DetachGroupPolicy",
          "iam:DetachRolePolicy"
        ]
        Resource = ["*"]
      }
    ]
  })
}

# ─── ATTACHMENTS: Policy → Group ──────────────────────────────────────────────

# Developers recebem: S3 read + proteção Deny destrutivo
resource "aws_iam_group_policy_attachment" "developers_s3_read" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.s3_read.arn
}

resource "aws_iam_group_policy_attachment" "developers_deny_destructive" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.deny_destructive.arn
}

# Platform Engineers recebem: EC2 + S3 full
resource "aws_iam_group_policy_attachment" "platform_eng_ec2_s3_full" {
  group      = aws_iam_group.platform_eng.name
  policy_arn = aws_iam_policy.ec2_s3_full.arn
}
