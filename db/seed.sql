-- =====================================================================
-- Datos de prueba — Sistema de gestión de tickets (Mesa de ayuda)
-- Requiere que db/schema.sql ya haya sido aplicado sobre la base de datos.
-- =====================================================================
-- Carga:
--   - 10 usuarios: 6 solicitantes y 4 agentes. Uno de los agentes
--     (Ricardo Salazar) queda deliberadamente SIN tickets asignados, para
--     poder verificar que la consulta de reporte de la seccion 3.5 del
--     enunciado no lo hace desaparecer del resultado.
--   - 18 tickets (>= 15 exigidos), repartidos en los 4 estados
--     (5 ABIERTO, 5 EN_PROCESO, 4 RESUELTO, 4 CERRADO) y en las 3
--     prioridades.
--   - Comentarios, incluido el de solucion obligatorio en todo ticket
--     RESUELTO/CERRADO (README seccion 5).
--   - Historial de estado consistente con el camino real de cada ticket
--     (ABIERTO -> EN_PROCESO -> RESUELTO -> CERRADO, segun corresponda).
--
-- Nota sobre fechas: se usan offsets relativos a now() para que el script
-- siga siendo valido sin importar cuando se ejecute. Para los 4 tickets
-- que terminan CERRADO, el paso final es un UPDATE (no un INSERT): el
-- trigger trg_ticket_set_fecha_actualizacion pisa fecha_actualizacion con
-- el momento real de carga del seed (eso es correcto y esperado, es la
-- misma regla que aplica en produccion). El historial_estado si conserva
-- fechas historicas realistas para esa transicion, porque esa tabla no
-- tiene un trigger que reescriba fechas.
--
-- TRUNCATE (a diferencia de DELETE) no dispara triggers por fila, asi que
-- no choca con la inmutabilidad de historial_estado y deja el script
-- reejecutable desde cero.

TRUNCATE TABLE historial_estado, comentario, ticket, usuario RESTART IDENTITY CASCADE;

-- ---------------------------------------------------------------------
-- Usuarios
-- ---------------------------------------------------------------------
INSERT INTO usuario (id, nombre, rol) VALUES
    (1, 'Laura Gómez', 'SOLICITANTE'),
    (2, 'Carlos Rodríguez', 'SOLICITANTE'),
    (3, 'Marta Fernández', 'SOLICITANTE'),
    (4, 'Diego Torres', 'SOLICITANTE'),
    (5, 'Sofía Ramírez', 'SOLICITANTE'),
    (6, 'Andrés Castillo', 'SOLICITANTE'),
    (7, 'Elena Vargas', 'AGENTE'),
    (8, 'Julián Morales', 'AGENTE'),
    (9, 'Patricia Nieto', 'AGENTE'),
    (10, 'Ricardo Salazar', 'AGENTE'); -- sin tickets asignados, a proposito

-- ---------------------------------------------------------------------
-- Tickets — ABIERTO (5)
-- ---------------------------------------------------------------------
INSERT INTO ticket (id, titulo, descripcion, prioridad, estado, solicitante_id, agente_id, fecha_creacion, fecha_actualizacion) VALUES
    (1, 'No puedo acceder a la VPN corporativa', 'Desde ayer la VPN rechaza mis credenciales, ya intente reiniciar el equipo.', 'BAJA', 'ABIERTO', 1, NULL, now() - interval '1 day', now() - interval '1 day'),
    (2, 'Solicito instalación de Microsoft Project', 'Necesito la licencia y el instalador para planificar el proyecto del trimestre.', 'MEDIA', 'ABIERTO', 2, NULL, now() - interval '2 days', now() - interval '2 days'),
    (3, 'El teclado inalámbrico no responde', 'El teclado se desconecta cada pocos minutos, ya cambie las pilas.', 'BAJA', 'ABIERTO', 3, 7, now() - interval '3 days', now() - interval '3 days'),
    (4, 'Servidor de archivos compartidos caído', 'Nadie del area comercial puede acceder a la carpeta compartida desde esta mañana.', 'ALTA', 'ABIERTO', 4, NULL, now() - interval '12 hours', now() - interval '12 hours'),
    (5, 'Solicito acceso al sistema de nómina', 'Ingrese la semana pasada y aun no tengo permisos para consultar mis pagos.', 'MEDIA', 'ABIERTO', 5, 8, now() - interval '5 days', now() - interval '5 days');

