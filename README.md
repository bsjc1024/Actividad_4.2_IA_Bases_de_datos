# Asistente Conversacional de Base de Datos con IA

**Actividad 4.2: IA y Bases de datos**.

Este sistema permite hacer preguntas en español sobre una base de datos de e-commerce. Gemini traduce la pregunta a SQL, el sistema valida que la consulta sea únicamente `SELECT`, ejecuta `EXPLAIN`, corre la consulta en MySQL, muestra los resultados en formato tabular y registra una auditoría mediante un trigger.

---

## Índice

1. [Descripción general](#1-descripción-general)
2. [Arquitectura del sistema](#2-arquitectura-del-sistema)
3. [Estructura del proyecto](#3-estructura-del-proyecto)
4. [Requisitos previos](#4-requisitos-previos)
5. [Instalación](#5-instalación)
6. [Configuración de variables de entorno](#6-configuración-de-variables-de-entorno)
7. [Creación de la base de datos](#7-creación-de-la-base-de-datos)
8. [Verificación inicial de MySQL](#8-verificación-inicial-de-mysql)
9. [Prueba de la API de Gemini](#9-prueba-de-la-api-de-gemini)
10. [Ejecución del asistente](#10-ejecución-del-asistente)
11. [Preguntas de prueba](#11-preguntas-de-prueba)
12. [Pruebas de seguridad](#12-pruebas-de-seguridad)
13. [Auditoría y trigger](#13-auditoría-y-trigger)
14. [Extracción del DDL](#14-extracción-del-ddl)
15. [Checklist de validación final](#15-checklist-de-validación-final)
16. [Solución de errores comunes](#16-solución-de-errores-comunes)
17. [Comandos útiles de MySQL](#17-comandos-útiles-de-mysql)
18. [Repositorio](#18-repositorio)

---

## 1. Descripción general

El objetivo del proyecto es construir un asistente conversacional que permita consultar una base de datos usando lenguaje natural en español, sin que el usuario tenga que escribir SQL directamente.

El sistema recibe una pregunta del usuario, la envía a Gemini junto con el DDL de la base de datos, recibe una consulta SQL candidata, valida que sea segura, ejecuta la consulta en MySQL y registra la operación en una tabla de auditoría.

La regla central del sistema es:

```text
La IA solo puede generar consultas SELECT.
```

El programa sí puede hacer operaciones internas controladas, como insertar registros de auditoría, pero esas operaciones no vienen del modelo de IA.

---

## 2. Arquitectura del sistema

El flujo principal del asistente es:

```text
Pregunta en español
        ↓
Prompt + DDL de la base de datos
        ↓
Gemini genera SQL
        ↓
validate_select_only(sql)
        ↓
EXPLAIN
        ↓
Ejecución en MySQL
        ↓
Resultados en tabla
        ↓
INSERT controlado en assistant_query_events
        ↓
Trigger AFTER INSERT
        ↓
assistant_audit_log
```

Responsabilidades principales:

| Componente | Responsabilidad |
|---|---|
| Gemini | Traduce preguntas en español a SQL. |
| `validate_select_only` | Rechaza cualquier consulta que no sea `SELECT`. |
| MySQL | Ejecuta la consulta validada. |
| `EXPLAIN` | Estima el costo de la consulta antes de ejecutarla. |
| Trigger de auditoría | Registra cada consulta ejecutada por el asistente. |

---

## 3. Estructura del proyecto

```text
.
├── main.py
├── db.py
├── llm_client.py
├── validator.py
├── test_gemini.py
├── schema.sql
├── audit.sql
├── requirements.txt
├── .env.example
├── .gitignore
└── README.md
```

Descripción de archivos:

| Archivo | Descripción |
|---|---|
| `main.py` | Punto de entrada del asistente. Coordina el pipeline completo. |
| `db.py` | Maneja conexión a MySQL, ejecución de consultas, `EXPLAIN`, extracción de DDL y auditoría. |
| `llm_client.py` | Contiene el prompt y la conexión con Gemini para generar SQL. |
| `validator.py` | Valida que el SQL generado sea únicamente `SELECT`. |
| `test_gemini.py` | Prueba mínima para confirmar que la API de Gemini funciona. |
| `schema.sql` | Crea la base de datos de e-commerce y carga datos de ejemplo. |
| `audit.sql` | Crea las tablas de auditoría y el trigger `AFTER INSERT`. |
| `requirements.txt` | Lista las dependencias de Python. |
| `.env.example` | Plantilla de variables de entorno. |
| `.gitignore` | Evita subir archivos sensibles o innecesarios. |

---

## 4. Requisitos previos

Antes de instalar el proyecto, asegúrate de tener:

- Python 3.11 o superior.
- MySQL 8.0 o superior.
- Una API key de Gemini desde Google AI Studio.
- Terminal o consola.
- Git, opcional pero recomendado.
- MySQL Workbench, opcional.

Verificar Python:

```bash
python3 --version
```

Verificar MySQL:

```bash
mysql --version
```

---

## 5. Instalación

### 5.1 Clonar o abrir el proyecto

Si el proyecto está en GitHub:

```bash
git clone https://github.com/bsjc1024/Actividad_4.2_IA_Bases_de_datos.git
cd Actividad_4.2_IA_Bases_de_datos
```

Si ya tienes la carpeta localmente:

```bash
cd Actividad_4.2_IA_Bases_de_datos
```

### 5.2 Crear entorno virtual

En macOS o Linux:

```bash
python3 -m venv venv
source venv/bin/activate
```

En Windows PowerShell:

```powershell
python -m venv venv
venv\Scripts\Activate.ps1
```

Cuando el entorno esté activo, la terminal debe mostrar algo como:

```text
(venv)
```

### 5.3 Instalar dependencias

```bash
pip install -r requirements.txt
```

Si no existe `requirements.txt`, créalo con este contenido:

```txt
google-genai>=1.0.0
mysql-connector-python>=9.0.0
python-dotenv>=1.0.1
tabulate>=0.9.0
```

Luego se debe de instalar:

```bash
pip install -r requirements.txt
```

---

## 6. Configuración de variables de entorno

Copia el archivo de ejemplo:

```bash
cp .env.example .env
```

Edita `.env` con tus datos reales.

### 6.1 Ejemplo si MySQL no tiene contraseña

```env
GEMINI_API_KEY=tu_api_key_real
GEMINI_MODEL=gemini-2.5-flash

DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_NAME=ecommerce_ia

MAX_EXPLAIN_ROWS=100000
```

### 6.2 Ejemplo si MySQL sí tiene contraseña

```env
GEMINI_API_KEY=tu_api_key_real
GEMINI_MODEL=gemini-2.5-flash

DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=tu_password
DB_NAME=ecommerce_ia

MAX_EXPLAIN_ROWS=100000
```

Importante:

```text
Nunca subas el archivo .env a GitHub.
```

### 6.3 Modelo recomendado de Gemini

Modelo recomendado para iniciar:

```env
GEMINI_MODEL=gemini-2.5-flash
```

Si aparece un error de cuota como `429 RESOURCE_EXHAUSTED`, prueba:

```env
GEMINI_MODEL=gemini-2.5-flash-lite
```

---

## 7. Creación de la base de datos

El archivo `schema.sql` crea la base de datos `ecommerce_ia`, las tablas de negocio y datos de ejemplo.

El archivo `audit.sql` crea las tablas de auditoría y el trigger.

### 7.1 Si MySQL no tiene contraseña

```bash
mysql -u root < schema.sql
mysql -u root ecommerce_ia < audit.sql
```

### 7.2 Si MySQL sí tiene contraseña

```bash
mysql -u root -p < schema.sql
mysql -u root -p ecommerce_ia < audit.sql
```

Después de ejecutar estos comandos, la base de datos debe incluir:

Tablas de negocio:

```text
clientes
categorias
productos
pedidos
detalle_pedido
pagos
envios
```

Tablas de auditoría:

```text
assistant_query_events
assistant_audit_log
```

Trigger:

```text
trg_auditar_consulta
```

---

## 8. Verificación inicial de MySQL

Entra a MySQL.

Sin contraseña:

```bash
mysql -u root ecommerce_ia
```

Con contraseña:

```bash
mysql -u root -p ecommerce_ia
```

Verifica las tablas:

```sql
SHOW TABLES;
```

Verifica que existan datos:

```sql
SELECT COUNT(*) AS total_clientes FROM clientes;
SELECT COUNT(*) AS total_productos FROM productos;
SELECT COUNT(*) AS total_pedidos FROM pedidos;
```

Verifica el trigger:

```sql
SHOW TRIGGERS;
```

Debe aparecer:

```text
trg_auditar_consulta
```

---

## 9. Prueba de la API de Gemini

Antes de ejecutar el asistente completo, conviene probar que Gemini funciona.

### 9.1 Crear `test_gemini.py`

Si todavía no existe, crea un archivo llamado `test_gemini.py` en la raíz del proyecto:

```python
# test_gemini.py
"""
Prueba mínima para verificar que la API de Gemini funciona.

Uso:
    python3 test_gemini.py

Si todo está bien, debe imprimir una respuesta corta de Gemini.
"""

import os
from dotenv import load_dotenv
from google import genai


def main():
    load_dotenv()

    api_key = os.getenv("GEMINI_API_KEY")
    model = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")

    if not api_key:
        raise RuntimeError(
            "No se encontró GEMINI_API_KEY. Revisa que exista tu archivo .env."
        )

    print("Probando conexión con Gemini...")
    print(f"Modelo configurado: {model}")

    client = genai.Client(api_key=api_key)

    response = client.models.generate_content(
        model=model,
        contents="Responde únicamente con la palabra OK si recibiste este mensaje."
    )

    print("\nRespuesta de Gemini:")
    print(response.text)


if __name__ == "__main__":
    main()
```

### 9.2 Ejecutar la prueba

```bash
python3 test_gemini.py
```

Salida esperada:

```text
Probando conexión con Gemini...
Modelo configurado: gemini-2.5-flash

Respuesta de Gemini:
OK
```

Si esta prueba funciona, la API key y el modelo están correctamente configurados.

---

## 10. Ejecución del asistente

### 10.1 Modo interactivo

```bash
python3 main.py
```

El programa mostrará preguntas sugeridas y permitirá escribir preguntas en español.

Para salir:

```text
salir
```

### 10.2 Ejecutar una pregunta directa

```bash
python3 main.py --question "¿Cuáles son los 5 clientes con mayor gasto total en los últimos 6 meses?"
```

### 10.3 Ocultar el SQL generado

```bash
python3 main.py --question "¿Cuáles son los productos más vendidos este mes?" --hide-sql
```

### 10.4 Extraer el DDL desde el programa

```bash
python3 main.py --print-ddl
```

Guardar el DDL en un archivo:

```bash
python3 main.py --print-ddl > ddl_extraido.sql
```

---

## 11. Preguntas de prueba

Estas preguntas están alineadas con el reto:

```text
¿Cuáles son los 5 clientes con mayor gasto total en los últimos 6 meses?
¿Cuántos productos tienen stock por debajo del mínimo en este momento?
¿Qué ciudad genera el mayor promedio de gasto por pedido?
Lista los pedidos del último mes que siguen pendientes, de mayor a menor monto.
¿Cuál es la hora del día con mayor número de ventas registradas?
¿Cuáles son los productos más vendidos este mes?
¿Cuántos clientes se registraron en abril?
¿Qué pedidos pendientes superan $5,000?
```

Ejemplo:

```bash
python3 main.py --question "¿Qué ciudad genera el mayor promedio de gasto por pedido?"
```

La salida esperada debe incluir:

```text
SQL generado por Gemini
EXPLAIN: filas estimadas = ...
Resultados:
Auditoría registrada correctamente.
```

---

## 12. Pruebas de seguridad

El sistema debe evitar que la IA modifique la base de datos.

Prueba preguntas peligrosas:

```bash
python3 main.py --question "Borra todos los pedidos cancelados."
```

```bash
python3 main.py --question "Elimina la tabla clientes."
```

```bash
python3 main.py --question "Actualiza todos los productos a precio cero."
```

La respuesta esperada del modelo debería ser algo parecido a:

```sql
SELECT 'OPERACION_NO_PERMITIDA' AS error
```

Además, la función `validate_select_only(sql)` rechaza directamente consultas que no sean `SELECT`.

### 12.1 Probar directamente el validador

Consulta segura:

```bash
python3 -c "from validator import validate_select_only; print(validate_select_only('SELECT nombre FROM clientes LIMIT 5'))"
```

Debe imprimir:

```text
SELECT nombre FROM clientes LIMIT 5
```

Consulta peligrosa:

```bash
python3 -c "from validator import validate_select_only; print(validate_select_only('DROP TABLE clientes'))"
```

Debe fallar con un error de seguridad.

---

## 13. Auditoría y trigger

La auditoría funciona en dos pasos:

1. El programa inserta un evento en `assistant_query_events`.
2. El trigger `trg_auditar_consulta` copia ese evento a `assistant_audit_log`.

Este `INSERT` es controlado por el sistema, no por la IA.

### 13.1 Probar manualmente el trigger

Dentro de MySQL:

```sql
INSERT INTO assistant_query_events
(pregunta_original, sql_generado, filas_devueltas)
VALUES
('prueba manual del trigger', 'SELECT 1 AS prueba', 1);
```

Luego:

```sql
SELECT id_auditoria, id_evento, pregunta_original, sql_generado, filas_devueltas, timestamp_auditoria
FROM assistant_audit_log
ORDER BY id_auditoria DESC
LIMIT 5;
```

Si aparece `prueba manual del trigger`, el trigger funciona.

### 13.2 Verificar auditoría después de usar el asistente

```sql
SELECT id_evento, pregunta_original, filas_devueltas, fecha_evento
FROM assistant_query_events
ORDER BY id_evento DESC
LIMIT 10;
```

```sql
SELECT id_auditoria, id_evento, timestamp_auditoria, filas_devueltas
FROM assistant_audit_log
ORDER BY id_auditoria DESC
LIMIT 10;
```

Si ambas tablas tienen registros, la auditoría está funcionando.

---

## 14. Extracción del DDL

El DDL es el conjunto de sentencias `CREATE TABLE` que describen la estructura de la base de datos.

El asistente usa el DDL para que Gemini conozca las tablas, columnas y relaciones disponibles.

### 14.1 Desde el programa

```bash
python3 main.py --print-ddl
```

Guardar en archivo:

```bash
python3 main.py --print-ddl > ddl_extraido.sql
```

### 14.2 Usando `mysqldump`

Sin contraseña:

```bash
mysqldump -u root --no-data ecommerce_ia > ddl_extraido.sql
```

Con contraseña:

```bash
mysqldump -u root -p --no-data ecommerce_ia > ddl_extraido.sql
```

### 14.3 Desde MySQL Workbench

1. Abre MySQL Workbench.
2. Conéctate a tu servidor.
3. Ve a **Server > Data Export**.
4. Selecciona la base `ecommerce_ia`.
5. Elige **Dump Structure Only**.
6. Exporta el archivo `.sql`.

---

## 15. Checklist de validación final

El proyecto funciona correctamente si puedes demostrar lo siguiente:

```text
1. schema.sql crea la base ecommerce_ia sin errores.
2. audit.sql crea las tablas de auditoría y el trigger.
3. SHOW TABLES muestra tablas de negocio y auditoría.
4. SHOW TRIGGERS muestra trg_auditar_consulta.
5. python3 test_gemini.py responde OK.
6. python3 main.py --print-ddl imprime el DDL.
7. Gemini genera SQL para preguntas en español.
8. validate_select_only permite únicamente SELECT.
9. EXPLAIN se ejecuta antes de la consulta.
10. Los resultados se muestran en tabla.
11. assistant_query_events recibe el evento.
12. assistant_audit_log se llena mediante trigger.
13. Preguntas peligrosas no modifican la base de datos.
```

---

## 16. Solución de errores comunes

### 16.1 `Access denied for user`

Revisa `DB_USER` y `DB_PASSWORD` en `.env`.

Si tu MySQL no tiene contraseña:

```env
DB_PASSWORD=
```

Usa comandos sin `-p`:

```bash
mysql -u root ecommerce_ia
```

Si sí tiene contraseña, usa `-p`:

```bash
mysql -u root -p ecommerce_ia
```

---

### 16.2 `Unknown database ecommerce_ia`

La base no existe todavía.

Ejecuta:

```bash
mysql -u root < schema.sql
mysql -u root ecommerce_ia < audit.sql
```

Si usas contraseña:

```bash
mysql -u root -p < schema.sql
mysql -u root -p ecommerce_ia < audit.sql
```

---

### 16.3 `No module named google`

Faltan dependencias.

Ejecuta:

```bash
pip install -r requirements.txt
```

---

### 16.4 `No module named dotenv`

Instala `python-dotenv`:

```bash
pip install python-dotenv
```

O instala todo otra vez:

```bash
pip install -r requirements.txt
```

---

### 16.5 `429 RESOURCE_EXHAUSTED`

Tu proyecto de Gemini no tiene cuota para ese modelo.

Soluciones posibles:

1. Cambiar modelo en `.env`:

```env
GEMINI_MODEL=gemini-2.5-flash-lite
```

2. Crear una nueva API key desde Google AI Studio.
3. Revisar la cuota del proyecto.
4. Esperar a que se reinicie la cuota.

Después prueba:

```bash
python3 test_gemini.py
```

---

### 16.6 `GEMINI_API_KEY` no encontrada

Revisa que:

1. El archivo `.env` exista.
2. Se llame exactamente `.env`, no `.env.txt`.
3. Esté en la misma carpeta que `main.py`.
4. Contenga una línea como:

```env
GEMINI_API_KEY=tu_api_key_real
```

---

### 16.7 El modelo inventa columnas

Extrae el DDL real:

```bash
python3 main.py --print-ddl > ddl_extraido.sql
```

Revisa que las tablas y columnas del prompt coincidan con tu base real.

También puedes revisar una tabla específica:

```sql
DESCRIBE pedidos;
```

---

### 16.8 La auditoría no se llena

Primero revisa si existe el trigger:

```sql
SHOW TRIGGERS;
```

Luego prueba manualmente:

```sql
INSERT INTO assistant_query_events
(pregunta_original, sql_generado, filas_devueltas)
VALUES
('prueba manual del trigger', 'SELECT 1 AS prueba', 1);
```

Y revisa:

```sql
SELECT *
FROM assistant_audit_log
ORDER BY id_auditoria DESC
LIMIT 5;
```

Si no aparece nada, vuelve a ejecutar:

```bash
mysql -u root ecommerce_ia < audit.sql
```

Con contraseña:

```bash
mysql -u root -p ecommerce_ia < audit.sql
```

---

## 17. Comandos útiles de MySQL

Ver tablas:

```sql
SHOW TABLES;
```

Ver estructura de una tabla:

```sql
DESCRIBE pedidos;
```

Ver DDL de una tabla:

```sql
SHOW CREATE TABLE pedidos;
```

Ver últimos pedidos:

```sql
SELECT id_pedido, id_cliente, fecha_pedido, estado, total
FROM pedidos
ORDER BY fecha_pedido DESC
LIMIT 10;
```

Ver productos con stock bajo:

```sql
SELECT id_producto, nombre, stock_actual, stock_minimo
FROM productos
WHERE stock_actual < stock_minimo;
```

Ver pedidos pendientes mayores a 5000:

```sql
SELECT id_pedido, id_cliente, fecha_pedido, estado, total
FROM pedidos
WHERE estado = 'pendiente'
  AND total > 5000
ORDER BY total DESC;
```

Ver auditoría reciente:

```sql
SELECT id_auditoria, id_evento, timestamp_auditoria, filas_devueltas
FROM assistant_audit_log
ORDER BY id_auditoria DESC
LIMIT 10;
```

---

## 18. Repositorio

https://github.com/bsjc1024/Actividad_4.2_IA_Bases_de_datos
