variable "aws_region" {
  description = "AWS region where the secret will be created"
  type        = string
  default     = "ap-southeast-2"
}

variable "secret_name" {
  description = "Name of the Secrets Manager secret for GitHub PAT"
  type        = string
  default     = "github/issue-resolver-mate-pat"
}

variable "github_pat" {
  description = "GitHub PAT read from secure credentials storage (for example, GitHub Actions Secrets)."
  type        = string
  sensitive   = true
}