-- ---------------------------------------------------------------------
-- Tickets — EN_PROCESO (5)
-- ---------------------------------------------------------------------
INSERT INTO ticket (id, titulo, descripcion, prioridad, estado, solicitante_id, agente_id, fecha_creacion, fecha_actualizacion) VALUES
    (6, 'Impresora del piso 3 no imprime a color', 'Solo imprime en blanco y negro desde el cambio de cartuchos.', 'MEDIA', 'EN_PROCESO', 6, 7, now() - interval '6 days', now() - interval '5 days'),
    (7, 'Correo corporativo no sincroniza en el celular', 'La app de correo del celular dejo de recibir mensajes nuevos.', 'BAJA', 'EN_PROCESO', 1, 8, now() - interval '4 days', now() - interval '3 days'),
    (8, 'Caída intermitente de la red WiFi en sala de juntas', 'La señal se cae varias veces durante las reuniones.', 'ALTA', 'EN_PROCESO', 2, 9, now() - interval '2 days', now() - interval '1 day'),
    (9, 'Solicito migración de equipo a Windows 11', 'Mi equipo aun tiene Windows 10 y necesito compatibilidad con las nuevas herramientas.', 'BAJA', 'EN_PROCESO', 3, 7, now() - interval '10 days', now() - interval '8 days'),
    (10, 'Bloqueo de cuenta por intentos fallidos de acceso', 'Mi cuenta se bloqueo despues de varios intentos fallidos de inicio de sesion.', 'ALTA', 'EN_PROCESO', 4, 9, now() - interval '1 day', now() - interval '10 hours');

-- ---------------------------------------------------------------------
-- Tickets — RESUELTO (4)
-- ---------------------------------------------------------------------
INSERT INTO ticket (id, titulo, descripcion, prioridad, estado, solicitante_id, agente_id, fecha_creacion, fecha_actualizacion, fecha_resolucion) VALUES
    (11, 'Instalación de antivirus corporativo', 'Se necesita instalar el antivirus estandar de la empresa en el equipo nuevo.', 'MEDIA', 'RESUELTO', 5, 8, now() - interval '9 days', now() - interval '2 days', now() - interval '2 days'),
    (12, 'Error al generar reporte mensual en el ERP', 'El modulo de reportes lanza un error al exportar a Excel.', 'ALTA', 'RESUELTO', 6, 9, now() - interval '15 days', now() - interval '6 days', now() - interval '6 days'),
    (13, 'Solicitud de mouse ergonómico', 'Por recomendacion medica necesito un mouse ergonomico para el puesto de trabajo.', 'BAJA', 'RESUELTO', 1, 7, now() - interval '20 days', now() - interval '18 days', now() - interval '18 days'),
    (14, 'Configuración de firma de correo institucional', 'Necesito que me configuren la firma con el logo nuevo de la empresa.', 'BAJA', 'RESUELTO', 2, 8, now() - interval '7 days', now() - interval '1 day', now() - interval '1 day');

-- ---------------------------------------------------------------------
-- Tickets — futuros CERRADO (4): se insertan como RESUELTO primero.
-- fn_comentario_ticket_no_cerrado bloquea comentarios sobre tickets ya
-- CERRADO, asi que el comentario de solucion se inserta antes de cerrar.
-- ---------------------------------------------------------------------
INSERT INTO ticket (id, titulo, descripcion, prioridad, estado, solicitante_id, agente_id, fecha_creacion, fecha_actualizacion, fecha_resolucion) VALUES
    (15, 'Reemplazo de cable de red dañado', 'El cable de red del puesto 14 esta dañado y la conexion se cae constantemente.', 'BAJA', 'RESUELTO', 3, 9, now() - interval '40 days', now() - interval '35 days', now() - interval '35 days'),
    (16, 'Actualización de licencia de Office', 'La licencia de Office vencio y necesito renovarla para seguir trabajando.', 'MEDIA', 'RESUELTO', 4, 7, now() - interval '30 days', now() - interval '25 days', now() - interval '25 days'),
    (17, 'Falla de audio en sala de videoconferencias', 'El microfono de la sala principal no se escucha en las llamadas.', 'ALTA', 'RESUELTO', 5, 8, now() - interval '50 days', now() - interval '45 days', now() - interval '45 days'),
    (18, 'Solicito restablecer contraseña de dominio', 'Olvide mi contraseña de dominio y necesito que me la restablezcan.', 'MEDIA', 'RESUELTO', 6, 9, now() - interval '14 days', now() - interval '10 days', now() - interval '10 days');

