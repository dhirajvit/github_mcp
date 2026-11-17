from fastmcp import FastMCP
from starlette.requests import Request
from starlette.responses import PlainTextResponse

mcp = FastMCP("Hello MCP")


@mcp.tool
def hello_world(name: str = "World") -> str:
    """Return a friendly greeting."""
    return f"Hello, {name}!"


# AgentCore Runtime health check endpoint.
@mcp.custom_route("/ping", methods=["GET"])
async def ping(request: Request) -> PlainTextResponse:
    return PlainTextResponse("pong")


if __name__ == "__main__":
    mcp.run(
        transport="http",
        host="0.0.0.0",
        port=8000,
        path="/mcp",
        stateless_http=True,
    )
