import importlib.util
import json
import unittest
from pathlib import Path

from starlette.testclient import TestClient

spec = importlib.util.spec_from_file_location("hello_server", Path(__file__).with_name("server.py"))
server = importlib.util.module_from_spec(spec)
spec.loader.exec_module(server)


class ServerTest(unittest.TestCase):
    def test_health_and_mcp_requests(self):
        headers = {
            "accept": "application/json, text/event-stream",
            "mcp-protocol-version": "2025-11-25",
            "mcp-session-id": "test-session",
            "x-amzn-bedrock-agentcore-runtime-session-id": "a" * 33,
        }
        with TestClient(server.mcp.http_app(path="/mcp", stateless_http=True)) as client:
            response = client.get("/ping")
            self.assertEqual((response.status_code, response.text), (200, "pong"))

            def request(method, params, request_id):
                response = client.post(
                    "/mcp",
                    headers=headers,
                    json={"jsonrpc": "2.0", "id": request_id, "method": method, "params": params},
                )
                self.assertEqual(response.status_code, 200, response.text)
                data = next(line[5:].strip() for line in response.text.splitlines() if line.startswith("data:"))
                return json.loads(data)["result"]

            result = request(
                "initialize",
                {
                    "protocolVersion": "2025-11-25",
                    "capabilities": {},
                    "clientInfo": {"name": "test", "version": "1.0"},
                },
                1,
            )
            self.assertEqual(result["protocolVersion"], "2025-11-25")
            result = request("tools/list", {}, 2)
            self.assertIn("hello_world", [tool["name"] for tool in result["tools"]])
            result = request("tools/call", {"name": "hello_world", "arguments": {"name": "AgentCore"}}, 3)
            self.assertFalse(result["isError"])
            self.assertEqual(result["structuredContent"]["result"], "Hello, AgentCore!")
            result = request("tools/call", {"name": "hello_world", "arguments": {}}, 4)
            self.assertEqual(result["structuredContent"]["result"], "Hello, World!")


if __name__ == "__main__":
    unittest.main()
