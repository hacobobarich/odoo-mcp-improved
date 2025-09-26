from fastmcp import FastMCP
from odoo_mcp import tools   # el módulo del paquete donde están las herramientas registradas

# Crear la instancia MCP manualmente
mcp = FastMCP(name="Odoo MCP (SSE)")

# Registrar todas las tools que exporta odoo_mcp.tools
for t in tools.ALL_TOOLS:
    mcp.add_tool(t)

if __name__ == "__main__":
    # Ejecutar en SSE en el puerto 8000
    mcp.run(transport="sse", host="0.0.0.0", port=8000, path="/sse")
