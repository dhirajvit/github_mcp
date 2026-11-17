# Deploy the Hello MCP server to AgentCore Runtime

The server uses standalone FastMCP and exposes `hello_world` over stateless
Streamable HTTP at `/mcp`, with a health check at `/ping`. Terraform creates a
private ECR repository, an execution role, and an AgentCore Runtime configured
for MCP. It also manages the gateway IAM roles in the same Terraform directory;
review the complete plan before applying.

## Prerequisites

- Python 3.11 or later for local testing.
- Terraform 1.10 or later, AWS CLI v2, and Docker with Buildx. On macOS, install
  and start [Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/)
  before running the build commands.
- AWS credentials with permission to manage ECR, IAM, and AgentCore resources.
  Verify the active account and identity with `aws sts get-caller-identity`.
- These commands use the default region `ap-southeast-2`. If you change
  `aws_region`, use the same region for the AWS CLI and Docker login.

The step2 Terraform state is stored in the private S3 bucket
`hello-mcp-s3-terraform-state-common-ground` at
`step2-agentcore/terraform.tfstate`, with S3 lockfile locking enabled. Local
Terraform and GitHub Actions must use this same bucket, key, and workspace.
Their AWS identities need permission to list the bucket, read and write the
state object, and read, write, and delete its `.tflock` object. The backend
region remains `ap-southeast-2` even if `aws_region` is changed.

If step2 was previously applied using local state, back up the state securely
and run `terraform init -migrate-state` in `terraform/step2-agentcore` before
using GitHub Actions. Review the migration prompt and the subsequent plan.
Terraform state can contain secrets; do not commit or share the backup.
The separate step1 configuration is not migrated by this change.

Creating and running AWS resources may incur charges. This configuration uses
the default IAM/SigV4 authorization; `PUBLIC` network mode does not make the
MCP endpoint anonymously accessible.

## Test locally

From the repository root:

```sh
.venv/bin/python -m pip install -r requirements.txt
.venv/bin/python -m unittest discover -s hello-mcp -p 'test_*.py'
```

To run the HTTP server locally, use `.venv/bin/python hello-mcp/server.py`.
The health endpoint is `http://localhost:8000/ping`.

## Deploy

The image must exist before the Runtime can be created. First create only the
ECR repository, then push an ARM64 image, then apply the complete configuration.
The targeted apply is only for this initial bootstrap; use normal plans and
applies afterward.

From the repository root:

```sh
cd terraform/step2-agentcore
terraform init -upgrade
terraform plan -target=aws_ecr_repository.mcp_server
terraform apply -target=aws_ecr_repository.mcp_server
export ECR_REPOSITORY_URL="$(terraform output -raw ecr_repository_url)"
export AWS_REGION=ap-southeast-2
export IMAGE_TAG=v1
```

Check the plan and approve the apply when prompted. Then authenticate and build
from the repository root. `--provenance=false` produces a single-platform image
manifest suitable for Runtime rather than a multi-manifest image index.

```sh
cd ../..
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "${ECR_REPOSITORY_URL%%/*}"
docker buildx build --platform linux/arm64 --provenance=false --push -f hello-mcp/Dockerfile -t "$ECR_REPOSITORY_URL:$IMAGE_TAG" .
cd terraform/step2-agentcore
terraform plan -var="image_tag=$IMAGE_TAG"
terraform apply -var="image_tag=$IMAGE_TAG"
terraform output agent_runtime_arn
```

Wait for the runtime status to become `READY` before invoking it:

```sh
aws bedrock-agentcore-control list-agent-runtimes --region "$AWS_REGION" --output table
```

To deploy a later build, choose a **new image tag**, build and push it, then
pass the new tag to both `terraform plan` and `terraform apply`. Replacing an
image under the same tag does not change the Terraform configuration and does
not trigger a Runtime update.

## Deploy with GitHub Actions

The `Terraform Step2 AgentCore` workflow automatically deploys pushes to
`main` that change the server, requirements, Docker build context settings,
step2 Terraform, or the workflow itself. It also supports manual execution
from the repository's Actions tab. It tests the server, creates the ECR
repository if it is not in Terraform state, builds and pushes an ARM64 image
with a new tag for each run, and applies the complete step2 configuration.
These applies are automatic and can create or change billable AWS resources.

Configure the repository secrets `AWS_ACCESS_KEY_ID` and
`AWS_SECRET_ACCESS_KEY` for an identity in account `365957109972`. It needs
permissions for the shared S3 state and lock, ECR image push, IAM roles and
policies, and AgentCore Runtime. This is the same credential setup used by the
step1 workflow; `GH_PAT` is not required by step2. Protect the `main` branch
and restrict who may run the workflow. For production, prefer GitHub OIDC
with a narrowly scoped AWS role over long-lived access keys.

The workflow and local commands use the same S3 state and workspace. Do not
run applies concurrently; S3 state locking protects individual Terraform
operations, not the entire build-and-deploy sequence. To avoid a local apply
unexpectedly reverting a CI deployment, supply its current image tag as
`-var="image_tag=..."` when planning or applying locally.

## Invoke the deployed tool

From `terraform/step2-agentcore`, use the AWS CLI to sign an MCP JSON-RPC
request with your active AWS credentials:

```sh
export RUNTIME_ARN="$(terraform output -raw agent_runtime_arn)"
aws bedrock-agentcore invoke-agent-runtime \
  --region "$AWS_REGION" \
  --agent-runtime-arn "$RUNTIME_ARN" \
  --content-type application/json \
  --accept 'application/json, text/event-stream' \
  --cli-binary-format raw-in-base64-out \
  --payload '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"hello_world","arguments":{"name":"AgentCore"}}}' \
  response.txt
```

Inspect `response.txt` for `Hello, AgentCore!`. The caller needs
`bedrock-agentcore:InvokeAgentRuntime` permission. See the
[AWS MCP Runtime guide](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-mcp.html)
for client and authentication options.
