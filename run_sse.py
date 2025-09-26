from odoo_mcp.server import server

if __name__ == "__main__":
    srv = server()
    srv.run(transport="sse", host="0.0.0.0", port=8000, path="/sse")
