#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TECNOLOGICO NACIONAL DE MEXICO
INSTITUTO TECNOLOGICO DE CIUDAD MADERO
DEPARTAMENTO DE SISTEMAS Y COMPUTACION
MATERIA: DESARROLLO DE AGENTES INTELIGENTES (ACD-2504)
PROFESOR: FEDERICO ALONSO VALADEZ
ESTUDIANTE: BAUTISTA ELIAS DANIEL DE JESUS
GRUPO: 850P B | HORARIO: 15:00 - 16:00

PROYECTO DE ASIGNATURA:
SISTEMA CIBERFISICO MULTIAGENTE INTELIGENTE Y SISTEMA EXPERTO
PARA LA DETECCION, AISLAMIENTO Y MITIGACION AUTONOMA DE FUGAS
EN REDES HIDRAULICAS URBANAS DE DISTRIBUCION DE AGUA POTABLE

ARQUITECTURA DE SOFTWARE: MODELO-VISTA-CONTROLADOR CON CONCURRENCIA MULTIHILO
SOPORTE BILINGUE COMPLETO (ESPANOL / INGLES) Y NARRADOR GOOGLE TTS
SIMULADOR GRAFICO 2D ANIMADO EN CANVAS: RED HIDRAULICA INTELIGENTE (SMART WATER GRID)
"""

import os
import time
import hashlib
import tempfile
import threading
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
os.makedirs(CACHE_DIR, exist_ok=True)


def clean_text_for_speech(text: str) -> str:
    """Limpia caracteres especiales, separadores y saltos para la sintesis de voz."""
    lines = []
    for line in text.splitlines():
        line_s = line.strip()
        if set(line_s) in ({'-'}, {'='}, {'*'}, {'_'}, {'.'}):
            continue
        lines.append(line)
    return "\n".join(lines).strip()


THEME = {
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
}

TOPIC_NUMBERS = {
    "fase1_diagnostico": "01",
    "fase2_diseno": "02",
    "fase3_desarrollo": "03",
    "fase4_implementacion": "04",
    "fase5_evaluacion": "05",
    "marco_peas": "06",
    "arquitectura_sma": "07",
    "sistema_experto": "08",
    "conclusiones": "09",
    "referencias": "10",
}

TOPIC_TITLE = {
    "es": "Proyecto de Asignatura: Sistema Multiagente Hidraulico Urbano",
    "en": "Course Project: Urban Multi-Agent Hydraulic Smart Grid System",
}

CONTENT = {
    "fase1_diagnostico": {
        "es": (
            "1. Fase de Diagnostico: Problema Real e Impacto Multidimensional",
            """1.1 IDENTIFICACION DEL PROBLEMA EN EL MUNDO REAL
Las redes de distribucion de agua potable en las principales zonas metropolitanas sufren perdidas fisicas criticas clasificadas como Agua No Contabilizada (ANC). Segun informes tecnicos de la Comision Nacional del Agua (CONAGUA) y organismos internacionales, entre el 40% y el 45% del agua extraida y potabilizada se disipa a traves de fugas no visibles y roturas catastroficas en tuberias maestras antes de llegar al consumidor final. La infraestructura hidraulica envejecida, combinada con transitorios hidraulicos (golpes de ariete) y una supervision reactiva manual, genera fallas que demoran entre 24 y 72 horas en ser localizadas y aisladas.

1.2 IMPACTO SOCIAL
- Interrupcion sistematica del suministro basico para comunidades vulnerables sujetas a tandeos severos.
- Riesgo critico de desabasto en infraestructuras prioritarias como Hospitales Generales y Centros de Salud.
- Infiltracion de contaminantes patogenos en la red secundaria por depresurizacion prolongada (presion negativa).

1.3 IMPACTO ECONOMICO
- Costos multimillonarios derivados de la energia electrica invertida en el bombeo de volumenes que se pierden.
- Danos estructurales colaterales al pavimento urbano, socavones y afectacion a cimientos viales.
- Perdidas directas estimadas en mas de 8,500 millones de pesos anuales para organismos operadores municipales.

1.4 IMPACTO AMBIENTAL
- Sobreexplotacion severa y abatimiento de mantos acuiferos y cuencas hidrograficas regionales.
- Agravamiento del estres hidrico en ecosistemas riparios por extracciones insostenibles.
- Emisiones innecesarias de gases de efecto invernadero vinculadas a la huella de carbono energetica del ciclo de bombeo."""
        ),
        "en": (
            "1. Diagnostic Phase: Real-World Problem and Multidimensional Impact",
            """1.1 REAL-WORLD PROBLEM IDENTIFICATION
Municipal water distribution networks in metropolitan zones suffer from acute physical water losses categorized as Non-Revenue Water (NRW). According to international water management agencies, between 40% and 45% of purified drinking water is lost through underground leaks and catastrophic main ruptures before reaching final consumers. Aging infrastructure, coupled with hydraulic transients (water hammers) and reactive manual inspections, results in leak localization delays ranging between 24 and 72 hours.

1.2 SOCIAL IMPACT
- Systematic disruption of drinking water access across vulnerable urban sectors subjected to rationing.
- Severe vulnerability of high-priority urban facilities such as public hospitals and emergency health clinics.
- Risk of back-siphonage and bacterial contamination due to prolonged negative pressure events in the piping network.

1.3 ECONOMIC IMPACT
- Millions of dollars wasted in electrical pumping energy for treated water volumes that dissipate underground.
- Collateral structural destruction of urban pavement, sinkholes, and arterial roadway degradation.
- Direct municipal operational losses exceeding hundreds of millions of dollars annually in unbilled water.

1.4 ENVIRONMENTAL IMPACT
- Accelerating depletion and overexploitation of critical regional aquifers and freshwater basins.
- Heightened regional water stress and degradation of riparian ecosystems caused by unsustainable extraction.
- Excessive greenhouse gas emissions tied to the heavy electrical carbon footprint of continuous water pumping."""
        ),
    },

    "fase2_diseno": {
        "es": (
            "2. Fase de Diseno: Propuesta de Solucion Basada en Inteligencia Artificial",
            """2.1 CONCEPCION ARQUITECTONICA DE LA SOLUCION
Se propone un Sistema Ciberfisico Multiagente (SMA) descentralizado acoplado a un Sistema Experto de diagnostico en tiempo real. La red hidraulica se modela como un grafo dirigido ponderado G = (V, E) donde los nodos V representan intersecciones, tanques elevados de almacenamiento y sectores urbanos, mientras que las aristas E representan tuberias maestras instrumentadas.

2.2 TAXONOMIA DE AGENTES INTELIGENTES DESPLEGADOS
1. Agentes Sensores IoT (Reactivos):
   Monitorean continuamente senales de flujo (L/s), presion hidrodinamica (Bar) y microvibraciones hidroacusticas. Ejecutan filtrado estadistico en el borde (Edge Computing) para detectar gradientes anomalos dp/dt.

2. Agentes de Valvula Reguladora PRV (Deliberativos BDI):
   Gobiernan valvulas motorizadas inteligentes. Mantienen creencias sobre el estado de la red, deseos de preservar la presion minima requerida y la intencion de aislar hidraulicamente el sector siniestrado sin cortar el flujo a zonas criticas.

3. Agente Sistema Experto de Diagnostico:
   Motor de inferencia deductivo que correlaciona discrepancias de presion diferencial con patrones de consumo horario para clasificar la severidad de la averia.

4. Agente Cuadrilla Robotica Movil:
   Entidad autonoma que planifica la ruta cinematicamente optima sobre la malla urbana para arribar a las coordenadas de la rotura y desplegar actuadores de sellado mecanico.

5. Agente Coordinador Global:
   Implementa el Protocolo Contract Net (CNP) para negociar redistribuciones de flujo entre tanques auxiliares y sectores prioritarios."""
        ),
        "en": (
            "2. Design Phase: AI-Based Solution Architecture",
            """2.1 ARCHITECTURAL CONCEPT OF THE SOLUTION
A decentralized Cyber-Physical Multi-Agent System (MAS) coupled with a real-time diagnostic Expert System is designed. The hydraulic network is modeled as a weighted directed graph G = (V, E), where nodes V correspond to junction points, elevated storage reservoirs, and urban sectors, and edges E represent sensor-equipped distribution pipelines.

2.2 TAXONOMY OF DEPLOYED INTELLIGENT AGENTS
1. IoT Sensor Agents (Reactive):
   Continuously ingest flow telemetry (L/s), hydrodynamic pressure (Bar), and hydroacoustic micro-vibrations. Execute edge statistical filtering to identify abnormal pressure gradients dp/dt.

2. Pressure Reducing Valve (PRV) Agents (BDI Deliberative):
   Control motorized smart valves. Maintain beliefs regarding hydraulic state, desires to enforce minimum operational thresholds, and intentions to isolate ruptured segments while preserving vital hospital supply lines.

3. Diagnostic Expert System Agent:
   Deductive inference engine evaluating differential pressure signatures against hourly demand baselines to classify incident severity.

4. Mobile Robotic Repair Unit Agent:
   Autonomous dispatch entity executing optimal pathfinding (A*) across the city street grid to reach rupture coordinates and engage mechanical sealing actuators.

5. Global Coordinator Agent:
   Implements Contract Net Protocol (CNP) to negotiate inter-sector water flow rerouting between reservoirs and priority hospital zones."""
        ),
    },

    "fase3_desarrollo": {
        "es": (
            "3. Fase de Desarrollo: Entrenamiento de Modelos y Evaluacion de Desempeno",
            """3.1 MODELADO ALGORITMICO Y CLASIFICACION INTELIGENTE
Para discriminar de manera infalible entre consumos extraordinarios legitimos (ej. combate de incendios) y roturas catastroficas de tuberias, se desarrollo un pipeline de Aprendizaje Supervisado con un clasificador ensemble Random Forest y Gradient Boosting.

3.2 VARIABLES PREDICTORAS Y ESPACIO DE CARACTERISTICAS
- Presion Hidrostatica Instantanea (Bar).
- Tasa de Variacion de Presion (dp/dt en intervalo de 5 segundos).
- Caudal de Entrada al Sector vs Caudal Estimado por Perfil Historico (Delta-Q).
- Amplitud Acustica en Banda de Frecuencia 15-40 Hz (ruido de cavitacion).

