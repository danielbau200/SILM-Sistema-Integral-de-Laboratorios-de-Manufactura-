-- ============================================================================
-- SILM: Sistema Integral de Laboratorios de Manufactura
-- Base de Datos Relacional PostgreSQL (Conforme a DIAGRAMA_ER_SILM.drawio)
-- ============================================================================
-- Compatible con: PostgreSQL 14, 15, 16+ y pgAdmin 4
-- Codificación: UTF-8
-- ============================================================================

-- Habilitar extensiones requeridas para identificadores UUID y funciones criptográficas
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. TIPOS ENUMERADOS (ENUMS DEL DICCIONARIO TÉCNICO SILM)
-- ============================================================================

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_usuario_enum') THEN
        CREATE TYPE tipo_usuario_enum AS ENUM (
            'estudiante',
            'docente',
            'administrador',
            'operador',
            'tesista'
        );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'rol_usuario_enum') THEN
        CREATE TYPE rol_usuario_enum AS ENUM (
            'super_admin',
            'jefe_laboratorio',
            'auxiliar_tecnico',
            'becario'
        );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_bobina_enum') THEN
        CREATE TYPE estado_bobina_enum AS ENUM (
            'sellado',
            'en_uso',
            'bajo_stock',
            'agotado',
            'merma'
        );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tecnologia_3d_enum') THEN
        CREATE TYPE tecnologia_3d_enum AS ENUM (
            'FDM',
            'SLA',
            'MSLA',
            'SLS'
        );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_impresora_enum') THEN
        CREATE TYPE estado_impresora_enum AS ENUM (
            'disponible',
            'imprimiendo',
            'mantenimiento',
            'fuera_servicio'
        );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_mantenimiento_enum') THEN
        CREATE TYPE tipo_mantenimiento_enum AS ENUM (
            'preventivo',
            'correctivo',
            'cambio_boquilla',
            'lubricacion_ejes',
            'calibracion_cama'
        );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_solicitante_enum') THEN
        CREATE TYPE tipo_solicitante_enum AS ENUM (
            'Estudiante',
            'Docente',
            'Posgrado',
            'Externo',
            'Otro'
        );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'categoria_pieza_enum') THEN
        CREATE TYPE categoria_pieza_enum AS ENUM (
            'Prototipo',
            'Pieza Funcional',
            'Miniatura',
            'Molde',
            'Soporte',
            'Otro'
        );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'categoria_consumible_enum') THEN
        CREATE TYPE categoria_consumible_enum AS ENUM (
            'Limpieza_Quimico',
            'Lubricante',
            'Refaccion_Mecanica',
            'Herramienta'
        );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'nivel_urgencia_enum') THEN
        CREATE TYPE nivel_urgencia_enum AS ENUM (
            'Rojo',
            'Amarillo',
            'Verde'
        );
    END IF;
END $$;

-- ============================================================================
-- 2. TABLAS DEL SISTEMA (SEGURIDAD, CONFIGURACIÓN Y AUDITORÍA)
-- ============================================================================

-- Parámetros institucionales globales del laboratorio
CREATE TABLE IF NOT EXISTS config_institucional (
    id SERIAL PRIMARY KEY,
    nombre_laboratorio VARCHAR(120) NOT NULL DEFAULT 'Laboratorio de Manufactura Avanzada SILM',
    tarifa_kwh_default NUMERIC(8,4) NOT NULL DEFAULT 2.8500,
    moneda_local VARCHAR(10) NOT NULL DEFAULT 'MXN',
    actualizado_el TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Catálogo de Roles de Acceso
CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    nombre rol_usuario_enum NOT NULL UNIQUE,
    descripcion TEXT,
    esta_activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_el TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Usuarios del Sistema (Operadores, Docentes, Administradores, Becarios)
CREATE TABLE IF NOT EXISTS usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(120) NOT NULL UNIQUE,
    username VARCHAR(60) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    nombre_completo VARCHAR(150) NOT NULL,
    numero_identificacion VARCHAR(50), -- No. de control o No. de empleado
    tipo_usuario tipo_usuario_enum NOT NULL DEFAULT 'operador',
    telefono VARCHAR(25),
    esta_activo BOOLEAN NOT NULL DEFAULT TRUE,
    ultimo_acceso TIMESTAMPTZ,
    creado_el TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_el TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Tabla Intermedia Muchos a Muchos: Asignación de Roles por Usuario
CREATE TABLE IF NOT EXISTS usuarios_roles (
    id_usuario UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    id_rol INT NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
    asignado_el TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_usuario, id_rol)
);

