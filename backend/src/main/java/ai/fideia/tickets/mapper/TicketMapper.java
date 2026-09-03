package ai.fideia.tickets.mapper;

import ai.fideia.tickets.domain.Comentario;
import ai.fideia.tickets.domain.HistorialEstado;
import ai.fideia.tickets.domain.Ticket;
import ai.fideia.tickets.domain.Usuario;
import ai.fideia.tickets.dto.ComentarioResponse;
import ai.fideia.tickets.dto.HistorialEstadoResponse;
import ai.fideia.tickets.dto.TicketDetailResponse;
import ai.fideia.tickets.dto.TicketResponse;
import ai.fideia.tickets.dto.UsuarioResumenResponse;
import java.util.List;

/** Traduce entidades JPA a los DTOs de respuesta de la API. */
public final class TicketMapper {

    private TicketMapper() {
    }

    public static UsuarioResumenResponse toResumen(Usuario usuario) {
        if (usuario == null) {
            return null;
        }
        return new UsuarioResumenResponse(usuario.getId(), usuario.getNombre(), usuario.getRol());
    }

    public static TicketResponse toResponse(Ticket ticket) {
        return new TicketResponse(
                ticket.getId(),
                ticket.getTitulo(),
                ticket.getDescripcion(),
                ticket.getPrioridad(),
                ticket.getEstado(),
                toResumen(ticket.getSolicitante()),
                toResumen(ticket.getAgente()),
                ticket.getFechaCreacion(),
                ticket.getFechaActualizacion(),
                ticket.getFechaResolucion());
    }

    public static ComentarioResponse toResponse(Comentario comentario) {
        return new ComentarioResponse(
                comentario.getId(),
                comentario.getTexto(),
                toResumen(comentario.getAutor()),
                comentario.isEsSolucion(),
                comentario.getCreadoEn());
    }

    public static HistorialEstadoResponse toResponse(HistorialEstado historial) {
        return new HistorialEstadoResponse(
                historial.getId(),
                historial.getEstadoAnterior(),
                historial.getEstadoNuevo(),
                toResumen(historial.getAutor()),
                historial.getCreadoEn());
    }

    public static TicketDetailResponse toDetailResponse(
            Ticket ticket, List<Comentario> comentarios, List<HistorialEstado> historial) {
        return new TicketDetailResponse(
                toResponse(ticket),
                comentarios.stream().map(TicketMapper::toResponse).toList(),
                historial.stream().map(TicketMapper::toResponse).toList());
    }
}
