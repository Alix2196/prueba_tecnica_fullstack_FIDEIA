package ai.fideia.tickets.dto;

import ai.fideia.tickets.domain.TicketEstado;
import java.time.OffsetDateTime;

public record HistorialEstadoResponse(
        Long id,
        TicketEstado estadoAnterior,
        TicketEstado estadoNuevo,
        UsuarioResumenResponse autor,
        OffsetDateTime creadoEn
) {
}