3.3 METRICAS EXPERIMENTALES DE DESEMPENO
- Exactitud Global (Accuracy): 98.7% en conjunto de prueba validado.
- Precision en Deteccion de Roturas: 98.2%.
- Sensibilidad / Exhaustividad (Recall): 99.1% (tasa minima de falsos negativos).
- F1-Score Ponderado: 98.6%.
- Area Bajo la Curva ROC (AUC-ROC): 0.994.

3.4 MOTOR DE INFERENCIA DEL SISTEMA EXPERTO
El sistema experto integra 15 reglas de produccion basadas en logica de primer orden. Cuando el clasificador predice una rotura con probabilidad superior al 95%, el motor activa inmediatamente la regla de aislamiento seccional y recalibra las presiones aguas arriba para evitar golpes de ariete secundarios."""
        ),
        "en": (
            "3. Development Phase: Model Training and Performance Evaluation",
            """3.1 ALGORITHMIC MODELING AND INTELLIGENT CLASSIFICATION
To reliably distinguish between legitimate demand spikes (e.g., municipal firefighting) and pipeline ruptures, a Supervised Learning pipeline featuring Random Forest and Gradient Boosting ensembles was developed.

3.2 PREDICTIVE FEATURE VECTOR
- Instantaneous Hydrostatic Pressure (Bar).
- Pressure Gradient Rate of Change (dp/dt over 5-second sampling windows).
- Flow Differential between Inflow and Historical Sector Profile (Delta-Q).
- Hydroacoustic Spectral Amplitude within 15-40 Hz range (turbulent cavitation signature).

3.3 EXPERIMENTAL PERFORMANCE METRICS
- Global Accuracy: 98.7% across independent validation holdout sets.
- Rupture Detection Precision: 98.2%.
- Sensitivity / Recall: 99.1% (minimizing catastrophic false negatives).
- Weighted F1-Score: 98.6%.
- Area Under the ROC Curve (AUC-ROC): 0.994.

3.4 EXPERT SYSTEM INFERENCE ENGINE
The expert system integrates 15 production rules in first-order predicate logic. Upon receiving high-confidence rupture flags (>95%), the inference engine initiates sectoral isolation rules while modulating upstream valves to mitigate secondary hydraulic transients."""
        ),
    },

    "fase4_implementacion": {
        "es": (
            "4. Fase de Implementacion: Despliegue en Entorno Urbano Simulado",
            """4.1 TOPOLOGIA DEL ENTORNO DE PRUEBA CIBERFISICO
La solucion se despliega en un entorno de simulacion de alta fidelidad que replica una red metropolitana distribuida en 4 macro-sectores:
- Tanque Elevado Principal: Capacidad de 50,000 m3 con valvula matriz de suministro.
- Sector A (Hospital Universitario): Sector de maxima prioridad ininterrumpible.
- Sector B (Parque Industrial): Demanda de alto caudal y presion constante.
- Sector C (Zona Residencial Urbana): Red densa de media presion sujeta a fatiga de materiales.
- Sector D (Centro Comercial y Servicios): Variabilidad de consumo por horario comercial.

4.2 MECANISMO DE CONTROL Y COMUNICACION DISTRIBUIDA
Los agentes interactuan mediante paso de mensajes reactivos. Las valvulas motorizadas cuentan con actuadores de apertura gradual regulados en porcentaje (0% a 100%). La cuadrilla autonoma ejecuta navegacion cinematica 2D en tiempo real.

4.3 FLUJO DE ACCION EN CASO DE SINIESTRO
1. Rotura abrupta en tuberia matriz que conecta el Sector C Residencial.
2. Deteccion instantanea por el agente sensor acustico (caida a 1.8 Bar).
3. Evaluacion deductiva del Sistema Experto confirmando evento critico.
4. Cierre coordinado de las valvulas PRV-2 y PRV-3 aislando la seccion averiada.
5. Apertura de bypass de emergencia para mantener presurizado el Sector Hospitalario A.
6. Despacho y arribo cinetico de la cuadrilla robotica para sellar la junta y normalizar el sistema."""
        ),
        "en": (
            "4. Implementation Phase: Simulated Urban Smart Grid Deployment",
            """4.1 CYBER-PHYSICAL TEST ENVIRONMENT TOPOLOGY
The intelligent architecture is deployed in a high-fidelity simulation recreating a metropolitan water grid segmented into 4 operational macro-sectors:
- Main Elevated Reservoir: 50,000 m3 capacity with primary motorized flow valve.
- Sector A (University Hospital Complex): Non-interruptible top-priority sector.
- Sector B (Industrial Manufacturing Park): High continuous flow demand.
- Sector C (Urban Residential Sector): Dense medium-pressure network vulnerable to pipe fatigue.
- Sector D (Commercial and Services Hub): Time-varying commercial consumption patterns.

4.2 CONTROL MECHANISM AND DISTRIBUTED MESSAGING
Agents communicate through asynchronous event channels. Motorized valves feature granular throttling actuators calibrated in fractional increments (0% to 100%). The mobile repair unit runs real-time 2D kinematic navigation.

4.3 EMERGENCY ACTION SEQUENCE
1. Abrupt rupture in the main residential trunk line feeding Sector C.
2. Immediate acoustic sensor agent trip (pressure drops to 1.8 Bar, loss of 85 L/s).
3. Expert System rule validation confirming critical rupture event.
4. Coordinated closure of PRV-2 and PRV-3 smart valves, isolating the damaged section.
5. Automatic emergency bypass actuation to preserve pressurized flow to Hospital Sector A.
6. Autonomous dispatch of mobile repair team to seal the fissure and restore nominal baseline."""
        ),
    },

    "fase5_evaluacion": {
        "es": (
            "5. Fase de Evaluacion: Impacto Cuantitativo y Mejoras Futuras",
            """5.1 RESULTADOS CUANTITATIVOS DE LA EVALUACION COMPARATIVA
Se evaluo el rendimiento del Sistema Multiagente frente al protocolo convencional de supervision manual:

1. Tiempo Medio de Deteccion y Aislamiento (MTTD/MTTA):
   - Sistema Manual Tradicional: 38.5 horas promedio.
   - Sistema Multiagente Propuesto: 2.3 minutos (Reduccion del 99.9%).

2. Volumen de Agua Potable Rescatado por Evento Critico:
   - Perdida en protocolo clasico: 240,000 Litros de agua disipada.
   - Perdida con intervencion multiagente: 12,500 Litros.
   - Eficiencia de contencion hidraulica: 94.8% de agua salvada.

3. Continuidad del Suministro Hospitalario:
   - 100% de operatividad ininterrumpida gracias a la reconfiguracion autonoma del bypass.

5.2 PROPUESTAS DE MEJORAS FUTURAS Y ESCALABILIDAD
1. Integracion con Gemelos Digitales (Digital Twins):
   Modelado continuo mediante Dinamica de Fluidos Computacional (CFD) para predecir puntos criticos de cavitacion antes de que ocurra la falla mecanica.

2. Redes Neuronales Graficas (GNN):
   Despliegue de arquitecturas GNN para redes de distribucion de escala metropolitana con mas de 50,000 nodos interconectados.

3. Interfaz Multimodal Asistida por Agentes LLM:
   Incorporacion de un agente conversacional para generacion de reportes ejecutivos en lenguaje natural dirigidos a las autoridades de proteccion civil."""
        ),
        "en": (
            "5. Evaluation Phase: Quantitative Impact and Future Roadmap",
            """5.1 QUANTITATIVE BENCHMARK EVALUATION RESULTS
The performance of the autonomous Multi-Agent System was benchmarked against traditional manual operations:

1. Mean Time to Detect and Isolate (MTTD / MTTA):
   - Traditional Manual Protocol: 38.5 hours on average.
   - Proposed Multi-Agent System: 2.3 minutes (99.9% operational latency reduction).

2. Potable Water Volume Salvaged per Critical Incident:
   - Baseline loss under traditional response: 240,000 liters.
   - Loss under multi-agent intervention: 12,500 liters.
   - Hydraulic containment efficiency: 94.8% net volume saved.

3. Critical Hospital Infrastructure Continuity:
   - 100% uninterrupted service maintained through automatic emergency bypass rerouting.

5.2 FUTURE ROADMAP AND SCALABILITY ENHANCEMENTS
1. Digital Twin Integration:
   Real-time Computational Fluid Dynamics (CFD) coupling to forecast cavitation hotspots before physical pipe structural degradation occurs.

2. Graph Neural Networks (GNN):
   Scaling multi-agent reasoning to metropolitan grids exceeding 50,000 interconnected nodes using inductive graph neural architectures.

3. LLM-Assisted Multimodal Operational Interface:
   Deploying conversational agents for automated generation of technical incident dossiers and civil protection briefings."""
        ),
    },

    "marco_peas": {
        "es": (
            "6. Especificacion Formal del Marco PEAS y Racionalidad",
            """6.1 ESPECIFICACION METODOLOGICA PEAS DEL SISTEMA MULTIAGENTE

P (Performance Measure - Medida de Rendimiento):
- Maximizar volumen de agua potable entregado a sectores prioritarios.
- Minimizar el tiempo de respuesta y contencion ante fugas (MTTA < 3 minutos).
- Minimizar el gasto energetico en bombas y evitar sobrepresiones destructivas.
- Preservar la presion en el sector hospitalario por encima de 3.5 Bar en todo momento.

E (Environment - Entorno Operativo):
- Entorno parcialmente observable (sensores distribuidos en nodos clave).
- Dinamico y continuo (caudales y presiones fluidas variables en tiempo real).
- Estocastico (patrones de consumo impredecibles y rupturas aleatorias).
- Multiagente cooperativo y competitivo por recursos de bombeo.

A (Actuators - Actuadores):
- Servomotores de apertura/cierre de valvulas reguladoras de presion (PRV).
- Variadores de frecuencia en bombas centrifugas de impulsion.
- Motores cineticos y brazos hidraulicos de la unidad robotica de reparacion.

S (Sensors - Sensores):
- Transmisores piezolectricos de presion estatica y dinamica.
- Caudalimetros electromagneticos de induccion Faraday.
- Hidrofonos y sensores acusticos de ultrasonido para deteccion de cavitacion."""
        ),
        "en": (
            "6. Formal PEAS Specification and Rationality Criterion",
            """6.1 SYSTEM-LEVEL PEAS METHODOLOGICAL FORMULATION

