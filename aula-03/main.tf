# =============================================================================
# main.tf — IAM Users, Groups e Memberships
# Aula 03 — Matheus Mantovani (RA: 1120245)
# Nota: AWS Academy voclabs não permite path customizado nem tags em IAM identities
# =============================================================================

# ─── GROUPS ──────────────────────────────────────────────────────────────────

# Grupo para desenvolvedores — acesso S3 leitura + proteção contra ações destrutivas
resource "aws_iam_group" "developers" {
  name = local.group_developers
}

# Grupo para platform engineers — acesso EC2 + S3 completo
resource "aws_iam_group" "platform_eng" {
  name = local.group_platform_eng
}

# ─── USERS ───────────────────────────────────────────────────────────────────

# Dev sênior — pertence ao grupo developers
resource "aws_iam_user" "juliana" {
  name = local.user_juliana
}

# Platform engineer — pertence a AMBOS os grupos (developers + platform_eng)
resource "aws_iam_user" "rafael" {
  name = local.user_rafael
}

# Estagiário — pertence ao grupo developers (com acesso mais restrito via policy)
resource "aws_iam_user" "lucas" {
  name = local.user_lucas
}

# ─── GROUP MEMBERSHIPS ────────────────────────────────────────────────────────

# Developers: juliana + lucas + rafael
resource "aws_iam_group_membership" "developers" {
  name  = "${local.group_developers}-membership"
  group = aws_iam_group.developers.name

  users = [
    aws_iam_user.juliana.name,
    aws_iam_user.lucas.name,
    aws_iam_user.rafael.name,
  ]
}

# Platform Engineers: apenas rafael
resource "aws_iam_group_membership" "platform_eng" {
  name  = "${local.group_platform_eng}-membership"
  group = aws_iam_group.platform_eng.name

  users = [
    aws_iam_user.rafael.name,
  ]
}
