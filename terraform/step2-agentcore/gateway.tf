resource "aws_iam_role_policy" "gateway_invoke_runtime" {
  name = "${var.gateway_execution_role_name}-invoke-runtime"
  role = aws_iam_role.gateway_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "bedrock-agentcore:InvokeAgentRuntime"
      Resource = [
        aws_bedrockagentcore_agent_runtime.hello_mcp.agent_runtime_arn,
        "${aws_bedrockagentcore_agent_runtime.hello_mcp.agent_runtime_arn}/runtime-endpoint/DEFAULT",
      ]
    }]
  })
}

resource "aws_bedrockagentcore_gateway" "hello_mcp" {
  name            = var.gateway_name
  role_arn        = aws_iam_role.gateway_execution.arn
  protocol_type   = "MCP"
  authorizer_type = "CUSTOM_JWT"

  authorizer_configuration {
    custom_jwt_authorizer {
      discovery_url   = var.gateway_jwt_discovery_url
      allowed_clients = var.gateway_jwt_allowed_clients
    }
  }

  depends_on = [aws_iam_role_policy.gateway_execution]
}

resource "aws_bedrockagentcore_gateway_target" "hello_mcp" {
  name               = "hello-mcp"
  gateway_identifier = aws_bedrockagentcore_gateway.hello_mcp.gateway_id

  credential_provider_configuration {
    gateway_iam_role {
      service = "bedrock-agentcore"
      region  = var.aws_region
    }
  }

  target_configuration {
    mcp {
      mcp_server {
        endpoint = "https://bedrock-agentcore.${var.aws_region}.amazonaws.com/runtimes/${urlencode(aws_bedrockagentcore_agent_runtime.hello_mcp.agent_runtime_arn)}/invocations?qualifier=DEFAULT"
      }
    }
  }

  depends_on = [aws_iam_role_policy.gateway_invoke_runtime]
}

output "gateway_url" {
  description = "MCP gateway URL; requires an access token from an allowed OAuth client"
  value       = aws_bedrockagentcore_gateway.hello_mcp.gateway_url
}