-- ---------------------------------------------------------------------
-- Comentarios
-- ---------------------------------------------------------------------
-- Comentarios de seguimiento normales (es_solucion = false)
INSERT INTO comentario (ticket_id, autor_id, texto, es_solucion, creado_en) VALUES
    (6, 7, 'Ya se reviso el cartucho de color, se pidio uno de reemplazo al proveedor.', false, now() - interval '5 days'),
    (8, 9, 'Se reviso el punto de acceso de la sala, se va a reemplazar el equipo esta semana.', false, now() - interval '1 day'),
    (10, 9, 'Se confirmo la identidad del usuario, se esta procesando el desbloqueo.', false, now() - interval '10 hours');

-- Comentarios de solucion obligatorios (es_solucion = true), uno por cada
-- ticket RESUELTO o CERRADO (en este punto los 18 estan en RESUELTO o antes).
INSERT INTO comentario (ticket_id, autor_id, texto, es_solucion, creado_en) VALUES
    (11, 8, 'Se instalo el antivirus corporativo y se verifico que las definiciones esten actualizadas.', true, now() - interval '2 days'),
    (12, 9, 'Se corrigio el modulo de exportacion a Excel del ERP y se probo la generacion del reporte.', true, now() - interval '6 days'),
    (13, 7, 'Se entrego el mouse ergonomico solicitado en el puesto de trabajo.', true, now() - interval '18 days'),
    (14, 8, 'Se configuro la firma institucional con el logo actualizado.', true, now() - interval '1 day'),
    (15, 9, 'Se reemplazo el cable de red del puesto 14, conexion estable verificada.', true, now() - interval '35 days'),
    (16, 7, 'Se renovo la licencia de Office para el puesto de trabajo.', true, now() - interval '25 days'),
    (17, 8, 'Se reemplazo el microfono de la sala principal y se probo en una llamada de prueba.', true, now() - interval '45 days'),
    (18, 9, 'Se restablecio la contraseña de dominio y se le indico al usuario como cambiarla.', true, now() - interval '10 days');

-- ---------------------------------------------------------------------
-- Historial de estado — ABIERTO (solo el registro de creacion)
-- ---------------------------------------------------------------------
INSERT INTO historial_estado (ticket_id, estado_anterior, estado_nuevo, autor_id, creado_en) VALUES
    (1, NULL, 'ABIERTO', 1, now() - interval '1 day'),
    (2, NULL, 'ABIERTO', 2, now() - interval '2 days'),
    (3, NULL, 'ABIERTO', 3, now() - interval '3 days'),
    (4, NULL, 'ABIERTO', 4, now() - interval '12 hours'),
    (5, NULL, 'ABIERTO', 5, now() - interval '5 days');

-- ---------------------------------------------------------------------
-- Historial de estado — EN_PROCESO (creacion + transicion)
-- ---------------------------------------------------------------------
INSERT INTO historial_estado (ticket_id, estado_anterior, estado_nuevo, autor_id, creado_en) VALUES
    (6, NULL, 'ABIERTO', 6, now() - interval '6 days'),
    (6, 'ABIERTO', 'EN_PROCESO', 7, now() - interval '5 days'),
    (7, NULL, 'ABIERTO', 1, now() - interval '4 days'),
    (7, 'ABIERTO', 'EN_PROCESO', 8, now() - interval '3 days'),
    (8, NULL, 'ABIERTO', 2, now() - interval '2 days'),
    (8, 'ABIERTO', 'EN_PROCESO', 9, now() - interval '1 day'),
    (9, NULL, 'ABIERTO', 3, now() - interval '10 days'),
    (9, 'ABIERTO', 'EN_PROCESO', 7, now() - interval '8 days'),
    (10, NULL, 'ABIERTO', 4, now() - interval '1 day'),
    (10, 'ABIERTO', 'EN_PROCESO', 9, now() - interval '10 hours');

