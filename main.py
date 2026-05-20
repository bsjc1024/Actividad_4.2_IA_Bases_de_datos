"""
main.py

Asistente conversacional Text-to-SQL para una base de datos de e-commerce.
"""

from __future__ import annotations

import argparse
import os

from dotenv import load_dotenv
from tabulate import tabulate

from db import audit_log, execute_select, explain_cost, extract_schema_ddl, get_connection
from llm_client import GeminiSQLClient
from validator import SQLValidationError, validate_select_only

load_dotenv()

SAMPLE_QUESTIONS = [
    "¿Cuáles son los 5 clientes con mayor gasto total en los últimos 6 meses?",
    "¿Cuántos productos tienen stock por debajo del mínimo en este momento?",
    "¿Qué ciudad genera el mayor promedio de gasto por pedido?",
    "Lista los pedidos del último mes que siguen pendientes, de mayor a menor monto.",
    "¿Cuál es la hora del día con mayor número de ventas registradas?",
    "¿Cuáles son los productos más vendidos este mes?",
    "¿Cuántos clientes se registraron en abril?",
    "¿Qué pedidos pendientes superan $5,000?",
]


def should_continue_after_explain(estimated_rows: int) -> bool:
    max_rows = int(os.getenv("MAX_EXPLAIN_ROWS", "100000"))
    if estimated_rows <= max_rows:
        return True
    print(f"\nAdvertencia: la consulta podría escanear aproximadamente {estimated_rows:,} filas.")
    answer = input("¿Deseas continuar? [s/n]: ").strip().lower()
    return answer in {"s", "si", "sí", "y", "yes"}


def run_question(question: str, show_sql: bool = True) -> None:
    conn = get_connection()
    try:
        schema_ddl = extract_schema_ddl(conn)
        if not schema_ddl:
            raise RuntimeError("No se pudo extraer el DDL. ¿Ya ejecutaste schema.sql?")

        llm = GeminiSQLClient()
        generated_sql = llm.translate_to_sql(question, schema_ddl)

        if show_sql:
            print("\nSQL generado por Gemini:")
            print(generated_sql)

        safe_sql = validate_select_only(generated_sql)
        cost = explain_cost(conn, safe_sql)
        estimated_rows = cost["estimated_rows"]
        print(f"\nEXPLAIN: filas estimadas = {estimated_rows:,}")

        if not should_continue_after_explain(estimated_rows):
            print("Consulta cancelada por el usuario.")
            return

        columns, rows = execute_select(conn, safe_sql)
        print("\nResultados:")
        if rows:
            print(tabulate(rows, headers=columns, tablefmt="fancy_grid"))
        else:
            print("(Sin resultados)")

        audit_log(conn=conn, question=question, generated_sql=safe_sql, rows_returned=len(rows))
        print("\nAuditoría registrada correctamente.")

    except SQLValidationError as exc:
        print(f"\nConsulta rechazada por seguridad: {exc}")
    finally:
        conn.close()


def interactive_loop() -> None:
    print("\nAsistente Text-to-SQL para e-commerce")
    print("Escribe una pregunta en español o 'salir' para terminar.\n")
    print("Preguntas de ejemplo:")
    for index, question in enumerate(SAMPLE_QUESTIONS, start=1):
        print(f"{index}. {question}")
    print()
    while True:
        question = input("¿Qué quieres saber sobre el negocio? ").strip()
        if question.lower() in {"salir", "exit", "quit"}:
            print("Listo. Sesión terminada.")
            break
        if question:
            run_question(question)


def print_live_ddl() -> None:
    conn = get_connection()
    try:
        print(extract_schema_ddl(conn))
    finally:
        conn.close()


def main() -> None:
    parser = argparse.ArgumentParser(description="Asistente conversacional Text-to-SQL con Gemini y MySQL.")
    parser.add_argument("-q", "--question", type=str, help="Pregunta en español para ejecutar una sola vez.")
    parser.add_argument("--print-ddl", action="store_true", help="Extrae e imprime el DDL real desde MySQL.")
    parser.add_argument("--hide-sql", action="store_true", help="No mostrar el SQL generado antes de ejecutar.")
    args = parser.parse_args()

    if args.print_ddl:
        print_live_ddl()
        return
    if args.question:
        run_question(args.question, show_sql=not args.hide_sql)
        return
    interactive_loop()


if __name__ == "__main__":
    main()
