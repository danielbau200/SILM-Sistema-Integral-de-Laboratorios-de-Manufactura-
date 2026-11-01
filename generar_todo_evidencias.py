#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script Maestro de Generacion de Entregables - Protocolo Valadez
Tecnologico Nacional de Mexico - Instituto Tecnologico de Ciudad Madero
Materia: Desarrollo de Agentes Inteligentes (DAI) · Clave: ACD-2504
Catedra: Profesor Federico Alonso Valadez
Estudiante: Bautista Elias Daniel de Jesus
Grupo: 850P B | Horario: 15:00 - 16:00

Genera el paquete oficial de 5 entregables (02 al 06):
0_PROYECTO_ASIGNATURA.txt
1_LINEA_POR_LINEA.pdf
2_POR_SEGMENTOS.pdf
3_RESUMEN_DEL_PROGRAMA.pdf
4_CAPTURAS_DE_PANTALLA.pdf
"""

import os
import shutil
import subprocess

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
EVIDENCIAS_DIR = os.path.join(BASE_DIR, "evidencias")
os.makedirs(EVIDENCIAS_DIR, exist_ok=True)

TARGET_DAI_DIR = "/home/daniel/Documentos/DESARROLLO DE AGENTES INTELIGENTES/PROYECTO_DE_ASIGNATURA"
TARGET_DAI_EVIDENCIAS = os.path.join(TARGET_DAI_DIR, "evidencias")
os.makedirs(TARGET_DAI_EVIDENCIAS, exist_ok=True)


def step_0_copy_txt():
    print("==================================================================")
    print("[1/5] Generando 0_PROYECTO_ASIGNATURA.txt (Coincidencia 100%)...")
    src = os.path.join(BASE_DIR, "proyecto_asignatura.py")
    dst = os.path.join(EVIDENCIAS_DIR, "0_PROYECTO_ASIGNATURA.txt")
    shutil.copyfile(src, dst)
    print(f"      Entregable 0 generado en: {dst} ({os.path.getsize(dst)} bytes)")


def step_1_capturar_pantallas():
    print("==================================================================")
    print("[2/5] Ejecutando subrutina automatica de captura de pantalla...")
    cmd = ["python3", os.path.join(BASE_DIR, "capturar_pantallas_auto.py")]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode == 0:
        print("      Capturas completadas exitosamente.")
    else:
        print("      Advertencia en subrutina de captura:", res.stderr)


def step_2_build_linea_por_linea():
    print("==================================================================")
    print("[3/5] Generando 1_LINEA_POR_LINEA.pdf (Bloques a 180 mm)...")
    import build_linea_por_linea_pdf
    out_pdf = os.path.join(EVIDENCIAS_DIR, "1_LINEA_POR_LINEA.pdf")
    build_linea_por_linea_pdf.build_linea_por_linea_pdf(
        src_file=os.path.join(BASE_DIR, "proyecto_asignatura.py"),
        output_path=out_pdf
    )
    print(f"      Entregable 1 generado en: {out_pdf} ({os.path.getsize(out_pdf)} bytes)")


def step_3_build_segmentos():
    print("==================================================================")
    print("[4/5] Generando 2_POR_SEGMENTOS.pdf (Desglose Modular)...")
    import build_segmentos_pdf
    out_pdf = os.path.join(EVIDENCIAS_DIR, "2_POR_SEGMENTOS.pdf")
    build_segmentos_pdf.build_segmentos_pdf(output_path=out_pdf)
    print(f"      Entregable 2 generado en: {out_pdf} ({os.path.getsize(out_pdf)} bytes)")


def step_4_build_resumen():
    print("==================================================================")
    print("[5/5] Generando 3_RESUMEN_DEL_PROGRAMA.pdf (Estricto 2 paginas)...")
    import build_resumen_pdf
    out_pdf = os.path.join(EVIDENCIAS_DIR, "3_RESUMEN_DEL_PROGRAMA.pdf")
    build_resumen_pdf.build_resumen_pdf(output_path=out_pdf)
    print(f"      Entregable 3 generado en: {out_pdf} ({os.path.getsize(out_pdf)} bytes)")


def step_5_build_capturas():
    print("==================================================================")
    print("[6/6] Generando 4_CAPTURAS_DE_PANTALLA.pdf (15 capturas HD)...")
    import build_capturas_pdf
    out_pdf = os.path.join(EVIDENCIAS_DIR, "4_CAPTURAS_DE_PANTALLA.pdf")
    build_capturas_pdf.build_capturas_pdf(output_path=out_pdf)
    print(f"      Entregable 4 generado en: {out_pdf} ({os.path.getsize(out_pdf)} bytes)")


def step_6_replicate_to_dai_folder():
    print("==================================================================")
    print("Replicando entregables a carpeta de la asignatura:")
    print(f"Destino: {TARGET_DAI_DIR}")

    files_to_copy = [
        "proyecto_asignatura.py",
        "capturar_pantallas_auto.py",
        "build_linea_por_linea_pdf.py",
        "build_segmentos_pdf.py",
        "build_resumen_pdf.py",
        "build_capturas_pdf.py",
        "generar_todo_evidencias.py",
    ]

    for f in files_to_copy:
        src = os.path.join(BASE_DIR, f)
        if os.path.exists(src):
            shutil.copy2(src, os.path.join(TARGET_DAI_DIR, f))

    # Replicar evidencias
    for ev in os.listdir(EVIDENCIAS_DIR):
        src_ev = os.path.join(EVIDENCIAS_DIR, ev)
        dst_ev = os.path.join(TARGET_DAI_EVIDENCIAS, ev)
        shutil.copy2(src_ev, dst_ev)
        print(f"  -> Copiado a evidencias DAI: {ev}")

    print("Replicacion completada con exito.")


def main():
    print("INICIANDO PROCESO MAESTRO PROTOCOLO VALADEZ...")
    step_0_copy_txt()
    step_1_capturar_pantallas()
    step_2_build_linea_por_linea()
    step_3_build_segmentos()
    step_4_build_resumen()
    step_5_build_capturas()
    step_6_replicate_to_dai_folder()
    print("==================================================================")
    print("TODOS LOS ENTREGABLES DEL PROTOCOLO VALADEZ HAN SIDO GENERADOS.")
    print("==================================================================")


if __name__ == "__main__":
    main()