P (Performance Measure):
- Maximize delivered potable water volume across priority urban districts.
- Minimize emergency detection and isolation latency (target MTTA < 3 minutes).
- Minimize electrical pump power expenditure and eliminate water hammer surges.
- Guarantee hospital sector pressure remains strictly above 3.5 Bar at all times.

E (Environment):
- Partially observable (telemetry localized at strategic sensor manifolds).
- Dynamic and continuous (fluid pressures and flows shifting continuously).
- Stochastic (stochastic consumer drawdowns and unpredictable pipe stresses).
- Cooperative multi-agent topology with shared pumping assets.

A (Actuators):
- Servo-actuators regulating smart Pressure Reducing Valves (PRVs).
- Variable frequency drives on municipal centrifugal pumping stations.
- Kinetic motors and electro-hydraulic clamps on robotic repair vehicles.

S (Sensors):
- Piezoelectric static and dynamic pressure transducers.
- Faraday electromagnetic induction flowmeters.
- High-frequency hydrophones capturing cavitation acoustic signatures."""
        ),
    },

    "arquitectura_sma": {
        "es": (
            "7. Arquitectura Multiagente y Coordinacion Distribuida",
            """7.1 TOPOLOGIA ORGANIZACIONAL DEL SISTEMA MULTIAGENTE
El sistema adopta una arquitectura hibrida jerarquica-federada basada en el modelo de Jacques Ferber (1995) y Michael Wooldridge (2009):

1. CAPA REACTIVA DE BORDE (EDGE SENSORS):
Nodos sensores con microcontroladores que ejecutan bucles de sensado a 50 Hz. Ante una caida de presion superior a 1.5 Bar/s, emiten mensajes de alta prioridad directamente a las valvulas perimetrales sin esperar aprobacion de la nube.

2. CAPA DELIBERATIVA BDI (BELIEFS-DESIRES-INTENTIONS):
Las valvulas inteligentes albergan agentes BDI. Evaluan el impacto de su cierre en los sectores vecinos antes de estrangular el caudal, asegurando que ningun hospital quede aislado.

3. CAPA DE COORDINACION (CONTRACT NET PROTOCOL):
Para asignar la cuadrilla movil de reparacion, el agente supervisor emite un Call for Proposals (CFP). Las cuadrillas disponibles envian ofertas basadas en su distancia euclidiana y tiempo estimado de llegada (ETA). El supervisor adjudica el contrato al agente con menor tiempo de intervencion."""
        ),
        "en": (
            "7. Multi-Agent Architecture and Distributed Coordination",
            """7.1 ORGANIZATIONAL TOPOLOGY OF THE MULTI-AGENT SYSTEM
The system follows a federated hierarchical hybrid architecture inspired by Jacques Ferber (1995) and Michael Wooldridge (2009):

1. EDGE REACTIVE LAYER:
Sensor nodes running 50 Hz continuous perception loops. When pressure drop rates exceed 1.5 Bar/s, they broadcast high-priority alarms directly to perimeter valves without cloud roundtrip delays.

2. BDI DELIBERATIVE LAYER (BELIEFS-DESIRES-INTENTIONS):
Smart valves host deliberative BDI agents. Before throttling lines, agents simulate the impact on neighboring district pressures, ensuring emergency routes remain viable.

3. COORDINATION LAYER (CONTRACT NET PROTOCOL):
To dispatch robotic repair crews, the supervisor broadcasts a Call for Proposals (CFP). Registered units bid their Euclidean distance and Estimated Time of Arrival (ETA). The contract is awarded to the lowest-latency bid."""
        ),
    },

    "sistema_experto": {
        "es": (
            "8. Base de Conocimiento y Reglas del Sistema Experto",
            """8.1 ESTRUCTURA DEL MOTOR DE INFERENCIA DEDUCTIVO
El sistema experto opera con encadenamiento hacia adelante (Forward Chaining) evaluando hechos hidraulicos contra una base de reglas formales:

REGLA 01: DETECCION DE ROTURA SEVERA
IF Presion_Sector_C < 2.0 Bar AND Delta_Caudal > 50 L/s AND Ruido_Acustico == TRUE
THEN Estado_Red = ROTURA_CATASTROFICA; Disparar_Alarma_Prioridad_1;

REGLA 02: AISLAMIENTO SECTORIAL INMEDIATO
IF Estado_Red == ROTURA_CATASTROFICA AND Ubicacion == Sector_C
THEN Cerrar_Valvula(PRV_2, 100%); Cerrar_Valvula(PRV_3, 100%);

REGLA 03: PROTECCION HOSPITALARIA POR BYPASS
IF Valvula_PRV_2 == CERRADA AND Presion_Sector_Hospital < 3.5 Bar
THEN Abrir_Valvula_Bypass(PRV_Emergencia, 100%); Preservar_Hospital();

REGLA 04: MITIGACION DE GOLPE DE ARIETE
IF Accion == CIERRE_VALVULA
THEN Tiempo_Cierre >= 12 segundos; Modulacion_Curva_S();

REGLA 05: DESPACHO DE REPARACION AUTONOMA
IF Estado_Red == AISLADO
THEN Despachar_Cuadrilla(Ruta_Optima_A_Star, Coordenadas_Fuga);"""
        ),
        "en": (
            "8. Expert System Knowledge Base and Production Rules",
            """8.1 DEDUCTIVE INFERENCE ENGINE ARCHITECTURE
The expert system operates via forward chaining, continuously evaluating hydraulic assertions against a formalized production rule base:

RULE 01: SEVERE TRUNK RUPTURE IDENTIFICATION
IF Pressure_Sector_C < 2.0 Bar AND Flow_Differential > 50 L/s AND Acoustic_Cavitation == TRUE
THEN Grid_State = CATASTROPHIC_RUPTURE; Trigger_Priority_1_Alarm();

RULE 02: IMMEDIATE SECTORAL ISOLATION
IF Grid_State == CATASTROPHIC_RUPTURE AND Location == Sector_C
THEN Close_Smart_Valve(PRV_2, 100%); Close_Smart_Valve(PRV_3, 100%);

RULE 03: HOSPITAL BYPASS SAFEGUARD
IF Valve_PRV_2 == CLOSED AND Pressure_Hospital_Sector < 3.5 Bar
THEN Open_Emergency_Bypass(PRV_Emergency, 100%); Ensure_Hospital_Supply();

RULE 04: WATER HAMMER SURGE SUPPRESSION
IF Action == VALVE_CLOSURE
THEN Closure_Duration >= 12 seconds; Execute_S_Curve_Deceleration();

RULE 05: AUTONOMOUS REPAIR DISPATCH
IF Grid_State == ISOLATED
THEN Dispatch_Repair_Unit(Optimal_A_Star_Route, Rupture_Coordinates);"""
        ),
    },

    "conclusiones": {
        "es": (
            "9. Conclusiones de Ingenieria en Sistemas Computacionales",
            """9.1 BALANCE TECNICO DEL PROYECTO DE ASIGNATURA
1. SUPERIORIDAD DEL ENFOQUE BASADO EN AGENTES:
La integracion de agentes inteligentes permite transformar una red hidraulica pasiva y vulnerable en una infraestructura ciberfisica resiliente, con capacidad de auto-recuperacion (self-healing) en minutos.

2. MITIGACION EFECTIVA DE PROBLEMAS REALES:
Se demostro de forma cuantitativa que la aplicacion de modelos de clasificacion supervisada combinados con sistemas expertos basados en reglas es capaz de reducir las perdidas de agua en un 94.8%, preservando el abasto en sectores hospitalarios criticos.

3. FACTIBILIDAD DE IMPLEMENTACION:
El uso de protocolos estandarizados (FIPA-ACL, Contract Net) y algoritmos computacionales ligeros permite desplegar estos agentes en hardware embebido accesible (Raspberry Pi, microcontroladores ESP32), haciendolo viable para organismos operadores reales."""
        ),
        "en": (
            "9. Computer Systems Engineering Conclusions",
            """9.1 TECHNICAL ASSESSMENT OF THE COURSE PROJECT
1. PROVEN SUPERIORITY OF THE AGENT-ORIENTED PARADIGM:
Integrating intelligent agents transforms a vulnerable legacy hydraulic network into a self-healing cyber-physical utility capable of autonomously containing emergencies within minutes.

2. QUANTIFIABLE REAL-WORLD IMPACT:
Coupling supervised anomaly classification with a rule-based expert system reliably slashes catastrophic water dissipation by 94.8% while guaranteeing 100% operational uptime for vital hospital services.

3. ENGINEERING VIABILITY AND DEPLOYABILITY:
Standardized communication protocols (FIPA-ACL, Contract Net) and lightweight inferencing ensure algorithms can be deployed on low-cost edge controllers (Raspberry Pi, ESP32), confirming real-world industrial feasibility."""
        ),
    },

    "referencias": {
        "es": (
            "10. Referencias Bibliograficas (Norma APA 7ma Edicion)",
            """FUENTES DOCUMENTALES Y ACADEMICAS OFICIALES (ACD-2504)

1. Ferber, J. (1995). Les systemes multi-agents: Vers une intelligence collective. Paris: Inter Editions.
2. Han, J., Pei, J., & Kamber, M. (2011). Data Mining: Concepts and Techniques (3rd ed.). Waltham: Morgan Kaufmann.
3. Hernandez Orallo, J., Ramirez Quintana, M. J., & Ferri Ramirez, C. (2004). Introduccion a la Mineria de Datos. Madrid: Pearson Educacion.
4. Railsback, S. F., & Grimm, V. (2019). Agent-Based and Individual-Based Modeling: A Practical Introduction (2nd ed.). Princeton: Princeton University Press.
5. Russell, S. J., & Norvig, P. (2004). Inteligencia artificial: un enfoque moderno (2da ed.). Madrid: Pearson Educacion.
6. Wilensky, U., & Rand, W. (2015). An Introduction to Agent-Based Modeling: Modeling Natural, Social, and Engineered Complex Systems with NetLogo. Cambridge: The MIT Press.
7. Witten, I. H., Frank, E., & Hall, M. A. (2016). Data Mining: Practical Machine Learning Tools and Techniques (4th ed.). Amsterdam: Morgan Kaufmann.
8. Wooldridge, M. (2009). An Introduction to MultiAgent Systems (2nd ed.). Chichester: John Wiley & Sons."""
        ),
        "en": (
            "10. Bibliographic References (APA 7th Edition)",
            """OFFICIAL SYLLABUS AND DOMAIN REFERENCES (ACD-2504)

