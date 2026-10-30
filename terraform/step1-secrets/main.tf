resource "aws_secretsmanager_secret" "github_pat" {
  name                    = var.secret_name
  description             = "Fine-grained GitHub PAT for issue-resolver-mate automation"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "github_pat" {
  secret_id = aws_secretsmanager_secret.github_pat.id
  secret_string = jsonencode({
    token = var.github_pat
  })
}

output "secret_arn" {
  description = "ARN of the created GitHub PAT secret"
  value       = aws_secretsmanager_secret.github_pat.arn
}
