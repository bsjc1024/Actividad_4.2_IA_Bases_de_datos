"""
validator.py

Capa de seguridad del asistente.
La IA puede sugerir SQL, pero esta función decide si esa consulta puede tocar MySQL.
"""

from __future__ import annotations

import re


class SQLValidationError(ValueError):
    """Error lanzado cuando una consulta SQL no cumple las reglas de seguridad."""


_FORBIDDEN_KEYWORDS = {
    "INSERT", "UPDATE", "DELETE", "DROP", "ALTER", "TRUNCATE", "CREATE",
    "REPLACE", "MERGE", "CALL", "EXEC", "EXECUTE", "GRANT", "REVOKE",
    "COMMIT", "ROLLBACK", "START", "LOCK", "UNLOCK", "LOAD", "OUTFILE",
    "DUMPFILE", "INTO",
}

_FORBIDDEN_COMMENT_PATTERNS = [r"--", r"#", r"/\*", r"\*/"]


def _normalize_sql(sql: str) -> str:
    if sql is None:
        raise SQLValidationError("La consulta está vacía.")
    cleaned = sql.strip()
    cleaned = re.sub(r"^```sql\s*", "", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"^```\s*", "", cleaned)
    cleaned = re.sub(r"\s*```$", "", cleaned)
    return cleaned.strip()


def _has_multiple_statements(sql: str) -> bool:
    without_final_semicolon = sql[:-1] if sql.endswith(";") else sql
    return ";" in without_final_semicolon


def validate_select_only(sql: str) -> str:
    """Valida que el SQL sea una sola consulta SELECT segura."""
    cleaned = _normalize_sql(sql)
    if not cleaned:
        raise SQLValidationError("La consulta está vacía.")
    if _has_multiple_statements(cleaned):
        raise SQLValidationError("No se permiten múltiples sentencias SQL.")
    for pattern in _FORBIDDEN_COMMENT_PATTERNS:
        if re.search(pattern, cleaned):
            raise SQLValidationError("No se permiten comentarios dentro del SQL generado.")
    cleaned = cleaned[:-1].strip() if cleaned.endswith(";") else cleaned
    if not re.match(r"^\s*SELECT\b", cleaned, flags=re.IGNORECASE):
        raise SQLValidationError("Solo se permiten consultas que inicien con SELECT.")
    tokens = re.findall(r"\b[A-Za-z_]+\b", cleaned.upper())
    forbidden_found = sorted(set(tokens).intersection(_FORBIDDEN_KEYWORDS))
    if forbidden_found:
        raise SQLValidationError("La consulta contiene palabras prohibidas: " + ", ".join(forbidden_found))
    return cleaned