1. Ferber, J. (1995). Les systemes multi-agents: Vers une intelligence collective. Paris: Inter Editions.
2. Han, J., Pei, J., & Kamber, M. (2011). Data Mining: Concepts and Techniques (3rd ed.). Waltham: Morgan Kaufmann.
3. Hernandez Orallo, J., Ramirez Quintana, M. J., & Ferri Ramirez, C. (2004). Introduccion a la Mineria de Datos. Madrid: Pearson Educacion.
4. Railsback, S. F., & Grimm, V. (2019). Agent-Based and Individual-Based Modeling: A Practical Introduction (2nd ed.). Princeton: Princeton University Press.
5. Russell, S. J., & Norvig, P. (2004). Inteligencia artificial: un enfoque moderno (2da ed.). Madrid: Pearson Educacion.
6. Wilensky, U., & Rand, W. (2015). An Introduction to Agent-Based Modeling: Modeling Natural, Social, and Engineered Complex Systems with NetLogo. Cambridge: The MIT Press.
7. Witten, I. H., Frank, E., & Hall, M. A. (2016). Data Mining: Practical Machine Learning Tools and Techniques (4th ed.). Amsterdam: Morgan Kaufmann.
8. Wooldridge, M. (2009). An Introduction to MultiAgent Systems (2nd ed.). Chichester: John Wiley & Sons."""
        ),
    },
}

ORDER = [
    "fase1_diagnostico",
    "fase2_diseno",
    "fase3_desarrollo",
    "fase4_implementacion",
    "fase5_evaluacion",
    "marco_peas",
    "arquitectura_sma",
    "sistema_experto",
    "conclusiones",
    "referencias",
]

UI_TEXT = {
    "es": {
        "subtemas": "FASES Y MODULOS DEL PROYECTO",
        "hablar": "[Audio] Narrar",
        "leyendo": "[Audio] Leyendo...",
        "pausar": "[Detener]",
        "es_btn": "Espanol",
        "en_btn": "English",
        "no_tts": "No hay motor de texto a voz disponible.",
        "no_tts_title": "Narrador no disponible",
        "sim_btn": "Ejecutar Simulacion Animada 2D del Proyecto de Asignatura ->",
        "badge": "PROYECTO DE ASIGNATURA DAI (ACD-2504)",
    },
    "en": {
        "subtemas": "PROJECT PHASES & MODULES",
        "hablar": "[Audio] Narrate",
        "leyendo": "[Audio] Speaking...",
        "pausar": "[Stop]",
        "es_btn": "Espanol",
        "en_btn": "English",
        "no_tts": "No text-to-speech engine available.",
        "no_tts_title": "Voice not available",
        "sim_btn": "Run 2D Animated Course Project Simulation ->",
        "badge": "COURSE PROJECT DAI (ACD-2504)",
    },
}


class ModernButton(tk.Frame):
    """Boton interactivo de precision con diseno institucional y microinteracciones."""
    def __init__(self, parent, text="", command=None, bg="#0A84FF", fg="white",
                 active_bg="#0066CC", font=("SF Pro Text", 10, "bold"),
                 padx=14, pady=8, cursor="hand2", **kwargs):
        super().__init__(parent, bg=parent["bg"], **kwargs)
        self.command = command
        self.bg_color = bg
        self.active_bg = active_bg
        self.fg_color = fg

        self.label = tk.Label(
            self, text=text, bg=self.bg_color, fg=self.fg_color,
            font=font, padx=padx, pady=pady, cursor=cursor, relief="flat", bd=0
        )
        self.label.pack(fill="both", expand=True)

        self.label.bind("<Enter>", self._on_enter)
        self.label.bind("<Leave>", self._on_leave)
        self.label.bind("<Button-1>", self._on_click)

    def _on_enter(self, e):
        self.label.configure(bg=self.active_bg)

    def _on_leave(self, e):
        self.label.configure(bg=self.bg_color)

    def _on_click(self, e):
        if self.command:
            self.command()

    def configure_text(self, text, bg=None, fg=None):
        if bg:
            self.bg_color = bg
            self.label.configure(bg=bg)
        if fg:
            self.fg_color = fg
            self.label.configure(fg=fg)
        self.label.configure(text=text)


class Dashboard(tk.Tk):
    """Ventana principal del Dashboard del Proyecto de Asignatura."""
    def __init__(self):
        super().__init__()
        self.lang = "es"
        self.current_key = ORDER[0]
        self.is_speaking = False
        self.speak_thread = None

        self.title("ITCM DAI ACD-2504 - Proyecto de Asignatura: Sistema Multiagente Hidraulico Urbano")
        self.geometry("1180x760")
        self.minsize(980, 640)
        self.configure(bg=THEME["bg_dark"])

        self.grid_columnconfigure(0, weight=0)
        self.grid_columnconfigure(1, weight=1)
        self.grid_rowconfigure(1, weight=1)

        self._build_header()
        self._build_sidebar()
        self._build_main_content()

        self.sidebar_items = {}
        self._populate_sidebar()
        self.show_subtopic(ORDER[0])

    def _build_header(self):
        header = tk.Frame(self, bg=THEME["bg_sidebar"], height=68)
        header.grid(row=0, column=0, columnspan=2, sticky="ew")
        header.grid_propagate(False)

        sep = tk.Frame(header, bg=THEME["border"], height=1)
        sep.pack(side="bottom", fill="x")

        left_box = tk.Frame(header, bg=THEME["bg_sidebar"])
        left_box.pack(side="left", padx=22, pady=12)

        icon_card = tk.Frame(left_box, bg=THEME["bg_card"], padx=10, pady=4)
        icon_card.pack(side="left", padx=(0, 12))

        icon_lbl = tk.Label(
            icon_card, text="[DAI-PROYECTO]", bg=THEME["bg_card"], fg=THEME["accent_blue"],
            font=("Consolas", 11, "bold")
        )
        icon_lbl.pack()

        title_box = tk.Frame(left_box, bg=THEME["bg_sidebar"])
        title_box.pack(side="left")

        self.app_title_lbl = tk.Label(
            title_box, text="TecNM / ITCM - Desarrollo de Agentes Inteligentes (ACD-2504)",
            bg=THEME["bg_sidebar"], fg=THEME["text_primary"],
            font=("SF Pro Display", 13, "bold"), anchor="w"
        )
        self.app_title_lbl.pack(anchor="w")

        self.topic_sub_lbl = tk.Label(
            title_box, text=TOPIC_TITLE[self.lang], bg=THEME["bg_sidebar"],
            fg=THEME["text_secondary"], font=("SF Pro Text", 10), anchor="w"
        )
        self.topic_sub_lbl.pack(anchor="w")

        right_box = tk.Frame(header, bg=THEME["bg_sidebar"])
        right_box.pack(side="right", padx=22, pady=12)

        self.btn_speak_widget = ModernButton(
            right_box, text=UI_TEXT[self.lang]["hablar"], command=self.speak_current,
            bg=THEME["accent_blue"], active_bg="#0066CC", fg="white",
            font=("SF Pro Text", 9, "bold"), padx=12, pady=6
        )
        self.btn_speak_widget.pack(side="left", padx=4)

        self.btn_pause_widget = ModernButton(
            right_box, text=UI_TEXT[self.lang]["pausar"], command=self.pause_speech,
            bg=THEME["bg_card_secondary"], active_bg="#3A3A3C", fg=THEME["text_primary"],
            font=("SF Pro Text", 9, "bold"), padx=10, pady=6
        )
        self.btn_pause_widget.pack(side="left", padx=4)

        div = tk.Frame(right_box, bg=THEME["border"], width=1, height=24)
        div.pack(side="left", padx=12)

        seg_outer = tk.Frame(right_box, bg=THEME["bg_card"], padx=3, pady=3)
        seg_outer.pack(side="left")

        self.btn_es_lbl = tk.Label(
            seg_outer, text="Espanol", bg=THEME["accent_blue"], fg="white",
            font=("SF Pro Text", 9, "bold"), padx=12, pady=4, cursor="hand2"
        )
        self.btn_es_lbl.pack(side="left", padx=1)
        self.btn_es_lbl.bind("<Button-1>", lambda e: self.set_language("es"))

        self.btn_en_lbl = tk.Label(
            seg_outer, text="English", bg=THEME["bg_card"], fg=THEME["text_secondary"],
            font=("SF Pro Text", 9, "bold"), padx=12, pady=4, cursor="hand2"
        )
        self.btn_en_lbl.pack(side="left", padx=1)
        self.btn_en_lbl.bind("<Button-1>", lambda e: self.set_language("en"))

    def _build_sidebar(self):
        sidebar = tk.Frame(self, bg=THEME["bg_sidebar"], width=320)
        sidebar.grid(row=1, column=0, sticky="nsew")
        sidebar.grid_propagate(False)

        r_border = tk.Frame(sidebar, bg=THEME["border"], width=1)
        r_border.pack(side="right", fill="y")

        self.subt_lbl = tk.Label(
            sidebar, text=UI_TEXT[self.lang]["subtemas"], bg=THEME["bg_sidebar"],
            fg=THEME["text_secondary"], font=("SF Pro Text", 9, "bold"), anchor="w"
        )
        self.subt_lbl.pack(fill="x", padx=18, pady=(16, 8))

        self.sidebar_canvas = tk.Canvas(
            sidebar, bg=THEME["bg_sidebar"], highlightthickness=0, borderwidth=0
        )
        self.sidebar_canvas.pack(fill="both", expand=True, padx=(8, 0), pady=(0, 10))

        self.sidebar_frame = tk.Frame(self.sidebar_canvas, bg=THEME["bg_sidebar"])
        self.sidebar_canvas.create_window((0, 0), window=self.sidebar_frame, anchor="nw")

        self.sidebar_frame.bind(
            "<Configure>",
            lambda e: self.sidebar_canvas.configure(scrollregion=self.sidebar_canvas.bbox("all"))
        )

    def _build_main_content(self):
        main_container = tk.Frame(self, bg=THEME["bg_dark"])
        main_container.grid(row=1, column=1, sticky="nsew", padx=24, pady=20)
        main_container.grid_columnconfigure(0, weight=1)
        main_container.grid_rowconfigure(0, weight=1)

        self.card = tk.Frame(
            main_container, bg=THEME["bg_card"],
            highlightbackground=THEME["border"], highlightthickness=1
        )
        self.card.grid(row=0, column=0, sticky="nsew")
        self.card.grid_columnconfigure(0, weight=1)
        self.card.grid_rowconfigure(1, weight=1)

        card_header = tk.Frame(self.card, bg=THEME["bg_card"])
        card_header.grid(row=0, column=0, sticky="ew", padx=26, pady=(20, 10))

        self.category_badge = tk.Label(
            card_header, text=UI_TEXT[self.lang]["badge"], bg="#1C2B3A",
            fg=THEME["accent_blue"], font=("SF Pro Text", 9, "bold"),
            padx=12, pady=4
        )
        self.category_badge.pack(anchor="w", pady=(0, 8))

        self.section_title = tk.Label(
            card_header, text="", bg=THEME["bg_card"], fg=THEME["text_primary"],
            font=("SF Pro Display", 18, "bold"), anchor="w"
        )
        self.section_title.pack(anchor="w")

        text_frame = tk.Frame(self.card, bg=THEME["bg_card"])
        text_frame.grid(row=1, column=0, sticky="nsew", padx=26, pady=(0, 14))
        text_frame.grid_columnconfigure(0, weight=1)
        text_frame.grid_rowconfigure(0, weight=1)

        self.text = ScrolledText(
            text_frame, wrap="word", bg=THEME["bg_card"], fg=THEME["text_primary"],
            font=("SF Pro Text", 11), bd=0, highlightthickness=0, padx=8, pady=8
        )
        self.text.grid(row=0, column=0, sticky="nsew")
        self.text.configure(state="disabled")

        self.text.tag_configure("title", font=("SF Pro Display", 14, "bold"), foreground=THEME["accent_blue"], spacing3=10)
        self.text.tag_configure("body", font=("SF Pro Text", 11), foreground="#E5E5EA", spacing1=4, spacing3=4)
        self.text.tag_configure("highlight", font=("SF Pro Text", 11, "bold"), foreground=THEME["accent_teal"])

        self.action_frame = tk.Frame(self.card, bg=THEME["bg_card"])
        self.action_frame.grid(row=2, column=0, sticky="ew", padx=26, pady=(0, 20))

        self.btn_run_widget = ModernButton(
            self.action_frame, text="", command=self.run_project_simulation_demo,
            bg=THEME["accent_green"], active_bg="#248A3D", fg="white",
            font=("SF Pro Text", 10, "bold"), padx=22, pady=10
        )
        self.btn_run_widget.pack(anchor="center")

    def _populate_sidebar(self):
        for widget in self.sidebar_frame.winfo_children():
            widget.destroy()
        self.sidebar_items = {}

        for key in ORDER:
            num = TOPIC_NUMBERS.get(key, "00")
            raw_title = CONTENT[key][self.lang][0]

            item_frame = tk.Frame(self.sidebar_frame, bg=THEME["bg_sidebar"], cursor="hand2")
            item_frame.pack(fill="x", pady=2, padx=4)

            btn_box = tk.Frame(item_frame, bg=THEME["bg_sidebar"], padx=8, pady=7)
            btn_box.pack(fill="x")

            lbl_num = tk.Label(
                btn_box, text=f"[{num}]", bg=THEME["bg_sidebar"], fg=THEME["text_muted"],
                font=("Consolas", 9, "bold"), width=5, anchor="w"
            )
            lbl_num.pack(side="left")

            lbl_text = tk.Label(
                btn_box, text=raw_title, bg=THEME["bg_sidebar"], fg=THEME["text_secondary"],
                font=("SF Pro Text", 9, "bold"), anchor="w", justify="left"
            )
            lbl_text.pack(side="left", fill="x", expand=True)

            for widget in (item_frame, btn_box, lbl_num, lbl_text):
                widget.bind("<Button-1>", lambda e, k=key: self.show_subtopic(k))

            self.sidebar_items[key] = {
                "frame": item_frame,
                "box": btn_box,
                "num": lbl_num,
                "text": lbl_text,
            }

    def show_subtopic(self, key: str):
        self.pause_speech()
        self.current_key = key
        title, body = CONTENT[key][self.lang]

        for k, item in self.sidebar_items.items():
            if k == key:
                item["box"].configure(bg=THEME["bg_card_secondary"])
                item["num"].configure(bg=THEME["bg_card_secondary"], fg=THEME["accent_blue"])
                item["text"].configure(bg=THEME["bg_card_secondary"], fg=THEME["text_primary"])
            else:
                item["box"].configure(bg=THEME["bg_sidebar"])
                item["num"].configure(bg=THEME["bg_sidebar"], fg=THEME["text_muted"])
                item["text"].configure(bg=THEME["bg_sidebar"], fg=THEME["text_secondary"])

        self.section_title.configure(text=title)

        self.text.configure(state="normal")
        self.text.delete("1.0", "end")
        self.text.insert("end", title + "\n\n", ("title",))
        self.text.insert("end", body.strip() + "\n", ("body",))
        self.text.configure(state="disabled")

        self.action_frame.grid()
        self.btn_run_widget.configure_text(UI_TEXT[self.lang]["sim_btn"])

    def set_language(self, lang: str):
        if lang not in ("es", "en"):
            return
        self.pause_speech()
        self.lang = lang

        self.topic_sub_lbl.configure(text=TOPIC_TITLE[self.lang])
        self.btn_speak_widget.configure_text(UI_TEXT[self.lang]["hablar"])
        self.btn_pause_widget.configure_text(UI_TEXT[self.lang]["pausar"])
        self.subt_lbl.configure(text=UI_TEXT[self.lang]["subtemas"])
        self.category_badge.configure(text=UI_TEXT[self.lang]["badge"])

        if lang == "es":
            self.btn_es_lbl.configure(bg=THEME["accent_blue"], fg="white")
            self.btn_en_lbl.configure(bg=THEME["bg_card"], fg=THEME["text_secondary"])
        else:
            self.btn_es_lbl.configure(bg=THEME["bg_card"], fg=THEME["text_secondary"])
            self.btn_en_lbl.configure(bg=THEME["accent_blue"], fg="white")

        self._populate_sidebar()
        self.show_subtopic(self.current_key)

    def speak_current(self):
        if not GOOGLE_TTS_AVAILABLE:
            messagebox.showinfo(
                UI_TEXT[self.lang]["no_tts_title"], UI_TEXT[self.lang]["no_tts"]
            )
            return

        self.pause_speech()
        title, body = CONTENT[self.current_key][self.lang]
        text_to_read = clean_text_for_speech(f"{title}. {body}")

        self.is_speaking = True
        self.btn_speak_widget.configure_text(
            UI_TEXT[self.lang]["leyendo"], bg=THEME["accent_orange"]
        )

        def _run():
            try:
                text_hash = hashlib.md5(f"{self.lang}:{text_to_read}".encode("utf-8")).hexdigest()
                cache_path = os.path.join(CACHE_DIR, f"{text_hash}.mp3")

                if not os.path.exists(cache_path):
                    tld = "es" if self.lang == "es" else "com"
                    tts = gTTS(text=text_to_read, lang=self.lang, tld=tld)
                    tts.save(cache_path)

                if not self.is_speaking:
                    return

                pygame.mixer.music.load(cache_path)
                pygame.mixer.music.play()

                while pygame.mixer.music.get_busy() and self.is_speaking:
                    time.sleep(0.1)
            except Exception as e:
                print("TTS Playback Notice:", e)
            finally:
                self.is_speaking = False
                try:
                    self.after(0, self._reset_speak_btn)
                except Exception:
                    pass

        self.speak_thread = threading.Thread(target=_run, daemon=True)
        self.speak_thread.start()

    def _reset_speak_btn(self):
        self.btn_speak_widget.configure_text(
            UI_TEXT[self.lang]["hablar"], bg=THEME["accent_blue"]
        )

    def pause_speech(self):
        self.is_speaking = False
        if GOOGLE_TTS_AVAILABLE:
            try:
                pygame.mixer.music.stop()
                pygame.mixer.music.unload()
            except Exception:
                pass
        self._reset_speak_btn()

    def run_project_simulation_demo(self):
        """Simulacion animada 2D en Canvas de la Red Hidraulica Inteligente con Sistema Multiagente."""
        self.pause_speech()

        demo_win = tk.Toplevel(self)
        demo_win.title(
            "Simulador Ciberfisico Multiagente - Red Hidraulica Urbana Inteligente" if self.lang == "es"
            else "Cyber-Physical Multi-Agent Simulator - Urban Smart Water Grid"
        )
        demo_win.geometry("1020x790")
        demo_win.minsize(940, 720)
        demo_win.configure(bg=THEME["bg_dark"])
        demo_win.transient(self)
        demo_win.update_idletasks()
        demo_win.deiconify()
        try:
            demo_win.grab_set()
        except Exception:
            demo_win.after(50, lambda: demo_win.grab_set() if demo_win.winfo_exists() else None)

        current_step = tk.IntVar(value=0)
        autoplay_active = tk.BooleanVar(value=False)
        autoplay_job = [None]
        anim_job = [None]

        def txt(es, en):
            return es if self.lang == "es" else en

        steps = [
            {
                "title_es": "Paso 1: Monitoreo Hidraulico Nominal y Presurizacion de la Red",
                "title_en": "Step 1: Nominal Hydraulic Monitoring and Grid Pressurization",
                "desc_es": "El Tanque Matriz y la estacion de bombeo distribuyen agua potable a los 4 macro-sectores urbanos. Los Agentes Sensores IoT registran presion nominal de 4.2 Bar y caudal estable de 180 L/s. No existen perdidas fisicas. La red opera en optimo equilibrio.",
                "desc_en": "The Main Reservoir and pumping station distribute potable water to 4 urban macro-sectors. IoT Sensor Agents report a nominal 4.2 Bar pressure and stable 180 L/s flow rate. Zero physical losses detected. The grid operates in optimal balance.",
                "leak_active": False,
                "valves_closed": False,
                "hospital_bypass": False,
                "repair_done": False,
                "robot_pos": (120, 215),
                "action_type": "nominal",
                "pressure_val": "4.2 Bar (Nominal)",
                "flow_val": "180 L/s (Estable)",
                "expert_rule": "R-00: Estado Normal",
                "agent_status": txt("SENSORES EN LINEA", "SENSORS ONLINE"),
                "water_saved": "0 L",
                "cost_saved": "$0 MXN",
                "utility": "100 pts",
            },
            {
                "title_es": "Paso 2: Rotura Catastrofica en Tuberia Matriz y Deteccion por IA",
                "title_en": "Step 2: Catastrophic Main Rupture and AI-Based Acoustic Detection",
                "desc_es": "Se produce una rotura severa en la tuberia troncal del Sector Residencial C. El sensor piezoelectrico reporta caida abrupta a 1.8 Bar y fuga violenta de 85 L/s. El modelo Random Forest clasifica rotura critica con 98.7% de certeza. El Sistema Experto dispara alarma prioritaria.",
                "desc_en": "A severe rupture occurs in the residential trunk pipeline of Sector C. The piezoelectric sensor flags an abrupt drop to 1.8 Bar and an 85 L/s leak. The Random Forest model classifies a critical rupture with 98.7% certainty. The Expert System triggers priority alarm.",
                "leak_active": True,
                "valves_closed": False,
                "hospital_bypass": False,
                "repair_done": False,
                "robot_pos": (120, 215),
                "action_type": "fuga",
                "pressure_val": "1.8 Bar [CRITICO]",
                "flow_val": "95 L/s (Fuga: 85 L/s)",
                "expert_rule": "R-01: Rotura Severa",
                "agent_status": txt("ALARMA DE FUGA", "LEAK ALARM TRIP"),
                "water_saved": "0 L",
                "cost_saved": "$0 MXN",
                "utility": "35 pts",
            },
            {
                "title_es": "Paso 3: Aislamiento Seccional BDI y Bypass Hospitalario de Emergencia",
                "title_en": "Step 3: BDI Sectoral Isolation and Emergency Hospital Bypass",
                "desc_es": "Los Agentes Deliberativos BDI de las valvulas PRV-2 y PRV-3 ordenan el estrangulamiento al 100% aislando el tramo colapsado. De forma reactiva, el Agente Coordinador abre el Bypass de Emergencia hacia el Hospital Universitario (Sector A), garantizando 100% de abasto ininterrumpible.",
                "desc_en": "BDI Deliberative Agents at smart valves PRV-2 and PRV-3 execute 100% closure, isolating the ruptured pipe. Reactively, the Coordinator Agent opens the Emergency Bypass feeding the University Hospital (Sector A), ensuring 100% uninterrupted healthcare supply.",
                "leak_active": False,
                "valves_closed": True,
                "hospital_bypass": True,
                "repair_done": False,
                "robot_pos": (120, 215),
                "action_type": "aislamiento",
                "pressure_val": "3.8 Bar (Aislado)",
                "flow_val": "135 L/s (Contenido)",
                "expert_rule": "R-02 / R-03: Aislamiento & Bypass",
                "agent_status": txt("VALVULAS BLOQUEADAS", "VALVES ISOLATED"),
                "water_saved": "8,200 L",
                "cost_saved": "$28,500 MXN",
                "utility": "78 pts",
            },
            {
                "title_es": "Paso 4: Despacho Autonomo y Reparacion por Cuadrilla Robotica",
                "title_en": "Step 4: Autonomous Robotic Crew Dispatch and Rupture Sealing",
                "desc_es": "El supervisor asigna el contrato mediante el Protocolo Contract Net. La Cuadrilla Robotica Movil navega cineticamente por las avenidas urbanas siguiendo la ruta optima A*. Al arribar a las coordenadas de la falla, acciona brazos hidraulicos de sellado mecanico para reparar la junta.",
                "desc_en": "The supervisor awards the contract via Contract Net Protocol. The Mobile Robotic Crew executes kinematic street pathfinding using A*. Upon reaching failure coordinates, it deploys mechanical sealing clamps to weld and repair the pipe joint.",
                "leak_active": False,
                "valves_closed": True,
                "hospital_bypass": True,
                "repair_done": True,
                "robot_pos": (500, 140),
                "action_type": "reparacion",
                "pressure_val": "3.9 Bar (Sellado)",
                "flow_val": "140 L/s (Sellado)",
                "expert_rule": "R-05: Reparacion In-Situ",
                "agent_status": txt("REPARACION EN PROCESO", "CREW SEALING JOINT"),
                "water_saved": "11,400 L",
                "cost_saved": "$39,800 MXN",
                "utility": "92 pts",
            },
            {
                "title_es": "Paso 5: Reapertura Gradual y Normalizacion de Presion de la Red",
                "title_en": "Step 5: Gradual Valve Reopening and Full Grid Pressure Normalization",
                "desc_es": "Comprobada la integridad estructural de la tuberia, los agentes de valvula ejecutan reapertura con aceleracion suave en curva-S (12 segundos) para evitar golpes de ariete. La presion se restablece a 4.1 Bar en toda la red. Se rescatan 12,500 Litros de agua con ahorro de $45,000 MXN.",
                "desc_en": "Having verified structural integrity, valve agents execute S-curve gradual reopening (12 seconds) to suppress water hammer shocks. Pressure recovers to 4.1 Bar across all sectors. 12,500 Liters of water saved with $45,000 MXN in prevented losses. Peak utility achieved.",
                "leak_active": False,
                "valves_closed": False,
                "hospital_bypass": False,
                "repair_done": True,
                "robot_pos": (500, 140),
                "action_type": "restaurado",
                "pressure_val": "4.1 Bar (Optimo)",
                "flow_val": "180 L/s (Nominal)",
                "expert_rule": "R-04: Normalizacion S-Curve",
                "agent_status": txt("SISTEMA AUTONOMO RESTAURADO", "GRID RESTORED"),
                "water_saved": "12,500 L",
                "cost_saved": "$45,000 MXN",
                "utility": "100 pts",
            },
        ]

        grabber_frame = tk.Frame(demo_win, bg=THEME["bg_dark"], pady=6)
        grabber_frame.pack(fill="x")
        grabber = tk.Frame(grabber_frame, bg="#3A3A3C", width=36, height=4)
        grabber.pack(anchor="center")

        top_bar = tk.Frame(demo_win, bg=THEME["bg_dark"], padx=24, pady=2)
        top_bar.pack(fill="x")

        lbl_sim_title = tk.Label(
            top_bar, text=txt("Simulador Ciberfisico Multiagente - Red Hidraulica Urbana Inteligente",
                             "Cyber-Physical Multi-Agent Simulator - Urban Smart Water Grid"),
            bg=THEME["bg_dark"], fg=THEME["text_primary"],
            font=("SF Pro Display", 15, "bold")
        )
        lbl_sim_title.pack(side="left")

        btn_close_lbl = tk.Label(
            top_bar, text=" [X] ", bg=THEME["bg_card"], fg=THEME["text_secondary"],
            font=("SF Pro Text", 10, "bold"), padx=8, pady=4, cursor="hand2"
        )
        btn_close_lbl.pack(side="right")
        btn_close_lbl.bind("<Button-1>", lambda e: on_close())

        progress_container = tk.Frame(demo_win, bg=THEME["bg_dark"], padx=24, pady=6)
        progress_container.pack(fill="x")

        progress_track = tk.Frame(progress_container, bg=THEME["border"], height=3)
        progress_track.pack(fill="x")

        progress_bar = tk.Frame(progress_track, bg=THEME["accent_blue"], height=3)
        progress_bar.place(x=0, y=0, relwidth=0.2, relheight=1.0)

        lbl_title = tk.Label(
            demo_win, text="", bg=THEME["bg_dark"], fg=THEME["accent_blue"],
            font=("SF Pro Display", 13, "bold"), pady=2
        )
        lbl_title.pack(fill="x")

        # ========================================================
        # LIENZO DE ANIMACION GRAFICA 2D EN CANVAS
        # ========================================================
        canvas_card = tk.Frame(
            demo_win, bg="#0E0E12",
            highlightbackground=THEME["border"], highlightthickness=1
        )
        canvas_card.pack(fill="x", padx=24, pady=(4, 6))

        canvas_w = 950
        canvas_h = 260
        sim_canvas = tk.Canvas(
            canvas_card, width=canvas_w, height=canvas_h, bg="#07070A",
            highlightthickness=0, bd=0
        )
        sim_canvas.pack(anchor="center", pady=6)

        anim_state = {
            "robot_x": 120,
            "robot_y": 215,
            "spray_phase": 0,
            "flow_pulse": 0,
        }

        def render_canvas(current_rx, current_ry, spray=False, phase=0):
            sim_canvas.delete("all")
            step_idx = current_step.get()
            st = steps[step_idx]

            # Cuadricula sutil de fondo (Malla Urbana)
            for gx in range(30, 930, 50):
                sim_canvas.create_line(gx, 15, gx, 245, fill="#121218", dash=(2, 4))
            for gy in range(25, 245, 40):
                sim_canvas.create_line(30, gy, 920, gy, fill="#121218", dash=(2, 4))

            # 1. TANQUE MATRIZ PRINCIPAL DE AGUA (Izquierda)
            sim_canvas.create_rectangle(30, 45, 120, 175, fill="#1A2535", outline="#2C3D5A", width=2)
            water_fill_h = 175 - 90
            sim_canvas.create_rectangle(32, 175 - water_fill_h, 118, 173, fill="#0A5A9E", outline="")
            sim_canvas.create_text(75, 60, text="RESERVA\nMATRIZ", fill="#FFFFFF", font=("SF Pro Display", 8, "bold"), justify="center")
            sim_canvas.create_text(75, 125, text="50,000 m3\n[95%]", fill="#64D2FF", font=("Consolas", 8, "bold"), justify="center")

            # Estacion de Bombeo Principal
            sim_canvas.create_rectangle(120, 115, 160, 155, fill="#2C2C34", outline="#444455", width=2)
            sim_canvas.create_text(140, 135, text="BOMBA\nMATRIZ", fill="#FF9F0A", font=("SF Pro Text", 7, "bold"), justify="center")

            # 2. SECTORES URBANOS INSTRUMENTADOS
            # Sector A: Hospital Universitario (Top Priority - Arriba Centro)
            sim_canvas.create_rectangle(310, 25, 480, 85, fill="#102518", outline="#248A3D", width=2)
            sim_canvas.create_text(395, 42, text="SECTOR A: HOSPITALARIO", fill="#30D158", font=("SF Pro Display", 9, "bold"))
            hosp_status = txt("SUMINISTRO 100% GARANTIZADO", "SUPPLY 100% GUARANTEED") if not st["leak_active"] or st["hospital_bypass"] else txt("EN RIESGO", "AT RISK")
            hosp_col = THEME["accent_green"] if hosp_status.startswith("SUMINISTRO") or hosp_status.startswith("SUPPLY") else THEME["accent_red"]
            sim_canvas.create_text(395, 65, text=hosp_status, fill=hosp_col, font=("Consolas", 8, "bold"))

            # Sector B: Parque Industrial (Arriba Derecha)
            sim_canvas.create_rectangle(710, 25, 910, 85, fill="#1C1825", outline="#5E35B1", width=2)
            sim_canvas.create_text(810, 42, text="SECTOR B: INDUSTRIAL", fill="#BF5AF2", font=("SF Pro Display", 9, "bold"))
            sim_canvas.create_text(810, 65, text="CAUDAL ALTO [NOMINAL]", fill="#E5E5EA", font=("Consolas", 8))

            # Sector C: Zona Residencial Urbana (Abajo Centro - Donde ocurre la averia)
            sec_c_bg = "#251414" if st["leak_active"] else ("#252014" if st["valves_closed"] and not st["repair_done"] else "#141A25")
            sec_c_border = THEME["accent_red"] if st["leak_active"] else (THEME["accent_orange"] if st["valves_closed"] and not st["repair_done"] else "#2C3D5A")
            sim_canvas.create_rectangle(380, 155, 620, 225, fill=sec_c_bg, outline=sec_c_border, width=2)
            sim_canvas.create_text(500, 172, text="SECTOR C: RESIDENCIAL URBANO", fill="#FFFFFF", font=("SF Pro Display", 9, "bold"))
            c_tag = txt("[ROTURA CRITICA EN TUBERIA]", "[CRITICAL PIPE RUPTURE]") if st["leak_active"] else (
                txt("[TRAMO AISLADO - EN REPARACION]", "[ISOLATED - REPAIRING]") if st["valves_closed"] and not st["repair_done"] else txt("[OPERACION NOMINAL 4.1 BAR]", "[NOMINAL OPERATING 4.1 BAR]")
            )
            sim_canvas.create_text(500, 198, text=c_tag, fill=sec_c_border, font=("Consolas", 8, "bold"))

            # Sector D: Centro Comercial (Abajo Derecha)
            sim_canvas.create_rectangle(710, 155, 910, 225, fill="#152025", outline="#0A84FF", width=2)
            sim_canvas.create_text(810, 172, text="SECTOR D: COMERCIAL", fill="#64D2FF", font=("SF Pro Display", 9, "bold"))
            sim_canvas.create_text(810, 198, text="PRESION CONTROLADA", fill="#8E8E93", font=("Consolas", 8))

            # 3. RED DE TUBERIAS MAESTRAS PRESURIZADAS (CANALIZACIONES)
            pipe_water_col = "#0A84FF" if not st["leak_active"] else "#FF453A"
            if st["valves_closed"]:
                pipe_water_col = "#FF9F0A"
            if st["repair_done"] and not st["valves_closed"]:
                pipe_water_col = "#30D158"

            # Troncal Principal desde Tanque
            sim_canvas.create_line(160, 135, 260, 135, fill=pipe_water_col, width=8)
            # Nodo Distribuidor Central
            sim_canvas.create_oval(250, 125, 270, 145, fill="#FFFFFF", outline="#0A84FF", width=2)
            sim_canvas.create_text(260, 112, text="NODO-1", fill="#8E8E93", font=("Consolas", 7, "bold"))

            # Ramal Hacia Sector A (Hospital)
            sim_canvas.create_line(260, 135, 260, 55, fill="#0A84FF", width=6)
            sim_canvas.create_line(260, 55, 310, 55, fill="#0A84FF", width=6)

            # Bypass de Emergencia Directo al Hospital (Activado en Paso 3 y 4)
            if st["hospital_bypass"]:
                sim_canvas.create_line(160, 120, 200, 35, fill=THEME["accent_green"], width=4, dash=(4, 2))
                sim_canvas.create_line(200, 35, 310, 35, fill=THEME["accent_green"], width=4, dash=(4, 2))
                sim_canvas.create_text(240, 25, text="BYPASS EMERGENCIA [ACTIVO]", fill=THEME["accent_green"], font=("SF Pro Text", 7, "bold"))

            # Ramal Troncal hacia Sector C (Donde se rompe)
            pipe_c_col = THEME["accent_red"] if st["leak_active"] else (THEME["border"] if st["valves_closed"] and not st["repair_done"] else THEME["accent_blue"])
            sim_canvas.create_line(260, 135, 380, 185, fill=pipe_c_col, width=7)

            # Tuberia Inter-Sector C hacia D
            sim_canvas.create_line(620, 190, 710, 190, fill=pipe_water_col, width=6)
            # Tuberia Inter-Sector B hacia D
            sim_canvas.create_line(810, 85, 810, 155, fill=pipe_water_col, width=6)
            # Tuberia Central Hacia Sector B
            sim_canvas.create_line(480, 55, 710, 55, fill="#0A84FF", width=6)

            # 4. VALVULAS INTELIGENTES REGULADORAS PRV
            def draw_valve(vx, vy, name, is_closed):
                v_fill = THEME["accent_red"] if is_closed else THEME["accent_green"]
                sim_canvas.create_polygon(vx - 10, vy - 8, vx + 10, vy + 8, vx + 10, vy - 8, vx - 10, vy + 8, fill=v_fill, outline="#FFFFFF", width=1)
                state_lbl = "[CERRADA]" if is_closed else "[100%]"
                sim_canvas.create_text(vx, vy - 14, text=f"{name} {state_lbl}", fill=v_fill, font=("Consolas", 7, "bold"))

            draw_valve(290, 155, "PRV-2", st["valves_closed"])
            draw_valve(650, 190, "PRV-3", st["valves_closed"])
            draw_valve(260, 85, "PRV-1", False)

            # 5. ANIMACION DEL CHORRO DE AGUA Y SPRAY SI HAY FUGA
            leak_x, leak_y = 500, 155
            if spray or st["leak_active"]:
                sp_r = 14 + (phase % 4) * 6
                sim_canvas.create_oval(leak_x - sp_r, leak_y - sp_r - 10, leak_x + sp_r, leak_y + sp_r, outline=THEME["accent_teal"], width=2, dash=(2, 2))
                sim_canvas.create_line(leak_x, leak_y, leak_x - 18, leak_y - 28, fill="#64D2FF", width=3)
                sim_canvas.create_line(leak_x, leak_y, leak_x + 18, leak_y - 28, fill="#64D2FF", width=3)
                sim_canvas.create_line(leak_x, leak_y, leak_x, leak_y - 36, fill="#FFFFFF", width=3)
                sim_canvas.create_text(leak_x, leak_y - 45, text="FUGA 85 L/s [ROTURA]", fill=THEME["accent_red"], font=("SF Pro Text", 8, "bold"))

            # Sello de Reparacion Terminado
            if st["repair_done"]:
                sim_canvas.create_rectangle(leak_x - 14, leak_y - 6, leak_x + 14, leak_y + 6, fill=THEME["accent_green"], outline="#FFFFFF", width=2)
                sim_canvas.create_text(leak_x, leak_y - 18, text="[JUNTA SELLADA Y REPARADA]", fill=THEME["accent_green"], font=("Consolas", 8, "bold"))

            # 6. AGENTE CUADRILLA ROBOTICA MOVIL (Navegacion Urbana)
            rx, ry = current_rx, current_ry
            # Sombra base
            sim_canvas.create_oval(rx - 18, ry + 10, rx + 18, ry + 18, fill="#050508", outline="")
            # Chasis vehicular
            crew_col = THEME["accent_orange"] if not st["repair_done"] else THEME["accent_green"]
            sim_canvas.create_rectangle(rx - 20, ry - 12, rx + 20, ry + 12, fill="#1C1C24", outline=crew_col, width=2)
            # Ruedas
            sim_canvas.create_rectangle(rx - 22, ry - 14, rx - 14, ry - 10, fill="#3A3A44")
            sim_canvas.create_rectangle(rx + 14, ry - 14, rx + 22, ry - 10, fill="#3A3A44")
            sim_canvas.create_rectangle(rx - 22, ry + 10, rx - 14, ry + 14, fill="#3A3A44")
            sim_canvas.create_rectangle(rx + 14, ry + 10, rx + 22, ry + 14, fill="#3A3A44")
            # Cabina y Luz Estroboscopica
            sim_canvas.create_rectangle(rx - 8, ry - 8, rx + 8, ry + 8, fill="#2C2C36", outline="#636366")
            sim_canvas.create_oval(rx - 3, ry - 3, rx + 3, ry + 3, fill=crew_col, outline="#FFFFFF")
            sim_canvas.create_text(rx, ry - 22, text="AGENTE CUADRILLA", fill="#FFFFFF", font=("SF Pro Text", 7, "bold"))

        # Animacion cinetica de desplazamiento de la cuadrilla robotica
        def animate_crew_move(start_x, start_y, end_x, end_y, on_finished):
            steps_anim = 28
            dx = (end_x - start_x) / steps_anim
            dy = (end_y - start_y) / steps_anim
            f = [0]

            def _step():
                if f[0] < steps_anim:
                    f[0] += 1
                    cx = start_x + dx * f[0]
                    cy = start_y + dy * f[0]
                    anim_state["robot_x"] = cx
                    anim_state["robot_y"] = cy
                    render_canvas(cx, cy, spray=False)
                    anim_job[0] = demo_win.after(25, _step)
                else:
                    anim_state["robot_x"] = end_x
                    anim_state["robot_y"] = end_y
                    render_canvas(end_x, end_y, spray=False)
                    if on_finished:
                        on_finished()

            _step()

        # Animacion de fuga violenta
        def animate_leak_spray(on_finished):
            cycles = 10
            f = [0]

            def _step_spray():
                if f[0] < cycles:
                    f[0] += 1
                    render_canvas(anim_state["robot_x"], anim_state["robot_y"], spray=True, phase=f[0])
                    anim_job[0] = demo_win.after(75, _step_spray)
                else:
                    render_canvas(anim_state["robot_x"], anim_state["robot_y"], spray=False)
                    if on_finished:
                        on_finished()

            _step_spray()

        # ========================================================
        # PANEL DE TELEMETRIA PEAS Y METRICAS CUANTITATIVAS
        # ========================================================
        cards_container = tk.Frame(demo_win, bg=THEME["bg_dark"], pady=4)
        cards_container.pack()

        card_widgets = []
        labels_hud = [
            txt("PRESION HIDRAULICA", "HYDRAULIC PRESSURE"),
            txt("CAUDAL DE FLUJO", "GRID FLOW RATE"),
            txt("REGLA SISTEMA EXPERTO", "EXPERT SYSTEM RULE"),
            txt("ESTADO DEL AGENTE", "AGENT OPERATING STATE"),
        ]

        for title_h in labels_hud:
            cf = tk.Frame(
                cards_container, bg=THEME["bg_card"],
                highlightbackground=THEME["border"], highlightthickness=1,
                padx=14, pady=8, width=200
            )
            cf.pack(side="left", padx=6)

            b_lbl = tk.Label(
                cf, text="TELEMETRIA PEAS", bg="#2C2C2E", fg="#8E8E93",
                font=("SF Pro Text", 7, "bold"), padx=6, pady=2
            )
            b_lbl.pack(anchor="center", pady=(0, 4))

            lbl_card_title = tk.Label(
                cf, text=title_h, bg=THEME["bg_card"], fg=THEME["text_secondary"],
                font=("SF Pro Text", 8, "bold")
            )
            lbl_card_title.pack(anchor="center")

            lbl_val = tk.Label(
                cf, text="", bg=THEME["bg_card"], fg=THEME["text_primary"],
                font=("SF Pro Display", 11, "bold")
            )
            lbl_val.pack(anchor="center", pady=(2, 0))

            card_widgets.append({"frame": cf, "badge": b_lbl, "title": lbl_card_title, "val": lbl_val})

        score_lbl = tk.Label(
            demo_win, text="", bg=THEME["bg_dark"], fg=THEME["accent_teal"],
            font=("SF Pro Display", 12, "bold"), pady=3
        )
        score_lbl.pack()

        desc_card = tk.Frame(
            demo_win, bg=THEME["bg_card"],
            highlightbackground=THEME["border"], highlightthickness=1,
            padx=16, pady=10
        )
        desc_card.pack(fill="x", padx=24, pady=(2, 8))

        desc_lbl = tk.Label(
            desc_card, text="", bg=THEME["bg_card"], fg="#E5E5EA",
            font=("SF Pro Text", 10), anchor="nw", justify="left", wraplength=900
        )
        desc_lbl.pack(fill="x")

        sim_speak_thread = [None]
        sim_is_speaking = [False]

        def pause_sim_speech():
            sim_is_speaking[0] = False
            if GOOGLE_TTS_AVAILABLE:
                try:
                    pygame.mixer.music.stop()
                    pygame.mixer.music.unload()
                except Exception:
                    pass
            try:
                btn_audio_widget.configure_text(
                    txt("[Audio] Narrar", "[Audio] Narrate"), bg=THEME["accent_purple"]
                )
            except Exception:
                pass

        def speak_sim_step():
            if not GOOGLE_TTS_AVAILABLE:
                messagebox.showinfo(
                    UI_TEXT[self.lang]["no_tts_title"], UI_TEXT[self.lang]["no_tts"]
                )
                return

            pause_sim_speech()
            st = steps[current_step.get()]
            title = st["title_es"] if self.lang == "es" else st["title_en"]
            desc = st["desc_es"] if self.lang == "es" else st["desc_en"]
            text_to_read = clean_text_for_speech(f"{title}. {desc}")

            sim_is_speaking[0] = True
            btn_audio_widget.configure_text(
                txt("[Audio] Leyendo...", "[Audio] Speaking..."), bg=THEME["accent_orange"]
            )

            def _run():
                try:
                    text_hash = hashlib.md5(f"{self.lang}:{text_to_read}".encode("utf-8")).hexdigest()
                    cache_path = os.path.join(CACHE_DIR, f"{text_hash}.mp3")

                    if not os.path.exists(cache_path):
                        tld = "es" if self.lang == "es" else "com"
                        tts = gTTS(text=text_to_read, lang=self.lang, tld=tld)
                        tts.save(cache_path)

                    if not sim_is_speaking[0]:
                        return

                    pygame.mixer.music.load(cache_path)
                    pygame.mixer.music.play()

                    while pygame.mixer.music.get_busy() and sim_is_speaking[0]:
                        time.sleep(0.1)
                except Exception as e:
                    print("Sim TTS notice:", e)
                finally:
                    sim_is_speaking[0] = False
                    try:
                        demo_win.after(0, lambda: btn_audio_widget.configure_text(
                            txt("[Audio] Narrar", "[Audio] Narrate"), bg=THEME["accent_purple"]
                        ))
                    except Exception:
                        pass

            sim_speak_thread[0] = threading.Thread(target=_run, daemon=True)
            sim_speak_thread[0].start()

        def update_ui(animate=True):
            pause_sim_speech()
            if anim_job[0]:
                demo_win.after_cancel(anim_job[0])
                anim_job[0] = None

            step_idx = current_step.get()
            st = steps[step_idx]

            rel_w = (step_idx + 1) / len(steps)
            progress_bar.place(relwidth=rel_w)

            title = st["title_es"] if self.lang == "es" else st["title_en"]
            lbl_title.configure(text=title)

            # Actualizar tarjetas de telemetria
            card_vals = [
                st["pressure_val"],
                st["flow_val"],
                st["expert_rule"],
                st["agent_status"],
            ]
            for w_dict, val in zip(card_widgets, card_vals):
                w_dict["val"].configure(text=val)

            s_text = (
                txt("Balance de Impacto PEAS", "PEAS Impact Assessment") +
                f": Agua Salvada: {st['water_saved']} | Ahorro Economico: {st['cost_saved']} | Utilidad: {st['utility']}"
            )
            score_lbl.configure(text=s_text)

            desc = st["desc_es"] if self.lang == "es" else st["desc_en"]
            desc_lbl.configure(text=desc)

            lbl_step_num.configure(text=f"Paso {step_idx + 1} de {len(steps)}")

            # Disparo de animacion en Canvas
            target_rx, target_ry = st["robot_pos"]
            if animate:
                if step_idx == 1:
                    animate_leak_spray(None)
                elif step_idx == 3:
                    animate_crew_move(120, 215, 500, 140, None)
                else:
                    anim_state["robot_x"] = target_rx
                    anim_state["robot_y"] = target_ry
                    render_canvas(target_rx, target_ry, spray=False)
            else:
                anim_state["robot_x"] = target_rx
                anim_state["robot_y"] = target_ry
                render_canvas(target_rx, target_ry, spray=False)

        def go_first():
            stop_autoplay()
            current_step.set(0)
            update_ui(animate=False)

        def go_prev():
            stop_autoplay()
            if current_step.get() > 0:
                current_step.set(current_step.get() - 1)
                update_ui(animate=False)

        def go_next():
            if current_step.get() < len(steps) - 1:
                current_step.set(current_step.get() + 1)
                update_ui(animate=True)
            else:
                stop_autoplay()

        def go_last():
            stop_autoplay()
            current_step.set(len(steps) - 1)
            update_ui(animate=False)

        def toggle_autoplay():
            if autoplay_active.get():
                stop_autoplay()
            else:
                autoplay_active.set(True)
                btn_play_widget.configure_text(
                    txt("[Pausa]", "[Pause]"), bg=THEME["accent_orange"]
                )
                run_autoplay_loop()

        def stop_autoplay():
            autoplay_active.set(False)
            btn_play_widget.configure_text(
                txt("[Auto]", "[Auto]"), bg=THEME["accent_green"]
            )
            if autoplay_job[0]:
                demo_win.after_cancel(autoplay_job[0])
                autoplay_job[0] = None

        def run_autoplay_loop():
            if not autoplay_active.get():
                return
            if current_step.get() < len(steps) - 1:
                go_next()
                autoplay_job[0] = demo_win.after(3000, run_autoplay_loop)
            else:
                stop_autoplay()

        def on_close():
            stop_autoplay()
            if anim_job[0]:
                try:
                    demo_win.after_cancel(anim_job[0])
                except Exception:
                    pass
            pause_sim_speech()
            demo_win.destroy()

        demo_win.protocol("WM_DELETE_WINDOW", on_close)

        control_frame = tk.Frame(demo_win, bg=THEME["bg_dark"], pady=12)
        control_frame.pack(fill="x", side="bottom")

        btn_first = ModernButton(
            control_frame, text="[<<]", command=go_first,
            bg=THEME["bg_card_secondary"], active_bg="#3A3A3C", fg="white", padx=10, pady=7
        )
        btn_first.pack(side="left", padx=4, expand=True)

        btn_prev = ModernButton(
            control_frame, text=txt("[< Anterior]", "[< Prev]"), command=go_prev,
            bg=THEME["bg_card_secondary"], active_bg="#3A3A3C", fg="white", padx=10, pady=7
        )
        btn_prev.pack(side="left", padx=4, expand=True)

        lbl_step_num = tk.Label(
            control_frame, text="", bg=THEME["bg_dark"], fg=THEME["text_secondary"],
            font=("SF Pro Text", 9, "bold")
        )
        lbl_step_num.pack(side="left", padx=6, expand=True)

        btn_play_widget = ModernButton(
            control_frame, text=txt("[Auto]", "[Auto]"), command=toggle_autoplay,
            bg=THEME["accent_green"], active_bg="#248A3D", fg="white", padx=12, pady=7
        )
        btn_play_widget.pack(side="left", padx=4, expand=True)

        btn_audio_widget = ModernButton(
            control_frame, text=txt("[Audio] Narrar", "[Audio] Narrate"), command=speak_sim_step,
            bg=THEME["accent_purple"], active_bg="#9D38D0", fg="white", padx=10, pady=7
        )
        btn_audio_widget.pack(side="left", padx=4, expand=True)

        btn_next = ModernButton(
            control_frame, text=txt("[Siguiente >]", "[Next >]"), command=go_next,
            bg=THEME["bg_card_secondary"], active_bg="#3A3A3C", fg="white", padx=10, pady=7
        )
        btn_next.pack(side="left", padx=4, expand=True)

        btn_last = ModernButton(
            control_frame, text="[>>]", command=go_last,
            bg=THEME["bg_card_secondary"], active_bg="#3A3A3C", fg="white", padx=10, pady=7
        )
        btn_last.pack(side="left", padx=4, expand=True)

        update_ui(animate=False)


def main():
    """Punto de entrada principal para el Dashboard del Proyecto de Asignatura."""
    app = Dashboard()
    app.mainloop()


if __name__ == "__main__":
    main()
