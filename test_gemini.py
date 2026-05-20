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