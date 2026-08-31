# ─── USERS ───────────────────────────────────────────────────────────────────

output "user_juliana_arn" {
  description = "ARN do IAM user juliana-dev"
  value       = aws_iam_user.juliana.arn
}

output "user_rafael_arn" {
  description = "ARN do IAM user rafael-platform"
  value       = aws_iam_user.rafael.arn
}

output "user_lucas_arn" {
  description = "ARN do IAM user lucas-intern"
  value       = aws_iam_user.lucas.arn
}

# ─── GROUPS ──────────────────────────────────────────────────────────────────

output "group_developers_arn" {
  description = "ARN do grupo developers"
  value       = aws_iam_group.developers.arn
}

output "group_platform_eng_arn" {
  description = "ARN do grupo platform-eng"
  value       = aws_iam_group.platform_eng.arn
}

# ─── POLICIES ────────────────────────────────────────────────────────────────

output "policy_s3_read_arn" {
  description = "ARN da policy de leitura S3"
  value       = aws_iam_policy.s3_read.arn
}

output "policy_ec2_s3_full_arn" {
  description = "ARN da policy EC2 + S3 full para platform engineers"
  value       = aws_iam_policy.ec2_s3_full.arn
}

output "policy_deny_destructive_arn" {
  description = "ARN da policy de Deny em ações destrutivas"
  value       = aws_iam_policy.deny_destructive.arn
}

# ─── ROLE ────────────────────────────────────────────────────────────────────

output "ec2_role_arn" {
  description = "ARN do IAM Role para instâncias EC2"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_instance_profile_arn" {
  description = "ARN do Instance Profile para uso no EC2"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

output "ec2_instance_profile_name" {
  description = "Nome do Instance Profile (referência no recurso aws_instance)"
  value       = aws_iam_instance_profile.ec2_profile.name
}
