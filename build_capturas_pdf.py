#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generador del Documento 4_CAPTURAS_DE_PANTALLA.pdf
Protocolo Valadez - Desarrollo de Agentes Inteligentes (ACD-2504)
TecNM / Instituto Tecnologico de Ciudad Madero
Memoria Grafica de Pantallas y Estados de Interfaz
"""

import os
from fpdf import FPDF

class CapturasPDF(FPDF):
    def header(self):
        self.set_font("Helvetica", "B", 8)
        self.set_text_color(100, 100, 100)
        self.cell(0, 5, "TECNOLOGICO NACIONAL DE MEXICO | INSTITUTO TECNOLOGICO DE CIUDAD MADERO", ln=True, align="C")
        self.set_font("Helvetica", "", 7)
        self.cell(0, 4, "DEPARTAMENTO DE SISTEMAS Y COMPUTACION | MATERIA: DESARROLLO DE AGENTES INTELIGENTES (ACD-2504)", ln=True, align="C")
        self.set_draw_color(200, 200, 200)
        self.line(15, 18, 195, 18)
        self.ln(3)

    def footer(self):
        self.set_y(-14)
        self.set_font("Helvetica", "", 8)
        self.set_text_color(120, 120, 120)
        self.cell(0, 8, f"Proyecto de Asignatura - Memoria Grafica de Pantallas | Pagina {self.page_no()}/{{nb}}", align="C")


def build_capturas_pdf(output_path="4_CAPTURAS_DE_PANTALLA.pdf"):
    print(f"Generando {output_path}...")
    pdf = CapturasPDF(orientation="P", unit="mm", format="Letter")
    pdf.alias_nb_pages()
    pdf.set_auto_page_break(auto=True, margin=16)

    # PORTADA / FICHA DE REGISTRO FORMAL
    pdf.add_page()
    pdf.set_font("Helvetica", "B", 14)
    pdf.set_text_color(10, 40, 90)
    pdf.cell(0, 8, "EVIDENCIA 04: MEMORIA GRAFICA DE PANTALLAS Y ESTADOS DE INTERFAZ", ln=True, align="C")
    pdf.set_font("Helvetica", "B", 10)
    pdf.set_text_color(60, 60, 60)
    pdf.cell(0, 5, "PROYECTO DE ASIGNATURA: SISTEMA MULTIAGENTE HIDRAULICO URBANO", ln=True, align="C")
    pdf.ln(3)

    pdf.set_fill_color(245, 247, 250)
    pdf.set_draw_color(210, 220, 235)
    pdf.rect(15, 34, 180, 46, style="FD")

    pdf.set_xy(18, 37)
    pdf.set_font("Helvetica", "B", 8.5)
    pdf.set_text_color(20, 30, 60)
    pdf.cell(42, 4.5, "Asignatura:")
    pdf.set_font("Helvetica", "", 8.5)
    pdf.cell(128, 4.5, "Desarrollo de Agentes Inteligentes (ACD-2504) - Especialidad Ciencia de Datos", ln=True)

    pdf.set_x(18)
    pdf.set_font("Helvetica", "B", 8.5)
    pdf.cell(42, 4.5, "Proyecto Evaluado:")
    pdf.set_font("Helvetica", "", 8.5)
    pdf.cell(128, 4.5, "Sistema Ciberfisico Multiagente y Sistema Experto para Red Hidraulica Urbana", ln=True)

    pdf.set_x(18)
    pdf.set_font("Helvetica", "B", 8.5)
    pdf.cell(42, 4.5, "Catedratico Titular:")
    pdf.set_font("Helvetica", "", 8.5)
    pdf.cell(128, 4.5, "Profesor Federico Alonso Valadez - Grupo 850P B | 15:00 - 16:00", ln=True)

    pdf.set_x(18)
    pdf.set_font("Helvetica", "B", 8.5)
    pdf.cell(42, 4.5, "Estudiante:")
    pdf.set_font("Helvetica", "", 8.5)
    pdf.cell(128, 4.5, "Bautista Elias Daniel de Jesus", ln=True)

    pdf.set_x(18)
    pdf.set_font("Helvetica", "B", 8.5)
    pdf.cell(42, 4.5, "Entorno de Ejecucion:")
    pdf.set_font("Helvetica", "", 8.5)
    pdf.cell(128, 4.5, "Python 3.12 / Tkinter / Pygame Mixer / gTTS API / Linux Desktop (X11)", ln=True)

    pdf.set_x(18)
    pdf.set_font("Helvetica", "B", 8.5)
    pdf.cell(42, 4.5, "Estandar Grafico:")
    pdf.set_font("Helvetica", "", 8.5)
    pdf.cell(128, 4.5, "Dark Theme OLED (#000000, #111115, #1C1C1E, #0A84FF), Cero Emojis", ln=True)

    pdf.set_x(18)
    pdf.set_font("Helvetica", "B", 8.5)
    pdf.cell(42, 4.5, "Total de Capturas:")
    pdf.set_font("Helvetica", "", 8.5)
    pdf.cell(128, 4.5, "15 Estados Integrales (10 Modulos Tematicos + 5 Pasos del Simulador Ciberfisico)", ln=True)

    pdf.set_y(84)

    items = [
        ("screenshots_temp/tema_01_fase1_diagnostico.png",
         "ESTADO 01: FASE 1 - DIAGNOSTICO DEL PROBLEMA REAL E IMPACTO MULTIDIMENSIONAL",
         "Paleta: Fondo Negro (#000000), Barra Lateral (#111115), Tarjeta (#1C1C1E), Acento (#0A84FF)",
         "Visualizacion de la fundamentacion del problema de Agua No Contabilizada (ANC), desabasto urbano, perdidas de mas de 8,500 millones de pesos y evaluacion de impacto social, economico y ambiental. El panel lateral resalta el elemento 01."),

        ("screenshots_temp/tema_02_fase2_diseno.png",
         "ESTADO 02: FASE 2 - DISENO DE LA SOLUCION CIBERFISICA BASADA EN INTELIGENCIA ARTIFICIAL",
         "Paleta: Fondo OLED (#000000), Bordes (#2C2C2E), Texto Principal (#FFFFFF), Acento (#0A84FF)",
         "Despliegue del diseno de la solucion multiagente descentralizada: agentes sensores IoT reactivos, agentes deliberativos BDI en valvulas PRV, agente sistema experto de diagnostico y cuadrilla robotica movil con protocolo Contract Net."),

        ("screenshots_temp/tema_03_fase3_desarrollo.png",
         "ESTADO 03: FASE 3 - DESARROLLO, ENTRENAMIENTO DE MODELOS Y METRICAS DE RENDIMIENTO",
         "Paleta: Fondo Elevado (#1C1C1E), Texto Secundario (#8E8E93), Titular (#0A84FF), Acento Cyan (#64D2FF)",
         "Exposicion del pipeline de clasificacion supervisada Random Forest y Gradient Boosting. Espacio de caracteristicas hidroacusticas y metricas obtenidas: Exactitud de 98.7%, Recall de 99.1% y F1-Score de 98.6%."),

        ("screenshots_temp/tema_04_fase4_implementacion.png",
         "ESTADO 04: FASE 4 - IMPLEMENTACION Y DESPLIEGUE EN ENTORNO URBANO SIMULADO",
         "Paleta: Superficie Oscura (#000000), Borde (#2C2C2E), Insignia Tematica (#1C2B3A)",
         "Descripcion del despliegue en el simulador de 4 macro-sectores (Hospitalario, Industrial, Residencial, Comercial), el tanque matriz de 50,000 m3, valvulas motorizadas inteligentes y el protocolo de actuacion ante roturas."),

        ("screenshots_temp/tema_05_fase5_evaluacion.png",
         "ESTADO 05: FASE 5 - EVALUACION CUANTITATIVA DE IMPACTO Y MEJORAS FUTURAS",
         "Paleta: Fondo Primario (#000000), Superficie Activa (#2C2C2E), Texto Resaltado (#30D158)",
         "Analisis comparativo del tiempo de aislamiento (de 38.5 horas a 2.3 minutos, reduccion del 99.9%), 94.8% de agua salvada, proteccion del sector hospitalario y propuesta de Gemelos Digitales (CFD) y Redes Neuronales Graficas (GNN)."),

        ("screenshots_temp/tema_06_marco_peas.png",
         "ESTADO 06: ESPECIFICACION FORMAL DEL MARCO PEAS Y CRITERIO DE RACIONALIDAD",
         "Paleta: Fondo Lateral (#111115), Tarjeta Central (#1C1C1E), Acento Azul (#0A84FF)",
         "Desglose metodologico PEAS: Medida de Rendimiento (P), Entorno (E), Actuadores (A) y Sensores (S), formalizando el principio de racionalidad tecnica de Russell y Norvig en redes hidraulicas de alta criticidad."),

        ("screenshots_temp/tema_07_arquitectura_sma.png",
         "ESTADO 07: ARQUITECTURA MULTIAGENTE Y COORDINACION DISTRIBUIDA (SMA)",
         "Paleta: Fondo OLED (#000000), Tarjeta Agrupada (#1C1C1E), Acento Purpura (#BF5AF2)",
         "Detalle de la arquitectura hibrida jerarquica-federada de Jacques Ferber: Capa reactiva de borde a 50 Hz, capa deliberativa BDI para modulacion de valvulas y negociacion distribuida Contract Net Protocol (CNP)."),

        ("screenshots_temp/tema_08_sistema_experto.png",
         "ESTADO 08: BASE DE CONOCIMIENTO Y MOTOR DE REGLAS DEL SISTEMA EXPERTO",
         "Paleta: Fondo (#000000), Borde (#2C2C2E), Codigo (#0D0D11), Acento (#0A84FF)",
         "Especificacion de las 5 reglas de produccion clave en logica de primer orden (IF-THEN) con encadenamiento hacia adelante: deteccion de rotura, aislamiento sectorial, bypass hospitalario, mitigacion de golpe de ariete y despacho."),

        ("screenshots_temp/tema_09_conclusiones.png",
         "ESTADO 09: CONCLUSIONES DE INGENIERIA EN SISTEMAS Y BALANCE TECNICO",
         "Paleta: Superficie Tarjeta (#1C1C1E), Texto Principal (#FFFFFF), Acento Verde (#30D158)",
         "Sintesis ejecutiva de ingenieria: superioridad del paradigma multiagente, resiliencia ciberfisica (self-healing), factibilidad de despliegue en microcontroladores embebidos y cumplimiento de los estandares institucionales."),

        ("screenshots_temp/tema_10_referencias.png",
         "ESTADO 10: FUENTES DOCUMENTALES Y REFERENCIAS OFICIALES (NORMA APA 7MA EDICION)",
         "Paleta: Fondo Primario (#000000), Borde Fino (#2C2C2E), Texto Tipografico (#E5E5EA)",
         "Compilacion bibliografica oficial del programa curricular ACD-2504 en formato APA 7ma Edicion: Ferber, Russell & Norvig, Wooldridge, Railsback, Wilensky, Witten y Han."),

        ("screenshots_temp/sim_paso_1.png",
         "ESTADO 11: SIMULADOR PASO 1 - MONITOREO HIDRAULICO NOMINAL DE LA RED",
         "Paleta Simulador: Fondo (#07070A), Tuberias (#0A84FF), Tanque (#0A5A9E), HUD (#1C1C1E)",
         "Representacion visual 2D de la red urbana presurizada: Tanque Matriz con nivel al 95%, Bomba activa, 4 Sectores operando a 4.2 Bar y 180 L/s. Utilidad maxima de 100 puntos y cero fugas."),

        ("screenshots_temp/sim_paso_2.png",
         "ESTADO 12: SIMULADOR PASO 2 - ROTURA CATASTROFICA EN TUBERIA MATRIZ Y DETECCION IA",
         "Paleta Simulador: Tuberias Alerta (#FF453A), Fuga (#64D2FF), Telemetria (#FF9F0A)",
         "Generacion de rotura critica en el Sector C Residencial. Caida violenta a 1.8 Bar y fuga de 85 L/s. El sensor piezoelectrico reporta la falla y el modelo Random Forest clasifica el incidente con 98.7% de certeza."),

        ("screenshots_temp/sim_paso_3.png",
         "ESTADO 13: SIMULADOR PASO 3 - AISLAMIENTO BDI Y BYPASS HOSPITALARIO DE EMERGENCIA",
         "Paleta Simulador: Valvulas Cerradas (#FF453A), Bypass Activo (#30D158), Tuberias (#FF9F0A)",
         "Accion coordinada de los agentes BDI cerrando las valvulas PRV-2 y PRV-3 al 100%. Activacion simultanea del bypass de emergencia hacia el Hospital Universitario (Sector A), garantizando flujo continuo."),

        ("screenshots_temp/sim_paso_4.png",
         "ESTADO 14: SIMULADOR PASO 4 - DESPACHO Y ARRIBO DE LA CUADRILLA ROBOTICA MOVIL",
         "Paleta Simulador: Chasis Cuadrilla (#FF9F0A), Ruta Cinematica A*, Sello (#30D158)",
         "Desplazamiento cinetico de la cuadrilla robotica por las avenidas de la red hacia el punto exacto de la falla. Arribo, accionamiento de mordazas hidraulicas y ejecucion del sellado estructural de la tuberia."),

        ("screenshots_temp/sim_paso_5.png",
         "ESTADO 15: SIMULADOR PASO 5 - REAPERTURA EN CURVA-S, NORMALIZACION Y BALANCE PEAS",
         "Paleta Simulador: Tuberias Normalizadas (#30D158), Valvulas Abiertas (#30D158)",
         "Reapertura gradual con desaceleracion suave en curva-S para evitar golpe de ariete. Restablecimiento de presion a 4.1 Bar en toda la red. Balance final: 12,500 L de agua salvados y $45,000 MXN en costos prevenidos."),
    ]

    for img_path, titulo_estado, paleta, descripcion in items:
        pdf.add_page()

        pdf.set_fill_color(230, 238, 250)
        pdf.set_draw_color(180, 205, 235)
        pdf.set_font("Helvetica", "B", 9)
        pdf.set_text_color(15, 35, 75)
        pdf.cell(180, 5, f" {titulo_estado}", border="LRT", fill=True)
        pdf.ln(5)

        pdf.set_fill_color(240, 245, 252)
        pdf.set_font("Helvetica", "I", 7.5)
        pdf.set_text_color(80, 90, 110)
        pdf.cell(180, 4, f" {paleta}", border="LRB", fill=True)
        pdf.ln(5)

        # Incrustacion de la imagen capturada
        if os.path.exists(img_path):
            pdf.image(img_path, x=15, y=pdf.get_y(), w=180)
            pdf.ln(118)
        else:
            pdf.cell(180, 40, f"[Imagen no disponible: {img_path}]", border=1, align="C")
            pdf.ln(45)

        # Cuadro descriptivo de ingenieria
        pdf.set_fill_color(248, 250, 252)
        pdf.set_draw_color(210, 220, 235)
        pdf.set_font("Helvetica", "", 7.8)
        pdf.set_text_color(35, 35, 35)
        pdf.multi_cell(180, 3.8, f"Analisis Tecnico de la Interfaz: {descripcion}", border=1, fill=True)

    pdf.output(output_path)
    print(f"Documento 4_CAPTURAS_DE_PANTALLA.pdf generado exitosamente: {output_path} (15 capturas en alta resolucion)")


if __name__ == "__main__":
    build_capturas_pdf()
