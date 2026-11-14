#!/usr/bin/env bash
# Script para verificar el estado de PostgreSQL para SILM
DATA_DIR="/home/daniel/.postgres_data"
BIN_DIR="/home/daniel/.local/opt/postgresql16/usr/lib/postgresql/16/bin"

"$BIN_DIR/pg_ctl" -D "$DATA_DIR" status
pg_isready -h 127.0.0.1 -p 5432
