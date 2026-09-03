package ai.fideia.tickets.dto;

import java.time.OffsetDateTime;

public record ComentarioResponse(
        Long id,
        String texto,
        UsuarioResumenResponse autor,
        boolean esSolucion,
        OffsetDateTime creadoEn
) {
}
