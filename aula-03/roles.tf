# =============================================================================
# roles.tf — Service Role EC2 + Instance Profile
# Critério 7: assume_role_policy + policy_attachment + instance profile
# Aula 03 — Matheus Mantovani (RA: 1120245)
# Nota: AWS Academy não permite path customizado em roles
# =============================================================================

# ─── TRUST POLICY (quem pode assumir o role) ─────────────────────────────────
# Somente o serviço EC2 da AWS pode assumir este role.

data "aws_iam_policy_document" "ec2_trust_policy" {
  statement {
    sid    = "AllowEC2AssumeRole"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# ─── ROLE ────────────────────────────────────────────────────────────────────

resource "aws_iam_role" "ec2_role" {
  name               = local.role_ec2
  description        = "Role assumida por instâncias EC2 da TechNova para acesso ao S3"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust_policy.json

  # max_session_duration: 1 hora — credenciais temporárias expiram rapidamente
  max_session_duration = 3600
}

# ─── PERMISSIONS POLICY: EC2 pode ler/escrever apenas em technova-app-data-* ─

resource "aws_iam_policy" "ec2_s3_app_data" {
  name        = "${local.prefix}-technova-ec2-s3-app-data"
  description = "Permite que instâncias EC2 leiam e escrevam somente em buckets technova-app-data-*"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowListAppDataBuckets"
        Effect = "Allow"
        Action = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = [
          "arn:aws:s3:::technova-app-data-*"
        ]
      },
      {
        Sid    = "AllowReadWriteAppDataObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion"
        ]
        Resource = [
          "arn:aws:s3:::technova-app-data-*/*"
        ]
      }
    ]
  })
}

# ─── ATTACHMENT: Policy → Role ────────────────────────────────────────────────

resource "aws_iam_role_policy_attachment" "ec2_role_s3_app_data" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_s3_app_data.arn
}

# ─── INSTANCE PROFILE ────────────────────────────────────────────────────────
# O Instance Profile é o "envelope" que associa o Role a uma instância EC2.
# Sem ele, o Role existe mas não pode ser anexado a nenhuma instância.

resource "aws_iam_instance_profile" "ec2_profile" {
  name = local.profile_ec2
  role = aws_iam_role.ec2_role.name
}
