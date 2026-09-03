package ai.fideia.tickets.dto;

import ai.fideia.tickets.domain.TicketEstado;
import jakarta.validation.constraints.NotNull;

/**
 * {@code comentario} solo es obligatorio cuando {@code estadoNuevo} es
 * RESUELTO (README seccion 5); por eso no lleva {@code @NotBlank} aqui, esa
 * regla condicional se valida en el servicio.
 */
public record CambiarEstadoRequest(
        @NotNull(message = "el estado nuevo es obligatorio")
        TicketEstado estadoNuevo,

        @NotNull(message = "el autor es obligatorio")
        Long autorId,

        String comentario
) {
}
