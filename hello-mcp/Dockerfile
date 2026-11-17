# Build from the repo root for ARM64 (AgentCore Runtime requirement):
#   docker buildx build --platform linux/arm64 -f hello-mcp/Dockerfile -t hello-mcp .
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY hello-mcp/server.py .

EXPOSE 8000
CMD ["python", "server.py"]
