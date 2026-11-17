variable "aws_region" {
  description = "AWS region where the AgentCore resources will be created"
  type        = string
  default     = "ap-southeast-2"
}

variable "role_name" {
  description = "Name of the IAM role allowed to create AgentCore Gateways"
  type        = string
  default     = "agentcore-gateway-creator"
}

variable "gateway_execution_role_name" {
  description = "Name of the IAM role AgentCore Gateway assumes at runtime"
  type        = string
  default     = "agentcore-gateway-execution"
}

variable "ecr_repository_name" {
  description = "ECR repository that holds the MCP server container image"
  type        = string
  default     = "hello-mcp"
}

variable "image_tag" {
  description = "Tag of the MCP server image in ECR"
  type        = string
  default     = "latest"
}

variable "agent_runtime_name" {
  description = "AgentCore Runtime name (letters, digits, underscores; must start with a letter)"
  type        = string
  default     = "hello_mcp"
}

variable "runtime_execution_role_name" {
  description = "Name of the IAM role the AgentCore Runtime assumes to pull the image and write logs"
  type        = string
  default     = "agentcore-runtime-execution"
}
