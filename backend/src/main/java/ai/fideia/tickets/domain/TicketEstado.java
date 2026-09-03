package ai.fideia.tickets.domain;

/**
 * Espejo del tipo enumerado {@code ticket_estado} definido en db/schema.sql.
 * Las transiciones validas entre estados (README seccion 5) se implementan
 * en la capa de servicio, no aqui.
 */
public enum TicketEstado {
    ABIERTO,
    EN_PROCESO,
    RESUELTO,
    CERRADO
}
