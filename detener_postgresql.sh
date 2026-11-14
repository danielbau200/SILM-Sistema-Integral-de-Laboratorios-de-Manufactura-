#!/usr/bin/env bash
# Script para detener el servidor local de PostgreSQL para SILM
DATA_DIR="/home/daniel/.postgres_data"
BIN_DIR="/home/daniel/.local/opt/postgresql16/usr/lib/postgresql/16/bin"

echo "[*] Deteniendo servidor PostgreSQL 16..."
"$BIN_DIR/pg_ctl" -D "$DATA_DIR" stop -m fast
echo "[✓] PostgreSQL detenido."

