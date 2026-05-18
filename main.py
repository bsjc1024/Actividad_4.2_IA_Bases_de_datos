import os
import google.generativeai as genai
import mysql.connector
from tabulate import tabulate 

API_KEY = "AIzaSyC5fIPtlAMichScM7Vd7lQVnRRL1SF0ZEo"
DB_CONFIG = {
    "host" : "localhost",
    "user" : "root",
    "database" : "ecommerce"
}

SCHEMA_DDL = """
CREATE TABLE clientes (
  id_cliente INT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(100), email VARCHAR(100),
  ciudad VARCHAR(100), fecha_registro DATE
);
CREATE TABLE productos (
  id_producto INT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(100), categoria VARCHAR(50),
  precio DECIMAL(10,2), stock INT, stock_minimo INT
);
CREATE TABLE pedidos (
  id_pedido INT PRIMARY KEY AUTO_INCREMENT,
  id_cliente INT, fecha_pedido DATETIME,
  estado VARCHAR(30), total DECIMAL(10,2)
);
CREATE TABLE detalle_pedido (
  id_detalle INT PRIMARY KEY AUTO_INCREMENT,
  id_pedido INT, id_producto INT,
  cantidad INT, precio_unitario DECIMAL(10,2)
);
"""

SYSTEM_PROMPT = f"""
Eres un experto en SQL para MySQL 8.0. 
Conviertes preguntas en español a consultas SQL válidas.

REGLAS ESTRICTAS:
- Responde ÚNICAMENTE con SQL válido, sin markdown, sin explicaciones, sin comillas triples.
- Solo genera sentencias SELECT.
- Usa solo las tablas del schema proporcionado.

SCHEMA:
{SCHEMA_DDL}

EJEMPLOS:
Pregunta: ¿Cuáles son los 5 productos más vendidos?
SQL: SELECT p.nombre, SUM(dp.cantidad) AS total_vendido FROM productos p JOIN detalle_pedido dp ON p.id_producto = dp.id_producto GROUP BY p.id_producto, p.nombre ORDER BY total_vendido DESC LIMIT 5;

Pregunta: ¿Cuántos clientes se registraron en abril de 2024?
SQL: SELECT COUNT(*) AS clientes_abril FROM clientes WHERE MONTH(fecha_registro) = 4 AND YEAR(fecha_registro) = 2024;

Pregunta: ¿Qué pedidos pendientes superan $5,000?
SQL: SELECT id_pedido, id_cliente, fecha_pedido, total FROM pedidos WHERE estado = 'pendiente' AND total > 5000 ORDER BY total DESC;
"""

def get_connection():
    return mysql.connector.connect(**DB_CONFIG)

def translate(question: str) -> str:
    genai.configure(api_key=API_KEY)
    model = genai.GenerativeModel("gemini-1.5-flash")
    response = model.generate_content(
        f"{SYSTEM_PROMPT}\n\nPregunta: {question}\nSQL:"
    )
    sql = response.text.strip()
    # Limpiar posibles markdown residuales
    sql = sql.replace("```sql", "").replace("```", "").strip()
    return sql

FORBIDDEN = {"DROP","INSERT","UPDATE","DELETE","TRUNCATE","ALTER","CREATE","REPLACE","MERGE"}

def validate_select_only(sql: str) -> str:
    first_word = sql.strip().split()[0].upper()
    if first_word != "SELECT":
        raise ValueError(f"Sentencia no permitida: {first_word}. Solo se permiten SELECT.")
    for word in FORBIDDEN:
        if word in sql.upper():
            raise ValueError(f"Palabra prohibida detectada: {word}")
    return sql

def explain_cost(sql: str, conn) -> dict:
    cursor = conn.cursor(dictionary=True)
    cursor.execute(f"EXPLAIN {sql}")
    rows = cursor.fetchall()
    total_rows = sum(r.get("rows", 0) or 0 for r in rows)
    return {"rows": total_rows, "plan": rows}

def audit_log(pregunta: str, sql: str, num_filas: int, conn):
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO log_trigger (pregunta, sql_generado, filas_devueltas) VALUES (%s, %s, %s)",
        (pregunta, sql, num_filas)
    )
    conn.commit()

def main():
    conn = get_connection()
    print("=== Asistente de Base de Datos ===")
    print("Escribe 'salir' para terminar.\n")

    while True:
        pregunta = input("¿Qué quieres saber sobre el negocio? ").strip()
        if pregunta.lower() == "salir":
            break
        if not pregunta:
            continue

        try:
            # 1. Traducir
            sql = translate(pregunta)
            print(f"\nSQL generado:\n{sql}\n")

            # 2. Validar seguridad
            sql = validate_select_only(sql)

            # 3. EXPLAIN
            cost = explain_cost(sql, conn)
            print(f"Filas estimadas a escanear: {cost['rows']:,}")
            if cost["rows"] > 100_000:
                respuesta = input("⚠️  Advertencia: consulta costosa. ¿Continuar? [s/n]: ")
                if respuesta.lower() != "s":
                    print("Consulta cancelada.\n")
                    continue

            # 4. Ejecutar
            cursor = conn.cursor()
            cursor.execute(sql)
            results = cursor.fetchall()
            columns = [desc[0] for desc in cursor.description]

            # 5. Auditoría
            audit_log(pregunta, sql, len(results), conn)

            # 6. Mostrar resultados
            if results:
                print(tabulate(results, headers=columns, tablefmt="rounded_outline"))
                print(f"\n{len(results)} fila(s) devuelta(s).\n")
            else:
                print("Sin resultados.\n")

        except ValueError as e:
            print(f"{e}\n")
        except Exception as e:
            print(f"Error: {e}\n")

    conn.close()

if __name__ == "__main__":
    main()    