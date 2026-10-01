# SILM — Sistema Integral de Laboratorios de Manufactura

Sistema integral para la gestión, costos e inventario en laboratorios de manufactura aditiva e impresión 3D (Voxelcost3D Flutter).

## 🚀 Características Principales

- **Gestión de Impresiones 3D**: Registro detallado de piezas, tiempos de impresión, cotización de costos, consumo de energía y filamento.
- **Inventario Inteligente de Materiales**:
  - Control de bobinas por material (PLA, PETG, ABS, TPU, Resina, etc.), color, marca y acabado.
  - Registro de tara de bobinas y cálculo exacto de filamento neto mediante báscula.
  - Alertas automáticas de bajo stock y bobinas agotadas.
  - Ajustes rápidos de consumo ($\pm 50\text{ g}$).
- **Catálogos y Parámetros Técnicos**: Temperaturas de boquilla/cama, densidades, diámetros ($1.75\text{ mm}$, $2.85\text{ mm}$) y costos por kilogramo.
- **Analítica y Reportes**: Exportación de datos de consumos, historiales y reportes técnicos.
- **Persistencia Local**: Base de datos SQLite integrada con alto rendimiento y funcionamiento offline.

---

## 📁 Estructura del Repositorio

```text
├── NOTASS.txt                  # Requerimientos y notas de desarrollo
├── .gitignore                  # Configuración de exclusión para control de versiones
└── Voxelcost3D_Flutter/        # Aplicación multiplataforma en Flutter
    ├── lib/
    │   ├── main.dart           # Entrada principal y autenticación
    │   ├── screens.dart        # Vistas de usuario e interfaz gráfica
    │   ├── models.dart         # Modelos de dominio y estructuras de datos
    │   ├── database.dart       # Conexión y operaciones SQLite
    │   ├── controllers.dart    # Lógica de negocio (ViewModels)
    │   └── theme.dart          # Paleta de colores y diseño visual
    ├── pubspec.yaml            # Dependencias del proyecto
    └── ...
```

---

## 🛠️ Requisitos e Instalación

1. **Requisitos**:
   - Flutter SDK $\ge 3.3.0$
   - Dart SDK
   - Linux / Windows / Android SDK según la plataforma objetivo

2. **Ejecución del proyecto**:
   ```bash
   cd Voxelcost3D_Flutter
   flutter pub get
   flutter run
   ```

---

## 👤 Autor y Licencia
Desarrollado para la gestión integral de laboratorios de manufactura aditiva 3D.
