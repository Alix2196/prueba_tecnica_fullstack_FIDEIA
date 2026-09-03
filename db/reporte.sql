-- =====================================================================
-- Consulta de reporte — Sistema de gestión de tickets (Mesa de ayuda)
-- Enunciado seccion 3.5: para los tickets que aun no estan cerrados,
-- conteo agrupado por prioridad y agente asignado, junto con la
-- antiguedad promedio en dias. Los agentes sin tickets asignados no
-- deben desaparecer del resultado.
-- =====================================================================
-- Escrita a mano (no generada por el ORM). Usa idx_ticket_agente_estado
-- (agente_id, estado), creado especificamente para esta consulta
-- (README seccion 9), para el filtro por agente + estado no cerrado.

WITH agentes AS (
    -- Todos los agentes del catalogo, sin importar si tienen tickets o no.
    SELECT id, nombre
    FROM usuario
    WHERE rol = 'AGENTE'
),
prioridades AS (
    -- Las 3 prioridades del dominio, tomadas del tipo enumerado en vez de
    -- hardcodearlas, para que la consulta no se desactualice si el enum cambia.
    SELECT unnest(enum_range(NULL::ticket_prioridad)) AS prioridad
),
base AS (
    -- Un renglon por cada combinacion (agente, prioridad): esto es lo que
    -- garantiza que un agente sin tickets en una prioridad (o en ninguna)
    -- siga apareciendo en el resultado con conteo 0, en vez de desaparecer
    -- por un INNER JOIN o un GROUP BY que solo agrupe filas existentes.
    SELECT a.id AS agente_id, a.nombre AS agente_nombre, p.prioridad
    FROM agentes a
    CROSS JOIN prioridades p
)
SELECT
    b.agente_id,
    b.agente_nombre,
    b.prioridad,
    COUNT(t.id) AS cantidad_tickets,
    ROUND(AVG(EXTRACT(EPOCH FROM (now() - t.fecha_creacion)) / 86400)::numeric, 1) AS antiguedad_promedio_dias
FROM base b
LEFT JOIN ticket t
    ON t.agente_id = b.agente_id
   AND t.prioridad = b.prioridad
   AND t.estado <> 'CERRADO'
GROUP BY b.agente_id, b.agente_nombre, b.prioridad

UNION ALL

-- Tickets abiertos/en proceso/resueltos que todavia no tienen agente
-- asignado (agente_id NULL). No los exige el enunciado explicitamente,
-- pero omitirlos escondería trabajo pendiente sin dueño del reporte;
-- se listan aparte para no romper el agrupamiento por agente de arriba.
SELECT
    NULL::bigint AS agente_id,
    'Sin asignar' AS agente_nombre,
    t.prioridad,
    COUNT(*) AS cantidad_tickets,
    ROUND(AVG(EXTRACT(EPOCH FROM (now() - t.fecha_creacion)) / 86400)::numeric, 1) AS antiguedad_promedio_dias
FROM ticket t
WHERE t.agente_id IS NULL
  AND t.estado <> 'CERRADO'
GROUP BY t.prioridad

ORDER BY agente_nombre, prioridad;