-- Auditoría de Acciones y Trazabilidad Transaccional
CREATE TABLE IF NOT EXISTS auditoria_logs (
    id BIGSERIAL PRIMARY KEY,
    id_usuario UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    modulo_afectado VARCHAR(60) NOT NULL,
    accion VARCHAR(80) NOT NULL,
    registro_id VARCHAR(100),
    datos_previos_json JSONB,
    datos_nuevos_json JSONB,
    timestamp_accion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 3. CATÁLOGOS TÉCNICOS DE MATERIALES, COLORES, MARCAS Y ACABADOS
-- ============================================================================

-- Catálogo de Tipos de Material (Polímeros Termoplásticos / Resinas)
CREATE TABLE IF NOT EXISTS tipos_material (
    id SERIAL PRIMARY KEY,
    nombre_tecnico VARCHAR(60) NOT NULL UNIQUE,
    densidad_g_cm3 NUMERIC(6,3) NOT NULL DEFAULT 1.240,
    temperatura_boquilla_rec INT DEFAULT 210,
    temperatura_cama_rec INT DEFAULT 60,
    descripcion TEXT
);

-- Catálogo Maestro de Colores de Filamento
CREATE TABLE IF NOT EXISTS colores (
    id SERIAL PRIMARY KEY,
    nombre_color VARCHAR(60) NOT NULL UNIQUE,
    codigo_hex VARCHAR(10) NOT NULL DEFAULT '#111111',
    esta_activo BOOLEAN NOT NULL DEFAULT TRUE
);

-- Catálogo de Fabricantes / Marcas de Filamento
CREATE TABLE IF NOT EXISTS marcas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL UNIQUE,
    pais_origen VARCHAR(60),
    esta_activo BOOLEAN NOT NULL DEFAULT TRUE
);

-- Catálogo de Acabados Especiales
CREATE TABLE IF NOT EXISTS acabados (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(60) NOT NULL UNIQUE,
    descripcion VARCHAR(150)
);

-- Catálogo de Consumibles e Insumos Operativos del Laboratorio
CREATE TABLE IF NOT EXISTS consumibles_catalogo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(120) NOT NULL UNIQUE,
    categoria categoria_consumible_enum NOT NULL,
    unidad_medida VARCHAR(30) NOT NULL DEFAULT 'pieza',
    stock_actual NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    stock_minimo_alerta NUMERIC(10,2) NOT NULL DEFAULT 2.00,
    costo_referencia NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    ubicacion_almacen VARCHAR(80),
    esta_activo BOOLEAN NOT NULL DEFAULT TRUE,
    actualizado_el TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 4. INVENTARIO DE BOBINAS (CMI - CONTROL DE MATERIAL INDIVIDUAL)
-- ============================================================================

CREATE TABLE IF NOT EXISTS bobinas_inventario (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo_barras_qr VARCHAR(100) UNIQUE,
    id_tipo_material INT NOT NULL REFERENCES tipos_material(id) ON DELETE RESTRICT,
    id_color INT NOT NULL REFERENCES colores(id) ON DELETE RESTRICT,
    id_marca INT REFERENCES marcas(id) ON DELETE SET NULL,
    id_acabado INT REFERENCES acabados(id) ON DELETE SET NULL,
    diametro_mm NUMERIC(4,2) NOT NULL DEFAULT 1.75,
    peso_inicial_g NUMERIC(10,2) NOT NULL DEFAULT 1000.00,
    stock_actual_g NUMERIC(10,2) NOT NULL DEFAULT 1000.00,
    tara_carrete_g NUMERIC(8,2) NOT NULL DEFAULT 220.00,
    costo_bobina NUMERIC(10,2) NOT NULL DEFAULT 350.00,
    costo_por_gramo NUMERIC(10,4) GENERATED ALWAYS AS (
        CASE WHEN peso_inicial_g > 0 THEN costo_bobina / peso_inicial_g ELSE 0 END
    ) STORED,
    ubicacion_almacen VARCHAR(80) DEFAULT 'Estante A1',
    temperatura_boquilla INT,
    temperatura_cama INT,
    estado_bobina estado_bobina_enum NOT NULL DEFAULT 'sellado',
    en_uso BOOLEAN NOT NULL DEFAULT FALSE,
    notas TEXT,
    creado_el TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_stock_positivo CHECK (stock_actual_g >= 0)
);

