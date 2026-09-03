package ai.fideia.tickets.dto;

import ai.fideia.tickets.domain.TicketEstado;
import ai.fideia.tickets.domain.TicketPrioridad;
import java.time.OffsetDateTime;

public record TicketResponse(
        Long id,
        String titulo,
        String descripcion,
        TicketPrioridad prioridad,
        TicketEstado estado,
        UsuarioResumenResponse solicitante,
        UsuarioResumenResponse agente,
        OffsetDateTime fechaCreacion,
        OffsetDateTime fechaActualizacion,
        OffsetDateTime fechaResolucion
) {
}
