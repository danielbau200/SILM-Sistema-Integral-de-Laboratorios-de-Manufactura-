#!/usr/bin/env bash
# Script para iniciar el servidor local de PostgreSQL para SILM
DATA_DIR="/home/daniel/.postgres_data"
BIN_DIR="/home/daniel/.local/opt/postgresql16/usr/lib/postgresql/16/bin"

if [ ! -d "$DATA_DIR" ]; then
    echo "[!] Error: No se encontró el directorio de datos en $DATA_DIR"
    exit 1
fi

echo "[*] Iniciando servidor PostgreSQL 16 para SILM..."
"$BIN_DIR/pg_ctl" -D "$DATA_DIR" -l "$DATA_DIR/server.log" start

if pg_isready -h 127.0.0.1 -p 5432; then
    echo "[✓] PostgreSQL 16 está ACTIVO y escuchando en 127.0.0.1:5432"
    echo "[✓] Base de datos lista: silm_db"
else
    echo "[✗] Hubo un problema al arrancar el servidor. Revisa $DATA_DIR/server.log"
fi
