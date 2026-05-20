"""
db.py

Funciones de conexión, ejecución, EXPLAIN, extracción de DDL y auditoría.
"""

from __future__ import annotations

import os
from typing import Any

import mysql.connector
from mysql.connector import Error
from dotenv import load_dotenv

load_dotenv()

BUSINESS_TABLES = ["clientes", "categorias", "productos", "pedidos", "detalle_pedido", "pagos", "envios"]


def get_connection(database: str | None = None):
    db_name = database if database is not None else os.getenv("DB_NAME", "ecommerce_ia")
    try:
        return mysql.connector.connect(
            host=os.getenv("DB_HOST", "localhost"),
            port=int(os.getenv("DB_PORT", "3306")),
            user=os.getenv("DB_USER", "root"),
            password=os.getenv("DB_PASSWORD", ""),
            database=db_name,
            autocommit=False,
        )
    except Error as exc:
        raise RuntimeError(f"No se pudo conectar a MySQL: {exc}") from exc


def execute_select(conn, sql: str) -> tuple[list[str], list[tuple[Any, ...]]]:
    cursor = conn.cursor()
    try:
        cursor.execute(sql)
        rows = cursor.fetchall()
        columns = [desc[0] for desc in cursor.description] if cursor.description else []
        return columns, rows
    finally:
        cursor.close()


def explain_cost(conn, sql: str) -> dict[str, Any]:
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(f"EXPLAIN {sql}")
        plan = cursor.fetchall()
        estimated_rows = 0
        for step in plan:
            value = step.get("rows")
            if value is not None:
                try:
                    estimated_rows += int(value)
                except (TypeError, ValueError):
                    pass
        return {"estimated_rows": estimated_rows, "plan": plan}
    finally:
        cursor.close()


def audit_log(conn, question: str, generated_sql: str, rows_returned: int) -> None:
    query = """
        INSERT INTO assistant_query_events
            (pregunta_original, sql_generado, filas_devueltas)
        VALUES
            (%s, %s, %s)
    """
    cursor = conn.cursor()
    try:
        cursor.execute(query, (question, generated_sql, rows_returned))
        conn.commit()
    except Error:
        conn.rollback()
        raise
    finally:
        cursor.close()


def extract_schema_ddl(conn, tables: list[str] | None = None) -> str:
    tables = tables or BUSINESS_TABLES
    cursor = conn.cursor()
    ddl_parts: list[str] = []
    try:
        for table in tables:
            cursor.execute("SHOW TABLES LIKE %s", (table,))
            if not cursor.fetchone():
                continue
            cursor.execute(f"SHOW CREATE TABLE `{table}`")
            row = cursor.fetchone()
            if row and len(row) >= 2:
                ddl_parts.append(row[1] + ";")
        return "\n\n".join(ddl_parts)
    finally:
        cursor.close()
