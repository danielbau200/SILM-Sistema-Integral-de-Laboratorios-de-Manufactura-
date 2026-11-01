#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generador del Documento 2_POR_SEGMENTOS.pdf
Protocolo Valadez - Desarrollo de Agentes Inteligentes (ACD-2504)
TecNM / Instituto Tecnologico de Ciudad Madero
Analisis Arquitectonico Modular por Componentes
"""

from fpdf import FPDF

class SegmentosPDF(FPDF):
    def header(self):
        self.set_font("Helvetica", "B", 8)
        self.set_text_color(90, 90, 90)
        self.cell(0, 4, "TECNOLOGICO NACIONAL DE MEXICO | INSTITUTO TECNOLOGICO DE CIUDAD MADERO", align="C")
        self.ln(4)
        self.set_font("Helvetica", "", 7)
        self.cell(0, 3, "DEPARTAMENTO DE SISTEMAS Y COMPUTACION | DESARROLLO DE AGENTES INTELIGENTES (ACD-2504)", align="C")
        self.ln(3)
        self.set_draw_color(180, 195, 215)
        self.line(15, 15, 195, 15)
        self.ln(2)

    def footer(self):
        self.set_y(-12)
        self.set_font("Helvetica", "", 8)
        self.set_text_color(110, 110, 110)
        self.cell(0, 8, f"Proyecto de Asignatura - Analisis Arquitectonico Modular | Pagina {self.page_no()}/{{nb}}", align="C")


def build_segmentos_pdf(output_path="2_POR_SEGMENTOS.pdf"):
    print(f"Generando {output_path}...")
    pdf = SegmentosPDF(orientation="P", unit="mm", format="Letter")
    pdf.alias_nb_pages()
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.set_margins(15, 16, 15)

    # PORTADA / INTRODUCCION FORMAL
    pdf.add_page()
    pdf.set_font("Helvetica", "B", 14)
    pdf.set_text_color(15, 35, 75)
    pdf.cell(0, 7, "EVIDENCIA 02: ANALISIS ARQUITECTONICO MODULAR POR COMPONENTES", align="C")
    pdf.ln(5)
    pdf.set_font("Helvetica", "B", 10)
    pdf.set_text_color(70, 70, 70)
    pdf.cell(0, 5, "DESGLOSE DE MODULOS FUNCIONALES - PROYECTO DE ASIGNATURA DAI", align="C")
    pdf.ln(4)

    pdf.set_fill_color(245, 248, 252)
    pdf.set_draw_color(200, 215, 235)
    pdf.rect(15, 32, 180, 38, style="FD")

    pdf.set_xy(18, 35)
    pdf.set_font("Helvetica", "B", 8.5)
    pdf.set_text_color(20, 30, 60)
    pdf.cell(45, 4.5, "Asignatura / Clave:")
    pdf.set_font("Helvetica", "", 8.5)
    pdf.cell(125, 4.5, "Desarrollo de Agentes Inteligentes (ACD-2504) - Especialidad Ciencia de Datos", ln=True)

    pdf.set_x(18)
    pdf.set_font("Helvetica", "B", 8.5)
    pdf.cell(45, 4.5, "Proyecto Evaluado:")
    pdf.set_font("Helvetica", "", 8.5)
    pdf.cell(125, 4.5, "Sistema Ciberfisico Multiagente y Sistema Experto para Red Hidraulica Urbana", ln=True)

    pdf.set_x(18)
    pdf.set_font("Helvetica", "B", 8.5)
    pdf.cell(45, 4.5, "Catedratico Titular:")
    pdf.set_font("Helvetica", "", 8.5)
    pdf.cell(125, 4.5, "Profesor Federico Alonso Valadez - Grupo 850P B | 15:00 - 16:00", ln=True)

    pdf.set_x(18)
    pdf.set_font("Helvetica", "B", 8.5)
    pdf.cell(45, 4.5, "Estudiante:")
    pdf.set_font("Helvetica", "", 8.5)
    pdf.cell(125, 4.5, "Bautista Elias Daniel de Jesus", ln=True)

    pdf.set_x(18)
    pdf.set_font("Helvetica", "B", 8.5)
    pdf.cell(45, 4.5, "Estructura Modular:")
    pdf.set_font("Helvetica", "", 8.5)
    pdf.cell(125, 4.5, "12 Segmentos Arquitectonicos con Cobertura Integral del Codigo Fuente", ln=True)

    pdf.set_y(74)

    segmentos = [
        ("SEGMENTO 01: METADATOS INSTITUCIONALES Y DIRECTIVAS DE ENTORNO",
         "Lineas 1 a 24 de proyecto_asignatura.py",
         """#!/usr/bin/env python3
