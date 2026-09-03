-- =====================================================================
-- Esquema de base de datos — Sistema de gestión de tickets (Mesa de ayuda)
-- Motor: PostgreSQL 14+
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Tipos enumerados
-- ---------------------------------------------------------------------
-- Enums nativos en vez de VARCHAR + CHECK: el motor rechaza valores
-- fuera del dominio permitido sin necesidad de validación adicional.

CREATE TYPE usuario_rol AS ENUM ('SOLICITANTE', 'AGENTE');

CREATE TYPE ticket_prioridad AS ENUM ('BAJA', 'MEDIA', 'ALTA');

CREATE TYPE ticket_estado AS ENUM ('ABIERTO', 'EN_PROCESO', 'RESUELTO', 'CERRADO');

-- ---------------------------------------------------------------------
-- 2. Tabla: usuario
-- ---------------------------------------------------------------------
-- Catálogo simple precargado (solicitantes y agentes). No hay registro
-- ni gestión de usuarios vía API (fuera de alcance, ver README §12).

CREATE TABLE usuario (
    id          BIGSERIAL PRIMARY KEY,
    nombre      VARCHAR(150) NOT NULL,
    rol         usuario_rol NOT NULL,
    creado_en   TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE usuario IS 'Catálogo precargado de solicitantes y agentes. Sin autenticación real.';

-- ---------------------------------------------------------------------
-- 3. Tabla: ticket
-- ---------------------------------------------------------------------

CREATE TABLE ticket (
    id                   BIGSERIAL PRIMARY KEY,
    titulo               VARCHAR(200) NOT NULL,
    descripcion          TEXT NOT NULL,
    prioridad            ticket_prioridad NOT NULL,
    estado               ticket_estado NOT NULL DEFAULT 'ABIERTO',
    solicitante_id       BIGINT NOT NULL REFERENCES usuario(id) ON DELETE RESTRICT,
    agente_id            BIGINT NULL REFERENCES usuario(id) ON DELETE SET NULL,
    fecha_creacion       TIMESTAMPTZ NOT NULL DEFAULT now(),
    fecha_actualizacion  TIMESTAMPTZ NOT NULL DEFAULT now(),
    fecha_resolucion     TIMESTAMPTZ NULL,

    CONSTRAINT chk_ticket_titulo_no_vacio CHECK (length(trim(titulo)) > 0),
    CONSTRAINT chk_ticket_descripcion_no_vacia CHECK (length(trim(descripcion)) > 0)
);

COMMENT ON COLUMN ticket.fecha_resolucion IS
    'Momento de la última transición a RESUELTO. Usada para validar la ventana de 3 días de reapertura (RESUELTO -> EN_PROCESO).';

-- ---------------------------------------------------------------------
-- 4. Tabla: comentario
-- ---------------------------------------------------------------------

CREATE TABLE comentario (
    id          BIGSERIAL PRIMARY KEY,
    ticket_id   BIGINT NOT NULL REFERENCES ticket(id) ON DELETE CASCADE,
    autor_id    BIGINT NOT NULL REFERENCES usuario(id) ON DELETE RESTRICT,
    texto       TEXT NOT NULL,
    es_solucion BOOLEAN NOT NULL DEFAULT false,
    creado_en   TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT chk_comentario_texto_no_vacio CHECK (length(trim(texto)) > 0)
);

COMMENT ON COLUMN comentario.es_solucion IS
    'Marca el comentario de solución no vacío exigido al transicionar el ticket a RESUELTO.';

-- ---------------------------------------------------------------------
-- 5. Tabla: historial_estado
-- ---------------------------------------------------------------------
-- Registro inmutable de cada transición. No se edita ni se borra
-- (ver trigger fn_historial_inmutable más abajo).

CREATE TABLE historial_estado (
    id              BIGSERIAL PRIMARY KEY,
    ticket_id       BIGINT NOT NULL REFERENCES ticket(id) ON DELETE CASCADE,
    estado_anterior ticket_estado NULL,
    estado_nuevo    ticket_estado NOT NULL,
    autor_id        BIGINT NOT NULL REFERENCES usuario(id) ON DELETE RESTRICT,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON COLUMN historial_estado.estado_anterior IS
    'NULL únicamente en el registro que documenta la creación del ticket (entrada a ABIERTO).';

-- =====================================================================
-- 6. Triggers — restricciones de negocio reforzadas en la base de datos
-- =====================================================================
-- La máquina de estados (transiciones válidas, regla de los 3 días) vive
-- en el backend, dentro de una transacción que actualiza ticket,
-- comentario e historial_estado de forma atómica (ver README §7).
-- Los triggers de abajo son una segunda línea de defensa a nivel de
-- base de datos para invariantes que NO deben violarse aunque exista
-- un error en el backend: inmutabilidad del historial, integridad de
-- roles y bloqueo de comentarios en tickets cerrados.

-- 6.1 Inmutabilidad del historial de estados
CREATE FUNCTION fn_historial_inmutable() RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'El historial de estados es inmutable: no se permite % sobre historial_estado', TG_OP;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_historial_inmutable
    BEFORE UPDATE OR DELETE ON historial_estado
    FOR EACH ROW EXECUTE FUNCTION fn_historial_inmutable();

-- 6.2 Integridad de roles: solicitante_id debe ser SOLICITANTE,
--     agente_id (si viene) debe ser AGENTE.
CREATE FUNCTION fn_ticket_validar_roles() RETURNS TRIGGER AS $$
DECLARE
    rol_solicitante usuario_rol;
    rol_agente usuario_rol;
BEGIN
    SELECT rol INTO rol_solicitante FROM usuario WHERE id = NEW.solicitante_id;
    IF rol_solicitante IS DISTINCT FROM 'SOLICITANTE' THEN
        RAISE EXCEPTION 'El usuario % no tiene rol SOLICITANTE', NEW.solicitante_id;
    END IF;

    IF NEW.agente_id IS NOT NULL THEN
        SELECT rol INTO rol_agente FROM usuario WHERE id = NEW.agente_id;
        IF rol_agente IS DISTINCT FROM 'AGENTE' THEN
            RAISE EXCEPTION 'El usuario % no tiene rol AGENTE', NEW.agente_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ticket_validar_roles
    BEFORE INSERT OR UPDATE OF solicitante_id, agente_id ON ticket
    FOR EACH ROW EXECUTE FUNCTION fn_ticket_validar_roles();

-- 6.3 Un ticket CERRADO no admite comentarios nuevos
CREATE FUNCTION fn_comentario_ticket_no_cerrado() RETURNS TRIGGER AS $$
DECLARE
    estado_actual ticket_estado;
BEGIN
    SELECT estado INTO estado_actual FROM ticket WHERE id = NEW.ticket_id;
    IF estado_actual = 'CERRADO' THEN
        RAISE EXCEPTION 'No se pueden agregar comentarios a un ticket CERRADO (ticket %)', NEW.ticket_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_comentario_ticket_no_cerrado
    BEFORE INSERT ON comentario
    FOR EACH ROW EXECUTE FUNCTION fn_comentario_ticket_no_cerrado();

-- 6.4 Actualización automática de fecha_actualizacion en cada UPDATE
CREATE FUNCTION fn_ticket_set_fecha_actualizacion() RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ticket_set_fecha_actualizacion
    BEFORE UPDATE ON ticket
    FOR EACH ROW EXECUTE FUNCTION fn_ticket_set_fecha_actualizacion();

-- =====================================================================
-- 7. Índices
-- =====================================================================
-- Justificación detallada en README §9. Resumen:

-- Filtro por estado (solo) y por estado+prioridad combinados (GET /tickets)
CREATE INDEX idx_ticket_estado_prioridad ON ticket (estado, prioridad);

-- Filtro por prioridad sola (no cubierto por el índice compuesto anterior)
CREATE INDEX idx_ticket_prioridad ON ticket (prioridad);

-- Consulta de reporte: agrupación por agente sobre tickets no cerrados
CREATE INDEX idx_ticket_agente_estado ON ticket (agente_id, estado);

-- Orden por defecto del listado (más recientes primero) + paginación
CREATE INDEX idx_ticket_fecha_creacion ON ticket (fecha_creacion DESC);

-- Carga de comentarios e historial en la vista de detalle de un ticket
CREATE INDEX idx_comentario_ticket_id ON comentario (ticket_id);
CREATE INDEX idx_historial_ticket_id ON historial_estado (ticket_id);