-- ---------------------------------------------------------------------
-- Historial de estado — RESUELTO (creacion + EN_PROCESO + RESUELTO)
-- Incluye los 4 tickets RESUELTO y los 4 que luego se cierran mas abajo.
-- ---------------------------------------------------------------------
INSERT INTO historial_estado (ticket_id, estado_anterior, estado_nuevo, autor_id, creado_en) VALUES
    (11, NULL, 'ABIERTO', 5, now() - interval '9 days'),
    (11, 'ABIERTO', 'EN_PROCESO', 8, now() - interval '8 days'),
    (11, 'EN_PROCESO', 'RESUELTO', 8, now() - interval '2 days'),
    (12, NULL, 'ABIERTO', 6, now() - interval '15 days'),
    (12, 'ABIERTO', 'EN_PROCESO', 9, now() - interval '13 days'),
    (12, 'EN_PROCESO', 'RESUELTO', 9, now() - interval '6 days'),
    (13, NULL, 'ABIERTO', 1, now() - interval '20 days'),
    (13, 'ABIERTO', 'EN_PROCESO', 7, now() - interval '19 days'),
    (13, 'EN_PROCESO', 'RESUELTO', 7, now() - interval '18 days'),
    (14, NULL, 'ABIERTO', 2, now() - interval '7 days'),
    (14, 'ABIERTO', 'EN_PROCESO', 8, now() - interval '5 days'),
    (14, 'EN_PROCESO', 'RESUELTO', 8, now() - interval '1 day'),
    (15, NULL, 'ABIERTO', 3, now() - interval '40 days'),
    (15, 'ABIERTO', 'EN_PROCESO', 9, now() - interval '38 days'),
    (15, 'EN_PROCESO', 'RESUELTO', 9, now() - interval '35 days'),
    (16, NULL, 'ABIERTO', 4, now() - interval '30 days'),
    (16, 'ABIERTO', 'EN_PROCESO', 7, now() - interval '27 days'),
    (16, 'EN_PROCESO', 'RESUELTO', 7, now() - interval '25 days'),
    (17, NULL, 'ABIERTO', 5, now() - interval '50 days'),
    (17, 'ABIERTO', 'EN_PROCESO', 8, now() - interval '47 days'),
    (17, 'EN_PROCESO', 'RESUELTO', 8, now() - interval '45 days'),
    (18, NULL, 'ABIERTO', 6, now() - interval '14 days'),
    (18, 'ABIERTO', 'EN_PROCESO', 9, now() - interval '12 days'),
    (18, 'EN_PROCESO', 'RESUELTO', 9, now() - interval '10 days');

-- ---------------------------------------------------------------------
-- Cierre de los 4 tickets CERRADO (UPDATE, ya con su comentario de
-- solucion guardado). fecha_actualizacion queda en el momento de carga
-- del seed por el trigger trg_ticket_set_fecha_actualizacion.
-- ---------------------------------------------------------------------
UPDATE ticket SET estado = 'CERRADO' WHERE id IN (15, 16, 17, 18);

INSERT INTO historial_estado (ticket_id, estado_anterior, estado_nuevo, autor_id, creado_en) VALUES
    (15, 'RESUELTO', 'CERRADO', 9, now() - interval '33 days'),
    (16, 'RESUELTO', 'CERRADO', 7, now() - interval '23 days'),
    (17, 'RESUELTO', 'CERRADO', 8, now() - interval '43 days'),
    (18, 'RESUELTO', 'CERRADO', 9, now() - interval '8 days');

-- ---------------------------------------------------------------------
-- Reajuste de secuencias (usuario y ticket usaron ids explicitos)
-- ---------------------------------------------------------------------
SELECT setval('usuario_id_seq', (SELECT MAX(id) FROM usuario));
SELECT setval('ticket_id_seq', (SELECT MAX(id) FROM ticket));
