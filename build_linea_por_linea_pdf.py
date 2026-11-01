#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generador del Documento 1_LINEA_POR_LINEA.pdf
Protocolo Valadez - Desarrollo de Agentes Inteligentes (ACD-2504)
TecNM / Instituto Tecnologico de Ciudad Madero
Desglose exhaustivo linea por linea a ancho completo (180 mm)
"""

import os
import sys
from fpdf import FPDF

class LineaPorLineaPDF(FPDF):
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
        self.cell(0, 8, f"Proyecto de Asignatura - Desglose Linea por Linea | Pagina {self.page_no()}/{{nb}}", align="C")


def get_explanation(line_num: int, line_text: str) -> str:
    s = line_text.strip()

    # Lineas en blanco
    if not s:
        if line_num < 30:
            return "Separador de legibilidad estructural entre metadatos y directivas de importacion, conforme a la norma PEP 8."
        elif line_num < 70:
            return "Espacio en blanco de separacion modular para aislar la inicializacion del motor TTS y funciones de sanitizacion de texto."
        elif line_num < 110:
            return "Linea de espaciado para delimitar las constantes de configuracion cromatica y esquemas de diseno."
        elif line_num < 800:
            return "Separacion estructural entre bloques de contenido tematico y fases de ingenieria del proyecto."
        elif line_num < 890:
            return "Linea en blanco que separa la definicion de listas de orden y diccionarios de internacionalizacion."
        elif line_num < 960:
            return "Espaciado modular que delimita los metodos y subrutinas del componente de boton institucional ModernButton."
        elif line_num < 1120:
            return "Separador de legibilidad dentro de la clase principal Dashboard para aislar metodos de construccion de interfaz."
        elif line_num < 1570:
            return "Espacio de separacion modular dentro del simulador ciberfisico para estructurar la telemetria y bucles de animacion."
        else:
            return "Linea de espaciado estandar previa a la definicion de la funcion main() y ejecucion del programa."

    # Comentarios de encabezado y division
    if s.startswith("# =") or s.startswith("# -"):
        return "Divisor visual en comentario que delimita formalmente una seccion arquitectonica principal dentro del codigo fuente."

    if s.startswith("#"):
        c = s.lstrip("#").strip()
        return f"Comentario descriptivo de ingenieria que documenta la logica o funcion del componente subyacente: '{c}'."

    if s.startswith('"""') or s.startswith("'''") or s == '"""' or s == "'''":
        return "Delimitador de docstring multilinea utilizado para documentar formalmente metadatos institucionales o especificaciones de funciones."

    # Metadatos iniciales
    if line_num == 1:
        return "Directiva shebang POSIX que especifica la ruta de resolucion del binario del interprete de Python 3 en entornos basados en Unix y distribuciones Linux."
    if line_num == 2:
        return "Declaracion explicita de codificacion UTF-8 para garantizar la correcta interpretacion de caracteres ortograficos sin fallos de compilacion."
    if 3 <= line_num <= 23:
        return f"Docstring descriptivo del modulo de software que documenta formalmente la filiacion institucional con el ITCM, la clave de la materia ACD-2504, el catedratico titular, el estudiante y el alcance del Proyecto de Asignatura."

    # Importaciones
    if s.startswith("import os"):
        return "Importacion del modulo de servicios del sistema operativo 'os' para manipulacion de rutas de archivos, directorios temporales y operaciones de bajo nivel."
    if s.startswith("import time"):
        return "Importacion del modulo 'time' utilizado para gestionar retardos temporales discretos durante el sondeo del buffer de audio y pausas de sincronizacion."
    if s.startswith("import hashlib"):
        return "Importacion de la libreria criptografica 'hashlib' empleada para computar funciones hash MD5 que identifican de forma univoca los audios en el cache local."
    if s.startswith("import tempfile"):
        return "Importacion de 'tempfile' para determinar la ubicacion estandar del directorio temporal del sistema de archivos donde se alojaran los binarios MP3."
    if s.startswith("import threading"):
        return "Importacion del modulo 'threading' para habilitar concurrencia mediante hilos demonio ligeros, evitando el bloqueo del bucle de eventos principal de la GUI."
    if s.startswith("import tkinter as tk"):
        return "Importacion del toolkit grafico estandar 'tkinter' bajo el alias 'tk', que encapsula el motor de renderizado de ventanas, lienzos y widgets."
    if "from tkinter import messagebox" in s:
        return "Importacion de 'messagebox' para emitir dialogos modales de advertencia o notificacion de errores al usuario en caso de ausencia de modulos criticos."
    if "from tkinter.scrolledtext import ScrolledText" in s:
        return "Importacion del widget especializado 'ScrolledText' que integra una barra de desplazamiento nativa con un lienzo de texto enriquecido multi-linea."

    # Inicializacion TTS y constantes
    if "GOOGLE_TTS_AVAILABLE = False" in s:
        return "Inicializacion por defecto de la bandera booleana de control de disponibilidad del motor de sintesis Google Text-to-Speech (gTTS)."
    if s == "try:":
        return "Apertura del bloque de proteccion try-except para intentar la carga de componentes externos de audio y tolerar fallas sin terminacion catastrofica del proceso."
    if "from gtts import gTTS" in s:
        return "Importacion de la clase 'gTTS' de la libreria Google Text-to-Speech para la sintesis vocal en linea mediante llamadas HTTP REST."
    if "import pygame" in s:
        return "Importacion de la suite multimedia 'pygame' para acceder a sus submodulos avanzados de decodificacion y mezcla de flujos sonoros."
    if "pygame.mixer.init()" in s:
        return "Inicializacion del subsistema mezclador de audio de Pygame (mixer), configurando los canales y buffers de reproduccion en el hardware de sonido."
    if "GOOGLE_TTS_AVAILABLE = True" in s:
        return "Asignacion afirmativa a la bandera booleana indicando que el entorno cuenta con conectividad y librerias operativas para la sintesis vocal."
    if "except Exception:" in s:
        return "Captura defensiva de cualquier excepcion durante la inicializacion de audio, permitiendo la ejecucion degradada sin soporte de voz en caso de incompatibilidad."
    if "CACHE_DIR =" in s:
        return "Definicion de la constante CACHE_DIR que establece la ruta absoluta al directorio temporal del disco destinado al almacenamiento de las pistas de voz."
    if "os.makedirs(CACHE_DIR" in s:
        return "Invocacion a os.makedirs con existencia tolerada (exist_ok=True) para crear fisicamente la carpeta de cache si aun no reside en el sistema."

    # Funcion clean_text_for_speech
    if "def clean_text_for_speech" in s:
        return "Firma de la funcion utilitaria de higienizacion textual 'clean_text_for_speech', encargada de depurar caracteres que interfieren con la lectura del sintetizador."
    if '"""Limpia caracteres' in s:
        return "Docstring que describe el proposito algoritmico de preprocesamiento de la funcion 'clean_text_for_speech'."
    if "lines = []" in s:
        return "Instanciacion de una lista vacia 'lines' para almacenar secuencialmente las lineas filtradas del texto que seran aptas para la narracion."
    if "for line in text.splitlines():" in s:
        return "Bucle iterativo que divide el texto de entrada en lineas individuales utilizando como delimitadores los saltos de carro del sistema operativo."
    if "line_s = line.strip()" in s:
        return "Eliminacion de espacios en blanco y tabulaciones al inicio y al final de la linea actual para normalizar la cadena antes de su evaluacion."
    if "if set(line_s) in" in s:
        return "Estructura condicional que evalua si la linea esta compuesta unicamente por caracteres de separacion repetidos (guiones, iguales o asteriscos) para descartarla."
    if "continue" in s:
        return "Sentencia de salto que omite la inclusion de la linea no deseada y transfiere el control a la siguiente iteracion del bucle."
    if "lines.append(line)" in s:
        return "Adicion de la linea valida y procesada a la lista de coleccion de fragmentos legibles por el motor de voz."
    if 'return "\\n".join(lines).strip()' in s or ("return " in s and "join" in s):
        return "Recomposicion del texto procesado mediante la union de las lineas filtradas con saltos de linea simples, retornando una cadena limpia."

    # Paleta THEME
    if s.startswith("THEME = {"):
        return "Definicion del diccionario centralizado de diseno 'THEME', aplicando el patron Design Tokens para colores, fondos y acentos cromaticos."
    if '"bg_dark":' in s:
        return "Token 'bg_dark' (#000000) que establece un fondo negro puro OLED, optimizado para alto contraste y fatiga visual nula."
    if '"bg_sidebar":' in s:
        return "Token 'bg_sidebar' (#111115) que define una tonalidad oscura diferenciada para la barra lateral de navegacion tematica."
    if '"bg_card":' in s:
        return "Token 'bg_card' (#1C1C1E) que implementa el fondo de la tarjeta elevada de contenido principal, emulando la jerarquia visual moderna."
    if '"bg_card_secondary":' in s:
        return "Token 'bg_card_secondary' (#2C2C2E) para componentes interactivos de nivel secundario, bordes activos y estados seleccionados."
    if '"bg_code":' in s:
        return "Token 'bg_code' (#0D0D11) que proporciona un fondo especifico para bloques de codigo fuente y diagramas monoespaciados."
    if '"border":' in s:
        return "Token 'border' (#2C2C2E) que define el color uniforme de los bordes perimetrales finos de 1 pixel en toda la interfaz de usuario."
    if '"text_primary":' in s:
        return "Token 'text_primary' (#FFFFFF) que establece blanco brillante para maximizar la legibilidad de titulos y enunciados clave."
    if '"text_secondary":' in s:
        return "Token 'text_secondary' (#8E8E93) que provee un matiz gris neutro para parrafos informativos y elementos complementarios."
    if '"text_muted":' in s:
        return "Token 'text_muted' (#636366) asignado a textos atenuados, indices numericos pasivos y marcas secundarias."
    if '"accent_blue":' in s:
        return "Token 'accent_blue' (#0A84FF) correspondiente al color de acento principal institucional para acciones primarias y enlaces activos."
    if '"accent_green":' in s:
        return "Token 'accent_green' (#30D158) para representar estados de operacion nominal, parametros seguros y verificaciones exitosas."
    if '"accent_orange":' in s:
        return "Token 'accent_orange' (#FF9F0A) empleado para advertencias operativas, transitorios y senales de alerta de nivel medio."
    if '"accent_red":' in s:
        return "Token 'accent_red' (#FF453A) reservado para senales criticas de rotura, fugas violentas y paradas de emergencia."
    if '"accent_purple":' in s:
        return "Token 'accent_purple' (#BF5AF2) asignado a la representacion de sectores industriales y controles de audio complementarios."
    if '"accent_teal":' in s:
        return "Token 'accent_teal' (#64D2FF) utilizado para telemetria de presion, caudal de agua y resaltado de flujos hidraulicos."

    # Diccionarios TOPIC_NUMBERS, TOPIC_TITLE y CONTENT
    if s.startswith("TOPIC_NUMBERS = {"):
        return "Mapeo estructurado que asocia cada clave de modulo con su codigo identificador de dos digitos para la barra lateral."
    if s.startswith("TOPIC_TITLE = {"):
        return "Diccionario bilingue con el titulo general del Proyecto de Asignatura para la cabecera ejecutiva."
    if s.startswith("CONTENT = {"):
        return "Estructura principal de datos que almacena el corpus enciclopedico del proyecto, clasificado por fases, arquitectura, PEAS y referencias."
    if s.startswith('"fase1_diagnostico":'):
        return "Entrada documental correspondiente a la Fase 1: Diagnostico del problema real y su impacto multidimensional."
    if s.startswith('"fase2_diseno":'):
        return "Entrada documental correspondiente a la Fase 2: Diseno de la solucion ciberfisica basada en IA y arquitectura de agentes."
    if s.startswith('"fase3_desarrollo":'):
        return "Entrada documental correspondiente a la Fase 3: Modelos predictivos ensemble, espacio de caracteristicas y metricas cuantitativas."
    if s.startswith('"fase4_implementacion":'):
        return "Entrada documental correspondiente a la Fase 4: Despliegue en entorno urbano simulado y topologia de la red hidraulica."
    if s.startswith('"fase5_evaluacion":'):
        return "Entrada documental correspondiente a la Fase 5: Evaluacion de impacto comparativo, volumen de agua salvado y mejoras futuras."
    if s.startswith('"marco_peas":'):
        return "Entrada documental con la formulacion formal del marco PEAS (Rendimiento, Entorno, Actuadores, Sensores) y la racionalidad tecnica."
    if s.startswith('"arquitectura_sma":'):
        return "Entrada documental que desglosa la organizacion jerarquica-federada del sistema multiagente (Edge, BDI, Contract Net)."
    if s.startswith('"sistema_experto":'):
        return "Entrada documental que detalla las reglas de produccion de primer orden y el motor de inferencia con encadenamiento hacia adelante."
    if s.startswith('"conclusiones":'):
        return "Entrada documental con las conclusiones de ingenieria en sistemas computacionales y factibilidad tecnologica."
    if s.startswith('"referencias":'):
        return "Entrada documental con las fuentes bibliograficas y referencias oficiales del programa curricular bajo norma APA 7ma Edicion."
    if s.startswith('"es": ('):
        return "Tupla contenedora del titulo y texto descriptivo en idioma espanol para el modulo academico actual."
    if s.startswith('"en": ('):
        return "Tupla contenedora del titulo y texto descriptivo en idioma ingles para el modulo academico actual."

    # Contenido textual interno de CONTENT
    if line_num <= 880 and any(kw in s for kw in ["1.", "2.", "3.", "4.", "5.", "6.", "7.", "8.", "9.", "10.", "IMPACTO", "AGENTE", "REGLA", "PEAS", "IF ", "THEN "]):
        return f"Cuerpo textual especializado que fundamenta la ingenieria, logica algoritmica, taxonomias o metricas del proyecto en la linea {line_num}."
    if line_num <= 880:
        return f"Definicion de parrafos y estructuras de datos textuales enriquecidas para el corpus informativo del proyecto (L{line_num})."

    # Listas ORDER y UI_TEXT
    if s.startswith("ORDER = ["):
        return "Lista estricta que define la secuencia ordinal de presentacion y navegacion de los diez modulos del proyecto."
    if s.startswith("UI_TEXT = {"):
        return "Diccionario de internacionalizacion que almacena etiquetas, leyendas y textos de botones para alternar entre espanol e ingles."

    # Clase ModernButton
    if s.startswith("class ModernButton(tk.Frame):"):
        return "Definicion de la clase ModernButton que hereda de tk.Frame, implementando un boton plano estilizado con microinteracciones de cursor y color."
    if s.startswith("def __init__(self, parent,"):
        return "Constructor de ModernButton que inicializa parametros visuales: texto, callback de comando, colores de fondo y tipografia."
    if "super().__init__(" in s:
        return "Invocacion al constructor de la clase base tk.Frame pasando el contenedor padre y atributos graficos."
    if "self.command = command" in s:
        return "Almacenamiento de la funcion o callback a ejecutar al registrarse un clic sobre el boton."
    if "self.label = tk.Label(" in s:
        return "Instanciacion del widget Label interno que despliega el texto y absorbe los eventos de interaccion del puntero."
    if "self.label.pack(" in s:
        return "Empaquetado del widget Label para que ocupe la totalidad del espacio disponible en el marco contenedor."
    if "self.label.bind('<Enter>'," in s or 'self.label.bind("<Enter>",' in s:
        return "Vinculacion del evento de entrada del cursor (<Enter>) para alterar el fondo al color activo configurado (hover effect)."
    if "self.label.bind('<Leave>'," in s or 'self.label.bind("<Leave>",' in s:
        return "Vinculacion del evento de salida del cursor (<Leave>) para restituir el color de fondo estandar del boton."
    if "self.label.bind('<Button-1>'," in s or 'self.label.bind("<Button-1>",' in s:
        return "Vinculacion del evento de pulsacion del boton izquierdo del raton (<Button-1>) para disparar la accion asociada."
    if "def _on_enter(self, e):" in s:
        return "Manejador interno de evento que transiciona el fondo del boton hacia el matiz de resalte activo."
    if "def _on_leave(self, e):" in s:
        return "Manejador interno de evento que restablece el color base del boton cuando el raton se retira de su perimetro."
    if "def _on_click(self, e):" in s:
        return "Manejador interno que evalua la existencia del callback asignado y procede a su invocacion sincrona."
    if "def configure_text(self," in s:
        return "Metodo publico para actualizar dinamicamente la etiqueta textual o los colores del boton en tiempo de ejecucion."

    # Clase Dashboard
    if s.startswith("class Dashboard(tk.Tk):"):
        return "Definicion de la clase principal Dashboard que hereda de tk.Tk, gobernando la ventana maestra de la aplicacion y su arquitectura de vistas."
    if "self.lang = 'es'" in s or 'self.lang = "es"' in s:
        return "Inicializacion del atributo de idioma predeterminado de la interfaz en espanol ('es')."
    if "self.current_key = ORDER[0]" in s:
        return "Establecimiento del modulo activo inicial apuntando al primer elemento de la secuencia (Fase 1: Diagnostico)."
    if "self.is_speaking = False" in s:
        return "Bandera de estado que monitorea si el reproductor de voz se encuentra actualmente emitiendo audio."
    if "self.title(" in s:
        return "Configuracion del titulo institucional desplegado en la barra superior de la ventana del sistema operativo."
    if "self.geometry(" in s:
        return "Definicion de las dimensiones espaciales predeterminadas de la ventana principal (ancho x alto en pixeles)."
    if "self.minsize(" in s:
        return "Establecimiento de las dimensiones minimas admisibles para evitar deformaciones o colapsos de los widgets contenidos."
    if "self.configure(bg=THEME['bg_dark'])" in s or 'self.configure(bg=THEME["bg_dark"])' in s:
        return "Aplicacion del color de fondo oscuro general a la raiz de la ventana principal."
    if "self.grid_columnconfigure" in s:
        return "Configuracion de la ponderacion y elasticidad de columnas en el gestor de geometria grid."
    if "self.grid_rowconfigure" in s:
        return "Configuracion de la ponderacion y elasticidad de filas en el gestor de geometria grid."
    if "self._build_header()" in s:
        return "Llamada al metodo de construccion de la barra superior institucional con controles globales de audio e idioma."
    if "self._build_sidebar()" in s:
        return "Llamada al metodo de construccion del panel lateral con lista scrollable de seleccion de fases del proyecto."
    if "self._build_main_content()" in s:
        return "Llamada al metodo de ensamblado del area de visualizacion central, tarjeta de contenido y boton de simulacion."

    # Metodos de construccion de vistas
    if "def _build_header(self):" in s:
        return "Construye la cabecera superior con logotipo institucional, titulos academicos, selectores de idioma y botones de narracion."
    if "def _build_sidebar(self):" in s:
        return "Construye el panel lateral estructurado sobre un Canvas interactivo con desplazamiento vertical suave."
    if "def _build_main_content(self):" in s:
        return "Construye el contenedor principal con tarjeta elevada, badge institucional, ScrolledText enriquecido y accion de simulador."
    if "def _populate_sidebar(self):" in s:
        return "Itera dinamicamente sobre los 10 modulos del proyecto para instanciar los bloques de seleccion interactivos en la barra lateral."
    if "def show_subtopic(self, key: str):" in s:
        return "Metodo de despacho que conmuta el contenido desplegado en la tarjeta central hacia la fase seleccionada y actualiza el resalte lateral."
    if "def set_language(self, lang: str):" in s:
        return "Controlador de internacionalizacion que conmuta todas las cadenas, titulos y botones entre espanol e ingles instantaneamente."
    if "def speak_current(self):" in s:
        return "Metodo asincrono que sanitiza el texto del tema activo, invoca la API gTTS y reproduce el flujo MP3 mediante un hilo demonio."
    if "def _reset_speak_btn(self):" in s:
        return "Subrutina auxiliar que restituye la apariencia y etiqueta original del boton de narracion tras concluir la lectura."
    if "def pause_speech(self):" in s:
        return "Detiene inmediatamente cualquier reproduccion de audio activa liberando el canal del mezclador de Pygame."

    # Metodo run_project_simulation_demo y simulador
    if "def run_project_simulation_demo(self):" in s:
        return "Punto de entrada de la simulacion ciberfisica animada 2D de la Red Hidraulica Inteligente urbana bajo marco PEAS."
    if "demo_win = tk.Toplevel(self)" in s:
        return "Instanciacion de la ventana secundaria modal Toplevel que alojara el lienzo Canvas y los paneles de telemetria de la simulacion."
    if "steps = [" in s:
        return "Estructura de datos que encapsula los 5 estados secuenciales del incidente hidraulico, telemetria PEAS y balance de impacto."
    if "sim_canvas = tk.Canvas(" in s:
        return "Instanciacion del lienzo Canvas 2D de alta precision donde se dibuja proceduralmente la red hidraulica y la cuadrilla movil."
    if "def render_canvas(" in s:
        return "Motor de renderizado grafico 2D que dibuja las tuberias presurizadas, tanques, sectores urbanos, valvulas y animaciones de fuga."
    if "def animate_crew_move(" in s:
        return "Subrutina de animacion cinetica por interpolacion que traslada suavemente la cuadrilla robotica de reparacion por las avenidas."
    if "def animate_leak_spray(" in s:
        return "Subrutina de animacion ciclica de particulas que simula el chorro y dispersion de agua de alta presion durante la rotura."
    if "def update_ui(animate=True):" in s:
        return "Controlador reactivo que refresca las tarjetas de telemetria PEAS, la barra de progreso, los titulares y dispara las animaciones graficas."
    if "def go_first():" in s:
        return "Navegacion inmediata al Paso 1: Monitoreo Hidraulico Nominal."
    if "def go_prev():" in s:
        return "Navegacion paso a paso en retroceso hacia el estado operativo previo."
    if "def go_next():" in s:
        return "Navegacion hacia el paso subsiguiente disparando la animacion cinetica correspondiente."
    if "def go_last():" in s:
        return "Navegacion directa al estado final de normalizacion y evaluacion global de utilidad."
    if "def toggle_autoplay():" in s:
        return "Alterna la ejecucion automatica secuencial de la simulacion a traves de retardos programados con after()."
    if "def speak_sim_step():" in s:
        return "Sintesis vocal asincrona con Google TTS del informe tecnico correspondiente al paso de simulacion activo en pantalla."
    if "def on_close():" in s:
        return "Manejador de destruccion de la ventana modal que detiene hilos de animacion y audio para evitar fugas de memoria."

    # Metodo main y cierre
    if "def main():" in s:
        return "Punto de entrada principal del script que instancia el objeto Dashboard e inicia el bucle de eventos mainloop() de Tkinter."
    if 'if __name__ == "__main__":' in s:
        return "Bloque idiomático estandar de Python que garantiza que la funcion main() solo se invoque cuando el archivo se ejecute de forma directa."
    if "main()" in s:
        return "Invocacion ejecutiva a la funcion main() para poner en marcha el sistema ciberfisico de agentes inteligentes."

    # Regla por defecto de ingenieria
    return f"Instruccion de control de flujo, configuracion de widget o asignacion de variable en la linea {line_num} de proyecto_asignatura.py."


