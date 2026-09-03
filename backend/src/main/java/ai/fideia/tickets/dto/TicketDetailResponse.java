package ai.fideia.tickets.dto;

import java.util.List;

/** Detalle de un ticket con sus comentarios y su historial de estados (enunciado seccion 3.4). */
public record TicketDetailResponse(
        TicketResponse ticket,
        List<ComentarioResponse> comentarios,
        List<HistorialEstadoResponse> historial
) {
}
