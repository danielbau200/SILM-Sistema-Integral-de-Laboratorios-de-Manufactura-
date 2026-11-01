#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Subrutina de Captura Automatizada de Pantallas
Protocolo Valadez - Proyecto de Asignatura DAI (ACD-2504)
Captura programaticamente todos los estados de la interfaz y simulador
"""

import os
import sys
import time
import tkinter as tk
from PIL import ImageGrab

# Importar aplicacion principal
import proyecto_asignatura as app_module

OUTPUT_DIR = "screenshots_temp"
os.makedirs(OUTPUT_DIR, exist_ok=True)


def capture_widget(widget, filepath):
    widget.update_idletasks()
    widget.update()
    time.sleep(0.15)
    x = widget.winfo_rootx()
    y = widget.winfo_rooty()
    w = widget.winfo_width()
    h = widget.winfo_height()
    bbox = (x, y, x + w, y + h)
    img = ImageGrab.grab(bbox=bbox)
    img.save(filepath)
    print(f"Captura guardada: {filepath} ({w}x{h})")


def main():
    print("Iniciando captura automatizada de estados...")
    app = app_module.Dashboard()
    app.update_idletasks()
    app.update()

    # 1. Capturar los 10 temas del dashboard principal
    for idx, key in enumerate(app_module.ORDER, start=1):
        app.show_subtopic(key)
        app.update_idletasks()
        app.update()
        time.sleep(0.1)
        filename = f"tema_{idx:02d}_{key}.png"
        path = os.path.join(OUTPUT_DIR, filename)
        capture_widget(app, path)

    # 2. Abrir simulador y capturar los 5 pasos
    app.run_project_simulation_demo()
    app.update_idletasks()
    app.update()
    time.sleep(0.3)

    # Localizar ventana Toplevel
    demo_win = None
    for child in app.winfo_children():
        if isinstance(child, tk.Toplevel):
            demo_win = child
            break

    if demo_win:
        demo_win.update_idletasks()
        demo_win.update()

        # Encontrar los widgets y funciones de control en demo_win
        # Localizamos la funcion asociada buscando variables en el entorno
        # Pero podemos navegar usando los botones
        # O disparar eventos directos sobre los botones de navegacion
        # Los botones ModernButton tienen command
        # Localicemos los ModernButton en demo_win
        modern_buttons = []
        def find_buttons(w):
            if isinstance(w, app_module.ModernButton):
                modern_buttons.append(w)
            for c in w.winfo_children():
                find_buttons(c)

        find_buttons(demo_win)

        # Los botones son: [<<], [< Anterior], [Auto], [Audio], [Siguiente >], [>>]
        btn_first = None
        btn_next = None
        for b in modern_buttons:
            t = b.label.cget("text")
            if "[<<]" in t:
                btn_first = b
            elif "[Siguiente" in t or "[Next" in t:
                btn_next = b

        if btn_first:
            btn_first.command()
            demo_win.update_idletasks()
            demo_win.update()

        for step in range(1, 6):
            time.sleep(0.2)
            demo_win.update_idletasks()
            demo_win.update()
            path = os.path.join(OUTPUT_DIR, f"sim_paso_{step}.png")
            capture_widget(demo_win, path)
            if step < 5 and btn_next:
                btn_next.command()

        demo_win.destroy()

    app.destroy()
    print("Todas las capturas se han generado exitosamente en:", OUTPUT_DIR)


if __name__ == "__main__":
    main()