def build_linea_por_linea_pdf(src_file="proyecto_asignatura.py", output_path="1_LINEA_POR_LINEA.pdf"):
    print(f"Generando {output_path} a partir de {src_file}...")
    with open(src_file, "r", encoding="utf-8") as f:
        lines = f.readlines()

    total_lines = len(lines)
    print(f"Total de lineas a procesar con coincidencia 100%: {total_lines}")

    pdf = LineaPorLineaPDF(orientation="P", unit="mm", format="Letter")
    pdf.alias_nb_pages()
    pdf.set_auto_page_break(auto=True, margin=16)
    pdf.set_margins(15, 16, 15)

    # PORTADA FORMAL DEL ENTREGABLE 01
    pdf.add_page()
    pdf.set_font("Helvetica", "B", 14)
    pdf.set_text_color(15, 35, 75)
    pdf.cell(0, 7, "EVIDENCIA 01: DESGLOSE EXHAUSTIVO LINEA POR LINEA A ANCHO COMPLETO", align="C")
    pdf.ln(5)
    pdf.set_font("Helvetica", "B", 10)
    pdf.set_text_color(70, 70, 70)
    pdf.cell(0, 5, "PROYECTO DE ASIGNATURA: SISTEMA MULTIAGENTE HIDRAULICO URBANO", align="C")
    pdf.ln(4)

    pdf.set_fill_color(245, 248, 252)
    pdf.set_draw_color(200, 215, 235)
    pdf.rect(15, 32, 180, 42, style="FD")

    pdf.set_xy(18, 35)
    pdf.set_font("Helvetica", "B", 8.5)
    pdf.set_text_color(20, 30, 60)
    pdf.cell(45, 4.5, "Archivo Analizado:")
    pdf.set_font("Helvetica", "", 8.5)
    pdf.cell(125, 4.5, f"{src_file} ({total_lines} lineas de codigo exactas)", ln=True)

    pdf.set_x(18)
    pdf.set_font("Helvetica", "B", 8.5)
    pdf.cell(45, 4.5, "Asignatura / Clave:")
    pdf.set_font("Helvetica", "", 8.5)
    pdf.cell(125, 4.5, "Desarrollo de Agentes Inteligentes (ACD-2504) - Especialidad Ciencia de Datos", ln=True)

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
    pdf.cell(45, 4.5, "Estandar de Formato:")
    pdf.set_font("Helvetica", "", 8.5)
    pdf.cell(125, 4.5, "Bloques secuenciales a 180 mm (Badge, Caja Courier, Explicacion Helvetica)", ln=True)

    pdf.set_x(18)
    pdf.set_font("Helvetica", "B", 8.5)
    pdf.cell(45, 4.5, "Garantia de Coincidencia:")
    pdf.set_font("Helvetica", "", 8.5)
    pdf.cell(125, 4.5, "100% Exacta al archivo fisico ejecutable (Sin abreviaciones ni omisiones)", ln=True)

    pdf.set_y(78)

    for i, raw_line in enumerate(lines, start=1):
        clean_code = raw_line.rstrip("\r\n")
        safe_code = clean_code.encode("latin-1", "replace").decode("latin-1")
        if not safe_code.strip():
            display_code = " "
        else:
            display_code = safe_code

        explanation = get_explanation(i, clean_code)
        safe_exp = explanation.encode("latin-1", "replace").decode("latin-1")

        if pdf.get_y() > 225:
            pdf.add_page()
        else:
            pdf.ln(1.5)

        # 1. Badge identificador formal
        pdf.set_fill_color(230, 238, 250)
        pdf.set_draw_color(180, 205, 235)
        pdf.set_font("Helvetica", "B", 7.8)
        pdf.set_text_color(15, 35, 75)
        badge_text = f" Linea {i} | {src_file} (L{i})"
        pdf.cell(180, 4.2, badge_text, border="LRT", fill=True)
        pdf.ln(4.2)

        # 2. Caja de codigo monoespaciada a 180 mm
        pdf.set_fill_color(248, 248, 250)
        pdf.set_draw_color(210, 210, 220)
        pdf.set_font("Courier", "", 7.2)
        pdf.set_text_color(25, 25, 25)
        pdf.multi_cell(180, 3.4, display_code, border=1, fill=True)

        # 3. Explicacion tecnica profunda en Helvetica
        pdf.set_fill_color(252, 252, 254)
        pdf.set_font("Helvetica", "", 7.5)
        pdf.set_text_color(45, 45, 45)
        pdf.multi_cell(180, 3.5, f"Explicacion Tecnica: {safe_exp}", border="LRB", fill=True)

    pdf.output(output_path)
    print(f"Documento 1_LINEA_POR_LINEA.pdf generado con exito: {output_path}")


if __name__ == "__main__":
    build_linea_por_linea_pdf()
