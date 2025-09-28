from fastmcp import FastMCP
from odoo_mcp import tools

# Crear instancia MCP limpia
mcp = FastMCP(name="Odoo MCP (SSE)")

# Registrar todas las tools definidas en el paquete
for t in tools.ALL_TOOLS:
    mcp.add_tool(t)

if __name__ == "__main__":
    mcp.run(transport="sse", host="0.0.0.0", port=8000, path="/sse")