# -*- coding: utf-8 -*-
\"\"\"
TECNOLOGICO NACIONAL DE MEXICO / ITCM
MATERIA: DESARROLLO DE AGENTES INTELIGENTES (ACD-2504)
PROFESOR: FEDERICO ALONSO VALADEZ
ESTUDIANTE: BAUTISTA ELIAS DANIEL DE JESUS
PROYECTO DE ASIGNATURA: RED HIDRAULICA MULTIAGENTE
\"\"\"""",
         "ANALISIS TECNICO: El segmento establece la directiva shebang POSIX para resolucion dinamica del interprete de Python 3 y fija la codificacion UTF-8 estricta. Documenta la filiacion institucional con el ITCM, el catedratico titular y la delimitacion del proyecto bajo los lineamientos del Protocolo Valadez."),

        ("SEGMENTO 02: IMPORTACION DE LIBRERIAS Y SUBSISTEMA DE AUDIO GTTS",
         "Lineas 25 a 68 de proyecto_asignatura.py",
         """import os, time, hashlib, tempfile, threading
import tkinter as tk
from tkinter import messagebox
from tkinter.scrolledtext import ScrolledText

GOOGLE_TTS_AVAILABLE = False
try:
    from gtts import gTTS
    import pygame
    pygame.mixer.init()
    GOOGLE_TTS_AVAILABLE = True
except Exception:
    GOOGLE_TTS_AVAILABLE = False

CACHE_DIR = os.path.join(tempfile.gettempdir(), "proyecto_dai_gtts_cache")
os.makedirs(CACHE_DIR, exist_ok=True)""",
         "ANALISIS TECNICO: Gestion de dependencias operativas y soporte de audio multiplataforma. Implementa un bloque try-except tolerante a fallas para inicializar Google TTS (gTTS) y el motor de audio de Pygame Mixer. Configura una ruta en el almacenamiento temporal del sistema para cachear las pistas sintetizadas con hashes MD5, garantizando reproduccion instantanea sin re-descargas."),

        ("SEGMENTO 03: TOKENIZACION CROMATICA Y DISENO VISUAL THEME",
         "Lineas 69 a 93 de proyecto_asignatura.py",
         """THEME = {
    "bg_dark": "#000000",
    "bg_sidebar": "#111115",
    "bg_card": "#1C1C1E",
    "bg_card_secondary": "#2C2C2E",
    "bg_code": "#0D0D11",
    "border": "#2C2C2E",
    "text_primary": "#FFFFFF",
    "text_secondary": "#8E8E93",
    "text_muted": "#636366",
    "accent_blue": "#0A84FF",
    "accent_green": "#30D158",
    "accent_orange": "#FF9F0A",
    "accent_red": "#FF453A",
    "accent_purple": "#BF5AF2",
    "accent_teal": "#64D2FF",
}""",
         "ANALISIS TECNICO: Implementacion del patron Design Tokens. Centraliza la paleta visual de alto contraste inspirada en la estetica Dark OLED (#000000) y componentes elevados (#1C1C1E). Elimina ad-hoc styling y asegura uniformidad milimetrica en bordes (#2C2C2E), acentos operativos (Azul Apple, Verde Nominal, Rojo Rotura) y cumplimiento total de cero emojis."),

        ("SEGMENTO 04: CORPUS DOCUMENTAL Y FASES 1 A 5 DEL PROYECTO",
         "Lineas 94 a 580 de proyecto_asignatura.py",
         """CONTENT = {
    "fase1_diagnostico": {
        "es": ("1. Fase de Diagnostico: Problema Real e Impacto...", "..."),
        "en": ("1. Diagnostic Phase: Real-World Problem...", "..."),
    },
    "fase2_diseno": {...},
    "fase3_desarrollo": {...},
    "fase4_implementacion": {...},
    "fase5_evaluacion": {...},
}""",
         "ANALISIS TECNICO: Modelo de dominio del conocimiento. Estructura el desglose exhaustivo de las cinco fases formativas del proyecto de asignatura (Diagnostico, Diseno, Desarrollo, Implementacion y Evaluacion) con redaccion tecnica de ingenieria, justificacion de impacto social, economico y ambiental, metricas de exactitud del 98.7% y soporte bilingue simetrico."),

        ("SEGMENTO 05: ESPECIFICACION PEAS, ARQUITECTURA MULTIAGENTE Y SISTEMA EXPERTO",
         "Lineas 581 a 885 de proyecto_asignatura.py",
         """    "marco_peas": {
        "es": ("6. Especificacion Formal del Marco PEAS...", "..."),
    },
    "arquitectura_sma": {
        "es": ("7. Arquitectura Multiagente y Coordinacion...", "..."),
    },
    "sistema_experto": {
        "es": ("8. Base de Conocimiento y Reglas...", "..."),
    },
    "conclusiones": {...},
    "referencias": {...},""",
         "ANALISIS TECNICO: Formalizacion metodologica de agentes inteligentes. Modela la cuadrupla PEAS (Rendimiento, Entorno, Actuadores, Sensores) para el sistema hidraulico, detalla la topologia hibrida jerarquica-federada (Edge, Deliberativo BDI, Contract Net) y codifica las 5 reglas de produccion clave en logica de primer orden con encadenamiento hacia adelante."),

        ("SEGMENTO 06: COMPONENTE INSTITUCIONAL MODERNBUTTON",
         "Lineas 886 a 955 de proyecto_asignatura.py",
         """class ModernButton(tk.Frame):
    def __init__(self, parent, text="", command=None, bg="#0A84FF", fg="white",
                 active_bg="#0066CC", font=("SF Pro Text", 10, "bold"),
                 padx=14, pady=8, cursor="hand2", **kwargs):
        super().__init__(parent, bg=parent["bg"], **kwargs)
        self.command = command
        self.bg_color = bg
        self.active_bg = active_bg
        self.label = tk.Label(...)
        self.label.bind("<Enter>", self._on_enter)
        self.label.bind("<Leave>", self._on_leave)
        self.label.bind("<Button-1>", self._on_click)""",
         "ANALISIS TECNICO: Diseno de componente interactivo desacoplado. Encapsula widgets tk.Label dentro de un marco contenedor para superar las limitaciones de apariencia nativas de Tkinter en Linux y macOS. Implementa microinteracciones de entrada (<Enter>) y salida (<Leave>) con transicion suave de fondo, gestionando el cursor hand2 y el despacho seguro de eventos."),

        ("SEGMENTO 07: INICIALIZACION Y CONSTRUCCION DE LA CABECERA (HEADER)",
         "Lineas 956 a 1055 de proyecto_asignatura.py",
         """class Dashboard(tk.Tk):
    def __init__(self):
        super().__init__()
        self.lang = "es"
        self.current_key = ORDER[0]
        self.title("ITCM DAI ACD-2504 - Proyecto de Asignatura...")
        self.geometry("1180x760")
        self._build_header()
        self._build_sidebar()
        self._build_main_content()""",
         "ANALISIS TECNICO: Controlador principal de la aplicacion de escritorio. Inicializa la ventana raiz bajo patron Modelo-Vista-Controlador (MVC). En la cabecera, ensambla la placa de identificacion institucional [DAI-PROYECTO], los botones de sintesis vocal (Narrar/Detener) y el interruptor segmentado para conmutacion instantanea de idioma."),

        ("SEGMENTO 08: PANEL LATERAL DE NAVEGACION Y AREA CENTRAL SCROLLEDTEXT",
         "Lineas 1056 a 1180 de proyecto_asignatura.py",
         """    def _build_sidebar(self):
        # Canvas con autodesplazamiento vertical para items tematicos
        self.sidebar_canvas = tk.Canvas(...)
        self.sidebar_frame = tk.Frame(...)
    def _build_main_content(self):
        # Tarjeta principal elevada, badge institucional y ScrolledText
        self.text = ScrolledText(..., wrap="word", bg=THEME["bg_card"], ...)
        self.text.tag_configure("title", ...)
        self.text.tag_configure("body", ...)""",
         "ANALISIS TECNICO: Construccion de la vista jerarquica. El panel lateral implementa un Canvas con evento <Configure> para sincronizar el scrollregion dinamico segun la resolucion. El area central aloja una tarjeta con efecto de elevacion perimetral y un componente ScrolledText provisto de etiquetas semanticas para renderizado de texto."),

        ("SEGMENTO 09: DESPACHO REACTIVO, INTERNACIONALIZACION Y AUDIO GTTS",
         "Lineas 1181 a 1285 de proyecto_asignatura.py",
         """    def show_subtopic(self, key: str):
        # Conmutacion visual, actualizacion de resaltes y formateo
    def set_language(self, lang: str):
        # Conmutacion bilingue global
    def speak_current(self):
        # Despacho en hilo demonio de la sintesis de voz con gTTS
        self.speak_thread = threading.Thread(target=_run, daemon=True)
        self.speak_thread.start()""",
         "ANALISIS TECNICO: Gestion de reactividad y concurrencia multihilo. El metodo speak_current delega la peticion a la API REST de Google y la lectura de Pygame a un subproceso demonio, garantizando que el bucle de eventos principal (Main Loop) de Tkinter mantenga una respuesta de 60 FPS sin congelamientos de la interfaz grafica."),

        ("SEGMENTO 10: SIMULADOR 2D EN CANVAS - RED HIDRAULICA Y MODELO PEAS",
         "Lineas 1286 a 1450 de proyecto_asignatura.py",
         """def run_project_simulation_demo(self):
    demo_win = tk.Toplevel(self)
    steps = [
        {"title_es": "Paso 1: Monitoreo Nominal...", "pressure": "4.2 Bar", ...},
        {"title_es": "Paso 2: Rotura Catastrofica...", "pressure": "1.8 Bar", ...},
        {"title_es": "Paso 3: Aislamiento Seccional BDI...", ...},
        {"title_es": "Paso 4: Despacho y Reparacion Cuadrilla...", ...},
        {"title_es": "Paso 5: Reapertura y Normalizacion...", ...},
    ]""",
         "ANALISIS TECNICO: Motor de simulacion ciberfisica animada. Define los 5 estados hidraulicos discretos que modelan el ciclo Percepcion-Razonamiento-Accion. Enlaza variables cuantitativas de presion, caudal, reglas del sistema experto disparadas, volumen de agua salvado y la funcion de utilidad global esperada."),

        ("SEGMENTO 11: RENDERIZADO GRAFICO PROCEDURAL Y ANIMACION CINETICA EN CANVAS",
         "Lineas 1451 a 1545 de proyecto_asignatura.py",
         """def render_canvas(current_rx, current_ry, spray=False, phase=0):
    # Dibuja: Tanque Matriz, Bomba, Sectores A, B, C, D
    # Tuberias presurizadas, Valvulas PRV-1/2/3, Chorro de Fuga
    # Cuadrilla Robotica con coordenadas cinematicas (rx, ry)
def animate_crew_move(start_x, start_y, end_x, end_y, on_finished):
    # Interpolacion lineal por cuadros para navegacion cinematica""",
         "ANALISIS TECNICO: Renderizado vectorial en tiempo real sobre Tkinter Canvas. Emplea primitivas de dibujo (create_rectangle, create_line, create_polygon, create_oval) para proyectar la topologia de la red hidraulica metropolitana, el flujo de agua presurizado, la animacion estocastica del chorro de fuga y el desplazamiento cinetico continuo del vehiculo de reparacion."),

        ("SEGMENTO 12: PANEL DE TELEMETRIA PEAS, NAVEGACION PASO A PASO Y MAIN()",
         "Lineas 1546 a 1589 de proyecto_asignatura.py",
         """# 4 Tarjetas HUD: Presion, Caudal, Regla Experta, Estado Agente
# Controles: [<<], [< Anterior], [Auto], [Audio], [Siguiente >], [>>]
def main():
    app = Dashboard()
    app.mainloop()

if __name__ == "__main__":
    main()""",
         "ANALISIS TECNICO: Telemetria industrial y orquestacion final. Construye el HUD con 4 tarjetas de medicion en tiempo real y la barra de controles con reproduccion automatica sincronizada (after) y narracion vocal independiente. La funcion main() instancia la arquitectura y transfiere el control al bucle de eventos del sistema operativo."),
    ]

    for titulo, rango, codigo, analisis in segmentos:
        if pdf.get_y() > 210:
            pdf.add_page()
        else:
            pdf.ln(3)

        pdf.set_fill_color(230, 238, 250)
        pdf.set_draw_color(180, 205, 235)
        pdf.set_font("Helvetica", "B", 9)
        pdf.set_text_color(15, 35, 75)
        pdf.cell(180, 5, f" {titulo}", border="LRT", fill=True)
        pdf.ln(5)

        pdf.set_fill_color(240, 245, 252)
        pdf.set_font("Helvetica", "I", 7.5)
        pdf.set_text_color(80, 90, 110)
        pdf.cell(180, 4, f" {rango}", border="LRB", fill=True)
        pdf.ln(4.5)

        # Caja de codigo monoespaciada
        pdf.set_fill_color(248, 248, 250)
        pdf.set_draw_color(210, 210, 220)
        pdf.set_font("Courier", "", 7.2)
        pdf.set_text_color(20, 20, 20)
        pdf.multi_cell(180, 3.4, codigo, border=1, fill=True)
        pdf.ln(1.5)

        # Analisis tecnico de ingenieria
        pdf.set_fill_color(252, 252, 254)
        pdf.set_font("Helvetica", "", 7.8)
        pdf.set_text_color(40, 40, 40)
        pdf.multi_cell(180, 3.7, analisis, border="LRB", fill=True)
        pdf.ln(2)

    pdf.output(output_path)
    print(f"Documento 2_POR_SEGMENTOS.pdf generado exitosamente: {output_path}")


if __name__ == "__main__":
    build_segmentos_pdf()
