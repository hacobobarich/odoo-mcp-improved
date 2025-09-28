FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# 1) Dependencias base + fastmcp (última estable disponible en PyPI)
RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
 && pip install --no-cache-dir fastmcp

# 2) Cliente Odoo (XML-RPC) SOLO LECTURA
RUN python - <<'PY'
import textwrap, pathlib
pathlib.Path("/app/odoo_client.py").write_text(textwrap.dedent(r"""
import os, functools, xmlrpc.client

ODOO_URL = os.environ["ODOO_URL"].rstrip("/")
ODOO_DB  = os.environ["ODOO_DB"]
ODOO_USER = os.environ.get("ODOO_USERNAME") or os.environ["ODOO_USER"]
ODOO_PASS = os.environ.get("ODOO_PASSWORD") or os.environ["ODOO_PASS"]

COMMON = xmlrpc.client.ServerProxy(f"{ODOO_URL}/xmlrpc/2/common", allow_none=True)
OBJECT = xmlrpc.client.ServerProxy(f"{ODOO_URL}/xmlrpc/2/object", allow_none=True)

@functools.lru_cache(maxsize=1)
def _uid():
    uid = COMMON.authenticate(ODOO_DB, ODOO_USER, ODOO_PASS, {})
    if not uid:
        raise RuntimeError("Autenticación Odoo fallida")
    return uid

READ_ONLY_METHODS = {"search_read", "read", "fields_get", "name_search", "search_count"}

def exec_kw(model: str, method: str, args=None, kwargs=None):
    if method not in READ_ONLY_METHODS:
        raise PermissionError(f"Método no permitido: {method}")
    return OBJECT.execute_kw(ODOO_DB, _uid(), ODOO_PASS, model, method, args or [], kwargs or {})

def search_read(model, domain=None, fields=None, limit=80, offset=0, order=None):
    kwargs = {"domain": domain or [], "fields": fields or [], "limit": limit, "offset": offset}
    if order: kwargs["order"] = order
    return exec_kw(model, "search_read", [], kwargs)
"""), encoding="utf-8")
PY

# 3) Servidor MCP SSE
RUN python - <<'PY'
import textwrap, pathlib
pathlib.Path("/app/server.py").write_text(textwrap.dedent(r"""
from fastmcp import FastMCP
from typing import List, Optional, Any, Dict
from odoo_client import search_read, exec_kw

PORT = int(__import__('os').environ.get("PORT", "8000"))
SSE_PATH = __import__('os').environ.get("MCP_SSE_PATH", "/sse")

mcp = FastMCP(name="Odoo MCP SSE")

@mcp.tool
def odoo_search_read(model: str, domain: List[Any] = None,
                     fields: List[str] = None, limit: int = 80,
                     offset: int = 0, order: Optional[str] = None) -> list:
    return search_read(model, domain or [], fields or [], limit, offset, order)

@mcp.tool
def odoo_exec_readonly(model: str, method: str,
                       args: List[Any] = None,
                       kwargs: Dict[str, Any] = None) -> Any:
    return exec_kw(model, method, args or [], kwargs or {})

if __name__ == "__main__":
    print(f"🚀 Odoo MCP SSE corriendo en 0.0.0.0:{PORT}{SSE_PATH}", flush=True)
    mcp.run(transport="sse", host="0.0.0.0", port=PORT, path=SSE_PATH)
"""), encoding="utf-8")
PY

EXPOSE 8000
CMD ["python", "/app/server.py"]
