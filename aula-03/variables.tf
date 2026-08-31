variable "aws_region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto para uso em tags e nomes de recursos"
  type        = string
  default     = "TechNova"
}

variable "environment" {
  description = "Ambiente (dev, staging, production)"
  type        = string
  default     = "dev"
}

variable "aluno" {
  description = "Nome do aluno para identificação dos recursos"
  type        = string
  default     = "Matheus Mantovani"
}

variable "ra" {
  description = "RA do aluno — usado como prefixo em todos os recursos IAM"
  type        = string
  default     = "1120245"
}

# Prefixo construído a partir do RA — garante unicidade e rastreabilidade
locals {
  prefix = var.ra

  # Nomes dos grupos
  group_developers   = "${local.prefix}-technova-developers"
  group_platform_eng = "${local.prefix}-technova-platform-eng"

  # Nomes dos usuários
  user_juliana = "${local.prefix}-juliana-dev"
  user_rafael  = "${local.prefix}-rafael-platform"
  user_lucas   = "${local.prefix}-lucas-intern"

  # Nomes das policies
  policy_s3_read          = "${local.prefix}-technova-s3-read"
  policy_ec2_s3_full      = "${local.prefix}-technova-ec2-s3-full"
  policy_deny_destructive = "${local.prefix}-technova-deny-destructive"

  # Nomes do role e instance profile
  role_ec2    = "${local.prefix}-technova-ec2-role"
  profile_ec2 = "${local.prefix}-technova-ec2-profile"
}
