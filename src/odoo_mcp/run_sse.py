from odoo_mcp.server import server

if __name__ == "__main__":
    # `server` es la función factory que devuelve un FastMCP ya configurado
    mcp = server()
    mcp.run(transport="sse", host="0.0.0.0", port=8000, path="/sse")
