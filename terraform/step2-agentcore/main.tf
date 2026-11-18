data "aws_caller_identity" "current" {}

# Role that is allowed to create and manage AgentCore Gateways.
resource "aws_iam_role" "gateway_creator" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/ai_enginner" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "gateway_creator" {
  name = "${var.role_name}-policy"
  role = aws_iam_role.gateway_creator.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageAgentCoreGateways"
        Effect = "Allow"
        Action = [
          "bedrock-agentcore:CreateGateway",
          "bedrock-agentcore:GetGateway",
          "bedrock-agentcore:ListGateways",
          "bedrock-agentcore:UpdateGateway",
          "bedrock-agentcore:DeleteGateway",
          "bedrock-agentcore:CreateGatewayTarget",
          "bedrock-agentcore:GetGatewayTarget",
          "bedrock-agentcore:ListGatewayTargets",
          "bedrock-agentcore:UpdateGatewayTarget",
          "bedrock-agentcore:DeleteGatewayTarget",
        ]
        Resource = "arn:aws:bedrock-agentcore:${var.aws_region}:${data.aws_caller_identity.current.account_id}:gateway/*"
      },
      {
        Sid      = "PassGatewayExecutionRole"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = aws_iam_role.gateway_execution.arn
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "bedrock-agentcore.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Role the AgentCore Gateway service assumes at runtime.
resource "aws_iam_role" "gateway_execution" {
  name = var.gateway_execution_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "bedrock-agentcore.amazonaws.com" }
        Action    = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:bedrock-agentcore:${var.aws_region}:${data.aws_caller_identity.current.account_id}:gateway/*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "gateway_execution" {
  name = "${var.gateway_execution_role_name}-policy"
  role = aws_iam_role.gateway_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GatewayAuthorization"
        Effect = "Allow"
        Action = [
          "bedrock-agentcore:AuthorizeAction",
          "bedrock-agentcore:PartiallyAuthorizeActions",
          "bedrock-agentcore:GetPolicyEngine",
        ]
        Resource = "*"
      }
    ]
  })
}

output "gateway_creator_role_arn" {
  description = "ARN of the role allowed to create AgentCore Gateways"
  value       = aws_iam_role.gateway_creator.arn
}

output "gateway_execution_role_arn" {
  description = "ARN of the role AgentCore Gateway assumes at runtime"
  value       = aws_iam_role.gateway_execution.arn
}