-- Historial y Kardex de Ajustes / Pesaje de Bobinas
CREATE TABLE IF NOT EXISTS historial_ajustes_bobina (
    id BIGSERIAL PRIMARY KEY,
    id_bobina UUID NOT NULL REFERENCES bobinas_inventario(id) ON DELETE CASCADE,
    id_usuario UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    delta_gramos NUMERIC(10,2) NOT NULL, -- Negativo si es consumo, positivo si es recarga/ajuste báscula
    stock_anterior_g NUMERIC(10,2) NOT NULL,
    stock_nuevo_g NUMERIC(10,2) NOT NULL,
    motivo VARCHAR(120) NOT NULL,
    id_referencia_orden VARCHAR(100), -- Folio de impresión o pedido asociado
    creado_el TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 5. PARQUE DE MAQUINARIA (IMPRESORAS 3D Y MANTENIMIENTO)
-- ============================================================================

CREATE TABLE IF NOT EXISTS impresoras (
    id SERIAL PRIMARY KEY,
    nombre_identificador VARCHAR(100) NOT NULL UNIQUE,
    marca VARCHAR(80) NOT NULL,
    modelo VARCHAR(80) NOT NULL,
    tecnologia tecnologia_3d_enum NOT NULL DEFAULT 'FDM',
    volumen_xyz VARCHAR(50) DEFAULT '220x220x250 mm',
    potencia_watts INT NOT NULL DEFAULT 350,
    tarifa_kwh NUMERIC(8,4) NOT NULL DEFAULT 2.8500,
    horas_acumuladas NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    horas_para_mantenimiento INT NOT NULL DEFAULT 250,
    estado estado_impresora_enum NOT NULL DEFAULT 'disponible',
    fecha_adquisicion DATE DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS bitacora_mantenimiento (
    id BIGSERIAL PRIMARY KEY,
    id_impresora INT NOT NULL REFERENCES impresoras(id) ON DELETE CASCADE,
    id_tecnico UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    tipo_mantenimiento tipo_mantenimiento_enum NOT NULL,
    descripcion_trabajo TEXT NOT NULL,
    piezas_reemplazadas TEXT,
    costo_mantenimiento NUMERIC(10,2) DEFAULT 0.00,
    horas_en_mantenimiento INT DEFAULT 1,
    fecha_servicio TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    proximo_servicio_horas INT
);

-- ============================================================================
-- 6. PRODUCCIÓN Y ÓRDENES DE IMPRESIÓN 3D
-- ============================================================================

-- Proyectos y Solicitantes Institucionales
CREATE TABLE IF NOT EXISTS proyectos_solicitantes (
    id SERIAL PRIMARY KEY,
    codigo_proyecto VARCHAR(50) UNIQUE,
    nombre_proyecto VARCHAR(150) NOT NULL,
    solicitante_nombre VARCHAR(120) NOT NULL,
    solicitante_tipo tipo_solicitante_enum NOT NULL DEFAULT 'Estudiante',
    departamento_carrera VARCHAR(100),
    correo_contacto VARCHAR(120),
    telefono_contacto VARCHAR(25),
    creado_el TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Registro Maestro de Órdenes de Impresión
CREATE TABLE IF NOT EXISTS ordenes_impresion (
    id SERIAL PRIMARY KEY,
    folio_orden VARCHAR(50) NOT NULL UNIQUE,
    id_proyecto INT REFERENCES proyectos_solicitantes(id) ON DELETE SET NULL,
    id_impresora INT REFERENCES impresoras(id) ON DELETE SET NULL,
    id_operador UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    nombre_pieza VARCHAR(150) NOT NULL,
    categoria_pieza categoria_pieza_enum NOT NULL DEFAULT 'Prototipo',
    cantidad_piezas INT NOT NULL DEFAULT 1 CHECK (cantidad_piezas >= 1),
    tiempo_impresion_texto VARCHAR(40), -- Ej: '3h 45m'
    minutos_totales INT NOT NULL DEFAULT 0,
    numero_impresoras_usadas INT NOT NULL DEFAULT 1,
    tiene_combinacion_material BOOLEAN NOT NULL DEFAULT FALSE,
    costo_energia NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    costo_material NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    costo_total_estimado NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    fecha_impresion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notas TEXT
);

-- Desglose Atómico de Filamento por Impresión
CREATE TABLE IF NOT EXISTS detalle_material_impresion (
    id BIGSERIAL PRIMARY KEY,
    id_orden_impresion INT NOT NULL REFERENCES ordenes_impresion(id) ON DELETE CASCADE,
    id_bobina UUID REFERENCES bobinas_inventario(id) ON DELETE RESTRICT,
    gramos_unitarios NUMERIC(8,2) NOT NULL CHECK (gramos_unitarios > 0),
    gramos_totales_lote NUMERIC(10,2) NOT NULL CHECK (gramos_totales_lote > 0),
    costo_linea NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    se_desconto_inventario BOOLEAN NOT NULL DEFAULT TRUE
);

-- ============================================================================
-- 7. REQUISICIONES Y PEDIDOS DE MATERIALES / CONSUMIBLES
-- ============================================================================

CREATE TABLE IF NOT EXISTS pedidos_materiales (
    id VARCHAR(60) PRIMARY KEY, -- ID alfanumérico generado (ej. ORD-2026-001)
    id_usuario_solicita UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    enlace_pagina_web TEXT,
    estado_urgencia nivel_urgencia_enum NOT NULL DEFAULT 'Verde',
    tipo_urgencia VARCHAR(80),
    detalle_urgencia TEXT,
    es_solo_consumibles BOOLEAN NOT NULL DEFAULT FALSE,
    costo_total_pedido NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    fecha_pedido TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    creado_el TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS items_pedido_filamento (
    id BIGSERIAL PRIMARY KEY,
    id_pedido VARCHAR(60) NOT NULL REFERENCES pedidos_materiales(id) ON DELETE CASCADE,
    id_tipo_material INT REFERENCES tipos_material(id) ON DELETE SET NULL,
    color_nombre VARCHAR(60) NOT NULL,
    peso_carrete_g NUMERIC(10,2) NOT NULL DEFAULT 1000.00,
    costo_unitario NUMERIC(10,2) NOT NULL DEFAULT 0.00
);

CREATE TABLE IF NOT EXISTS items_pedido_consumible (
    id BIGSERIAL PRIMARY KEY,
    id_pedido VARCHAR(60) NOT NULL REFERENCES pedidos_materiales(id) ON DELETE CASCADE,
    id_consumible UUID REFERENCES consumibles_catalogo(id) ON DELETE SET NULL,
    nombre_insumo VARCHAR(120) NOT NULL,
    cantidad_texto VARCHAR(50) NOT NULL DEFAULT '1 unidad',
    enlace_especifico TEXT,
    costo_unitario NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    estado_urgencia nivel_urgencia_enum NOT NULL DEFAULT 'Verde'
);

-- ============================================================================
-- 8. ÍNDICES DE RENDIMIENTO (B-TREE & GIN PARA CONSULTAS RÁPIDAS)
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_usuarios_email ON usuarios(email);
CREATE INDEX IF NOT EXISTS idx_usuarios_username ON usuarios(username);
CREATE INDEX IF NOT EXISTS idx_bobinas_material ON bobinas_inventario(id_tipo_material);
CREATE INDEX IF NOT EXISTS idx_bobinas_color ON bobinas_inventario(id_color);
CREATE INDEX IF NOT EXISTS idx_bobinas_estado ON bobinas_inventario(estado_bobina);
CREATE INDEX IF NOT EXISTS idx_bobinas_qr ON bobinas_inventario(codigo_barras_qr);
CREATE INDEX IF NOT EXISTS idx_ordenes_fecha ON ordenes_impresion(fecha_impresion);
CREATE INDEX IF NOT EXISTS idx_ordenes_proyecto ON ordenes_impresion(id_proyecto);
CREATE INDEX IF NOT EXISTS idx_ordenes_impresora ON ordenes_impresion(id_impresora);
CREATE INDEX IF NOT EXISTS idx_detalle_orden ON detalle_material_impresion(id_orden_impresion);
CREATE INDEX IF NOT EXISTS idx_detalle_bobina ON detalle_material_impresion(id_bobina);
CREATE INDEX IF NOT EXISTS idx_pedidos_fecha ON pedidos_materiales(fecha_pedido);
CREATE INDEX IF NOT EXISTS idx_pedidos_urgencia ON pedidos_materiales(estado_urgencia);
CREATE INDEX IF NOT EXISTS idx_auditoria_timestamp ON auditoria_logs(timestamp_accion);
CREATE INDEX IF NOT EXISTS idx_auditoria_usuario ON auditoria_logs(id_usuario);
CREATE INDEX IF NOT EXISTS idx_auditoria_json ON auditoria_logs USING GIN (datos_nuevos_json);

-- ============================================================================
-- 9. TRIGGERS Y FUNCIONES AUTOMATIZADAS DE INTEGRIDAD
-- ============================================================================

-- A. Actualización automática de marca de tiempo (actualizado_el)
CREATE OR REPLACE FUNCTION fn_actualizar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_el = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_actualizar_usuarios_timestamp ON usuarios;
CREATE TRIGGER trg_actualizar_usuarios_timestamp
BEFORE UPDATE ON usuarios
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_timestamp();

DROP TRIGGER IF EXISTS trg_actualizar_consumibles_timestamp ON consumibles_catalogo;
CREATE TRIGGER trg_actualizar_consumibles_timestamp
BEFORE UPDATE ON consumibles_catalogo
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_timestamp();

-- B. Descuento atómico de filamento en bobina al insertar detalle de impresión
CREATE OR REPLACE FUNCTION fn_descontar_bobina_impresion()
RETURNS TRIGGER AS $$
DECLARE
    v_stock_actual NUMERIC(10,2);
    v_nuevo_stock NUMERIC(10,2);
    v_folio VARCHAR(50);
BEGIN
    IF NEW.id_bobina IS NOT NULL AND NEW.se_desconto_inventario = TRUE THEN
        SELECT stock_actual_g INTO v_stock_actual
        FROM bobinas_inventario
        WHERE id = NEW.id_bobina
        FOR UPDATE;

        IF FOUND THEN
            v_nuevo_stock := GREATEST(0.00, v_stock_actual - NEW.gramos_totales_lote);

            -- Obtener folio de la orden
            SELECT folio_orden INTO v_folio FROM ordenes_impresion WHERE id = NEW.id_orden_impresion;

            -- Registrar en el Kardex / Historial de Ajustes
            INSERT INTO historial_ajustes_bobina (
                id_bobina,
                delta_gramos,
                stock_anterior_g,
                stock_nuevo_g,
                motivo,
                id_referencia_orden
            ) VALUES (
                NEW.id_bobina,
                -NEW.gramos_totales_lote,
                v_stock_actual,
                v_nuevo_stock,
                'Consumo automático por impresión 3D',
                COALESCE(v_folio, 'Orden #' || NEW.id_orden_impresion::text)
            );

            -- Actualizar bobina y su estado
            UPDATE bobinas_inventario
            SET stock_actual_g = v_nuevo_stock,
                estado_bobina = CASE
                    WHEN v_nuevo_stock <= 0 THEN 'agotado'::estado_bobina_enum
                    WHEN v_nuevo_stock <= 100 THEN 'bajo_stock'::estado_bobina_enum
                    ELSE 'en_uso'::estado_bobina_enum
                END,
                en_uso = (v_nuevo_stock > 0)
            WHERE id = NEW.id_bobina;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_descontar_bobina_impresion ON detalle_material_impresion;
CREATE TRIGGER trg_descontar_bobina_impresion
AFTER INSERT ON detalle_material_impresion
FOR EACH ROW EXECUTE FUNCTION fn_descontar_bobina_impresion();

-- C. Acumulación automática de horas de trabajo en impresora
CREATE OR REPLACE FUNCTION fn_acumular_horas_impresora()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.id_impresora IS NOT NULL AND NEW.minutos_totales > 0 THEN
        UPDATE impresoras
        SET horas_acumuladas = horas_acumuladas + ROUND((NEW.minutos_totales::numeric / 60.0), 2)
        WHERE id = NEW.id_impresora;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_acumular_horas_impresora ON ordenes_impresion;
CREATE TRIGGER trg_acumular_horas_impresora
AFTER INSERT ON ordenes_impresion
FOR EACH ROW EXECUTE FUNCTION fn_acumular_horas_impresora();

-- ============================================================================
-- 10. VISTAS ANALÍTICAS PARA REPORTES Y DASHBOARD SILM
-- ============================================================================

-- Vista 1: Resumen completo de bobinas de filamento con semáforo de inventario
CREATE OR REPLACE VIEW v_resumen_inventario_bobinas AS
SELECT 
    b.id AS id_bobina,
    b.codigo_barras_qr,
    tm.nombre_tecnico AS material,
    c.nombre_color AS color,
    c.codigo_hex AS color_hex,
    COALESCE(m.nombre, 'Genérico') AS marca,
    COALESCE(a.nombre, 'Estándar') AS acabado,
    b.diametro_mm,
    b.peso_inicial_g,
    b.stock_actual_g,
    b.tara_carrete_g,
    ROUND(b.costo_bobina, 2) AS costo_bobina,
    ROUND(b.costo_por_gramo, 4) AS costo_por_gramo,
    b.estado_bobina,
    b.en_uso,
    b.ubicacion_almacen,
    CASE 
        WHEN b.stock_actual_g <= 0 THEN 'Agotado (0g)'
        WHEN b.stock_actual_g <= 100 THEN 'Crítico / Bajo Stock'
        WHEN b.stock_actual_g <= 300 THEN 'Stock Regular'
        ELSE 'Stock Óptimo'
    END AS estado_semaforo
FROM bobinas_inventario b
JOIN tipos_material tm ON b.id_tipo_material = tm.id
JOIN colores c ON b.id_color = c.id
LEFT JOIN marcas m ON b.id_marca = m.id
LEFT JOIN acabados a ON b.id_acabado = a.id;

-- Vista 2: Análisis Mensual de Producción y Costos
CREATE OR REPLACE VIEW v_analisis_produccion_mensual AS
SELECT 
    TO_CHAR(o.fecha_impresion, 'YYYY-MM') AS periodo_mes,
    COUNT(o.id) AS total_ordenes,
    SUM(o.cantidad_piezas) AS total_piezas_fabricadas,
    ROUND(SUM(o.minutos_totales)::numeric / 60.0, 2) AS total_horas_maquina,
    ROUND(SUM(d.gramos_totales_lote), 2) AS gramos_material_consumido,
    ROUND(SUM(o.costo_energia), 2) AS costo_total_energia,
    ROUND(SUM(o.costo_material), 2) AS costo_total_material,
    ROUND(SUM(o.costo_total_estimado), 2) AS costo_total_produccion
FROM ordenes_impresion o
LEFT JOIN detalle_material_impresion d ON o.id = d.id_orden_impresion
GROUP BY TO_CHAR(o.fecha_impresion, 'YYYY-MM')
ORDER BY periodo_mes DESC;

-- Vista 3: Monitoreo de Mantenimiento Preventivo de Impresoras
CREATE OR REPLACE VIEW v_alertas_mantenimiento_impresoras AS
SELECT 
    i.id AS id_impresora,
    i.nombre_identificador,
    i.marca,
    i.modelo,
    i.horas_acumuladas,
    i.horas_para_mantenimiento,
    ROUND(i.horas_para_mantenimiento - i.horas_acumuladas, 2) AS horas_restantes_servicio,
    CASE 
        WHEN i.horas_acumuladas >= i.horas_para_mantenimiento THEN 'Mantenimiento Urgente Requerido'
        WHEN i.horas_acumuladas >= (i.horas_para_mantenimiento * 0.85) THEN 'Próximo a Servicio'
        ELSE 'Operativa Normal'
    END AS estado_mantenimiento,
    i.estado AS estado_operativo
FROM impresoras i;

-- Vista 4: Requisiciones de Compra y Pedidos Clasificados por Urgencia
CREATE OR REPLACE VIEW v_pedidos_pendientes_urgencia AS
SELECT 
    p.id AS id_pedido,
    p.estado_urgencia,
    p.tipo_urgencia,
    p.detalle_urgencia,
    p.es_solo_consumibles,
    p.costo_total_pedido,
    p.fecha_pedido,
    u.nombre_completo AS solicitante,
    COUNT(DISTINCT f.id) AS items_filamento,
    COUNT(DISTINCT c.id) AS items_consumibles
FROM pedidos_materiales p
LEFT JOIN usuarios u ON p.id_usuario_solicita = u.id
LEFT JOIN items_pedido_filamento f ON p.id = f.id_pedido
LEFT JOIN items_pedido_consumible c ON p.id = c.id_pedido
GROUP BY p.id, p.estado_urgencia, p.tipo_urgencia, p.detalle_urgencia, p.es_solo_consumibles, p.costo_total_pedido, p.fecha_pedido, u.nombre_completo
ORDER BY 
    CASE p.estado_urgencia 
        WHEN 'Rojo' THEN 1 
        WHEN 'Amarillo' THEN 2 
        WHEN 'Verde' THEN 3 
    END, 
    p.fecha_pedido DESC;

-- ============================================================================
-- 11. DATOS SEMILLA INICIALES (SEED DATA REALISTA PARA EL LABORATORIO)
-- ============================================================================

-- Configuración Institucional
INSERT INTO config_institucional (nombre_laboratorio, tarifa_kwh_default, moneda_local)
VALUES ('Laboratorio de Impresión 3D y Manufactura Aditiva (SILM)', 2.8500, 'MXN')
ON CONFLICT DO NOTHING;

-- Roles del Sistema
INSERT INTO roles (nombre, descripcion) VALUES
('super_admin', 'Control total administrativo, auditoría y configuraciones'),
('jefe_laboratorio', 'Supervisión de inventarios, asignación y mantenimiento de impresoras'),
('auxiliar_tecnico', 'Operación diaria, registro de piezas, pesaje y recepción de pedidos'),
('becario', 'Apoyo operativo básico y monitoreo de impresión')
ON CONFLICT (nombre) DO NOTHING;

-- Usuario Administrador por Defecto (admin / admin123)
-- Hash BCrypt para 'admin123'
INSERT INTO usuarios (id, email, username, password_hash, nombre_completo, numero_identificacion, tipo_usuario)
VALUES (
    'a0000000-0000-0000-0000-000000000001',
    'admin@silm.com',
    'admin',
    '$2a$12$e8Y50j2uMvh.5Uj7N.W58exO21bOQ2V.Hq8gA32Gph9Wc4Xz9r1a.', -- BCrypt admin123
    'Ing. José Daniel (Administrador SILM)',
    'TEC-2026-001',
    'administrador'
)
ON CONFLICT (email) DO NOTHING;

-- Asignar rol super_admin a admin
INSERT INTO usuarios_roles (id_usuario, id_rol)
SELECT 'a0000000-0000-0000-0000-000000000001', id FROM roles WHERE nombre = 'super_admin'
ON CONFLICT DO NOTHING;

-- Catálogo de Tipos de Materiales Industriales
INSERT INTO tipos_material (nombre_tecnico, densidad_g_cm3, temperatura_boquilla_rec, temperatura_cama_rec, descripcion) VALUES
('PLA', 1.240, 205, 60, 'Ácido poliláctico biodegradable, excelente acabado visual y fácil impresión.'),
('PETG', 1.270, 235, 75, 'Polietileno tereftalato glicol, alta resistencia química e impacto mecánico.'),
('ABS', 1.040, 245, 95, 'Acrilonitrilo butadieno estireno, piezas mecánicas duraderas y resistentes a temperatura.'),
('TPU', 1.210, 220, 50, 'Poliuretano termoplástico flexible, dureza Shore 95A.'),
('ASA', 1.070, 250, 100, 'Resistente a rayos UV e intemperie exterior.'),
('Nylon (PA)', 1.140, 260, 80, 'Poliamida con alta tenacidad y resistencia a la abrasión.'),
('PC (Policarbonato)', 1.200, 270, 105, 'Grado de ingeniería con máxima resistencia al impacto y rigidez térmica.'),
('Resina Estándar UV', 1.110, 0, 0, 'Fotopolímero para tecnología SLA/MSLA a 405nm.')
ON CONFLICT (nombre_tecnico) DO NOTHING;

-- Catálogo Oficial de Colores SILM
INSERT INTO colores (nombre_color, codigo_hex) VALUES
('Blanco', '#FFFFFF'),
('Negro', '#111111'),
('Gris', '#808080'),
('Silver', '#C0C0C0'),
('Rojo', '#E53935'),
('Naranja', '#FB8C00'),
('Amarillo', '#FDD835'),
('Verde', '#43A047'),
('Verde lima', '#C0CA33'),
('Azul', '#1E88E5'),
('Azul marino', '#1A237E'),
('Celeste', '#4FC3F7'),
('Petrol', '#2E8B98'),
('Morado', '#8E24AA'),
('Rosa', '#EC407A'),
('Café', '#6D4C41'),
('Beige', '#D7C4A3'),
('Oro', '#D4AF37'),
('Marrón Van Dyke', '#3A1E11'),
('Transparente', '#00000000')
ON CONFLICT (nombre_color) DO NOTHING;

-- Catálogo de Marcas
INSERT INTO marcas (nombre, pais_origen) VALUES
('eSUN', 'China'),
('Polymaker', 'China / USA'),
('Creality', 'China'),
('Sunlu', 'China'),
('Hatchbox', 'USA'),
('Bambu Lab', 'China'),
('Prusament', 'República Checa')
ON CONFLICT (nombre) DO NOTHING;

-- Catálogo de Acabados
INSERT INTO acabados (nombre, descripcion) VALUES
('Estándar Mate', 'Superficie sin brillo para ocultar líneas de capa'),
('Brillante / Glossy', 'Superficie reflejante'),
('Seda / Silk', 'Efecto nacarado metálico sedoso'),
('Fibra de Carbono', 'Cargado con 15% fibra de carbono picada para rigidez estructural'),
('Glow in the dark', 'Fosforescente luminiscente')
ON CONFLICT (nombre) DO NOTHING;

-- Catálogo de Consumibles del Taller
INSERT INTO consumibles_catalogo (nombre, categoria, unidad_medida, stock_actual, stock_minimo_alerta, costo_referencia, ubicacion_almacen) VALUES
('Alcohol Isopropílico 99.9%', 'Limpieza_Quimico', 'litros', 6.00, 2.00, 110.00, 'Gabinete Seguridad Q-1'),
('Boquilla Latón 0.4 mm V6', 'Refaccion_Mecanica', 'piezas', 14.00, 5.00, 35.00, 'Cajón Refacciones B-2'),
('Boquilla Acero Templado 0.4 mm', 'Refaccion_Mecanica', 'piezas', 4.00, 2.00, 180.00, 'Cajón Refacciones B-2'),
('Grasa Blanca de Litio PTFE', 'Lubricante', 'tubos', 3.00, 1.00, 145.00, 'Gabinete Herramientas H-1'),
('Pegamento en Barra Magigoo', 'Limpieza_Quimico', 'piezas', 5.00, 2.00, 240.00, 'Mesa Operativa'),
('Llave Dinamométrica para Boquillas', 'Herramienta', 'piezas', 2.00, 1.00, 480.00, 'Panel de Herramientas')
ON CONFLICT (nombre) DO NOTHING;

-- Parque de Impresoras 3D Iniciales
INSERT INTO impresoras (nombre_identificador, marca, modelo, tecnologia, volumen_xyz, potencia_watts, tarifa_kwh, horas_acumuladas, horas_para_mantenimiento, estado) VALUES
('Ender-3-V3-Lab1', 'Creality', 'Ender 3 V3 Plus', 'FDM', '300x300x330 mm', 350, 2.8500, 42.50, 250, 'disponible'),
('Bambu-X1C-Carbon', 'Bambu Lab', 'X1-Carbon Combo', 'FDM', '256x256x256 mm', 350, 2.8500, 118.00, 300, 'disponible'),
('Prusa-MK4-Estudio', 'Prusa Research', 'Original Prusa MK4', 'FDM', '250x210x220 mm', 280, 2.8500, 248.50, 250, 'disponible'),
('Elegoo-Saturn-MSLA', 'Elegoo', 'Saturn 3 Ultra 12K', 'MSLA', '218x122x260 mm', 150, 2.8500, 15.00, 150, 'disponible')
ON CONFLICT (nombre_identificador) DO NOTHING;

-- Bobinas en Inventario
INSERT INTO bobinas_inventario (
    id, codigo_barras_qr, id_tipo_material, id_color, id_marca, id_acabado, 
    diametro_mm, peso_inicial_g, stock_actual_g, tara_carrete_g, costo_bobina, ubicacion_almacen, estado_bobina, en_uso
) VALUES
(
    'b0000000-0000-0000-0000-000000000001',
    'SILM-BOB-PLA-001',
    (SELECT id FROM tipos_material WHERE nombre_tecnico = 'PLA'),
    (SELECT id FROM colores WHERE nombre_color = 'Negro'),
    (SELECT id FROM marcas WHERE nombre = 'eSUN'),
    (SELECT id FROM acabados WHERE nombre = 'Estándar Mate'),
    1.75, 1000.00, 780.00, 220.00, 380.00, 'Estante A1-01', 'en_uso', TRUE
),
(
    'b0000000-0000-0000-0000-000000000002',
    'SILM-BOB-PETG-002',
    (SELECT id FROM tipos_material WHERE nombre_tecnico = 'PETG'),
    (SELECT id FROM colores WHERE nombre_color = 'Azul'),
    (SELECT id FROM marcas WHERE nombre = 'Polymaker'),
    (SELECT id FROM acabados WHERE nombre = 'Brillante / Glossy'),
    1.75, 1000.00, 450.00, 230.00, 420.00, 'Estante A1-02', 'en_uso', TRUE
),
(
    'b0000000-0000-0000-0000-000000000003',
    'SILM-BOB-PLA-003',
    (SELECT id FROM tipos_material WHERE nombre_tecnico = 'PLA'),
    (SELECT id FROM colores WHERE nombre_color = 'Rojo'),
    (SELECT id FROM marcas WHERE nombre = 'Creality'),
    (SELECT id FROM acabados WHERE nombre = 'Estándar Mate'),
    1.75, 1000.00, 85.00, 215.00, 350.00, 'Estante A2-01', 'bajo_stock', TRUE
),
(
    'b0000000-0000-0000-0000-000000000004',
    'SILM-BOB-TPU-004',
    (SELECT id FROM tipos_material WHERE nombre_tecnico = 'TPU'),
    (SELECT id FROM colores WHERE nombre_color = 'Naranja'),
    (SELECT id FROM marcas WHERE nombre = 'Sunlu'),
    (SELECT id FROM acabados WHERE nombre = 'Estándar Mate'),
    1.75, 1000.00, 1000.00, 225.00, 490.00, 'Estante B1-01', 'sellado', FALSE
)
ON CONFLICT (codigo_barras_qr) DO NOTHING;

-- Proyectos y Solicitantes Demo
INSERT INTO proyectos_solicitantes (codigo_proyecto, nombre_proyecto, solicitante_nombre, solicitante_tipo, departamento_carrera, correo_contacto, telefono_contacto) VALUES
('PRJ-MEC-2026-01', 'Chasis de Vehículo Autónomo Shell Eco-Marathon', 'Carlos Mendoza Alarcón', 'Estudiante', 'Ingeniería Mecánica', 'carlos.mendoza@alumnos.edu', '8331234567'),
('PRJ-BIO-2026-02', 'Prótesis Mioeléctrica Transradial Infantil', 'Dra. Elena Ramos Garza', 'Docente', 'Ingeniería Biomédica', 'elena.ramos@docentes.edu', '8339876543')
ON CONFLICT (codigo_proyecto) DO NOTHING;

-- Órdenes de Impresión Demo
INSERT INTO ordenes_impresion (
    folio_orden, id_proyecto, id_impresora, id_operador, nombre_pieza, categoria_pieza,
    cantidad_piezas, tiempo_impresion_texto, minutos_totales, numero_impresoras_usadas,
    tiene_combinacion_material, costo_energia, costo_material, costo_total_estimado, notas
) VALUES
(
    'ORD-2026-0001',
    (SELECT id FROM proyectos_solicitantes WHERE codigo_proyecto = 'PRJ-MEC-2026-01'),
    (SELECT id FROM impresoras WHERE nombre_identificador = 'Bambu-X1C-Carbon'),
    'a0000000-0000-0000-0000-000000000001',
    'Soporte de Suspensión Delantera',
    'Pieza Funcional',
    2,
    '4h 15m',
    255,
    1,
    FALSE,
    4.23,
    58.90,
    63.13,
    'Impreso a 6 paredes y 40% de relleno gyroid para resistencia mecánica.'
)
ON CONFLICT (folio_orden) DO NOTHING;

-- Detalle de Material para la orden demo (No dispara el trigger si ya existe)
INSERT INTO detalle_material_impresion (
    id_orden_impresion, id_bobina, gramos_unitarios, gramos_totales_lote, costo_linea, se_desconto_inventario
) VALUES
(
    (SELECT id FROM ordenes_impresion WHERE folio_orden = 'ORD-2026-0001'),
    'b0000000-0000-0000-0000-000000000001',
    77.50,
    155.00,
    58.90,
    FALSE
)
ON CONFLICT DO NOTHING;

-- Requisición de Pedido Demo
INSERT INTO pedidos_materiales (
    id, id_usuario_solicita, enlace_pagina_web, estado_urgencia, tipo_urgencia, detalle_urgencia, es_solo_consumibles, costo_total_pedido
) VALUES
(
    'REQ-2026-001',
    'a0000000-0000-0000-0000-000000000001',
    'https://amazon.com.mx/esun-pla-plus',
    'Rojo',
    'Paro Crítico',
    'Falta urgente de filamento PLA Negro y boquillas de latón para proyecto de titulación.',
    FALSE,
    1240.00
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO items_pedido_filamento (id_pedido, id_tipo_material, color_nombre, peso_carrete_g, costo_unitario)
VALUES
('REQ-2026-001', (SELECT id FROM tipos_material WHERE nombre_tecnico = 'PLA'), 'Negro', 1000.00, 380.00),
('REQ-2026-001', (SELECT id FROM tipos_material WHERE nombre_tecnico = 'PETG'), 'Azul', 1000.00, 420.00)
ON CONFLICT DO NOTHING;

INSERT INTO items_pedido_consumible (id_pedido, id_consumible, nombre_insumo, cantidad_texto, costo_unitario, estado_urgencia)
VALUES
('REQ-2026-001', (SELECT id FROM consumibles_catalogo WHERE nombre LIKE 'Boquilla Latón%'), 'Boquilla Latón 0.4 mm V6', '5 piezas', 175.00, 'Rojo')
ON CONFLICT DO NOTHING;

-- Registro de Auditoría Inicial
INSERT INTO auditoria_logs (id_usuario, modulo_afectado, accion, registro_id, datos_nuevos_json)
VALUES (
    'a0000000-0000-0000-0000-000000000001',
    'SISTEMA_BASE_DATOS',
    'INICIALIZACION_ESQUEMA_SILM',
    'silm_db',
    '{"version": "1.0.0", "motor": "PostgreSQL 16", "tablas_creadas": 20, "estado": "exitoso"}'::jsonb
);

-- Fin del script

